// lib/features/gratitudes/data/repositories/gratitude_repository.dart

import '../../../../storage.dart';
import '../../../../services/auth_service.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';

/// Repository for gratitude data operations
///
/// Single source of truth for all gratitude data.
/// Coordinates between local and remote data sources.
class GratitudeRepository {
  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;
  final AuthService _authService;

  String? _activeGalaxyId;

  GratitudeRepository({
    required LocalDataSource localDataSource,
    required RemoteDataSource remoteDataSource,
    required AuthService authService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _authService = authService;

  /// Get all gratitudes from local storage (filtered by active galaxy)
  Future<List<GratitudeStar>> getGratitudes() async {
    final allStars = await _localDataSource.loadStars();

    print('🌌 Repository: Loading stars, activeGalaxyId: $_activeGalaxyId');
    print('🌌 All stars: ${allStars.length}');

    // Debug: Show what galaxy IDs the stars actually have
    print('🌌 Star galaxy IDs:');
    for (final star in allStars) {
      print('   - "${star.text.substring(0, star.text.length > 30 ? 30 : star.text.length)}" → galaxyId: "${star.galaxyId}" (deleted: ${star.deleted})');
    }

    // Filter by active galaxy if set
    if (_activeGalaxyId != null) {
      final filtered = allStars.where((star) => star.galaxyId == _activeGalaxyId).toList();
      print('🌌 Filtered stars for galaxy $_activeGalaxyId: ${filtered.length}');
      return filtered;
    }

    print('🌌 No active galaxy, returning all ${allStars.length} stars');
    return allStars;
  }

  /// Set the active galaxy ID for filtering
  void setActiveGalaxyId(String? galaxyId) {
    _activeGalaxyId = galaxyId;
    print('🌌 Active galaxy set to: $galaxyId');
  }

  /// Get the current active galaxy ID
  String? getActiveGalaxyId() => _activeGalaxyId;

  /// Get all gratitudes regardless of galaxy (for migration, etc.)
  Future<List<GratitudeStar>> getAllGratitudesUnfiltered() async {
    return await _localDataSource.loadStars();
  }

  /// Save gratitudes to local storage
  Future<void> saveGratitudes(List<GratitudeStar> stars) async {
    await _localDataSource.saveStars(stars);
  }

  /// Add a new gratitude (local + cloud if authenticated)
  Future<void> addGratitude(GratitudeStar star, List<GratitudeStar> allStars) async {
    final updatedStars = [...allStars, star];
    await _localDataSource.saveStars(updatedStars);

    // Sync to cloud if authenticated
    if (_authService.hasEmailAccount) {
      try {
        await _remoteDataSource.addStar(star);
      } catch (e) {
        print('⚠️ Failed to sync new star to cloud: $e');
        // Don't rethrow - local save succeeded
      }
    }
  }

  /// Update an existing gratitude (local + cloud if authenticated)
  Future<void> updateGratitude(GratitudeStar star, List<GratitudeStar> allStars) async {
    final updatedStars = List<GratitudeStar>.from(allStars);
    final index = updatedStars.indexWhere((s) => s.id == star.id);

    if (index != -1) {
      updatedStars[index] = star;
      await _localDataSource.saveStars(updatedStars);

      // Sync to cloud if authenticated
      if (_authService.hasEmailAccount) {
        try {
          await _remoteDataSource.updateStar(star);
        } catch (e) {
          print('⚠️ Failed to sync star update to cloud: $e');
        }
      }
    }
  }

  /// Delete a gratitude (soft delete - marks as deleted)
  Future<void> deleteGratitude(GratitudeStar deletedStar, List<GratitudeStar> allStars) async {
    final updatedStars = List<GratitudeStar>.from(allStars);
    final index = updatedStars.indexWhere((s) => s.id == deletedStar.id);

    if (index != -1) {
      updatedStars[index] = deletedStar;
      await _localDataSource.saveStars(updatedStars);

      // Sync soft delete to cloud if authenticated
      if (_authService.hasEmailAccount) {
        try {
          await _remoteDataSource.updateStar(deletedStar);
        } catch (e) {
          print('⚠️ Failed to sync star deletion to cloud: $e');
        }
      }
    }
  }

  /// Sync with cloud - merge local and remote data
  Future<List<GratitudeStar>> syncWithCloud(List<GratitudeStar> localStars) async {
    print('🔄 Starting cloud sync...');

    final hasCloudData = await _remoteDataSource.hasCloudData();

    if (hasCloudData) {
      // Delta sync - merge changes
      print('📥 Cloud data exists, syncing...');
      final mergedStars = await _remoteDataSource.syncStars(localStars);
      await _localDataSource.saveStars(mergedStars);
      print('✅ Sync complete! Total stars: ${mergedStars.length}');
      return mergedStars;
    } else {
      // First sync - upload local to cloud
      print('📤 No cloud data, uploading local stars...');
      await _remoteDataSource.uploadStars(localStars);
      print('✅ Local stars uploaded to cloud');
      return localStars;
    }
  }

  /// Clear all local data
  Future<void> clearAllData() async {
    await _localDataSource.clearAll();
  }

  /// Get deleted gratitudes (for trash view - filtered by active galaxy)
  Future<List<GratitudeStar>> getDeletedGratitudes() async {
    final allStars = await _localDataSource.loadStars();

    // Filter by active galaxy AND deleted status
    if (_activeGalaxyId != null) {
      return allStars
          .where((star) => star.deleted && star.galaxyId == _activeGalaxyId)
          .toList();
    }

    // Fallback: return all deleted stars if no active galaxy
    return allStars.where((star) => star.deleted).toList();
  }

  /// Get count of deleted gratitudes in active galaxy
  Future<int> getDeletedGratitudesCount() async {
    final deletedStars = await getDeletedGratitudes();
    return deletedStars.length;
  }

  /// Restore a deleted gratitude
  Future<void> restoreGratitude(GratitudeStar star, List<GratitudeStar> allStars) async {
    final restoredStar = star.copyWith(
      deleted: false,
      deletedAt: null,
    );

    final updatedStars = List<GratitudeStar>.from(allStars);
    final index = updatedStars.indexWhere((s) => s.id == star.id);

    if (index != -1) {
      updatedStars[index] = restoredStar;
      await _localDataSource.saveStars(updatedStars);

      // Sync restore to cloud if authenticated
      if (_authService.hasEmailAccount) {
        try {
          await _remoteDataSource.updateStar(restoredStar);
        } catch (e) {
          print('⚠️ Failed to sync star restore to cloud: $e');
        }
      }
    }
  }

  /// Delete a gratitude from cloud storage only
  Future<void> deleteFromCloud(String starId) async {
    try {
      await _remoteDataSource.deleteStar(starId);
      print('✅ Deleted star $starId from cloud');
    } catch (e) {
      print('⚠️ Failed to delete star from cloud: $e');
      // Don't rethrow - this is a background sync operation
    }
  }

  /// Purge old deleted items (older than 30 days)
  Future<List<GratitudeStar>> purgeOldDeletedItems(List<GratitudeStar> allStars) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));

