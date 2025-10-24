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

/// Provider for gratitude state management
///
/// Manages all gratitude-related state and coordinates with use cases.
/// Notifies listeners only when relevant data changes.
class GratitudeProvider extends ChangeNotifier {
  // Dependencies
  final GratitudeRepository _repository;
  final AuthService _authService;
  final math.Random _random;

  // Use cases
  late final AddGratitudeUseCase _addGratitudeUseCase;
  late final DeleteGratitudeUseCase _deleteGratitudeUseCase;
  late final UpdateGratitudeUseCase _updateGratitudeUseCase;
  late final LoadGratitudesUseCase _loadGratitudesUseCase;
  late final SyncGratitudesUseCase _syncGratitudesUseCase;

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
  }

  void _setupAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null && _authService.hasEmailAccount) {
        print('👤 Auth state changed, reloading gratitudes...');
        loadGratitudes();
      }
    });
  }

  /// Load gratitudes from storage
  Future<void> loadGratitudes() async {
    final result = await _loadGratitudesUseCase(NoParams());

    _gratitudeStars = result.stars;
    _isLoading = false;
    notifyListeners();

    // Sync with cloud if needed
    if (result.shouldSyncWithCloud) {
      await syncWithCloud();
    }
  }

  /// Sync with cloud
  Future<void> syncWithCloud() async {
    try {
      final result = await _syncGratitudesUseCase(
        SyncGratitudesParams(localStars: _gratitudeStars),
      );

      _gratitudeStars = result.mergedStars;
      notifyListeners();
    } catch (e) {
      print('⚠️ Sync failed: $e');
    }
  }

  /// Create a new gratitude star
  Future<GratitudeStar> createGratitude(String text, Size screenSize) async {
    final star = await _addGratitudeUseCase(
      AddGratitudeParams(
        text: text,
        screenSize: screenSize,
        existingStars: _gratitudeStars,
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
      await _repository.addGratitude(_animatingStar!, _gratitudeStars);

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
    final updatedStars = await _deleteGratitudeUseCase(
      DeleteGratitudeParams(
        star: star,
        allStars: _gratitudeStars,
      ),
    );

    _gratitudeStars = updatedStars;
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
    if (_gratitudeStars.isNotEmpty) {
      _activeMindfulnessStar = _gratitudeStars[_random.nextInt(_gratitudeStars.length)];
      notifyListeners();
    }
  }

  void _scheduleNextStar() {
    _mindfulnessTimer?.cancel();
    _mindfulnessTimer = Timer(
      Duration(seconds: _mindfulnessInterval),
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

  // ADD THIS METHOD HERE ↓
  void test() {
    print('✅ Provider is accessible!');
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _mindfulnessTimer?.cancel();
    super.dispose();
  }
}