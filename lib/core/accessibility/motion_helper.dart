import 'package:flutter/material.dart';

/// Helper for respecting user's reduced motion preferences
///
/// Checks system accessibility settings and provides motion-safe alternatives
class MotionHelper {
  /// Check if user has enabled reduced motion in system settings
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// Get animation duration respecting user's motion preferences
  ///
  /// Returns Duration.zero if reduced motion is enabled,
  /// otherwise returns the provided normal duration
  static Duration getDuration(BuildContext context, Duration normal) {
    return shouldReduceMotion(context) ? Duration.zero : normal;
  }

  /// Get animation curve respecting motion preferences
  ///
  /// Returns linear curve if reduced motion enabled,
  /// otherwise returns the provided curve
  static Curve getCurve(BuildContext context, Curve normal) {
    return shouldReduceMotion(context) ? Curves.linear : normal;
  }

  /// Get a very brief duration for essential feedback animations
  ///
  /// Even with reduced motion, some animations are necessary for feedback.
  /// This returns a very short duration (100ms) instead of zero.
  /// Use for: button presses, dialog open/close, essential state changes
  static Duration getEssentialDuration(BuildContext context) {
    return shouldReduceMotion(context)
        ? const Duration(milliseconds: 100)
        : const Duration(milliseconds: 300);
  }

  /// Check if decorative animations should play
  ///
  /// Decorative animations (background effects, twinkling, etc.)
  /// should be completely disabled with reduced motion
  static bool shouldPlayDecorativeAnimations(BuildContext context) {
    return !shouldReduceMotion(context);
  }

  /// Debug helper to verify touch targets meet accessibility guidelines
  /// Call during development to log touch target sizes
  static void debugTouchTarget(BuildContext context, String elementName, double size) {
    final minSize = 48.0;
    final status = size >= minSize ? "✅ PASS" : "❌ FAIL";
    print("Touch Target: $elementName = ${size.toStringAsFixed(1)}dp $status (min: ${minSize}dp)");
  }
}