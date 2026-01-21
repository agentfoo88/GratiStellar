import 'package:flutter/foundation.dart';

import '../../../../galaxy_metadata.dart';
import '../../../../services/auth_service.dart';
import '../datasources/galaxy_local_data_source.dart';
import '../datasources/galaxy_remote_data_source.dart';
import 'gratitude_repository.dart';
import '../../../../core/utils/app_logger.dart';

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
  }) : _localDataSource = localDataSource,
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
        AppLogger.sync('⚠️ Failed to save galaxy to cloud: $e');
      }
    }

    // Set as active if requested
    if (setAsActive) {
      await setActiveGalaxy(galaxy.id);
    }

    AppLogger.start('✨ Created galaxy: ${galaxy.name}');
    return galaxy;
  }

  /// Update an existing galaxy
  ///
  /// OPTIMIZATION: Only saves locally. Cloud sync is handled by GalaxyProvider's
  /// debounced sync mechanism to batch multiple updates together.
  Future<void> updateGalaxy(GalaxyMetadata galaxy) async {
    final galaxies = await getGalaxies();
    final index = galaxies.indexWhere((g) => g.id == galaxy.id);

    if (index != -1) {
      galaxies[index] = galaxy;
      await saveGalaxies(galaxies);

      // OPTIMIZATION: Don't sync immediately - let GalaxyProvider's debounced
      // sync handle cloud updates to batch multiple changes together
      // This reduces individual writes when star counts or metadata update frequently

      AppLogger.info('📝 Updated galaxy: ${galaxy.name}');
    }
  }

  /// Delete a galaxy (cascade soft delete to all its stars)
  Future<void> deleteGalaxy(String galaxyId) async {
    final now = DateTime.now();

    // 1. Soft delete the galaxy
    final galaxies = await getGalaxies();
    final index = galaxies.indexWhere((g) => g.id == galaxyId);

    if (index == -1) {
      AppLogger.warning('⚠️ Galaxy $galaxyId not found');
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
        AppLogger.sync('⚠️ Failed to delete galaxy in cloud: $e');
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

    AppLogger.data(
      '🗑️ Deleted galaxy and ${updatedStars.where((s) => s.galaxyId == galaxyId && s.deleted).length} stars',
    );
  }

  /// Restore a deleted galaxy (and its stars)
  Future<void> restoreGalaxy(String galaxyId) async {
    // 1. Restore the galaxy
    final galaxies = await getGalaxies();
    final index = galaxies.indexWhere((g) => g.id == galaxyId);

    if (index == -1) {
      AppLogger.warning('⚠️ Galaxy $galaxyId not found');
      return;
    }

    final galaxy = galaxies[index];
    final restoredGalaxy = galaxy.copyWith(
      deleted: false,
      deletedAt: null,
      lastModifiedAt: DateTime.now(),
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
        AppLogger.sync('⚠️ Failed to restore galaxy in cloud: $e');
      }
    }

    AppLogger.data('♻️ Restored galaxy ${galaxy.name}');
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
        AppLogger.sync('⚠️ Failed to get active galaxy from cloud: $e');
      }
    }

    // Validate that the active galaxy exists and is not deleted
    if (activeId != null) {
      final galaxies = await getGalaxies();
      final activeGalaxy = galaxies.firstWhere(
        (g) => g.id == activeId,
        orElse: () =>
            GalaxyMetadata(id: '', name: '', createdAt: DateTime.now()),
      );

      // If galaxy doesn't exist or is deleted, find a non-deleted galaxy
      if (activeGalaxy.id.isEmpty || activeGalaxy.deleted) {
        final nonDeletedGalaxies = galaxies.where((g) => !g.deleted).toList();
        if (nonDeletedGalaxies.isNotEmpty) {
          // Sort by last viewed or created date
          nonDeletedGalaxies.sort((a, b) {
            final aDate = a.lastViewedAt ?? a.createdAt;
            final bDate = b.lastViewedAt ?? b.createdAt;
            return bDate.compareTo(aDate);
          });
          activeId = nonDeletedGalaxies.first.id;
          // Update stored active galaxy ID
          await _localDataSource.setActiveGalaxyId(activeId);
          AppLogger.sync(
            '🔄 Active galaxy was deleted, switched to: $activeId',
          );
        } else {
          // No non-deleted galaxies, return null
          activeId = null;
          await _localDataSource.setActiveGalaxyId('');
        }
      }
    }

    return activeId;
  }

  /// Set the active galaxy
  Future<void> setActiveGalaxy(String galaxyId) async {
    AppLogger.info('🌌 Setting active galaxy: $galaxyId');

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
        AppLogger.sync('⚠️ Failed to set active galaxy in cloud: $e');
      });
    }

    AppLogger.success('✅ Active galaxy set: $galaxyId');
  }

  /// Sync galaxies from cloud to local
  ///
  /// Merges cloud galaxies with local galaxies instead of overwriting.
  /// Preserves local galaxies and merges with cloud galaxies.
  Future<void> syncFromCloud() async {
    // #region agent log
    if (kDebugMode) {
      final currentUser = _authService.currentUser;
      AppLogger.auth(
        '🔐 DEBUG: syncFromCloud auth check - currentUser=${currentUser?.uid}, isAnonymous=${currentUser?.isAnonymous}, hasEmailAccount=${_authService.hasEmailAccount}',
      );
    }
    // #endregion

    if (!_authService.hasEmailAccount) {
      AppLogger.auth('⚠️ Not authenticated, skipping galaxy sync');
      return;
    }

    try {
      // Load local galaxies first
      final localGalaxies = await getGalaxies();
      final localGalaxiesCount = localGalaxies.length;
      AppLogger.sync('📋 Local galaxies: $localGalaxiesCount');
      if (localGalaxiesCount > 0) {
        AppLogger.sync(
          '   📋 Local galaxy IDs: ${localGalaxies.map((g) => '${g.id}(${g.name})').join(', ')}',
        );
      }

      // Load cloud galaxies
      final cloudGalaxies = await _remoteDataSource.loadGalaxies();
      final cloudGalaxiesCount = cloudGalaxies.length;
      AppLogger.sync('☁️ Cloud galaxies: $cloudGalaxiesCount');
      if (cloudGalaxiesCount > 0) {
        AppLogger.sync(
          '   ☁️ Cloud galaxy IDs: ${cloudGalaxies.map((g) => '${g.id}(${g.name})').join(', ')}',
        );
      }

      // Merge galaxies: combine local and cloud, keeping newer version for conflicts
      // Filter out deleted galaxies from local list before merging
      final activeLocalGalaxies = localGalaxies
          .where((g) => !g.deleted)
          .toList();
      final mergedGalaxies = <String, GalaxyMetadata>{};

      // Add all active local galaxies first
      for (final galaxy in activeLocalGalaxies) {
        mergedGalaxies[galaxy.id] = galaxy;
      }

      // Merge cloud galaxies (already filtered to exclude deleted)
      for (final cloudGalaxy in cloudGalaxies) {
        final localGalaxy = mergedGalaxies[cloudGalaxy.id];

        if (localGalaxy == null) {
          // New galaxy from cloud - add it
          mergedGalaxies[cloudGalaxy.id] = cloudGalaxy;
          AppLogger.sync(
            '   ➕ Added new cloud galaxy: ${cloudGalaxy.name} (${cloudGalaxy.id})',
          );
        } else {
          // Galaxy exists in both - merge metadata
          // Keep the one with more recent lastModifiedAt, falling back to createdAt
          final localDate = localGalaxy.lastModifiedAt ?? localGalaxy.createdAt;
          final cloudDate = cloudGalaxy.lastModifiedAt ?? cloudGalaxy.createdAt;

          if (cloudDate.isAfter(localDate)) {
            // Cloud is newer - use cloud but preserve local star count if it's higher
            final mergedGalaxy = cloudGalaxy.copyWith(
              starCount: localGalaxy.starCount > cloudGalaxy.starCount
                  ? localGalaxy.starCount
                  : cloudGalaxy.starCount,
            );
            mergedGalaxies[cloudGalaxy.id] = mergedGalaxy;
            AppLogger.sync(
              '   🔀 Merged galaxy (cloud newer): ${cloudGalaxy.name} (${cloudGalaxy.id})',
            );
          } else {
            // Local is newer - use local but preserve cloud star count if it's higher
            final mergedGalaxy = localGalaxy.copyWith(
              starCount: cloudGalaxy.starCount > localGalaxy.starCount
                  ? cloudGalaxy.starCount
                  : localGalaxy.starCount,
            );
            mergedGalaxies[localGalaxy.id] = mergedGalaxy;
            AppLogger.sync(
              '   🔀 Merged galaxy (local newer): ${localGalaxy.name} (${localGalaxy.id})',
            );
          }
        }
      }

      // Save merged galaxies
      final mergedList = mergedGalaxies.values.toList();
      await saveGalaxies(mergedList);

      // Recalculate star counts after merge
      await recalculateAllStarCounts();

      // Also get active galaxy from cloud
      final cloudActiveId = await _remoteDataSource.getActiveGalaxyId();
      if (cloudActiveId != null) {
        await setActiveGalaxy(cloudActiveId);
      }

      AppLogger.sync(
        '✅ Merged galaxies: local=$localGalaxiesCount, cloud=$cloudGalaxiesCount, merged=${mergedList.length}',
      );
    } catch (e) {
      AppLogger.sync('⚠️ Failed to sync galaxies from cloud: $e');
      rethrow;
    }
  }

  /// Sync galaxies from local to cloud
  ///
  /// Syncs all galaxies with per-galaxy error handling to ensure
  /// all galaxies are attempted even if some fail.
  Future<void> syncToCloud() async {
    // #region agent log
    if (kDebugMode) {
      final currentUser = _authService.currentUser;
      AppLogger.auth(
        '🔐 DEBUG: syncToCloud auth check - currentUser=${currentUser?.uid}, isAnonymous=${currentUser?.isAnonymous}, hasEmailAccount=${_authService.hasEmailAccount}',
      );
    }
    // #endregion

    if (!_authService.hasEmailAccount) {
      AppLogger.auth('⚠️ Not authenticated, skipping galaxy sync');
      return;
    }

    try {
      final localGalaxies = await getGalaxies();

      AppLogger.sync('☁️ Syncing ${localGalaxies.length} galaxies to cloud...');
      AppLogger.sync(
        '   📋 Galaxy IDs: ${localGalaxies.map((g) => '${g.id}(${g.name})').join(', ')}',
      );

      // OPTIMIZATION: Batch write all galaxies + activeGalaxyId instead of individual writes
      // This reduces N+1 writes to 1 write (or ceil(N/500) batches)
      final activeId = await getActiveGalaxyId();
      try {
        await _remoteDataSource.batchSaveGalaxies(
          localGalaxies,
          activeGalaxyId: activeId,
        );
        if (activeId != null) {
          AppLogger.sync(
            '   ✅ Batch synced ${localGalaxies.length} galaxies + activeGalaxyId to cloud',
          );
        } else {
          AppLogger.sync(
            '   ✅ Batch synced ${localGalaxies.length} galaxies to cloud',
          );
        }
      } catch (e) {
        AppLogger.sync(
          '   ❌ Batch sync failed, falling back to individual syncs: $e',
        );
        // Fallback to individual syncs if batch fails
        int syncedCount = 0;
        int failedCount = 0;
        final List<String> failedGalaxyIds = [];

        for (final galaxy in localGalaxies) {
          try {
            await _remoteDataSource.saveGalaxy(galaxy);
            syncedCount++;
          } catch (e) {
            failedCount++;
            failedGalaxyIds.add(galaxy.id);
          }
        }

        // Also sync active galaxy ID individually if batch failed
        if (activeId != null) {
          try {
            await _remoteDataSource.setActiveGalaxyId(activeId);
            AppLogger.sync('   ☁️ Synced active galaxy: $activeId');
          } catch (e) {
            AppLogger.sync('   ⚠️ Failed to sync active galaxy ID: $e');
          }
        }

        if (failedCount > 0) {
          AppLogger.sync(
            '⚠️ Synced $syncedCount/${localGalaxies.length} galaxies individually. Failed: ${failedGalaxyIds.join(', ')}',
          );
        }
      }

      AppLogger.sync('✅ Synced all ${localGalaxies.length} galaxies to cloud');
    } catch (e) {
      AppLogger.sync('⚠️ Failed to sync galaxies to cloud: $e');
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

  /// Recalculate star counts for ALL galaxies by counting actual stars
  /// This should be called after syncing galaxies from cloud to ensure counts are accurate
  Future<void> recalculateAllStarCounts() async {
    try {
      final galaxies = await getGalaxies();
      final allStars = await _gratitudeRepository.getAllGratitudesUnfiltered();

      // Count stars for each galaxy (excluding deleted stars)
      final starCounts = <String, int>{};
      for (final star in allStars) {
        if (!star.deleted) {
          starCounts[star.galaxyId] = (starCounts[star.galaxyId] ?? 0) + 1;
        }
      }

      // Update each galaxy's star count
      bool anyUpdated = false;
      final updatedGalaxies = galaxies.map((galaxy) {
        final actualCount = starCounts[galaxy.id] ?? 0;
        if (galaxy.starCount != actualCount) {
          anyUpdated = true;
          return galaxy.copyWith(starCount: actualCount);
        }
        return galaxy;
      }).toList();

      if (anyUpdated) {
        await saveGalaxies(updatedGalaxies);
        AppLogger.success('✅ Recalculated star counts for all galaxies');
      }
    } catch (e) {
      AppLogger.error('⚠️ Error recalculating star counts: $e');
    }
  }

  /// Clear all galaxy data (called on sign out)
  Future<void> clearAll() async {
    await _localDataSource.clearAll();
    _gratitudeRepository.setActiveGalaxyId(null);
    AppLogger.data('🗑️ Cleared all galaxy data');
  }

  /// Migrate existing stars to a galaxy
  Future<void> migrateExistingStarsToGalaxy(String galaxyId) async {
    final allStars = await _gratitudeRepository.getAllGratitudesUnfiltered();
    final starsNeedingMigration = allStars
        .where((star) => star.galaxyId == 'default' || star.galaxyId.isEmpty)
        .toList();

    if (starsNeedingMigration.isEmpty) {
      AppLogger.success('✅ No stars need migration');
      return;
    }

    final updatedStars = allStars.map((star) {
      if (star.galaxyId == 'default' || star.galaxyId.isEmpty) {
        return star.copyWith(galaxyId: galaxyId);
      }
      return star;
    }).toList();

    await _gratitudeRepository.saveGratitudes(updatedStars);
    AppLogger.success(
      '✅ Migrated ${starsNeedingMigration.length} stars to galaxy $galaxyId',
    );
  }
}
