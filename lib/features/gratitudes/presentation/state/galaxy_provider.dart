import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../galaxy_metadata.dart';
import '../../../gratitudes/data/repositories/galaxy_repository.dart';
import '../../../gratitudes/data/repositories/gratitude_repository.dart';
import 'gratitude_provider.dart';
import '../../../../core/utils/app_logger.dart';

/// Default galaxy name constant - used as system identifier
/// The localized display name is in l10n (defaultGalaxyName)
const String kDefaultGalaxyName = 'My First Galaxy';

/// Provider for galaxy state management
///
/// Manages all galaxy-related state and coordinates with repository
class GalaxyProvider extends ChangeNotifier {
  final GalaxyRepository _galaxyRepository;
  final GratitudeRepository _gratitudeRepository;

  late final GratitudeProvider _gratitudeProvider;

  List<GalaxyMetadata> _galaxies = [];
  String? _activeGalaxyId;
  final bool _isLoading = false;
  bool _isSwitching = false;
  bool _isInitialized = false; // Guard against duplicate initialization
  Timer? _starCountUpdateTimer;
  DateTime? _lastReconciliationTime;

  // Completer for tracking initialization status
  Completer<void>? _initializationCompleter;

  GalaxyProvider({
    required GalaxyRepository galaxyRepository,
    required GratitudeRepository gratitudeRepository,
  }) : _galaxyRepository = galaxyRepository,
       _gratitudeRepository = gratitudeRepository;

  /// Set gratitude provider (called after construction)
  void setGratitudeProvider(GratitudeProvider gratitudeProvider) {
    _gratitudeProvider = gratitudeProvider;
  }

  // Getters
  List<GalaxyMetadata> get galaxies => _galaxies;
  String? get activeGalaxyId => _activeGalaxyId;
  bool get isLoading => _isLoading;
  bool get isSwitching => _isSwitching;

  /// Get a Future that completes when initialization is done
  /// Returns immediately if already initialized
  Future<void> get initialized {
    if (_isInitialized) {
      return Future.value();
    }
    return _initializationCompleter?.future ?? Future.value();
  }

  /// Get active galaxy metadata
  GalaxyMetadata? get activeGalaxy {
    if (_activeGalaxyId == null) return null;
    try {
      return _galaxies.firstWhere((g) => g.id == _activeGalaxyId);
    } catch (e) {
      return null;
    }
  }

