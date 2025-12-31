import 'dart:convert';
import '../storage.dart'; // For GratitudeStar
import '../galaxy_metadata.dart';
import '../services/user_scoped_storage.dart';
import '../services/firestore_service.dart';
import '../features/gratitudes/data/datasources/galaxy_remote_data_source.dart';
import '../core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of a data migration operation
class MergeResult {
  final bool merged;
  final int localStarsCount;
  final int cloudStarsCount;
  final int localGalaxiesCount;
  final int cloudGalaxiesCount;

  MergeResult({
    required this.merged,
    this.localStarsCount = 0,
    this.cloudStarsCount = 0,
    this.localGalaxiesCount = 0,
    this.cloudGalaxiesCount = 0,
  });
}

/// Service for migrating data between users and handling merges
/// 
/// Handles migration from anonymous users to email accounts,
/// including merge detection and conflict resolution.
class DataMigrationService {
  final FirestoreService _firestoreService;
  final GalaxyRemoteDataSource _galaxyRemoteDataSource;

  DataMigrationService({
    required FirestoreService firestoreService,
    required GalaxyRemoteDataSource galaxyRemoteDataSource,
  })  : _firestoreService = firestoreService,
        _galaxyRemoteDataSource = galaxyRemoteDataSource;

  /// Migrate anonymous user's data to email account
  /// 
  /// [anonymousUserId] - The anonymous user's ID (local storage key)
  /// [emailUserId] - The email user's Firebase UID
  /// 
  /// Returns MergeResult indicating if merge occurred and data counts
  Future<MergeResult> migrateAnonymousToEmail(
    String anonymousUserId,
    String emailUserId,
  ) async {
    try {
      AppLogger.auth('🔀 Starting migration from anonymous user to email account');
      AppLogger.auth('   Anonymous user: $anonymousUserId');
      AppLogger.auth('   Email user: $emailUserId');

      // 1. Load anonymous user's local data
      final localStars = await UserScopedStorage.loadStars(anonymousUserId);
      final localGalaxies = await UserScopedStorage.loadGalaxies(anonymousUserId);

      AppLogger.data('📥 Loaded local data - ${localStars.length} stars, ${localGalaxies.length} galaxies');

      // 2. Load email user's cloud data
      List<GratitudeStar> cloudStars = [];
      List<GalaxyMetadata> cloudGalaxies = [];

      try {
        // Check if cloud has data
        final hasCloudData = await _firestoreService.hasCloudData();
        if (hasCloudData) {
          // Download all stars from cloud
          cloudStars = await _firestoreService.downloadDeltaStars();
          // Download all galaxies from cloud
          cloudGalaxies = await _galaxyRemoteDataSource.loadGalaxies();
        }
      } catch (e) {
        AppLogger.warning('⚠️ Could not load cloud data (may not exist): $e');
        // Continue with migration even if cloud data doesn't exist
      }

      AppLogger.data('📥 Loaded cloud data - ${cloudStars.length} stars, ${cloudGalaxies.length} galaxies');

      // 3. Detect merge scenario
      final needsMerge = localGalaxies.isNotEmpty && cloudGalaxies.isNotEmpty;

      if (needsMerge) {
        AppLogger.auth('🔀 Merge detected - both local and cloud galaxies exist');
        
        // 4. Merge data (with conflict resolution)
        final mergedStars = _mergeStars(localStars, cloudStars);
        final mergedGalaxies = _mergeGalaxies(localGalaxies, cloudGalaxies);

        AppLogger.data('🔀 Merged data - ${mergedStars.length} stars, ${mergedGalaxies.length} galaxies');

        // 5. Save merged data to email user's local storage
        await UserScopedStorage.saveStars(emailUserId, mergedStars);
        await UserScopedStorage.saveGalaxies(emailUserId, mergedGalaxies);

        // Track that email user has data
        await UserScopedStorage.trackUserHasData(emailUserId);

        // 6. Mark anonymous data as migrated (keep as backup for 30 days)
        await _markAsMigrated(anonymousUserId, emailUserId);

        AppLogger.success('✅ Migration complete with merge');

        return MergeResult(
          merged: true,
          localStarsCount: localStars.length,
          cloudStarsCount: cloudStars.length,
          localGalaxiesCount: localGalaxies.length,
          cloudGalaxiesCount: cloudGalaxies.length,
        );
      } else {
        AppLogger.auth('📤 No merge needed - migrating data only');

        // No merge needed - just migrate
        await UserScopedStorage.saveStars(emailUserId, localStars);
        await UserScopedStorage.saveGalaxies(emailUserId, localGalaxies);

        // Track that email user has data
        await UserScopedStorage.trackUserHasData(emailUserId);

        // Mark anonymous data as migrated
        await _markAsMigrated(anonymousUserId, emailUserId);

        AppLogger.success('✅ Migration complete without merge');

        return MergeResult(
          merged: false,
          localStarsCount: localStars.length,
          cloudStarsCount: cloudStars.length,
          localGalaxiesCount: localGalaxies.length,
          cloudGalaxiesCount: cloudGalaxies.length,
        );
      }
    } catch (e, stack) {
      AppLogger.error('❌ Migration failed: $e');
      AppLogger.error('Stack trace: $stack');
      rethrow;
    }
  }

