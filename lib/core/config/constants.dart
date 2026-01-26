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

  // Mindfulness mode transition duration
  static const Duration mindfulnessTransition = Duration(milliseconds: 2000);

  // Mindfulness mode vertical position (40% from top to avoid slider overlap)
  static const double mindfulnessVerticalPosition = 0.40;

  // Jump to star animation duration
  static const Duration jumpToStarAnimation = Duration(milliseconds: 1500);

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
  static const double jumpToStarZoom = 2.5;
  static const double mindfulnessZoom = 2.0;
}

/// Timeout and delay duration constants
///
/// This class centralizes all timeout and delay durations used throughout
/// the application, making it easier to maintain consistency and adjust
/// timing values globally.
class Timeouts {
  Timeouts._(); // Private constructor to prevent instantiation

  // Network operation timeouts
  /// Firebase initialization timeout
  static const Duration firebaseInit = Duration(seconds: 10);
  
  /// Crashlytics initialization timeout
  static const Duration crashlyticsInit = Duration(seconds: 3);
  
  /// Texture loading timeout
  static const Duration textureLoad = Duration(seconds: 3);
  
  /// Standard Firestore operation timeout (for reads/writes)
  static const Duration firestoreOperation = Duration(seconds: 30);
  
  /// Quick Firestore operation timeout (for simple queries)
  static const Duration firestoreQuickOperation = Duration(seconds: 10);

  // UI operation timeouts
  /// Standard snackbar display duration
  static const Duration snackbar = Duration(seconds: 2);
  
  /// Long snackbar display duration
  static const Duration snackbarLong = Duration(seconds: 4);
  
  /// Standard debounce delay for input/resize operations
  static const Duration debounce = Duration(milliseconds: 500);
  
  /// Short debounce delay for quick operations
  static const Duration debounceShort = Duration(milliseconds: 100);

  // Animation and transition timeouts
  /// Standard animation duration
  static const Duration animation = Duration(milliseconds: 300);
  
  /// Fast animation duration (for quick transitions)
  static const Duration animationFast = Duration(milliseconds: 150);
  
  /// Slow animation duration (for prominent transitions)
  static const Duration animationSlow = Duration(milliseconds: 2000);
  
  /// Standard transition duration
  static const Duration transition = Duration(milliseconds: 400);

  // Auto-advance and auto-hide timeouts
  /// Splash screen auto-advance timeout
  static const Duration splashAutoAdvance = Duration(seconds: 10);
  
  /// Background animation duration
  static const Duration backgroundAnimation = Duration(seconds: 30);
  
  /// Standard delay before auto-hiding UI elements
  static const Duration autoHideDelay = Duration(seconds: 3);
  
  /// Short delay for UI feedback
  static const Duration feedbackDelay = Duration(seconds: 2);

  // Sync operation timeouts
  /// Standard sync debounce delay
  static const Duration syncDebounce = Duration(seconds: 30);
  
  /// Delay before showing sync status
  static const Duration syncStatusDelay = Duration(seconds: 2);

  /// Tutorial tooltip show delay
  static const Duration tutorialTooltipDelay = Duration(seconds: 3);
}

/// Bottom controls button sizing constants
class BottomControlsConstants {
  BottomControlsConstants._();

  /// Action button size (visibility, mindfulness)
  static const double actionButtonSize = 56.0;

  /// Add star button size
  static const double addStarButtonSize = 70.0;

  /// Spacing between buttons
  static const double buttonSpacing = 16.0;

  /// Connector line height between slider and button
  static const double connectorHeight = 12.0;

  /// Star icon size inside add star button
  static const double starIconSize = 56.0;

  /// Icon size inside action buttons
  static const double actionIconSize = 24.0;

  /// Pulse animation duration in milliseconds
  static const int pulseAnimationDuration = 1000;
}

/// Tutorial tooltip sizing constants
class TooltipConstants {
  TooltipConstants._();

  /// Maximum width of tooltip container
  static const double maxWidth = 280.0;

  /// Minimum height for WCAG touch target compliance
  static const double minHeight = 48.0;

  /// Horizontal padding inside tooltip
  static const double paddingHorizontal = 20.0;

  /// Vertical padding inside tooltip
  static const double paddingVertical = 14.0;

  /// Offset from bottom of screen to tooltip
  static const double bottomOffset = 140.0;

  /// Arrow width
  static const double arrowWidth = 20.0;

  /// Arrow height
  static const double arrowHeight = 10.0;
}