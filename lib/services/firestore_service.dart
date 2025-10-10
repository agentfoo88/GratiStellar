import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    // Update last sync timestamp
    await updateLastSync();
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

  // Sync: merge local and cloud data intelligently
  Future<List<GratitudeStar>> syncStars(List<GratitudeStar> localStars) async {
    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    print('🔄 Syncing stars...');
    print('   Local stars: ${localStars.length}');

    // Download cloud stars
    final cloudStars = await downloadStars();
    print('   Cloud stars: ${cloudStars.length}');

    // Create maps for efficient lookup
    final cloudStarsMap = {for (var star in cloudStars) star.id: star};
    final localStarsMap = {for (var star in localStars) star.id: star};

    // Merge logic: keep all unique stars, use newest for duplicates
    final mergedStars = <GratitudeStar>[];
    final starsToUpload = <GratitudeStar>[];
    final allIds = {...localStarsMap.keys, ...cloudStarsMap.keys};

    for (final id in allIds) {
      final localStar = localStarsMap[id];
      final cloudStar = cloudStarsMap[id];

      if (localStar == null) {
        // Only in cloud - keep it
        mergedStars.add(cloudStar!);
      } else if (cloudStar == null) {
        // Only local - add to merged and mark for upload
        mergedStars.add(localStar);
        starsToUpload.add(localStar);
      } else {
        // In both - keep newer one
        final localNewer = localStar.createdAt.isAfter(cloudStar.createdAt);
        final newerStar = localNewer ? localStar : cloudStar;
        mergedStars.add(newerStar);

        // If local is newer, upload it
        if (localNewer) {
          starsToUpload.add(localStar);
        }
      }
    }

    // Upload any new or updated stars in batch
    if (starsToUpload.isNotEmpty) {
      print('📤 Uploading ${starsToUpload.length} new/updated stars');
      await uploadStars(starsToUpload);
    }

    print('✅ Sync complete. Total stars: ${mergedStars.length}');
    return mergedStars;
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
            star.createdAt.isAfter(starMap[star.id]!.createdAt)) {
          starMap[star.id] = star;
        }
      }

      final mergedStars = starMap.values.toList();
      print('   Merged to ${mergedStars.length} unique stars');

      // Upload all merged stars to the new account
      await uploadStars(mergedStars);

      print('✅ Successfully merged anonymous account data');

      // Optional: Delete old anonymous account data (commented out for safety)
      // await _firestore.collection('users').doc(anonymousUid).delete();

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

  // Delete a star from Firestore
  Future<void> deleteStar(String starId) async {
    if (_starsCollection == null) return;

    try {
      await _starsCollection!.doc(starId).delete();
      print('🗑️ Star deleted from Firestore: $starId');
    } catch (e) {
      print('❌ Error deleting star from Firestore: $e');
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