import '../../../../galaxy_metadata.dart';
import '../../../../services/auth_service.dart';
import '../datasources/galaxy_local_data_source.dart';
import '../datasources/galaxy_remote_data_source.dart';
import 'gratitude_repository.dart';

/// Repository for galaxy metadata operations
///
/// Coordinates between local and remote galaxy data sources
class GalaxyRepository {
  final GalaxyLocalDataSource _localDataSource;
  final GalaxyRemoteDataSource _remoteDataSource;
  final GratitudeRepository _gratitudeRepository;
  final AuthService _authService;

  GalaxyRepository({
    required GalaxyLocalDataSource localDataSource,
    required GalaxyRemoteDataSource remoteDataSource,
    required GratitudeRepository gratitudeRepository,
    required AuthService authService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _gratitudeRepository = gratitudeRepository,
        _authService = authService;

  /// Load all galaxies from local storage
  Future<List<GalaxyMetadata>> getGalaxies() async {
    return await _localDataSource.loadGalaxies();
  }

  /// Save galaxies to local storage
  Future<void> saveGalaxies(List<GalaxyMetadata> galaxies) async {
    await _localDataSource.saveGalaxies(galaxies);
  }

  /// Create a new galaxy
  Future<GalaxyMetadata> createGalaxy({
    required String name,
    bool setAsActive = true,
  }) async {
    // Limit galaxy name length
    final truncatedName = name.length > GalaxyMetadata.maxNameLength
        ? name.substring(0, GalaxyMetadata.maxNameLength)
        : name;

    final galaxy = GalaxyMetadata.create(name: truncatedName);

    // Save to local storage
    final existingGalaxies = await getGalaxies();
    await saveGalaxies([...existingGalaxies, galaxy]);

    // Save to cloud if authenticated
    if (_authService.hasEmailAccount) {
      try {
        await _remoteDataSource.saveGalaxy(galaxy);
      } catch (e) {
        print('⚠️ Failed to save galaxy to cloud: $e');
      }
    }

    // Set as active if requested
    if (setAsActive) {
      await setActiveGalaxy(galaxy.id);
    }

    print('✨ Created galaxy: ${galaxy.name}');
    return galaxy;
  }

  /// Update an existing galaxy
  Future<void> updateGalaxy(GalaxyMetadata galaxy) async {
    final galaxies = await getGalaxies();
    final index = galaxies.indexWhere((g) => g.id == galaxy.id);

    if (index != -1) {
      galaxies[index] = galaxy;
      await saveGalaxies(galaxies);

      // Sync to cloud if authenticated
      if (_authService.hasEmailAccount) {
        try {
          await _remoteDataSource.updateGalaxy(galaxy);
        } catch (e) {
          print('⚠️ Failed to update galaxy in cloud: $e');
        }
      }

      print('📝 Updated galaxy: ${galaxy.name}');
    }
  }

  /// Delete a galaxy (cascade soft delete to all its stars)
  Future<void> deleteGalaxy(String galaxyId) async {
    final now = DateTime.now();

    // 1. Soft delete the galaxy
    final galaxies = await getGalaxies();
    final index = galaxies.indexWhere((g) => g.id == galaxyId);

    if (index == -1) {
      print('⚠️ Galaxy $galaxyId not found');
      return;
    }

    final deletedGalaxy = galaxies[index].copyWith(
      deleted: true,
      deletedAt: now,
    );
    galaxies[index] = deletedGalaxy;
    await saveGalaxies(galaxies);

    // 2. Cascade soft delete all stars in this galaxy
    final allStars = await _gratitudeRepository.getAllGratitudesUnfiltered();
    final updatedStars = allStars.map((star) {
      if (star.galaxyId == galaxyId && !star.deleted) {
        return star.copyWith(deleted: true, deletedAt: now);
      }
      return star;
    }).toList();
    await _gratitudeRepository.saveGratitudes(updatedStars);

    // 3. Sync to cloud if authenticated
    if (_authService.hasEmailAccount) {
      try {
        await _remoteDataSource.deleteGalaxy(galaxyId);
        // Note: Star deletions will sync via normal delta sync
      } catch (e) {
        print('⚠️ Failed to delete galaxy in cloud: $e');
      }
    }

    // 4. If this was the active galaxy, switch to most recent non-deleted
    final activeId = await getActiveGalaxyId();
    if (activeId == galaxyId) {
      final nonDeletedGalaxies = galaxies.where((g) => !g.deleted).toList();
      if (nonDeletedGalaxies.isNotEmpty) {
        // Sort by last viewed or created date
        nonDeletedGalaxies.sort((a, b) {
          final aDate = a.lastViewedAt ?? a.createdAt;
          final bDate = b.lastViewedAt ?? b.createdAt;
          return bDate.compareTo(aDate);
        });
        await setActiveGalaxy(nonDeletedGalaxies.first.id);
      }
    }

    print('🗑️ Deleted galaxy and ${updatedStars.where((s) => s.galaxyId == galaxyId && s.deleted).length} stars');
  }

  /// Restore a deleted galaxy (and its stars)
  Future<void> restoreGalaxy(String galaxyId) async {
    // 1. Restore the galaxy
    final galaxies = await getGalaxies();
    final index = galaxies.indexWhere((g) => g.id == galaxyId);

    if (index == -1) {
      print('⚠️ Galaxy $galaxyId not found');
      return;
    }

    final galaxy = galaxies[index];
    final restoredGalaxy = galaxy.copyWith(
      deleted: false,
      deletedAt: null,
    );
    galaxies[index] = restoredGalaxy;
    await saveGalaxies(galaxies);

    // 2. Restore stars that were deleted at the same time as the galaxy
    final allStars = await _gratitudeRepository.getAllGratitudesUnfiltered();
    final updatedStars = allStars.map((star) {
      // Only restore stars deleted with the galaxy (matching timestamps)
      if (star.galaxyId == galaxyId &&
          star.deleted &&
          star.deletedAt != null &&
          galaxy.deletedAt != null &&
          (star.deletedAt!.difference(galaxy.deletedAt!).inSeconds.abs() < 5)) {
        return star.copyWith(deleted: false, deletedAt: null);
      }
      return star;
    }).toList();
    await _gratitudeRepository.saveGratitudes(updatedStars);

    // 3. Sync to cloud if authenticated
    if (_authService.hasEmailAccount) {
      try {
        await _remoteDataSource.updateGalaxy(restoredGalaxy);
        // Note: Star restorations will sync via normal delta sync
      } catch (e) {
        print('⚠️ Failed to restore galaxy in cloud: $e');
      }
    }

    print('♻️ Restored galaxy ${galaxy.name}');
  }

  /// Get the active galaxy ID
  Future<String?> getActiveGalaxyId() async {
    // Try local first
    String? activeId = await _localDataSource.getActiveGalaxyId();

    // If not set locally and user is authenticated, try cloud
    if (activeId == null && _authService.hasEmailAccount) {
      try {
        activeId = await _remoteDataSource.getActiveGalaxyId();
        if (activeId != null) {
          // Cache locally
          await _localDataSource.setActiveGalaxyId(activeId);
        }
      } catch (e) {
        print('⚠️ Failed to get active galaxy from cloud: $e');
      }
    }

    return activeId;
  }

  /// Set the active galaxy
  Future<void> setActiveGalaxy(String galaxyId) async {
    print('🌌 Setting active galaxy: $galaxyId');

    // 1. Save locally FIRST
    await _localDataSource.setActiveGalaxyId(galaxyId);

    // 2. Update repository filter IMMEDIATELY
    _gratitudeRepository.setActiveGalaxyId(galaxyId);

    // 3. Update lastViewedAt for the galaxy
    final galaxies = await getGalaxies();
    final index = galaxies.indexWhere((g) => g.id == galaxyId);
    if (index != -1) {
      final updatedGalaxy = galaxies[index].copyWith(
        lastViewedAt: DateTime.now(),
      );
      await updateGalaxy(updatedGalaxy);
    }

    // 4. Sync to cloud if authenticated (don't block on this)
    if (_authService.hasEmailAccount) {
      _remoteDataSource.setActiveGalaxyId(galaxyId).catchError((e) {
        print('⚠️ Failed to set active galaxy in cloud: $e');
      });
    }

    print('✅ Active galaxy set: $galaxyId');
  }

  /// Sync galaxies from cloud to local
  Future<void> syncFromCloud() async {
    if (!_authService.hasEmailAccount) {
      print('⚠️ Not authenticated, skipping galaxy sync');
      return;
    }

    try {
      final cloudGalaxies = await _remoteDataSource.loadGalaxies();
      await saveGalaxies(cloudGalaxies);

      // Also get active galaxy from cloud
      final cloudActiveId = await _remoteDataSource.getActiveGalaxyId();
      if (cloudActiveId != null) {
        await setActiveGalaxy(cloudActiveId);
      }

      print('☁️ Synced ${cloudGalaxies.length} galaxies from cloud');
    } catch (e) {
      print('⚠️ Failed to sync galaxies from cloud: $e');
      rethrow;
    }
  }

  /// Sync galaxies from local to cloud
  Future<void> syncToCloud() async {
    if (!_authService.hasEmailAccount) {
      print('⚠️ Not authenticated, skipping galaxy sync');
      return;
    }

    try {
      final localGalaxies = await getGalaxies();
      
      print('☁️ Syncing ${localGalaxies.length} galaxies to cloud...');
      
      // Sync each galaxy individually (Firebase doesn't support batch for subcollections)
      int syncedCount = 0;
      for (final galaxy in localGalaxies) {
        await _remoteDataSource.saveGalaxy(galaxy);
        syncedCount++;
        print('   ☁️ Synced galaxy $syncedCount/${localGalaxies.length}: ${galaxy.name}');
      }

      // Also sync active galaxy ID
      final activeId = await getActiveGalaxyId();
      if (activeId != null) {
        await _remoteDataSource.setActiveGalaxyId(activeId);
        print('   ☁️ Synced active galaxy: $activeId');
      }

      print('✅ Synced ${localGalaxies.length} galaxies to cloud');
    } catch (e) {
      print('⚠️ Failed to sync galaxies to cloud: $e');
      rethrow;
    }
  }

  /// Update star count for a galaxy (called when stars are added/deleted)
  Future<void> updateStarCount(String galaxyId, int newCount) async {
    final galaxies = await getGalaxies();
    final index = galaxies.indexWhere((g) => g.id == galaxyId);

    if (index != -1) {
      final updatedGalaxy = galaxies[index].copyWith(starCount: newCount);
      await updateGalaxy(updatedGalaxy);
    }
  }

  /// Clear all galaxy data (called on sign out)
  Future<void> clearAll() async {
    await _localDataSource.clearAll();
    _gratitudeRepository.setActiveGalaxyId(null);
    print('🗑️ Cleared all galaxy data');
  }

  /// Migrate existing stars to a galaxy
  Future<void> migrateExistingStarsToGalaxy(String galaxyId) async {
    final allStars = await _gratitudeRepository.getAllGratitudesUnfiltered();
    final starsNeedingMigration = allStars.where((star) =>
    star.galaxyId == 'default' || star.galaxyId.isEmpty
    ).toList();

    if (starsNeedingMigration.isEmpty) {
      print('✅ No stars need migration');
      return;
    }

    final updatedStars = allStars.map((star) {
      if (star.galaxyId == 'default' || star.galaxyId.isEmpty) {
        return star.copyWith(galaxyId: galaxyId);
      }
      return star;
    }).toList();

    await _gratitudeRepository.saveGratitudes(updatedStars);
    print('✅ Migrated ${starsNeedingMigration.length} stars to galaxy $galaxyId');
  }
}