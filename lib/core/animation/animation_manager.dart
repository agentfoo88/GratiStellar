import 'package:flutter/material.dart';
import '../config/constants.dart';

/// Manages all animation controllers for the gratitude visualization
///
/// Centralizes animation lifecycle management to reduce complexity in the main screen.
/// Handles background animation, star field animation, and star birth animation.
class AnimationManager {
  late AnimationController _backgroundController;
  late AnimationController _starController;
  AnimationController? _birthController;

  bool _isInitialized = false;

  /// Gets the background animation controller (for nebula pulse effects)
  AnimationController get background => _backgroundController;

  /// Gets the star field animation controller (for twinkling stars)
  AnimationController get star => _starController;

  /// Gets the birth animation controller (for new star creation)
  AnimationController? get birth => _birthController;

  /// Initialize all animation controllers
  ///
  /// [vsync] must be provided by a TickerProviderStateMixin State
  /// [onBirthComplete] callback fired when birth animation completes
  void initialize(TickerProvider vsync, VoidCallback onBirthComplete) {
    if (_isInitialized) {
      throw StateError('AnimationManager already initialized');
    }

    _backgroundController = AnimationController(
      duration: AnimationConstants.backgroundDuration,
      vsync: vsync,
    )..repeat();

    _starController = AnimationController(
      duration: AnimationConstants.starFieldDuration,
      vsync: vsync,
    )..repeat();

    _birthController = AnimationController(
      duration: AnimationConstants.birthAnimationDuration,
      vsync: vsync,
    );

    _birthController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onBirthComplete();
      }
    });

    _isInitialized = true;
    print('🎭 AnimationManager initialized with 3 controllers');
  }

  /// Start the birth animation with a specific duration
  ///
  /// [duration] calculated based on travel distance
  void startBirthAnimation(Duration duration) {
    if (!_isInitialized) {
      throw StateError('AnimationManager not initialized');
    }
    _birthController!.duration = duration;
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
    _backgroundController.repeat();
    _starController.repeat();
    // Birth controller resumes only if it was animating
  }

  /// Dispose all animation controllers
  void dispose() {
    if (!_isInitialized) return;

    _backgroundController.dispose();
    _starController.dispose();
    _birthController?.dispose();
    _isInitialized = false;
    print('🎭 AnimationManager disposed');
  }
}
