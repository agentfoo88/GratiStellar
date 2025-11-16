import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/constants.dart';
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

  // Sync coordination
  bool _isSyncing = false;
  DateTime? _lastSuccessfulSync;
  int _retryAttempts = 0;

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
      if (user == null) {
        // User signed out - clear all state
        print('👤 User signed out, clearing state...');
        clearState();
      } else {
        // User signed in - reload their data
        print('👤 Auth state changed, reloading gratitudes...');
        loadGratitudes();
      }
    });
  }

  /// Set galaxy provider (called after construction)
  void setGalaxyProvider(GalaxyProvider galaxyProvider) {
    _galaxyProvider = galaxyProvider;
  }

  /// Clear all state (called on sign out)
  void clearState() {
    print('🗑️ Clearing provider state');
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
  Future<void> loadGratitudes() async {
    final result = await _loadGratitudesUseCase(NoParams());

    // Deduplicate by ID (in case of storage corruption or sync issues)
    final seenIds = <String>{};
    final dedupedStars = <GratitudeStar>[];

    for (final star in result.stars) {
      if (!seenIds.contains(star.id)) {
        seenIds.add(star.id);
        dedupedStars.add(star);
      } else {
        print('⚠️ Duplicate star detected and removed: ${star.id}');
      }
    }

    // Purge old deleted items (30+ days)
    final purgedStars = await _purgeOldDeletedUseCase(PurgeOldDeletedParams(dedupedStars));

    // Filter out deleted items for display
    _gratitudeStars = purgedStars.where((star) => !star.deleted).toList();
    _isLoading = false;
    notifyListeners();

    // Sync with cloud if needed
    if (result.shouldSyncWithCloud) {
      // Don't block on sync - run in background
      syncWithCloud().catchError((e) {
        print('⚠️ Background sync failed: $e');
      });
    }
  }

  /// Sync with cloud
  Future<void> syncWithCloud() async {
    // Check if already syncing (mutex)
    if (_isSyncing) {
      print('⏸️ Sync already in progress, skipping...');
      return;
    }

    // Smart sync: Skip if recently synced and no pending changes
    if (_lastSuccessfulSync != null && !_hasPendingChanges) {
      final timeSinceLastSync = DateTime.now().difference(_lastSuccessfulSync!);
      if (timeSinceLastSync < Duration(minutes: 5)) {
        print('⏭️ Skipping sync - recently synced ${timeSinceLastSync.inMinutes}m ago with no pending changes');
        return;
      }
    }

    _isSyncing = true;
    try {
      // Get ALL stars (unfiltered) for sync to prevent data loss across galaxies
      final allStarsUnfiltered = await _repository.getAllGratitudesUnfiltered();
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
      _retryAttempts = 0;

      notifyListeners();
    } catch (e) {
      print('⚠️ Sync failed: $e');
      rethrow; // Let caller handle the error
    } finally {
      _isSyncing = false;
    }
  }

  /// Create a new gratitude star
  Future<GratitudeStar> createGratitude(
      String text,
      Size screenSize, {
        int? colorPresetIndex,
        Color? customColor,
      }) async {
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
      // Schedule background sync
      _markPendingAndScheduleSync();

      // Update galaxy star count
      await _galaxyProvider.updateActiveGalaxyStarCount(_gratitudeStars.length);

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
    // Schedule background sync
    _markPendingAndScheduleSync();
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
    // Schedule background sync
    _markPendingAndScheduleSync();
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
    if (_gratitudeStars.isEmpty) return;

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

    print('🧘 Provider selected star: "${_activeMindfulnessStar?.text}"');
    notifyListeners();
  }

  void _scheduleNextStar() {
    _mindfulnessTimer?.cancel();
    final totalDelay = Duration(
      milliseconds: AnimationConstants.mindfulnessTransitionMs + (_mindfulnessInterval * 1000),
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
    // Schedule background sync
    _markPendingAndScheduleSync();
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

  /// Mark changes as pending and schedule background sync
  void _markPendingAndScheduleSync() {
    _hasPendingChanges = true;
    _syncStatusService.markPending();
    _scheduleSync();
  }

  /// Schedule a debounced sync (batches multiple changes)
  void _scheduleSync() {
    // Cancel any existing timer
    _syncDebouncer?.cancel();

    // Schedule new sync in 30 seconds
    _syncDebouncer = Timer(Duration(seconds: 30), () {
      _performBackgroundSync();
    });

    print('⏱️ Sync scheduled for 30 seconds from now');
  }

  /// Perform the actual background sync
  Future<void> _performBackgroundSync() async {
    if (!_authService.hasEmailAccount) {
      print('📵 Not signed in, skipping sync');
      return;
    }

    if (!_syncStatusService.canSync) {
      print('📵 Cannot sync (offline or already syncing)');
      return;
    }

    print('🔄 Starting background sync...');
    _syncStatusService.markSyncing();

    try {
      await syncWithCloud();

      _hasPendingChanges = false;
      _syncStatusService.markSynced();
      print('✅ Background sync complete');
    } catch (e) {
      print('❌ Background sync failed: $e');
      _syncStatusService.markError(e.toString());

      // Handle rate limit errors - DON'T retry automatically
      if (e is RateLimitException) {
        print('! Rate limit exceeded - waiting for reset, no automatic retry');
        // User can manually retry later or wait for next change to trigger sync
        return;
      }

      // For other errors (network, etc.), retry with exponential backoff
      _retryAttempts++;
      const maxRetries = 3;

      if (_retryAttempts > maxRetries) {
        print('❌ Max retry attempts reached ($maxRetries), giving up');
        _retryAttempts = 0; // Reset for next sync trigger
        return;
      }

      // Exponential backoff: 2min, 4min, 8min
      final backoffMinutes = 2 * math.pow(2, _retryAttempts - 1).toInt();
      print('🔄 Scheduling retry #$_retryAttempts in $backoffMinutes minutes...');

      _syncDebouncer = Timer(Duration(minutes: backoffMinutes), () {
        _performBackgroundSync();
      });
    }
  }

  /// Force immediate sync (called on app lifecycle events)
  Future<void> forceSync() async {
    _syncDebouncer?.cancel(); // Cancel scheduled sync
    await _performBackgroundSync();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _mindfulnessTimer?.cancel();
    _syncDebouncer?.cancel();
    super.dispose();
  }
}