import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../utils/app_logger.dart';

/// Manages all animation controllers for the gratitude visualization
///
/// Centralizes animation lifecycle management to reduce complexity in the main screen.
/// Handles background animation, star field animation, and star birth animation.
/// Respects user's reduced motion preferences for accessibility.
class AnimationManager {
  late AnimationController _backgroundController;
  late AnimationController _starController;
  AnimationController? _birthController;

  bool _isInitialized = false;
  bool _reduceMotion = false;

  /// Gets the background animation controller (for nebula pulse effects)
  AnimationController get background => _backgroundController;

  /// Gets the star field animation controller (for twinkling stars)
  AnimationController get star => _starController;

  /// Gets the birth animation controller (for new star creation)
  AnimationController? get birth => _birthController;

  /// Whether reduced motion is enabled
  bool get isReducedMotion => _reduceMotion;

  /// Initialize all animation controllers
  ///
  /// [vsync] must be provided by a TickerProviderStateMixin State
  /// [onBirthComplete] callback fired when birth animation completes
  /// [context] used to check reduced motion preferences
  void initialize(
      TickerProvider vsync,
      VoidCallback onBirthComplete,
      {required bool reduceMotion}
      ) {
    if (_isInitialized) {
      throw StateError('AnimationManager already initialized');
    }

    _reduceMotion = reduceMotion;

    // Background animation (nebula pulse) - decorative
    _backgroundController = AnimationController(
      duration: _reduceMotion
          ? Duration.zero
          : AnimationConstants.backgroundDuration,
      vsync: vsync,
    );

    // Only repeat if motion is allowed
    if (!_reduceMotion) {
      _backgroundController.repeat();
    }

    // Star field animation (twinkling) - decorative
    _starController = AnimationController(
      duration: _reduceMotion
          ? Duration.zero
          : AnimationConstants.starFieldDuration,
      vsync: vsync,
    );

    if (!_reduceMotion) {
      _starController.repeat();
    }

    // Birth animation - essential feedback, so we use a very short duration
    // instead of zero to maintain the feel of creation
    _birthController = AnimationController(
      duration: _reduceMotion
          ? const Duration(milliseconds: 150)  // Very fast but not instant
          : AnimationConstants.birthAnimationDuration,
      vsync: vsync,
    );

    _birthController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onBirthComplete();
      }
    });

    _isInitialized = true;
    AppLogger.start('🎭 AnimationManager initialized with ${_reduceMotion ? "REDUCED" : "FULL"} motion');
  }

  /// Start the birth animation with a specific duration
  ///
  /// [duration] calculated based on travel distance
  /// Automatically adjusted if reduced motion is enabled
  void startBirthAnimation(Duration duration) {
    if (!_isInitialized) {
      throw StateError('AnimationManager not initialized');
    }

    // Override duration if reduced motion is enabled
    final adjustedDuration = _reduceMotion
        ? const Duration(milliseconds: 150)
        : duration;

    _birthController!.duration = adjustedDuration;
    _birthController!.forward(from: 0.0);
  }

  /// Reset the birth animation controller
  void resetBirthAnimation() {
    _birthController?.reset();
  }

  /// Pause all animations (called when app goes to background)
  void pauseAll() {
    _backgroundController.stop();
    _starController.stop();
    _birthController?.stop();
  }

  /// Resume all animations (called when app returns to foreground)
  void resumeAll() {
    // Only resume if not in reduced motion mode
    if (!_reduceMotion) {
      _backgroundController.repeat();
      _starController.repeat();
    }
    // Birth controller resumes only if it was animating
  }

  /// Dispose all animation controllers
  void dispose() {
    if (!_isInitialized) return;

    _backgroundController.dispose();
    _starController.dispose();
    _birthController?.dispose();
    _isInitialized = false;
    AppLogger.info('🎭 AnimationManager disposed');
  }
}