    final updatedStars = allStars.where((star) {
      if (star.deleted && star.deletedAt != null) {
        return star.deletedAt!.isAfter(thirtyDaysAgo);
      }
      return true; // Keep non-deleted items
    }).toList();

    final purgedCount = allStars.length - updatedStars.length;
    if (purgedCount > 0) {
      print('🗑️ Purged $purgedCount old deleted items');
      await _localDataSource.saveStars(updatedStars);
    }

    return updatedStars;
  }

  /// Migrate existing stars without galaxy IDs to the active galaxy
  Future<void> migrateStarsToActiveGalaxy(String activeGalaxyId) async {
    try {
      final allStars = await _localDataSource.loadStars();
      bool needsSave = false;

      final migratedStars = allStars.map((star) {
        // If star has no galaxy ID, assign it to the active galaxy
        if (star.galaxyId.isEmpty || star.galaxyId == 'default') {
          print('📝 Migrating star "${star.text}" to galaxy $activeGalaxyId');
          needsSave = true;
          return star.copyWith(galaxyId: activeGalaxyId);
        }
        return star;
      }).toList();

      if (needsSave) {
        await _localDataSource.saveStars(migratedStars);
        print('✅ Migrated ${migratedStars.length} stars to active galaxy');
      }
    } catch (e) {
      print('❌ Star migration failed: $e');
    }
  }
}