import 'dart:async';

import 'package:flutter/material.dart';

import '../storage.dart';
import '../core/utils/app_logger.dart';

/// Service for managing onboarding tutorial state
///
/// Handles showing guided prompts for star creation and mindfulness mode discovery.
/// Uses ChangeNotifier pattern consistent with DailyReminderService.
class TutorialService extends ChangeNotifier {
  // State
  bool _showingStarButtonPulse = false;
  bool _showingStarButtonTooltip = false;
  bool _showingMindfulnessTooltip = false;
  bool _isInitialized = false;
  bool _starButtonTutorialSeen = false;
  bool _mindfulnessTutorialSeen = false;

  // Timer for delayed tooltip
  Timer? _tooltipTimer;

  // Public getters
  bool get showingStarButtonPulse => _showingStarButtonPulse;
  bool get showingStarButtonTooltip => _showingStarButtonTooltip;
  bool get showingMindfulnessTooltip => _showingMindfulnessTooltip;
  bool get isInitialized => _isInitialized;

  /// Initialize the service - loads persisted state
  Future<void> initialize() async {
    try {
      AppLogger.info('📚 Initializing TutorialService...');

      _starButtonTutorialSeen = await StorageService.hasTutorialStarButtonSeen();
      _mindfulnessTutorialSeen = await StorageService.hasTutorialMindfulnessSeen();

      _isInitialized = true;
      AppLogger.success(
        '✅ TutorialService initialized (starSeen: $_starButtonTutorialSeen, mindfulnessSeen: $_mindfulnessTutorialSeen)',
      );
      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Error initializing TutorialService: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Check if we should show the star button tutorial on starfield entry
  ///
  /// Call this when user reaches the main starfield with 0 stars.
  /// Starts the pulse animation immediately and shows tooltip after 3 seconds.
  ///
  /// [reduceMotion] - If true (accessibility setting), skip pulse and show tooltip immediately.
  void checkAndShowStarButtonTutorial({bool reduceMotion = false}) {
    if (_starButtonTutorialSeen) {
      AppLogger.info('📚 Star button tutorial already seen, skipping');
      return;
    }

    AppLogger.info('📚 Showing star button tutorial');

    if (reduceMotion) {
      // For reduced motion, skip pulse and show tooltip immediately
      _showingStarButtonPulse = false;
      _showingStarButtonTooltip = true;
      notifyListeners();
    } else {
      // Start pulse animation
      _showingStarButtonPulse = true;
      _showingStarButtonTooltip = false;
      notifyListeners();

      // Show tooltip after 3 seconds if user hasn't tapped
      _tooltipTimer?.cancel();
      _tooltipTimer = Timer(const Duration(seconds: 3), () {
        if (_showingStarButtonPulse && !_starButtonTutorialSeen) {
          _showingStarButtonTooltip = true;
          notifyListeners();
        }
      });
    }
  }

  /// Dismiss the star button tutorial and mark as seen
  ///
  /// Call this when user taps the star button or dismisses the tooltip.
  Future<void> dismissStarButtonTutorial() async {
    if (!_showingStarButtonPulse && !_showingStarButtonTooltip) {
      return;
    }

    AppLogger.info('📚 Dismissing star button tutorial');

    _tooltipTimer?.cancel();
    _showingStarButtonPulse = false;
    _showingStarButtonTooltip = false;
    _starButtonTutorialSeen = true;
    notifyListeners();

    await StorageService.markTutorialStarButtonSeen();
  }

  /// Check if we should show the mindfulness tutorial after star creation
  ///
  /// Call this after a star birth animation completes.
  /// Shows the mindfulness tooltip when user has created their 3rd star.
  void checkMindfulnessTutorial(int starCount) {
    if (_mindfulnessTutorialSeen) {
      return;
    }

    // Show mindfulness tutorial after creating 3 stars
    if (starCount >= 3) {
      AppLogger.info('📚 Showing mindfulness tutorial (star count: $starCount)');
      _showingMindfulnessTooltip = true;
      notifyListeners();
    }
  }

  /// Dismiss the mindfulness tutorial and mark as seen
  ///
  /// Call this when user taps the mindfulness button or dismisses the tooltip.
  Future<void> dismissMindfulnessTutorial() async {
    if (!_showingMindfulnessTooltip) {
      return;
    }

    AppLogger.info('📚 Dismissing mindfulness tutorial');

    _showingMindfulnessTooltip = false;
    _mindfulnessTutorialSeen = true;
    notifyListeners();

    await StorageService.markTutorialMindfulnessSeen();
  }

  /// Reset tutorial state (for testing or when user clears data)
  Future<void> reset() async {
    AppLogger.info('📚 Resetting tutorial state');

    _tooltipTimer?.cancel();
    _showingStarButtonPulse = false;
    _showingStarButtonTooltip = false;
    _showingMindfulnessTooltip = false;
    _starButtonTutorialSeen = false;
    _mindfulnessTutorialSeen = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }
}