  /// Merge stars from local and cloud sources
  /// 
  /// Uses last-write-wins conflict resolution: keeps newer version of each star
  List<GratitudeStar> _mergeStars(
    List<GratitudeStar> localStars,
    List<GratitudeStar> cloudStars,
  ) {
    final merged = <String, GratitudeStar>{};

    // Add all local stars
    for (final star in localStars) {
      merged[star.id] = star;
    }

    // Merge cloud stars (keep newer version)
    for (final cloudStar in cloudStars) {
      final localStar = merged[cloudStar.id];

      if (localStar == null) {
        // New star from cloud - add it
        merged[cloudStar.id] = cloudStar;
        AppLogger.sync('   🔀 Added new cloud star: ${cloudStar.id}');
      } else {
        // Star exists in both - keep newer version
        if (cloudStar.updatedAt.isAfter(localStar.updatedAt)) {
          merged[cloudStar.id] = cloudStar;
          AppLogger.sync('   🔀 Replaced local star with cloud version: ${cloudStar.id}');
        } else {
          AppLogger.sync('   🔀 Kept local star (newer): ${cloudStar.id}');
        }
      }
    }

    return merged.values.toList();
  }

  /// Merge galaxies from local and cloud sources
  /// 
  /// Merges galaxies by ID, keeping both if they don't conflict
  List<GalaxyMetadata> _mergeGalaxies(
    List<GalaxyMetadata> localGalaxies,
    List<GalaxyMetadata> cloudGalaxies,
  ) {
    final merged = <String, GalaxyMetadata>{};

    // Add all local galaxies
    for (final galaxy in localGalaxies) {
      merged[galaxy.id] = galaxy;
    }

    // Merge cloud galaxies
    for (final cloudGalaxy in cloudGalaxies) {
      final localGalaxy = merged[cloudGalaxy.id];

      if (localGalaxy == null) {
        // New galaxy from cloud - add it
        merged[cloudGalaxy.id] = cloudGalaxy;
        AppLogger.sync('   🔀 Added new cloud galaxy: ${cloudGalaxy.name}');
      } else {
        // Galaxy exists in both - merge metadata
        // Keep the one with more recent lastViewedAt or createdAt
        final localDate = localGalaxy.lastViewedAt ?? localGalaxy.createdAt;
        final cloudDate = cloudGalaxy.lastViewedAt ?? cloudGalaxy.createdAt;

        if (cloudDate.isAfter(localDate)) {
          // Cloud is newer - use cloud but preserve local star count if it's higher
          final mergedGalaxy = cloudGalaxy.copyWith(
            starCount: localGalaxy.starCount > cloudGalaxy.starCount
                ? localGalaxy.starCount
                : cloudGalaxy.starCount,
          );
          merged[cloudGalaxy.id] = mergedGalaxy;
          AppLogger.sync('   🔀 Merged galaxy (cloud newer): ${cloudGalaxy.name}');
        } else {
          // Local is newer - use local but preserve cloud star count if it's higher
          final mergedGalaxy = localGalaxy.copyWith(
            starCount: cloudGalaxy.starCount > localGalaxy.starCount
                ? cloudGalaxy.starCount
                : localGalaxy.starCount,
          );
          merged[localGalaxy.id] = mergedGalaxy;
          AppLogger.sync('   🔀 Merged galaxy (local newer): ${localGalaxy.name}');
        }
      }
    }

    return merged.values.toList();
  }

  /// Mark anonymous data as migrated
  /// 
  /// Stores migration metadata for potential rollback/recovery
  Future<void> _markAsMigrated(
    String anonymousUserId,
    String emailUserId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationsJson = prefs.getString('data_migrations') ?? '{}';
      final migrations = Map<String, dynamic>.from(json.decode(migrationsJson) as Map);

      migrations[anonymousUserId] = {
        'migratedTo': emailUserId,
        'migratedAt': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString('data_migrations', json.encode(migrations));
      AppLogger.data('📝 Marked anonymous user as migrated: $anonymousUserId → $emailUserId');
    } catch (e) {
      AppLogger.error('⚠️ Error marking migration: $e');
      // Don't throw - migration succeeded even if tracking fails
    }
  }

  /// Check if a user has been migrated
  /// 
  /// Returns the email user ID if the anonymous user was migrated, null otherwise
  Future<String?> getMigratedTo(String anonymousUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationsJson = prefs.getString('data_migrations') ?? '{}';
      final migrations = Map<String, dynamic>.from(json.decode(migrationsJson) as Map);

      final migration = migrations[anonymousUserId] as Map<String, dynamic>?;
      if (migration != null) {
        return migration['migratedTo'] as String?;
      }

      return null;
    } catch (e) {
      AppLogger.error('⚠️ Error checking migration: $e');
      return null;
    }
  }
}

