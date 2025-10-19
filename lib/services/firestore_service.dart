import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's stars collection reference
  CollectionReference? get _starsCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('stars');
  }

  // ============================================================================
  // DELTA SYNC METHODS (NEW)
  // ============================================================================

  // Upload only stars modified since last sync (DELTA SYNC)
  Future<void> uploadDeltaStars(List<GratitudeStar> localStars) async {
    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    try {
      // Get last sync time
      final lastSyncTime = await StorageService.getLastSyncTime();

      List<GratitudeStar> starsToUpload;

      if (lastSyncTime == null) {
        // First sync - upload everything
        print('📤 First sync - uploading all ${localStars.length} stars');
        starsToUpload = localStars;
      } else {
        // Delta sync - only upload stars modified since last sync
        starsToUpload = localStars.where((star) {
          return star.updatedAt.isAfter(lastSyncTime);
        }).toList();
        print('📤 Delta sync - uploading ${starsToUpload.length} stars (modified since $lastSyncTime)');
      }

      if (starsToUpload.isEmpty) {
        print('✅ No stars to upload');
        await StorageService.saveLastSyncTime(DateTime.now());
        return;
      }

      // Upload in batches (Firestore limit: 500 operations per batch)
      const batchSize = 500;
      int totalUploaded = 0;

      for (var i = 0; i < starsToUpload.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < starsToUpload.length)
            ? i + batchSize
            : starsToUpload.length;

        for (var j = i; j < end; j++) {
          final star = starsToUpload[j];
          final docRef = _starsCollection!.doc(star.id);
          batch.set(docRef, star.toJson());
        }

        await batch.commit();
        totalUploaded += (end - i);
        print('   Uploaded batch: $totalUploaded / ${starsToUpload.length}');
      }

      // Save sync timestamp
      await StorageService.saveLastSyncTime(DateTime.now());
      print('✅ Delta upload complete: $totalUploaded stars');

    } catch (e) {
      print('❌ Delta upload failed: $e');
      rethrow;
    }
  }

  // Download only stars modified since last sync (DELTA SYNC)
  Future<List<GratitudeStar>> downloadDeltaStars() async {
    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    try {
      // Get last sync time
      final lastSyncTime = await StorageService.getLastSyncTime();

      Query query = _starsCollection!;

      if (lastSyncTime != null) {
        // Delta sync - only get stars modified since last sync
        print('📥 Delta sync - downloading stars modified since $lastSyncTime');
        query = query
            .where('updatedAt', isGreaterThan: lastSyncTime.millisecondsSinceEpoch)
            .where('deleted', isEqualTo: false);  // Don't download deleted stars
      } else {
        // First sync - download everything
        print('📥 First sync - downloading all stars');
        query = query.where('deleted', isEqualTo: false);
      }

      final snapshot = await query.get();

      final stars = snapshot.docs
          .map((doc) {
        try {
          return GratitudeStar.fromJson(doc.data() as Map<String, dynamic>);
        } catch (e) {
          print('⚠️ Error parsing star ${doc.id}: $e');
          return null;
        }
      })
          .whereType<GratitudeStar>()
          .toList();

      print('✅ Delta download complete: ${stars.length} stars');
      return stars;

    } catch (e) {
      print('❌ Delta download failed: $e');
      rethrow;
    }
  }

  // Soft delete a star (mark as deleted, don't actually remove)
  Future<void> softDeleteStar(String starId) async {
    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    try {
      await _starsCollection!.doc(starId).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Star soft deleted: $starId');
    } catch (e) {
      print('❌ Soft delete failed: $e');
      rethrow;
    }
  }

  // Clean up stars that have been soft-deleted for >30 days
  Future<void> cleanupStaleDeletedStars() async {
    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    try {
      // Check if we've cleaned up recently (only run once per day)
      final prefs = await SharedPreferences.getInstance();
      final lastCleanup = prefs.getInt('last_cleanup_at');
      final now = DateTime.now().millisecondsSinceEpoch;

      if (lastCleanup != null &&
          now - lastCleanup < Duration(days: 1).inMilliseconds) {
        print('ℹ️ Cleanup already ran today, skipping');
        return;
      }

      // Find stars deleted >30 days ago
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final query = _starsCollection!
          .where('deleted', isEqualTo: true)
          .where('deletedAt', isLessThan: thirtyDaysAgo.millisecondsSinceEpoch);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print('✅ No stale deleted stars to clean up');
        await prefs.setInt('last_cleanup_at', now);
        return;
      }

      // Delete in batches
      const batchSize = 500;
      int totalDeleted = 0;

      for (var i = 0; i < snapshot.docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < snapshot.docs.length)
            ? i + batchSize
            : snapshot.docs.length;

        for (var j = i; j < end; j++) {
          batch.delete(snapshot.docs[j].reference);
        }

        await batch.commit();
        totalDeleted += (end - i);
      }

      await prefs.setInt('last_cleanup_at', now);
      print('✅ Cleaned up $totalDeleted stale deleted stars');

    } catch (e) {
      print('❌ Cleanup failed: $e');
      // Don't rethrow - cleanup failures shouldn't block the app
    }
  }

  // Sync: merge local and cloud data using delta sync
  Future<List<GratitudeStar>> syncStars(List<GratitudeStar> localStars) async {
    if (_auth.currentUser == null) {
      throw Exception('No user signed in');
    }

    print('🔄 Starting DELTA sync...');

    try {
      // Run cleanup in background (don't await)
      cleanupStaleDeletedStars();

      // Download stars modified since last sync
      final cloudDeltaStars = await downloadDeltaStars();
      print('   Cloud delta: ${cloudDeltaStars.length} stars');

      // Create a map of local stars by ID for fast lookup
      final localStarsMap = {for (var star in localStars) star.id: star};

      // Merge cloud delta with local stars
      for (final cloudStar in cloudDeltaStars) {
        final localStar = localStarsMap[cloudStar.id];

        if (localStar == null) {
          // New star from cloud - add it
          localStarsMap[cloudStar.id] = cloudStar;
        } else {
          // Star exists locally - keep newer version
          if (cloudStar.updatedAt.isAfter(localStar.updatedAt)) {
            localStarsMap[cloudStar.id] = cloudStar;
          }
        }
      }

      final mergedStars = localStarsMap.values.toList();

      // Upload local stars modified since last sync
      await uploadDeltaStars(mergedStars);

      print('✅ Delta sync complete. Total stars: ${mergedStars.length}');
      return mergedStars;

    } catch (e) {
      print('❌ Delta sync failed: $e');
      rethrow;
    }
  }

  // ============================================================================
  // LEGACY METHODS (kept for backward compatibility)
  // ============================================================================

  // Upload all local stars to Firestore (batch operation)
  Future<void> uploadStars(List<GratitudeStar> stars) async {
    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    if (stars.isEmpty) {
      print('📤 No stars to upload');
      return;
    }

    print('📤 Uploading ${stars.length} stars to Firestore...');

    // Firestore batch limit is 500 operations
    const batchSize = 500;

    for (var i = 0; i < stars.length; i += batchSize) {
      final batch = _firestore.batch();
      final end = (i + batchSize < stars.length) ? i + batchSize : stars.length;
      final batchStars = stars.sublist(i, end);

      for (final star in batchStars) {
        final docRef = _starsCollection!.doc(star.id);
        batch.set(docRef, star.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
      print('📤 Uploaded batch ${i ~/ batchSize + 1} (${batchStars.length} stars)');
    }

    print('✅ All stars uploaded successfully');
  }

  // Download all stars from Firestore
  Future<List<GratitudeStar>> downloadStars() async {
    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    print('📥 Downloading stars from Firestore...');

    final snapshot = await _starsCollection!.get();
    final stars = snapshot.docs
        .map((doc) {
      try {
        return GratitudeStar.fromJson(doc.data() as Map<String, dynamic>);
      } catch (e) {
        print('⚠️ Error parsing star ${doc.id}: $e');
        return null;
      }
    })
        .whereType<GratitudeStar>()
        .toList();

    print('✅ Downloaded ${stars.length} stars');
    return stars;
  }

  // Merge stars from an old anonymous account
  Future<void> mergeStarsFromAnonymousAccount(String anonymousUid, List<GratitudeStar> localStars) async {
    if (_auth.currentUser == null) {
      throw Exception('No user signed in');
    }

    print('🔀 Merging stars from anonymous account: $anonymousUid');

    try {
      // Try to get stars from the old anonymous account
      final oldStarsCollection = _firestore
          .collection('users')
          .doc(anonymousUid)
          .collection('stars');

      final oldSnapshot = await oldStarsCollection.get();
      final oldCloudStars = oldSnapshot.docs
          .map((doc) {
        try {
          return GratitudeStar.fromJson(doc.data());
        } catch (e) {
          print('⚠️ Error parsing old star ${doc.id}: $e');
          return null;
        }
      })
          .whereType<GratitudeStar>()
          .toList();

      print('   Found ${oldCloudStars.length} stars in old anonymous account');

      // Combine old cloud stars with local stars
      final allStarsToMerge = [...localStars, ...oldCloudStars];

      // Remove duplicates by ID, keeping the newest
      final starMap = <String, GratitudeStar>{};
      for (final star in allStarsToMerge) {
        if (!starMap.containsKey(star.id) ||
            star.updatedAt.isAfter(starMap[star.id]!.updatedAt)) {
          starMap[star.id] = star;
        }
      }

      final mergedStars = starMap.values.toList();
      print('   Merged to ${mergedStars.length} unique stars');

      // Upload all merged stars to the new account
      await uploadStars(mergedStars);

      print('✅ Successfully merged anonymous account data');

    } catch (e) {
      print('⚠️ Could not merge anonymous account data: $e');
      // Not critical - just upload local stars
      await uploadStars(localStars);
    }
  }

  // Add a single star to Firestore
  Future<void> addStar(GratitudeStar star) async {
    if (_starsCollection == null) return;

    try {
      await _starsCollection!.doc(star.id).set(star.toJson());
      print('➕ Star added to Firestore: ${star.id}');
    } catch (e) {
      print('❌ Error adding star to Firestore: $e');
      // Don't throw - local data is still saved
    }
  }

  // Update a star in Firestore
  Future<void> updateStar(GratitudeStar star) async {
    if (_starsCollection == null) return;

    try {
      await _starsCollection!.doc(star.id).update(star.toJson());
      print('✏️ Star updated in Firestore: ${star.id}');
    } catch (e) {
      print('❌ Error updating star in Firestore: $e');
      // Don't throw - local data is still saved
    }
  }

  // Delete a star from Firestore (now uses soft delete)
  Future<void> deleteStar(String starId) async {
    if (_starsCollection == null) return;

    try {
      // Use soft delete instead of hard delete
      await softDeleteStar(starId);
      print('✅ Star deleted: $starId');
    } catch (e) {
      print('❌ Delete failed: $e');
      // Don't throw - local data is still updated
    }
  }

  // Update user's last sync timestamp
  Future<void> updateLastSync() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).set({
        'lastSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('⚠️ Error updating last sync: $e');
    }
  }

  // Check if user has cloud data
  Future<bool> hasCloudData() async {
    if (_starsCollection == null) return false;

    try {
      final snapshot = await _starsCollection!.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('⚠️ Error checking cloud data: $e');
      return false;
    }
  }
}