  /// Get non-deleted galaxies (deduplicated by ID)
  List<GalaxyMetadata> get activeGalaxies {
    // Deduplicate by ID (keep most recent version if duplicates exist)
    final seenIds = <String>{};
    final deduplicated = _galaxies
        .where((g) => !g.deleted)
        .where((g) => seenIds.add(g.id)) // add returns false if already present
        .toList();

    return deduplicated..sort((a, b) {
      // Sort by last viewed (most recent first)
      final aDate = a.lastViewedAt ?? a.createdAt;
      final bDate = b.lastViewedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
  }

  /// Get deleted galaxies
  List<GalaxyMetadata> get deletedGalaxies {
    return _galaxies.where((g) => g.deleted).toList()..sort(
      (a, b) =>
          (b.deletedAt ?? b.createdAt).compareTo(a.deletedAt ?? a.createdAt),
    );
  }

  /// Initialize - load galaxies and set active
  Future<void> initialize() async {
    // Guard against duplicate initialization
    if (_isInitialized) {
      AppLogger.warning('ℹ️ Galaxy system already initialized, skipping...');
      return;
    }

    // If already initializing, return the existing completer
    if (_initializationCompleter != null && !_initializationCompleter!.isCompleted) {
      AppLogger.info('⏳ Galaxy initialization already in progress, waiting...');
      return _initializationCompleter!.future;
    }

    // Start new initialization
    _initializationCompleter = Completer<void>();

    try {
      await loadGalaxies();

      // Log galaxy counts for debugging
      final activeCount = activeGalaxies.length;
      final deletedCount = deletedGalaxies.length;
      final totalCount = _galaxies.length;
      AppLogger.data(
        '📊 Galaxy counts - Total: $totalCount, Active: $activeCount, Deleted: $deletedCount',
      );
      if (activeCount > 0) {
        AppLogger.data(
          '📊 Active galaxy IDs: ${activeGalaxies.map((g) => '${g.id}(${g.name})').join(', ')}',
        );
      }

      // Load the saved active galaxy ID from storage
      _activeGalaxyId = await _galaxyRepository.getActiveGalaxyId();
      if (kDebugMode) {
        AppLogger.data(
          '📝 DEBUG: Loaded active galaxy from storage - activeGalaxyId=$_activeGalaxyId, totalGalaxies=$totalCount, galaxyIds=${_galaxies.map((g) => g.id).toList()}',
        );
      }
      AppLogger.data('📝 Loaded active galaxy from storage: $_activeGalaxyId');

      // Validate that active galaxy ID points to a non-deleted galaxy
      if (_activeGalaxyId != null &&
          !activeGalaxies.any((g) => g.id == _activeGalaxyId)) {
        // Active galaxy ID points to deleted or non-existent galaxy
        AppLogger.warning(
          '⚠️ Active galaxy ID $_activeGalaxyId points to deleted/non-existent galaxy, clearing',
        );
        _activeGalaxyId = null;
        // Clear from storage (repository handles user-scoped clearing)
        await _galaxyRepository.setActiveGalaxy('');
      }

      // If no active galaxy, create a default one ONLY if no active galaxies exist
      if (_activeGalaxyId == null && activeGalaxies.isEmpty) {
        // Only create default galaxy if we truly have no active galaxies
        // Check if we have any galaxies at all (including deleted)
        if (_galaxies.isEmpty) {
          AppLogger.start('📝 No galaxies found, creating default galaxy');
          await createGalaxy(name: kDefaultGalaxyName, switchToNew: true);
          // Reload galaxies after creation to ensure state is consistent
          await loadGalaxies();
          _activeGalaxyId = await _galaxyRepository.getActiveGalaxyId();
        } else {
          // We have galaxies but they're all deleted - log warning but don't create new one
          // Instead, restore the most recently deleted galaxy
          AppLogger.warning(
            '⚠️ All ${_galaxies.length} galaxies are deleted. Restoring most recent deleted galaxy.',
          );
          if (deletedGalaxies.isNotEmpty) {
            final mostRecentDeleted = deletedGalaxies.first;
            AppLogger.info(
              '🔄 Restoring deleted galaxy: ${mostRecentDeleted.name}',
            );
            await restoreGalaxy(mostRecentDeleted.id);
            _activeGalaxyId = mostRecentDeleted.id;
            await _galaxyRepository.setActiveGalaxy(_activeGalaxyId!);
            notifyListeners();
          }
        }
      } else if (_activeGalaxyId == null && activeGalaxies.isNotEmpty) {
        // Set first galaxy as active
        AppLogger.info('📝 Setting first galaxy as active');
        _activeGalaxyId = activeGalaxies.first.id;
        await _galaxyRepository.setActiveGalaxy(_activeGalaxyId!);
        notifyListeners();
      }

      // Mark as initialized AFTER galaxies are loaded and validated
      _isInitialized = true;

      // Set the active galaxy filter in the gratitude repository
      if (_activeGalaxyId != null) {
        _gratitudeRepository.setActiveGalaxyId(_activeGalaxyId);
        AppLogger.info(
          '🔧 Set gratitude repository filter to: $_activeGalaxyId',
        );

        // Migrate existing stars to active galaxy (one-time migration)
        await _gratitudeRepository.migrateStarsToActiveGalaxy(_activeGalaxyId!);
      }

      // SAFETY: Ensure local galaxies are backed up to cloud if authenticated
      // This handles: email just linked, missed sync during login, etc.
      if (activeGalaxies.isNotEmpty) {
        // syncToCloud() handles auth check internally and no-ops if not authenticated
        syncToCloud().catchError((e) {
          AppLogger.sync('⚠️ Background galaxy sync failed during init: $e');
          // Not critical - will sync on next galaxy switch
        });
        // Don't await - run in background to avoid blocking initialization
      }

      AppLogger.success(
        '✅ Galaxy system initialized, active: $_activeGalaxyId',
      );

      // Complete the initialization completer
      _initializationCompleter?.complete();
    } catch (e) {
      AppLogger.error('❌ Galaxy initialization failed: $e');
      // Complete with error
      _initializationCompleter?.completeError(e);
      rethrow;
    }
  }

  /// Load all galaxies from repository
  Future<void> loadGalaxies() async {
    try {
      _galaxies = await _galaxyRepository.getGalaxies();

      // RECONCILIATION: Verify star counts match reality
      await _reconcileStarCounts();

      notifyListeners();
    } catch (e) {
      AppLogger.error('⚠️ Error loading galaxies: $e');
      rethrow;
    }
  }

  /// Reconcile star counts - verify cached counts match actual star data
  /// This fixes drift caused by failed updates, sync issues, or data corruption
  Future<void> _reconcileStarCounts() async {
    // Skip if reconciled in last 2 seconds
    if (_lastReconciliationTime != null &&
        DateTime.now().difference(_lastReconciliationTime!).inSeconds < 2) {
      return;
    }

    try {
      // Get all stars (unfiltered) to count per galaxy
      final allStars = await _gratitudeRepository.getAllGratitudesUnfiltered();

      // Count stars per galaxy (excluding deleted)
      final Map<String, int> actualCounts = {};
      final Set<String> validGalaxyIds = _galaxies.map((g) => g.id).toSet();
      int orphanedStars = 0;

      for (final star in allStars) {
        if (!star.deleted) {
          // Check for orphaned stars (pointing to non-existent galaxies)
          if (!validGalaxyIds.contains(star.galaxyId)) {
            orphanedStars++;
            AppLogger.warning(
              '⚠️ Found orphaned star "${star.text.substring(0, star.text.length > 30 ? 30 : star.text.length)}" pointing to deleted galaxy: ${star.galaxyId}',
            );
            // Don't count orphaned stars - they need manual cleanup
            continue;
          }

          actualCounts[star.galaxyId] = (actualCounts[star.galaxyId] ?? 0) + 1;
        }
      }

      if (orphanedStars > 0) {
        AppLogger.warning(
          '⚠️ Found $orphanedStars orphaned stars - consider manual cleanup',
        );
      }

      // Check each galaxy for mismatch
      bool needsUpdate = false;
      final updatedGalaxies = <GalaxyMetadata>[];

      for (final galaxy in _galaxies) {
        final actualCount = actualCounts[galaxy.id] ?? 0;

        if (galaxy.starCount != actualCount) {
          AppLogger.data(
            '🔄 Reconciling galaxy "${galaxy.name}": metadata says ${galaxy.starCount}, actual is $actualCount',
          );
          updatedGalaxies.add(galaxy.copyWith(starCount: actualCount));
          needsUpdate = true;
        } else {
          updatedGalaxies.add(galaxy);
        }
      }

      // Save corrected counts if any mismatches found
      if (needsUpdate) {
        _galaxies = updatedGalaxies;
        await _galaxyRepository.saveGalaxies(_galaxies);
        AppLogger.success(
          '✅ Reconciled star counts for ${updatedGalaxies.length} galaxies',
        );
      }

      // Update reconciliation timestamp to prevent repeated reconciliation
      _lastReconciliationTime = DateTime.now();
    } catch (e) {
      AppLogger.error('⚠️ Error reconciling star counts: $e');
      // Don't rethrow - this is a background operation
    }
  }

  /// Create a new galaxy
  Future<GalaxyMetadata> createGalaxy({
    required String name,
    bool switchToNew = true,
  }) async {
    try {
      final galaxy = await _galaxyRepository.createGalaxy(
        name: name,
        setAsActive: switchToNew,
      );

      // Reload galaxies
      await loadGalaxies();

      if (switchToNew) {
        // Use proper method to set active galaxy (updates repo, lastViewed, etc.)
        await setActiveGalaxy(galaxy.id);

        // Reload gratitudes to show stars from new galaxy (wait for sync)
        try {
          await _gratitudeProvider.loadGratitudes(waitForSync: true);
        } catch (e) {
          AppLogger.error('⚠️ Failed to load gratitudes during switch: $e');
          // Continue anyway - don't block the switch
        }
      }

      notifyListeners();

      AppLogger.success('✅ Created galaxy: ${galaxy.name} (${galaxy.id})');
      return galaxy;
    } catch (e) {
      AppLogger.error('⚠️ Error creating galaxy: $e');
      rethrow;
    }
  }

  /// Switch to a different galaxy (with animation support)
  Future<void> switchGalaxy(
    String galaxyId, {
    Future<void> Function()? onFadeOut,
    Future<void> Function()? onFadeIn,
  }) async {
    // Validate galaxy exists
    if (!_galaxies.any((g) => g.id == galaxyId)) {
      AppLogger.warning('⚠️ Cannot switch to non-existent galaxy: $galaxyId');
      throw Exception('Galaxy $galaxyId does not exist');
    }

    if (_activeGalaxyId == galaxyId) {
      AppLogger.info('ℹ️ Already on galaxy $galaxyId');
      return;
    }

    _isSwitching = true;
    notifyListeners();

    try {
      // Step 1: Fade out animation callback
      if (onFadeOut != null) {
        await onFadeOut();
      }

      // Step 2: Switch galaxy in repository and update filter
      await _galaxyRepository.setActiveGalaxy(galaxyId);
      _activeGalaxyId = galaxyId;

      AppLogger.info('🔄 Galaxy switch: set active to $galaxyId');

      // Step 3: Reload galaxies to update lastViewedAt
      await loadGalaxies();

      // Step 4: CRITICAL FIX - Sync this specific galaxy from cloud first
      // This ensures all stars for this galaxy are downloaded, even if they
      // weren't modified recently (fixes delta sync issue)
      AppLogger.sync(
        '🔄 Galaxy switch: syncing galaxy $galaxyId from cloud...',
      );
      try {
        await _gratitudeRepository.syncGalaxyFromCloud(galaxyId);
      } catch (e) {
        AppLogger.sync(
          '⚠️ Galaxy-specific sync failed: $e (continuing with local data)',
        );
        // Continue even if sync fails - we'll use local data
      }

      // Step 5: Reload gratitudes with new galaxy filter AND wait for full sync
      AppLogger.data(
        '🔄 Galaxy switch: reloading gratitudes for galaxy $galaxyId',
      );
      await _gratitudeProvider.loadGratitudes(waitForSync: true);

      final starCount = _gratitudeProvider.gratitudeStars.length;
      AppLogger.sync('🔄 Galaxy switch: loaded $starCount stars (synced)');

      // Step 6: Fade in animation callback
      if (onFadeIn != null) {
        await onFadeIn();
      }

      // Get galaxy name for logging
      final galaxyName = _galaxies.firstWhere((g) => g.id == galaxyId).name;
      AppLogger.success(
        '✅ Switched to galaxy "$galaxyName" ($starCount stars)',
      );
    } catch (e) {
      AppLogger.error('⚠️ Error switching galaxy: $e');
      rethrow;
    } finally {
      _isSwitching = false;
      notifyListeners();
    }
  }

  /// Set active galaxy without animation (for internal use)
  Future<void> setActiveGalaxy(String galaxyId) async {
    // Validate galaxy exists
    if (!_galaxies.any((g) => g.id == galaxyId)) {
      AppLogger.warning(
        '⚠️ Cannot set non-existent galaxy as active: $galaxyId',
      );
      throw Exception('Galaxy $galaxyId does not exist');
    }

    if (_activeGalaxyId == galaxyId) {
      AppLogger.info('ℹ️ Already on galaxy $galaxyId');
      return;
    }

    try {
      await _galaxyRepository.setActiveGalaxy(galaxyId);
      _activeGalaxyId = galaxyId;
      await loadGalaxies();

      // Sync this specific galaxy from cloud to ensure all stars are present
      AppLogger.sync(
        '🔄 Set active galaxy: syncing galaxy $galaxyId from cloud...',
      );
      try {
        await _gratitudeRepository.syncGalaxyFromCloud(galaxyId);
      } catch (e) {
        AppLogger.sync(
          '⚠️ Galaxy-specific sync failed: $e (continuing with local data)',
        );
      }

      // Reload gratitudes to show stars from new galaxy (wait for sync)
      await _gratitudeProvider.loadGratitudes(waitForSync: true);

      notifyListeners();

      // Get galaxy name for better logging
      final galaxyName = _galaxies.firstWhere((g) => g.id == galaxyId).name;
      final starCount = _gratitudeProvider.gratitudeStars.length;
      AppLogger.success(
        '✅ Set active galaxy: "$galaxyName" ($starCount stars)',
      );
    } catch (e) {
      AppLogger.error('⚠️ Error setting active galaxy: $e');
      rethrow;
    }
  }

  /// Rename a galaxy
  Future<void> renameGalaxy(String galaxyId, String newName) async {
    try {
      final index = _galaxies.indexWhere((g) => g.id == galaxyId);
      if (index == -1) {
        AppLogger.warning('⚠️ Galaxy $galaxyId not found');
        return;
      }

      // Limit galaxy name length
      final truncatedName = newName.length > GalaxyMetadata.maxNameLength
          ? newName.substring(0, GalaxyMetadata.maxNameLength)
          : newName;

      final updatedGalaxy = _galaxies[index].copyWith(
        name: truncatedName,
        lastModifiedAt: DateTime.now(),
      );
      await _galaxyRepository.updateGalaxy(updatedGalaxy);
      await loadGalaxies();

      AppLogger.success('✅ Renamed galaxy to: "$truncatedName"');

      // Sync to cloud immediately if authenticated (don't wait)
      syncToCloud().catchError((e) {
        AppLogger.sync('⚠️ Failed to sync renamed galaxy to cloud: $e');
      });
    } catch (e) {
      AppLogger.error('⚠️ Error renaming galaxy: $e');
      rethrow;
    }
  }

  /// Delete a galaxy (cascade delete stars)
  Future<void> deleteGalaxy(String galaxyId) async {
    try {
      final galaxyName = _galaxies
          .firstWhere(
            (g) => g.id == galaxyId,
            orElse: () => GalaxyMetadata(
              id: galaxyId,
              name: 'Unknown',
              createdAt: DateTime.now(),
            ),
          )
          .name;

      await _galaxyRepository.deleteGalaxy(galaxyId);
      await loadGalaxies();

      // If we deleted the active galaxy, update active ID and reload
      if (_activeGalaxyId == galaxyId) {
        _activeGalaxyId = await _galaxyRepository.getActiveGalaxyId();
        _gratitudeRepository.setActiveGalaxyId(_activeGalaxyId);

        // Reload gratitudes for new active galaxy
        await _gratitudeProvider.loadGratitudes();
      }

      // Check if zero galaxies remain and create a default one
      if (activeGalaxies.isEmpty) {
        await _ensureDefaultGalaxy();
      }

      notifyListeners();
      AppLogger.success('✅ Deleted galaxy "$galaxyName" ($galaxyId)');

      // Sync deletion to cloud immediately if authenticated (don't wait)
      syncToCloud().catchError((e) {
        AppLogger.sync('⚠️ Failed to sync galaxy deletion to cloud: $e');
      });
    } catch (e) {
      AppLogger.error('⚠️ Error deleting galaxy: $e');
      rethrow;
    }
  }

  /// Ensure a default galaxy exists (creates one if none exist)
  Future<void> _ensureDefaultGalaxy() async {
    try {
      AppLogger.start('📝 No galaxies remaining, creating default galaxy');
      final newGalaxy = await createGalaxy(
        name: kDefaultGalaxyName,
        switchToNew: true,
      );

      // Reload gratitudes for the new galaxy
      await _gratitudeProvider.loadGratitudes();

      AppLogger.success('✅ Created default galaxy: "${newGalaxy.name}"');
    } catch (e) {
      AppLogger.error('⚠️ Error creating default galaxy: $e');
      // Don't rethrow - app can continue with zero galaxies, will be handled on next initialization
    }
  }

  /// Restore a deleted galaxy
  Future<void> restoreGalaxy(String galaxyId) async {
    try {
      await _galaxyRepository.restoreGalaxy(galaxyId);
      await loadGalaxies();

      final galaxyName = _galaxies
          .firstWhere(
            (g) => g.id == galaxyId,
            orElse: () => GalaxyMetadata(
              id: galaxyId,
              name: 'Unknown',
              createdAt: DateTime.now(),
            ),
          )
          .name;

      notifyListeners();
      AppLogger.success('✅ Restored galaxy "$galaxyName" ($galaxyId)');

      // Sync restoration to cloud immediately if authenticated (don't wait)
      syncToCloud().catchError((e) {
        AppLogger.sync('⚠️ Failed to sync galaxy restoration to cloud: $e');
      });
    } catch (e) {
      AppLogger.error('⚠️ Error restoring galaxy: $e');
      rethrow;
    }
  }

  /// Update star count for active galaxy
  Future<void> updateActiveGalaxyStarCount(int count) async {
    if (_activeGalaxyId == null) return;

    // Debounce: cancel pending update and schedule new one
    _starCountUpdateTimer?.cancel();
    _starCountUpdateTimer = Timer(Duration(milliseconds: 300), () async {
      try {
        await _galaxyRepository.updateStarCount(_activeGalaxyId!, count);
        await loadGalaxies();
        notifyListeners();
      } catch (e, stack) {
        AppLogger.error('Failed to update galaxy star count: $e');
        AppLogger.error('Stack trace: $stack');
      }
    });
  }

  /// Update galaxy metadata
  Future<void> updateGalaxy(GalaxyMetadata galaxy) async {
    try {
      await _galaxyRepository.updateGalaxy(galaxy);
      await loadGalaxies();
      notifyListeners();

      // Sync to cloud immediately if authenticated (don't wait)
      syncToCloud().catchError((e) {
        AppLogger.sync('⚠️ Failed to sync updated galaxy to cloud: $e');
      });
    } catch (e) {
      AppLogger.error('⚠️ Error updating galaxy: $e');
      rethrow;
    }
  }

  /// Sync galaxies from cloud
  Future<void> syncFromCloud() async {
    try {
      await _galaxyRepository.syncFromCloud();
      await loadGalaxies();

      // Update active galaxy
      _activeGalaxyId = await _galaxyRepository.getActiveGalaxyId();
      _gratitudeRepository.setActiveGalaxyId(_activeGalaxyId);

      // Recalculate star counts for all galaxies to ensure accuracy
      await _galaxyRepository.recalculateAllStarCounts();
      await loadGalaxies(); // Reload to get updated counts

      notifyListeners();
    } catch (e) {
      AppLogger.sync('⚠️ Error syncing galaxies from cloud: $e');

      // If cloud sync fails but we have local galaxies, try to upload them
      // This handles the case where Firebase has no galaxy data yet
      if (_galaxies.isNotEmpty) {
        AppLogger.sync(
          '🔄 Attempting to upload local galaxies to cloud as fallback...',
        );
        try {
          await syncToCloud();
        } catch (uploadError) {
          AppLogger.sync('⚠️ Fallback upload also failed: $uploadError');
        }
      }

      // Don't rethrow - app continues with local data
    }
  }

  /// Sync galaxies to cloud
  Future<void> syncToCloud() async {
    try {
      await _galaxyRepository.syncToCloud();
    } catch (e) {
      AppLogger.sync('⚠️ Error syncing galaxies to cloud: $e');
      rethrow;
    }
  }

  /// Reset initialization flag to allow reinitialization (e.g., after profile switch)
  /// Also clears galaxy state to ensure clean initialization for new user
  void resetInitialization() {
    _isInitialized = false;
    _galaxies = [];
    _activeGalaxyId = null;
    AppLogger.data(
      '🔄 Reset galaxy initialization flag and cleared galaxy state',
    );
  }

  /// Clear all galaxy data (called on sign out)
  Future<void> clearAll() async {
    try {
      await _galaxyRepository.clearAll();
      _galaxies = [];
      _activeGalaxyId = null;
      _isInitialized = false; // Reset initialization flag
      notifyListeners();
    } catch (e) {
      AppLogger.error('⚠️ Error clearing galaxy data: $e');
    }
  }

  /// Restore galaxies from backup
  ///
  /// [backupActiveGalaxyId] - Optional active galaxy ID from backup metadata.
  /// If provided and the galaxy exists in backup, will switch to it.
  Future<void> restoreFromBackup(
    List<GalaxyMetadata> backupGalaxies, {
    String? backupActiveGalaxyId,
  }) async {
    _galaxies = backupGalaxies;

    // Save to local storage
    await _galaxyRepository.saveGalaxies(_galaxies);

    // Determine which galaxy should be active
    String? targetActiveGalaxyId;

    if (backupActiveGalaxyId != null &&
        _galaxies.any((g) => g.id == backupActiveGalaxyId)) {
      // Use active galaxy from backup if it exists
      targetActiveGalaxyId = backupActiveGalaxyId;
      AppLogger.info(
        '🔄 Restoring active galaxy from backup: $targetActiveGalaxyId',
      );
    } else if (_galaxies.isNotEmpty) {
      // Fallback to first galaxy if backup active galaxy doesn't exist or wasn't provided
      targetActiveGalaxyId = _galaxies.first.id;
      AppLogger.info('🔄 Using first galaxy as active: $targetActiveGalaxyId');
    }

    // Set active galaxy if we have one
    if (targetActiveGalaxyId != null) {
      final wasDifferent = _activeGalaxyId != targetActiveGalaxyId;
      _activeGalaxyId = targetActiveGalaxyId;
      await _galaxyRepository.setActiveGalaxy(_activeGalaxyId!);

      // If galaxy changed, we need to sync and reload stars
      if (wasDifferent) {
        AppLogger.info(
          '🔄 Active galaxy changed during restore, will sync and reload stars',
        );
      }
    }

    // Update gratitude repository filter to match active galaxy
    if (_activeGalaxyId != null) {
      _gratitudeRepository.setActiveGalaxyId(_activeGalaxyId);
      AppLogger.info(
        '🔧 Updated gratitude repository filter to: $_activeGalaxyId',
      );
    }

    // Reconcile star counts after restore
    await _reconcileStarCounts();

    // Sync to cloud (repository handles auth check internally)
    syncToCloud().catchError((e) {
      AppLogger.sync('⚠️ Cloud sync after galaxy restore failed: $e');
      // Don't block restore on sync failure
    });

    notifyListeners();
    AppLogger.success(
      '✅ Restored ${backupGalaxies.length} galaxies from backup',
    );
  }
}
