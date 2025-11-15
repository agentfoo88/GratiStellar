import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../storage.dart';
import '../../../../services/auth_service.dart';
import '../../data/repositories/gratitude_repository.dart';
import '../../domain/usecases/use_case.dart';
import '../../domain/usecases/add_gratitude_use_case.dart';
import '../../domain/usecases/delete_gratitude_use_case.dart';
import '../../domain/usecases/update_gratitude_use_case.dart';
import '../../domain/usecases/load_gratitudes_use_case.dart';
import '../../domain/usecases/sync_gratitudes_use_case.dart';
import '../../domain/usecases/get_deleted_gratitudes_use_case.dart';
import '../../domain/usecases/restore_gratitude_use_case.dart';
import '../../domain/usecases/purge_old_deleted_use_case.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/security/rate_limiter.dart';
import 'galaxy_provider.dart';

/// Provider for gratitude state management
///
/// Manages all gratitude-related state and coordinates with use cases.
/// Notifies listeners only when relevant data changes.
class GratitudeProvider extends ChangeNotifier {
  // Dependencies
  final GratitudeRepository _repository;
  final AuthService _authService;
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

  // Getters
  List<GratitudeStar> get gratitudeStars => _gratitudeStars;
  bool get isLoading => _isLoading;
  bool get showAllGratitudes => _showAllGratitudes;
  bool get mindfulnessMode => _mindfulnessMode;
  bool get isAnimating => _isAnimating;
  GratitudeStar? get animatingStar => _animatingStar;
  GratitudeStar? get activeMindfulnessStar => _activeMindfulnessStar;
  int get mindfulnessInterval => _mindfulnessInterval;

  GratitudeProvider({
    required GratitudeRepository repository,
    required AuthService authService,
    required math.Random random,
  })  : _repository = repository,
        _authService = authService,
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
    try {
      final result = await _syncGratitudesUseCase(
        SyncGratitudesParams(localStars: _gratitudeStars),
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

      _gratitudeStars = dedupedStars.where((star) => !star.deleted).toList();
      notifyListeners();
    } catch (e) {
      print('⚠️ Sync failed: $e');
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
  }

  /// Permanently delete a gratitude
  Future<void> permanentlyDeleteGratitude(GratitudeStar star) async {
    // Get all stars including deleted ones
    final allStarsIncludingDeleted = await _repository.getGratitudes();

    final updatedStars = List<GratitudeStar>.from(allStarsIncludingDeleted);
    updatedStars.removeWhere((s) => s.id == star.id);
    await _repository.saveGratitudes(updatedStars);

    // Also sync permanent deletion if authenticated
    if (_authService.hasEmailAccount) {
      await _repository.permanentlyDeleteGratitude(star.id, updatedStars);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _mindfulnessTimer?.cancel();
    super.dispose();
  }
}