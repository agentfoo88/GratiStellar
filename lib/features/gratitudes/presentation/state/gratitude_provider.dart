import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/error/error_context.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/retry_policy.dart';
import '../../../../core/security/rate_limiter.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/sync_status_service.dart';
import '../../../../storage.dart';
import '../../data/repositories/gratitude_repository.dart';
import '../../domain/usecases/add_gratitude_use_case.dart';
import '../../domain/usecases/delete_gratitude_use_case.dart';
import '../../domain/usecases/get_deleted_gratitudes_use_case.dart';
import '../../domain/usecases/load_gratitudes_use_case.dart';
import '../../domain/usecases/purge_old_deleted_use_case.dart';
import '../../domain/usecases/restore_gratitude_use_case.dart';
import '../../domain/usecases/sync_gratitudes_use_case.dart';
import '../../domain/usecases/update_gratitude_use_case.dart';
import '../../domain/usecases/use_case.dart';
import 'galaxy_provider.dart';
import '../../../../core/utils/app_logger.dart';

/// Provider for gratitude state management
///
/// Manages all gratitude-related state and coordinates with use cases.
/// Notifies listeners only when relevant data changes.
class GratitudeProvider extends ChangeNotifier {
  // Dependencies
  final GratitudeRepository _repository;
  final AuthService _authService;
  final SyncStatusService _syncStatusService;
  final math.Random _random;

  late final GalaxyProvider _galaxyProvider;

  // Use cases
  late final AddGratitudeUseCase _addGratitudeUseCase;
  late final DeleteGratitudeUseCase _deleteGratitudeUseCase;
  late final UpdateGratitudeUseCase _updateGratitudeUseCase;
  late final LoadGratitudesUseCase _loadGratitudesUseCase;
  late final SyncGratitudesUseCase _syncGratitudesUseCase;
  late final GetDeletedGratitudesUseCase _getDeletedGratitudesUseCase;
  late final RestoreGratitudeUseCase _restoreGratitudeUseCase;
  late final PurgeOldDeletedUseCase _purgeOldDeletedUseCase;

  // state
  List<GratitudeStar> _gratitudeStars = [];
  bool _isLoading = true;
  bool _showAllGratitudes = false;
  bool _mindfulnessMode = false;
  bool _isAnimating = false;
  GratitudeStar? _animatingStar;
  GratitudeStar? _activeMindfulnessStar;
  int _mindfulnessInterval = 3;
  Timer? _mindfulnessTimer;
  StreamSubscription<User?>? _authSubscription;
  Timer? _syncDebouncer;
  bool _hasPendingChanges = false;
  User? _previousUser; // Track previous user state to detect actual sign-out

  // Sync coordination
  bool _isSyncing = false;
  DateTime? _lastSuccessfulSync;
  bool _needsResyncAfterCurrent = false; // Flag to re-sync after current sync completes

  // Sign-in prompt tracking
  static const String _signInPromptDismissedKey = 'sign_in_prompt_dismissed';
  static const String _signInPromptStarThresholdKey = 'sign_in_prompt_star_threshold';
  static const int _defaultStarThreshold = 3; // Show prompt after 3 stars

  // Getters
  List<GratitudeStar> get gratitudeStars => _gratitudeStars;
  bool get isLoading => _isLoading;
  bool get showAllGratitudes => _showAllGratitudes;
  bool get mindfulnessMode => _mindfulnessMode;
  bool get isAnimating => _isAnimating;
  GratitudeStar? get animatingStar => _animatingStar;
  GratitudeStar? get activeMindfulnessStar => _activeMindfulnessStar;
  int get mindfulnessInterval => _mindfulnessInterval;
  SyncStatusService get syncStatus => _syncStatusService;
  bool get hasPendingChanges => _hasPendingChanges;

  /// Check if sign-in prompt should be shown
  /// Returns true if user is anonymous, has created enough stars, and hasn't dismissed the prompt
  Future<bool> shouldShowSignInPrompt() async {
    // Don't show if user is already signed in with email
    if (_authService.hasEmailAccount) {
      return false;
    }

    // Check if prompt was dismissed
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_signInPromptDismissedKey) ?? false;
    if (dismissed) {
      return false;
    }

