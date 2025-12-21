import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/error/error_context.dart';
import '../core/error/error_handler.dart';
import '../core/security/rate_limiter.dart';
import '../storage.dart';
import '../core/utils/app_logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's stars collection reference
  CollectionReference? get _starsCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('stars');
  }

  /// Helper method to execute Firestore operations with consistent error handling
  ///
  /// Wraps operations with ErrorHandler to convert FirebaseExceptions into
  /// appropriate RateLimitExceptions or generic Exceptions with user-friendly messages.
  Future<T> _executeFirestoreOperation<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    try {
      return await operation();
    } on FirebaseException catch (e, stack) {
      // Handle Firestore-specific errors with ErrorHandler
      if (e.code == 'resource-exhausted') {
        // Convert to RateLimitException for quota exceeded
        AppLogger.error('❌ Firestore quota exceeded: ${e.message}');
        throw RateLimitException('firestore_quota', Duration(minutes: 30));
      } else if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        // Network errors - retriable
        AppLogger.sync('❌ Network error during $operationName: ${e.message}');
        throw Exception('Network error: ${e.message}');
      } else {
        // Other Firebase errors - let ErrorHandler handle them
        final error = ErrorHandler.handle(e, stack, context: ErrorContext.database);
        AppLogger.sync('❌ Firebase error during $operationName: ${error.technicalMessage}');
        throw Exception(error.userMessage);
      }
    } catch (e, stack) {
      // Catch-all for unexpected errors
      if (e is RateLimitException) {
        rethrow; // Don't wrap RateLimitException
      }
      final error = ErrorHandler.handle(e, stack, context: ErrorContext.database);
      AppLogger.sync('❌ $operationName failed: ${error.technicalMessage}');
      throw Exception(error.userMessage);
    }
  }

  // ============================================================================
  // DELTA SYNC METHODS (NEW)
  // ============================================================================

  // Upload only stars modified since last sync (DELTA SYNC)
  Future<void> uploadDeltaStars(List<GratitudeStar> localStars) async {
    if (!RateLimiter.checkLimit('sync_operation')) {
      final retryAfter = RateLimiter.getTimeUntilReset('sync_operation');
      throw RateLimitException('sync_operation', retryAfter);
    }

    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    return _executeFirestoreOperation(() async {
      // Get last sync time
      final lastSyncTime = await StorageService.getLastSyncTime();

      List<GratitudeStar> starsToUpload;

      if (lastSyncTime == null) {
        // First sync - upload everything
        AppLogger.sync('📤 First sync - uploading all ${localStars.length} stars');
        starsToUpload = localStars;
      } else {
        // Delta sync - only upload stars modified since last sync
        starsToUpload = localStars.where((star) {
          return !star.updatedAt.isBefore(lastSyncTime);
        }).toList();
        AppLogger.sync('📤 Delta sync - uploading ${starsToUpload.length} stars (modified since $lastSyncTime)');
      }

      if (starsToUpload.isEmpty) {
        AppLogger.sync('✅ No stars to upload');
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

        // Track what we're uploading for debugging
        final List<String> starIds = [];

        for (var j = i; j < end; j++) {
          final star = starsToUpload[j];
          final docRef = _starsCollection!.doc(star.id);
          batch.set(docRef, star.toJson());
          starIds.add(star.id);
        }

        AppLogger.sync('   📤 Uploading batch with star IDs: ${starIds.join(", ")}');
        await batch.commit();
        totalUploaded += (end - i);
        AppLogger.sync('   ✅ Batch committed: $totalUploaded / ${starsToUpload.length}');
      }

      // Save sync timestamp
      await StorageService.saveLastSyncTime(DateTime.now());
      AppLogger.sync('✅ Delta upload complete: $totalUploaded stars');

      // VERIFICATION: Check if all stars actually made it to Firebase
      if (totalUploaded > 0 && totalUploaded <= 20) { // Only verify small syncs to avoid rate limits
        try {
          final snapshot = await _starsCollection!.limit(totalUploaded + 5).get();
          final actualCount = snapshot.docs.length;
          if (actualCount < totalUploaded) {
            AppLogger.sync('⚠️ MISMATCH: Uploaded $totalUploaded but Firebase shows $actualCount documents!');
          } else {
            AppLogger.sync('✅ Verification: Firebase has at least $actualCount stars');
          }
        } catch (e) {
          AppLogger.sync('⚠️ Could not verify upload: $e');
        }
      }
    }, 'upload');
  }

  // Download only stars modified since last sync (DELTA SYNC)
  Future<List<GratitudeStar>> downloadDeltaStars() async {
    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    return _executeFirestoreOperation(() async {
      // Get last sync time
      final lastSyncTime = await StorageService.getLastSyncTime();

      Query query = _starsCollection!;

      if (lastSyncTime != null) {
        // Delta sync - only get stars modified since last sync
        AppLogger.sync('📥 Delta sync - downloading stars modified since $lastSyncTime');
        query = query
            .where('updatedAt', isGreaterThan: lastSyncTime.millisecondsSinceEpoch)
            .where('deleted', isEqualTo: false);  // Don't download deleted stars
      } else {
        // First sync - download everything
        AppLogger.sync('📥 First sync - downloading all stars');
        query = query.where('deleted', isEqualTo: false);
      }

      final snapshot = await query.get();

      // #region agent log
      AppLogger.sync('📥 DEBUG: downloadDeltaStars query executed - lastSyncTime=${lastSyncTime?.toIso8601String()}, queryType=${lastSyncTime != null ? 'delta' : 'first'}, totalDocs=${snapshot.docs.length}');
      // #endregion

      final stars = snapshot.docs
          .map((doc) {
        try {
          final star = GratitudeStar.fromJson(doc.data() as Map<String, dynamic>);
          // #region agent log
          AppLogger.sync('📥 DEBUG: Downloaded star ${star.id} - galaxyId=${star.galaxyId}, deleted=${star.deleted}, updatedAt=${star.updatedAt.toIso8601String()}');
          // #endregion
          return star;
        } catch (e) {
          AppLogger.error('⚠️ Error parsing star ${doc.id}: $e');
          return null;
        }
      })
          .whereType<GratitudeStar>()
          .toList();

      // #region agent log
      final galaxyIdCounts = <String, int>{};
      for (final star in stars) {
        galaxyIdCounts[star.galaxyId] = (galaxyIdCounts[star.galaxyId] ?? 0) + 1;
      }
      AppLogger.sync('✅ DEBUG: Delta download complete: ${stars.length} stars by galaxy - ${galaxyIdCounts.toString()}');
      // #endregion

      AppLogger.sync('✅ Delta download complete: ${stars.length} stars');
      return stars;
    }, 'download');
  }

  // Download all stars for a specific galaxy (used when switching galaxies)
  Future<List<GratitudeStar>> downloadStarsForGalaxy(String galaxyId) async {
    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    return _executeFirestoreOperation(() async {
      AppLogger.sync('📥 Downloading all stars for galaxy: $galaxyId');

      final query = _starsCollection!
          .where('galaxyId', isEqualTo: galaxyId)
          .where('deleted', isEqualTo: false);

      final snapshot = await query.get();

      final stars = snapshot.docs
          .map((doc) {
        try {
          return GratitudeStar.fromJson(doc.data() as Map<String, dynamic>);
        } catch (e) {
          AppLogger.error('⚠️ Error parsing star ${doc.id}: $e');
          return null;
        }
      })
          .whereType<GratitudeStar>()
          .toList();

      AppLogger.sync('✅ Downloaded ${stars.length} stars for galaxy $galaxyId');
      return stars;
    }, 'galaxy download');
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

      AppLogger.success('✅ Star soft deleted: $starId');
    } catch (e) {
      AppLogger.error('❌ Soft delete failed: $e');
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
        AppLogger.warning('ℹ️ Cleanup already ran today, skipping');
        return;
      }

      // Find stars deleted >30 days ago
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final query = _starsCollection!
          .where('deleted', isEqualTo: true)
          .where('deletedAt', isLessThan: thirtyDaysAgo.millisecondsSinceEpoch);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        AppLogger.success('✅ No stale deleted stars to clean up');
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
      AppLogger.success('✅ Cleaned up $totalDeleted stale deleted stars');

    } catch (e) {
      AppLogger.error('❌ Cleanup failed: $e');
      // Don't rethrow - cleanup failures shouldn't block the app
    }
  }

  // Sync: merge local and cloud data using delta sync
  Future<List<GratitudeStar>> syncStars(List<GratitudeStar> localStars) async {
    if (_auth.currentUser == null) {
      throw Exception('No user signed in');
    }

    AppLogger.sync('🔄 Starting DELTA sync...');

    return _executeFirestoreOperation(() async {
      // Run cleanup in background (don't await)
      cleanupStaleDeletedStars();

      // Download stars modified since last sync
      final cloudDeltaStars = await downloadDeltaStars();
      AppLogger.sync('   Cloud delta: ${cloudDeltaStars.length} stars');

      // Create a map of local stars by ID for fast lookup
      final localStarsMap = {for (var star in localStars) star.id: star};

      // Merge cloud delta with local stars
      for (final cloudStar in cloudDeltaStars) {
        final localStar = localStarsMap[cloudStar.id];

        if (localStar == null) {
          // New star from cloud - add it
          localStarsMap[cloudStar.id] = cloudStar;
          // #region agent log
          AppLogger.sync('🔄 DEBUG: Adding new cloud star ${cloudStar.id} - galaxyId=${cloudStar.galaxyId}');
          // #endregion
        } else {
          // Star exists locally - keep newer version
          if (cloudStar.updatedAt.isAfter(localStar.updatedAt)) {
            localStarsMap[cloudStar.id] = cloudStar;
            // #region agent log
            AppLogger.sync('🔄 DEBUG: Replacing local star ${cloudStar.id} with cloud version - galaxyId=${cloudStar.galaxyId}, cloudUpdatedAt=${cloudStar.updatedAt.toIso8601String()}, localUpdatedAt=${localStar.updatedAt.toIso8601String()}');
            // #endregion
          }
        }
      }

      final mergedStars = localStarsMap.values.toList();
      
      // #region agent log
      final mergedGalaxyIdCounts = <String, int>{};
      for (final star in mergedStars) {
        mergedGalaxyIdCounts[star.galaxyId] = (mergedGalaxyIdCounts[star.galaxyId] ?? 0) + 1;
      }
      AppLogger.sync('🔄 DEBUG: Merged stars summary - total=${mergedStars.length}, by galaxy=${mergedGalaxyIdCounts.toString()}');
      // #endregion

      // Upload local stars modified since last sync
      await uploadDeltaStars(mergedStars);

      AppLogger.sync('✅ Delta sync complete. Total stars: ${mergedStars.length}');
      return mergedStars;
    }, 'sync');
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
      AppLogger.sync('📤 No stars to upload');
      return;
    }

    AppLogger.sync('📤 Uploading ${stars.length} stars to Firestore...');

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
      AppLogger.sync('📤 Uploaded batch ${i ~/ batchSize + 1} (${batchStars.length} stars)');
    }

    AppLogger.sync('✅ All stars uploaded successfully');
  }

  // Download all stars from Firestore
  Future<List<GratitudeStar>> downloadStars() async {
    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    AppLogger.sync('📥 Downloading stars from Firestore...');

    final snapshot = await _starsCollection!.get();
    final stars = snapshot.docs
        .map((doc) {
      try {
        return GratitudeStar.fromJson(doc.data() as Map<String, dynamic>);
      } catch (e) {
        AppLogger.error('⚠️ Error parsing star ${doc.id}: $e');
        return null;
      }
    })
        .whereType<GratitudeStar>()
        .toList();

    AppLogger.sync('✅ Downloaded ${stars.length} stars');
    return stars;
  }

  // Merge stars from an old anonymous account
  Future<void> mergeStarsFromAnonymousAccount(String anonymousUid, List<GratitudeStar> localStars) async {
    if (_auth.currentUser == null) {
      throw Exception('No user signed in');
    }

    AppLogger.auth('🔀 Merging stars from anonymous account: $anonymousUid');

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
          AppLogger.error('⚠️ Error parsing old star ${doc.id}: $e');
          return null;
        }
      })
          .whereType<GratitudeStar>()
          .toList();

      AppLogger.auth('   Found ${oldCloudStars.length} stars in old anonymous account');

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
      AppLogger.info('   Merged to ${mergedStars.length} unique stars');

      // Upload all merged stars to the new account
      await uploadStars(mergedStars);

      AppLogger.auth('✅ Successfully merged anonymous account data');

    } catch (e) {
      AppLogger.auth('⚠️ Could not merge anonymous account data: $e');
      // Not critical - just upload local stars
      await uploadStars(localStars);
    }
  }

  // Add a single star to Firestore
  Future<void> addStar(GratitudeStar star) async {
    if (_starsCollection == null) return;

    try {
      await _starsCollection!.doc(star.id).set(star.toJson());
      AppLogger.data('➕ Star added to Firestore: ${star.id}');
    } catch (e) {
      AppLogger.error('❌ Error adding star to Firestore: $e');
      // Don't throw - local data is still saved
    }
  }

  // Update a star in Firestore
  Future<void> updateStar(GratitudeStar star) async {
    if (_starsCollection == null) return;

    try {
      await _starsCollection!.doc(star.id).update(star.toJson());
      AppLogger.data('✏️ Star updated in Firestore: ${star.id}');
    } catch (e) {
      AppLogger.error('❌ Error updating star in Firestore: $e');
      // Don't throw - local data is still saved
    }
  }

  // Delete a star from Firestore (now uses soft delete)
  Future<void> deleteStar(String starId) async {
    if (_starsCollection == null) return;

    try {
      // Use soft delete instead of hard delete
      await softDeleteStar(starId);
      AppLogger.success('✅ Star deleted: $starId');
    } catch (e) {
      AppLogger.error('❌ Delete failed: $e');
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
      AppLogger.sync('⚠️ Error updating last sync: $e');
    }
  }

  // Check if user has cloud data
  Future<bool> hasCloudData() async {
    if (_starsCollection == null) return false;

    try {
      final snapshot = await _starsCollection!.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      AppLogger.sync('⚠️ Error checking cloud data: $e');
      return false;
    }
  }
  // ONE-TIME MIGRATION: Add missing fields AND rename old fields
  Future<void> migrateOldStars() async {
    if (_starsCollection == null) return;

    try {
      AppLogger.info('🔄 Checking for stars needing migration...');

      // Get all stars
      final snapshot = await _starsCollection!.get();

      int migrated = 0;
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data == null) {
          AppLogger.warning('Document ${doc.id} has no data, skipping');
          continue;
        }
        if (data is! Map<String, dynamic>) {
          AppLogger.error('Invalid document format for ${doc.id}');
          continue;
        }
        bool needsMigration = false;
        Map<String, dynamic> updates = {};

        // Check if missing new fields
        if (!data.containsKey('updatedAt')) {
          updates['updatedAt'] = data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch;
          needsMigration = true;
        }

        if (!data.containsKey('deleted')) {
          updates['deleted'] = false;
          updates['deletedAt'] = null;
          needsMigration = true;
        }

        if (!data.containsKey('compressed')) {
          updates['compressed'] = false;
          needsMigration = true;
        }

        // RENAME OLD FIELDS
        if (data.containsKey('colorIndex') && !data.containsKey('colorPresetIndex')) {
          updates['colorPresetIndex'] = data['colorIndex'];
          needsMigration = true;
        }

        if (needsMigration) {
          batch.update(doc.reference, updates);
          migrated++;
        }
      }

      if (migrated > 0) {
        await batch.commit();
        AppLogger.success('✅ Migrated $migrated old stars');
      } else {
        AppLogger.success('✅ All stars already migrated');
      }
    } catch (e) {
      AppLogger.error('❌ Migration failed: $e');
    }
  }
}