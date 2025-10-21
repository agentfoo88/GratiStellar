// lib/core/config/constants.dart

/// UI scale configuration for consistent sizing across the app
class UIConstants {
  UIConstants._(); // Private constructor to prevent instantiation

  // Universal UI scaling factor
  static const double universalUIScale = 1.0;

  // Label styling
  static const double labelBackgroundAlpha = 0.85;
  static const double statsLabelTextScale = 1.15;
}

/// Animation timing configuration
class AnimationConstants {
  AnimationConstants._();

  // Mindfulness mode transition duration in milliseconds
  static const int mindfulnessTransitionMs = 2000;

  // Background animation duration
  static const Duration backgroundDuration = Duration(seconds: 30);

  // Star field animation duration
  static const Duration starFieldDuration = Duration(seconds: 8);

  // Birth animation duration
  static const Duration birthAnimationDuration = Duration(milliseconds: 1500);
}

/// Camera control constraints
class CameraConstants {
  CameraConstants._();

  static const double minScale = 0.4;
  static const double maxScale = 5.0;
  static const double focusZoomLevel = 2.0;
}