    // Check star count threshold
    final threshold = prefs.getInt(_signInPromptStarThresholdKey) ?? _defaultStarThreshold;
    return _gratitudeStars.length >= threshold;
  }

  /// Dismiss the sign-in prompt (user tapped "Maybe Later")
  Future<void> dismissSignInPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_signInPromptDismissedKey, true);
    AppLogger.data('📝 Sign-in prompt dismissed');
  }

  /// Reset sign-in prompt (for testing or if user wants to see it again)
  Future<void> resetSignInPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_signInPromptDismissedKey);
    AppLogger.data('🔄 Sign-in prompt reset');
  }

  GratitudeProvider({
    required GratitudeRepository repository,
    required AuthService authService,
    required SyncStatusService syncStatusService,
    required math.Random random,
  })  : _repository = repository,
        _authService = authService,
        _syncStatusService = syncStatusService,
        _random = random {
    _initializeUseCases();
    // Initialize previous user state with current user
    _previousUser = _authService.currentUser;
    _setupAuthListener();
  }

  void _initializeUseCases() {
    _addGratitudeUseCase = AddGratitudeUseCase(_random);
    _deleteGratitudeUseCase = DeleteGratitudeUseCase(_repository);
    _updateGratitudeUseCase = UpdateGratitudeUseCase(_repository);
    _loadGratitudesUseCase = LoadGratitudesUseCase(
      repository: _repository,
      authService: _authService,
    );
    _syncGratitudesUseCase = SyncGratitudesUseCase(_repository);
    _getDeletedGratitudesUseCase = GetDeletedGratitudesUseCase(_repository);
    _restoreGratitudeUseCase = RestoreGratitudeUseCase(_repository);
    _purgeOldDeletedUseCase = PurgeOldDeletedUseCase(_repository);
  }

  void _setupAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      // Only clear if we had a user before and now we don't (actual sign-out)
      // This prevents clearing data on initial null state for device-based anonymous users
      if (_previousUser != null && user == null) {
        AppLogger.auth('👤 User signed out, clearing state...');
        clearState();
      } else if (_previousUser == null && user != null) {
        // User signed in - reload their data
        AppLogger.auth('👤 Auth state changed, reloading gratitudes...');
        loadGratitudes();
      }
      
      _previousUser = user;
    });
  }

  /// Set galaxy provider (called after construction)
  void setGalaxyProvider(GalaxyProvider galaxyProvider) {
    _galaxyProvider = galaxyProvider;
  }

  /// Clear all state (called on sign out)
  void clearState() {
    AppLogger.data('🗑️ Clearing provider state');
    _gratitudeStars = [];
    _isLoading = true;
    _showAllGratitudes = false;
    _mindfulnessMode = false;
    _isAnimating = false;
    _animatingStar = null;
    _activeMindfulnessStar = null;
    _mindfulnessTimer?.cancel();
    _mindfulnessTimer = null;

    _galaxyProvider.clearAll();

    notifyListeners();
  }

  /// Load gratitudes from storage
  /// 
  /// If [waitForSync] is true, this method will wait for cloud sync to complete
  /// before returning. This is important for galaxy switching to ensure fresh data.
  Future<void> loadGratitudes({bool waitForSync = false}) async {
    final result = await _loadGratitudesUseCase(NoParams());

    // Deduplicate by ID (in case of storage corruption or sync issues)
    final seenIds = <String>{};
    final dedupedStars = <GratitudeStar>[];

    for (final star in result.stars) {
      if (!seenIds.contains(star.id)) {
        seenIds.add(star.id);
        dedupedStars.add(star);
      } else {
        AppLogger.warning('⚠️ Duplicate star detected and removed: ${star.id}');
      }
    }

    // Purge old deleted items (30+ days)
    final purgedStars = await _purgeOldDeletedUseCase(PurgeOldDeletedParams(dedupedStars));

    // Filter for display: only non-deleted stars from the current galaxy
    // CRITICAL: Must filter by galaxy ID to match syncWithCloud() behavior!
    final activeGalaxyId = _galaxyProvider.activeGalaxyId;
    
    // #region agent log
    final allStarsCount = purgedStars.length;
    final galaxyIdCounts = <String, int>{};
    for (final star in purgedStars) {
      if (!star.deleted) {
        galaxyIdCounts[star.galaxyId] = (galaxyIdCounts[star.galaxyId] ?? 0) + 1;
      }
    }
    AppLogger.sync('📋 DEBUG: loadGratitudes filtering - totalStarsInStorage=$allStarsCount, activeGalaxyId=$activeGalaxyId, starsByGalaxyId=${galaxyIdCounts.toString()}');
    // #endregion
    
    _gratitudeStars = purgedStars
        .where((star) =>
            !star.deleted &&
            star.galaxyId == activeGalaxyId)
        .toList();
    
    // #region agent log
    AppLogger.sync('📋 DEBUG: loadGratitudes filtered result - filteredStarsCount=${_gratitudeStars.length}, activeGalaxyId=$activeGalaxyId');
    // #endregion
    
    _isLoading = false;
    notifyListeners();

    // Sync with cloud if needed
    if (result.shouldSyncWithCloud) {
      if (waitForSync) {
        // Wait for sync to complete (used for galaxy switching)
        try {
          // Add 30-second timeout to prevent hanging indefinitely
          await syncWithCloud().timeout(
            Duration(seconds: 30),
            onTimeout: () {
              AppLogger.sync('⏱️ Sync timeout during galaxy switch - continuing with local data');
              throw TimeoutException('Sync timed out after 30 seconds');
            },
          );
          AppLogger.sync('✅ Sync completed during load');
        } catch (e) {
          AppLogger.sync('⚠️ Sync failed during load: $e');
          // Don't rethrow - we still have local data
          // Update sync status to show error
          _syncStatusService.markError(e.toString());
        }
      } else {
        // Don't block on sync - run in background (normal startup behavior)
        syncWithCloud().catchError((e) {
          AppLogger.sync('⚠️ Background sync failed: $e');
        });
      }
    }
  }

  /// Sync with cloud
  Future<void> syncWithCloud({bool force = false}) async {
    // Check if already syncing (mutex)
    if (_isSyncing) {
      AppLogger.sync('⏸️ Sync already in progress, marking for re-sync after completion...');
      _needsResyncAfterCurrent = true;
      _hasPendingChanges = true; // Ensure re-sync isn't skipped
      return;
    }

    // Smart sync: Skip if recently synced and no pending changes (unless forced)
    if (!force && _lastSuccessfulSync != null && !_hasPendingChanges) {
      final timeSinceLastSync = DateTime.now().difference(_lastSuccessfulSync!);
      if (timeSinceLastSync < Duration(minutes: 5)) {
        AppLogger.sync('⏭️ Skipping sync - recently synced ${timeSinceLastSync.inMinutes}m ago with no pending changes');
        return;
      }
    }

    _isSyncing = true;
    final wasResync = _needsResyncAfterCurrent;
    _needsResyncAfterCurrent = false; // Clear flag at start
    
    try {
      // Get ALL stars (unfiltered) for sync to prevent data loss across galaxies
      final allStarsUnfiltered = await _repository.getAllGratitudesUnfiltered();
      
      // DEBUG: Log what we're syncing
      AppLogger.sync('📋 Preparing to sync ${allStarsUnfiltered.length} stars:');
      for (final star in allStarsUnfiltered) {
        AppLogger.info('   - "${star.text.substring(0, star.text.length > 30 ? 30 : star.text.length)}" (${star.id}) galaxy:${star.galaxyId} deleted:${star.deleted}');
      }
      
      final result = await _syncGratitudesUseCase(
        SyncGratitudesParams(localStars: allStarsUnfiltered),
      );

      // Deduplicate by ID (in case of sync issues)
      final seenIds = <String>{};
      final dedupedStars = <GratitudeStar>[];

      for (final star in result.mergedStars) {
        if (!seenIds.contains(star.id)) {
          seenIds.add(star.id);
          dedupedStars.add(star);
        }
      }

      // Filter for UI display: only non-deleted stars from the current galaxy
      // Note: ALL stars (dedupedStars) are already saved to repository by the sync use case
      // This filtering is ONLY for the UI display in _gratitudeStars
      _gratitudeStars = dedupedStars
          .where((star) =>
              !star.deleted &&
              star.galaxyId == _galaxyProvider.activeGalaxyId)
          .toList();

      // Track successful sync
      _lastSuccessfulSync = DateTime.now();

      // RECONCILIATION: Update galaxy star count after sync (in case cloud had different data)
      await _galaxyProvider.updateActiveGalaxyStarCount(_gratitudeStars.length);

      notifyListeners();
    } catch (e) {
      AppLogger.sync('⚠️ Sync failed: $e');
      rethrow; // Let caller handle the error
    } finally {
      _isSyncing = false;
      
      // If changes were made during sync, trigger another sync immediately
      if (wasResync || _needsResyncAfterCurrent) {
        AppLogger.sync('🔄 Changes occurred during sync, triggering immediate re-sync (force=true)...');
        final hadPendingChanges = _needsResyncAfterCurrent;
        _needsResyncAfterCurrent = false;
        // Run in background to avoid blocking
        Future.delayed(Duration(milliseconds: 100), () {
          syncWithCloud(force: true).catchError((e) {
            AppLogger.sync('⚠️ Re-sync failed: $e');
            // If re-sync fails and we had pending changes, keep the flag set
            if (hadPendingChanges) {
              _hasPendingChanges = true;
            }
          });
        });
      }
    }
  }

  /// Create a new gratitude star
  Future<GratitudeStar> createGratitude(
      String text,
      Size screenSize, {
        int? colorPresetIndex,
        Color? customColor,
      }) async {
    // Safety check: Ensure galaxy system is initialized
    // If not initialized, wait a bit and retry (handles race condition)
    if (_galaxyProvider.activeGalaxyId == null) {
      AppLogger.warning('⚠️ No active galaxy, waiting for initialization...');
      
      // Wait up to 2 seconds for initialization
      int attempts = 0;
      const maxAttempts = 20; // 20 * 100ms = 2 seconds
      while (_galaxyProvider.activeGalaxyId == null && attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      // If still not initialized, try initializing now
      if (_galaxyProvider.activeGalaxyId == null) {
        AppLogger.info('🔄 Attempting to initialize galaxy system...');
        try {
          await _galaxyProvider.initialize();
        } catch (e) {
          AppLogger.error('❌ Galaxy initialization failed: $e');
        }
      }
      
      // Final check
      if (_galaxyProvider.activeGalaxyId == null) {
        AppLogger.error('❌ Cannot create star: No active galaxy (initialization incomplete)');
        throw StateError(
            'Galaxy system not initialized. Please wait a moment and try again.'
        );
      }
    }
    
    final star = await _addGratitudeUseCase(
      AddGratitudeParams(
        text: text,
        screenSize: screenSize,
        existingStars: _gratitudeStars,
        galaxyId: _galaxyProvider.activeGalaxyId!,
        colorPresetIndex: colorPresetIndex,
        customColor: customColor,
      ),
    );
    return star;
  }

  /// Start birth animation for a new star
  void startBirthAnimation(GratitudeStar star) {
    _isAnimating = true;
    _animatingStar = star;
    notifyListeners();
  }

  /// Complete birth animation and add star to list
  Future<void> completeBirthAnimation() async {
    if (_animatingStar != null) {
      _gratitudeStars.add(_animatingStar!);

      // Save to repository (includes cloud sync if authenticated)
      final allStars = await _repository.getAllGratitudesUnfiltered();
      await _repository.addGratitude(_animatingStar!, allStars);
      
      // Check if we should show sign-in prompt (for anonymous users)
      // Notify listeners so UI can check and show prompt if needed
      notifyListeners();
      
      // CRITICAL: For single star adds, sync immediately instead of debouncing
      // This prevents data loss if app crashes before 30-second timer fires
      // BUT: Check connectivity first and add timeout to prevent animation freeze
      if (_authService.hasEmailAccount) {
        // Check connectivity BEFORE attempting sync
        if (_syncStatusService.hasConnectivity) {
          AppLogger.sync('💾 Star added - triggering immediate sync (online)');
          _markPendingChanges(); // Mark pending but don't schedule timer
          // Sync in background with timeout to prevent hanging
          _performImmediateSyncWithTimeout().catchError((e) {
            AppLogger.sync('⚠️ Immediate sync failed: $e');
            // Fallback: schedule debounced sync as backup
            _scheduleSync();
          });
        } else {
          // Offline - mark as pending, skip sync attempt
          AppLogger.sync('💾 Star added - offline, marking as pending');
          _markPendingChanges();
          // Star is saved locally, user can continue using app
        }
      }

      // Update galaxy star count (non-blocking)
      _galaxyProvider.updateActiveGalaxyStarCount(_gratitudeStars.length)
          .catchError((e) {
        AppLogger.error('⚠️ Error updating galaxy star count: $e');
        // Don't block animation completion
      });

      // Complete animation immediately - don't wait for sync
      _isAnimating = false;
      _animatingStar = null;
      notifyListeners();
    }
  }

  /// Update an existing gratitude
  Future<void> updateGratitude(GratitudeStar updatedStar) async {
    final updatedStars = await _updateGratitudeUseCase(
      UpdateGratitudeParams(
        updatedStar: updatedStar,
        allStars: _gratitudeStars,
      ),
    );

    _gratitudeStars = updatedStars;
    notifyListeners();
    
    // CRITICAL: Sync immediately for data safety
    if (_authService.hasEmailAccount) {
      AppLogger.sync('💾 Star updated - triggering immediate sync');
      _markPendingChanges();
      _performBackgroundSync().catchError((e) {
        AppLogger.sync('⚠️ Immediate sync failed: $e');
        _scheduleSync(); // Fallback to debounced
      });
    }
  }

  /// Delete a gratitude
  Future<void> deleteGratitude(GratitudeStar star) async {
    // Rate limit check
    if (!RateLimiter.checkLimit('delete_gratitude')) {
      final retryAfter = RateLimiter.getTimeUntilReset('delete_gratitude');
      throw RateLimitException('delete_gratitude', retryAfter);
    }

    // Get all stars including deleted ones for the repository operation (UNFILTERED!)
    final allStarsIncludingDeleted = await _repository.getAllGratitudesUnfiltered();

    final params = DeleteGratitudeParams(star: star, allStars: allStarsIncludingDeleted);
    await _deleteGratitudeUseCase(params);

    // Reload from repository to get properly filtered stars
    // (loadGratitudes already calls notifyListeners, so we don't need to call it again)
    await loadGratitudes();

    // Update galaxy star count (this also notifies its own listeners)
    await _galaxyProvider.updateActiveGalaxyStarCount(_gratitudeStars.length);

    notifyListeners();
    
    // CRITICAL: Sync immediately for data safety (deletion is important to sync)
    if (_authService.hasEmailAccount) {
      AppLogger.sync('💾 Star deleted - triggering immediate sync');
      _markPendingChanges();
      _performBackgroundSync().catchError((e) {
        AppLogger.sync('⚠️ Immediate sync failed: $e');
        _scheduleSync(); // Fallback to debounced
      });
    }
  }

  /// Toggle show all gratitudes mode
  void toggleShowAll() {
    // Cancel mindfulness if active
    if (_mindfulnessMode) {
      stopMindfulness();
    }

    _showAllGratitudes = !_showAllGratitudes;
    notifyListeners();
  }

  /// Toggle mindfulness mode
  void toggleMindfulness() {
    if (_mindfulnessMode) {
      stopMindfulness();
    } else {
      startMindfulness();
    }
  }

  /// Start mindfulness mode
  void startMindfulness() {
    // Require at least 2 stars for mindfulness mode
    if (_gratitudeStars.length < 2) return;

    // Cancel show all if active
    _showAllGratitudes = false;

    _mindfulnessMode = true;
    _selectRandomStar();
    _scheduleNextStar();
    notifyListeners();
  }

  /// Stop mindfulness mode
  void stopMindfulness() {
    _mindfulnessMode = false;
    _activeMindfulnessStar = null;
    _mindfulnessTimer?.cancel();
    _mindfulnessTimer = null;
    notifyListeners();
  }

  void _selectRandomStar() {
    // Safety check: no stars available
    if (_gratitudeStars.isEmpty) {
      _activeMindfulnessStar = null;
      stopMindfulness(); // Auto-stop if no stars left
      return;
    }

    // If only one star, use it
    if (_gratitudeStars.length == 1) {
      _activeMindfulnessStar = _gratitudeStars[0];
      notifyListeners();
      return;
    }

    // Filter out current star to avoid repetition
    final availableStars = _gratitudeStars
        .where((star) => star.id != _activeMindfulnessStar?.id)
        .toList();

    // Safety check: filtered list might be empty (shouldn't happen, but be safe)
    if (availableStars.isEmpty) {
      _activeMindfulnessStar = _gratitudeStars[0];
      notifyListeners();
      return;
    }

    // Select random star from available pool
    _activeMindfulnessStar = availableStars[_random.nextInt(availableStars.length)];

    AppLogger.info('🧘 Provider selected star: "${_activeMindfulnessStar?.text}"');
    notifyListeners();
  }

  void _scheduleNextStar() {
    _mindfulnessTimer?.cancel();
    final totalDelay = Duration(
      milliseconds: AnimationConstants.mindfulnessTransition.inMilliseconds + (_mindfulnessInterval * 1000),
    );

    _mindfulnessTimer = Timer(
      totalDelay,
          () {
        if (_mindfulnessMode) {
          _selectRandomStar();
          _scheduleNextStar();
        }
      },
    );
  }

  /// Update mindfulness interval
  void setMindfulnessInterval(int seconds) {
    _mindfulnessInterval = seconds;

    if (_mindfulnessMode) {
      _scheduleNextStar();
    }

    notifyListeners();
  }

  void cancelModes() {
    if (_mindfulnessMode) {
      stopMindfulness();
    }
    if (_showAllGratitudes) {
      _showAllGratitudes = false;
      notifyListeners();
    }
  }

  /// Get deleted gratitudes (for trash view)
  Future<List<GratitudeStar>> getDeletedGratitudes() async {
    final result = await _getDeletedGratitudesUseCase(NoParams());
    return result.stars;
  }

  /// Get count of deleted gratitudes in current galaxy
  Future<int> getDeletedGratitudesCount() async {
    final result = await _getDeletedGratitudesUseCase(NoParams());
    return result.count;
  }

  /// Restore a deleted gratitude
  Future<void> restoreGratitude(GratitudeStar star) async {
    // Get all stars including deleted ones for the repository operation (UNFILTERED!)
    final allStarsIncludingDeleted = await _repository.getAllGratitudesUnfiltered();

    await _restoreGratitudeUseCase(
      RestoreGratitudeParams(star: star, allStars: allStarsIncludingDeleted),
    );

    // Reload to reflect changes
    await loadGratitudes();

    // Update galaxy star count
    await _galaxyProvider.updateActiveGalaxyStarCount(_gratitudeStars.length);
    
    // CRITICAL: Sync immediately for data safety (restoration is important)
    if (_authService.hasEmailAccount) {
      AppLogger.sync('💾 Star restored - triggering immediate sync');
      _markPendingChanges();
      _performBackgroundSync().catchError((e) {
        AppLogger.sync('⚠️ Immediate sync failed: $e');
        _scheduleSync(); // Fallback to debounced
      });
    }
  }

  /// Permanently delete a gratitude
  Future<void> permanentlyDeleteGratitude(GratitudeStar star) async {
    // Get all stars including deleted ones
    final allStarsIncludingDeleted = await _repository.getAllGratitudesUnfiltered();

    final updatedStars = List<GratitudeStar>.from(allStarsIncludingDeleted);
    updatedStars.removeWhere((s) => s.id == star.id);
    await _repository.saveGratitudes(updatedStars);

    // Also sync permanent deletion if authenticated
    if (_authService.hasEmailAccount) {
      await _repository.deleteFromCloud(star.id);
    }

    notifyListeners();
  }

  /// Mark changes as pending without scheduling sync (for manual sync triggering)
  void _markPendingChanges() {
    _hasPendingChanges = true;
    _syncStatusService.markPending();
  }

  /// Schedule a debounced sync (batches multiple changes)
  void _scheduleSync() {
    // Cancel any existing timer
    _syncDebouncer?.cancel();

    // Schedule new sync in 30 seconds
    _syncDebouncer = Timer(Duration(seconds: 30), () {
      _performBackgroundSync();
    });

    AppLogger.sync('⏱️ Sync scheduled for 30 seconds from now');
  }

  /// Perform immediate sync with timeout (for star creation)
  /// 
  /// Uses short timeout to prevent animation freeze, doesn't retry
  Future<void> _performImmediateSyncWithTimeout() async {
    if (!_authService.hasEmailAccount) {
      AppLogger.auth('📵 Not signed in, skipping sync');
      return;
    }

    if (!_syncStatusService.canSync) {
      AppLogger.sync('📵 Cannot sync (offline or already syncing)');
      return;
    }

    AppLogger.sync('🔄 Starting immediate sync with timeout...');
    _syncStatusService.markSyncing();

    try {
      // Use short timeout (10 seconds) to prevent hanging
      await syncWithCloud().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          AppLogger.sync('⏱️ Immediate sync timeout - marking as pending');
          throw TimeoutException('Sync timed out after 10 seconds');
        },
      );

      // Sync succeeded
      _hasPendingChanges = false;
      _syncStatusService.markSynced();
      AppLogger.sync('✅ Immediate sync complete');
    } catch (e) {
      // Handle timeout or other errors
      if (e is TimeoutException) {
        AppLogger.sync('⏱️ Immediate sync timed out - will retry later');
        _syncStatusService.markPending();
        // Don't mark as error - just pending
      } else {
        final error = ErrorHandler.handle(
          e,
          null,
          context: ErrorContext.sync,
        );
        AppLogger.sync('❌ Immediate sync failed: ${error.technicalMessage}');
        _syncStatusService.markError(error.userMessage);
      }
      // Re-throw so caller can handle (schedule retry, etc.)
      rethrow;
    }
  }

  /// Perform the actual background sync (with retry logic)
  /// 
  /// Used for scheduled syncs, not immediate syncs
  Future<void> _performBackgroundSync() async {
    if (!_authService.hasEmailAccount) {
      AppLogger.auth('📵 Not signed in, skipping sync');
      return;
    }

    if (!_syncStatusService.canSync) {
      AppLogger.sync('📵 Cannot sync (offline or already syncing)');
      return;
    }

    AppLogger.sync('🔄 Starting background sync...');
    _syncStatusService.markSyncing();

    try {
      // Use ErrorHandler's retry logic with exponential backoff
      await ErrorHandler.withRetry(
        operation: () async {
          await syncWithCloud();
        },
        context: ErrorContext.sync,
        policy: RetryPolicy.sync, // 3 attempts, 2min/4min/8min backoff
        onRetry: (attempt, delay) {
          final minutes = delay.inMinutes;
          AppLogger.info('🔄 Retry attempt #$attempt scheduled in $minutes minutes...');
        },
      );

      // Sync succeeded
      _hasPendingChanges = false;
      _syncStatusService.markSynced();
      AppLogger.sync('✅ Background sync complete');
    } catch (e, stack) {
      // Handle error with ErrorHandler for consistent logging and reporting
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.sync,
      );

      AppLogger.sync('❌ Background sync failed after retries: ${error.technicalMessage}');
      _syncStatusService.markError(error.userMessage);

      // Note: ErrorHandler.withRetry() already handles:
      // - RateLimitException (no retry, thrown immediately)
      // - Exponential backoff (2min, 4min, 8min)
      // - Max 3 attempts
      // So we don't need manual retry logic here anymore
    }
  }

  /// Force immediate sync (called on app lifecycle events or manual retry)
  /// Clears any error state before attempting sync
  Future<void> forceSync() async {
    _syncDebouncer?.cancel(); // Cancel scheduled sync
    
    // Clear error state before attempting sync
    if (_syncStatusService.status == SyncStatus.error) {
      AppLogger.sync('🔄 Clearing error state before force sync');
      _syncStatusService.markPending(); // Clear error, mark as pending
    }
    
    await _performBackgroundSync();
  }

  /// Restore data from backup
  /// 
  /// After restoring stars, forces a full reload to ensure UI is refreshed
  /// and stars are properly displayed for the active galaxy.
  Future<void> restoreFromBackup(List<GratitudeStar> backupStars) async {
    // Save ALL backup stars to local storage (unfiltered)
    await StorageService.saveGratitudeStars(backupStars);

    AppLogger.data('💾 Saved ${backupStars.length} stars to local storage');

    // CRITICAL: Force a full reload of gratitudes to ensure UI is refreshed
    // This ensures stars are properly filtered for the active galaxy and displayed
    AppLogger.data('🔄 Forcing full reload of gratitudes after restore...');
    await loadGratitudes(waitForSync: false); // Don't wait for sync, just reload from storage

    // Update galaxy star count to match restored data
    final activeGalaxyStarCount = _gratitudeStars.length;
    await _galaxyProvider.updateActiveGalaxyStarCount(activeGalaxyStarCount);

    // If signed in, sync to cloud immediately
    if (_authService.hasEmailAccount) {
      AppLogger.sync('💾 Backup restored - triggering immediate sync');
      _markPendingChanges();
      _performBackgroundSync().catchError((e) {
        AppLogger.sync('⚠️ Sync after restore failed: $e');
        _scheduleSync(); // Fallback to debounced
      });
    }

    notifyListeners();
    AppLogger.success('✅ Restored ${backupStars.length} total stars from backup ($activeGalaxyStarCount in active galaxy)');
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _mindfulnessTimer?.cancel();
    _syncDebouncer?.cancel();
    super.dispose();
  }
}