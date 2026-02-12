/// Application-wide configuration constants
///
/// This class contains URLs, version numbers, and other configuration
/// values used throughout the GratiStellar app.
class AppConfig {
  AppConfig._(); // Private constructor - this is a static-only class

  // ============================================================================
  // PRIVACY & LEGAL URLs
  // ============================================================================

  /// Privacy Policy URL
  static const String privacyPolicyUrl =
      'https://gratistellar.com/privacy_policy.html';

  /// Terms of Service URL
  static const String termsOfServiceUrl =
      'https://gratistellar.com/terms_of_service.html';

  /// Ko-fi support page (optional support / sustainment)
  static const String supportGratiStellarUrl = 'https://ko-fi.com/gratistellar';

  // ============================================================================
  // CONSENT TRACKING
  // ============================================================================

  /// Current version of the privacy policy and terms of service
  ///
  /// This version number is saved with user consent records in Firestore.
  /// Increment this version when privacy policy or terms are updated,
  /// which allows tracking which version users consented to.
  static const String consentVersion = '1.0';

  // ============================================================================
  // ONBOARDING CONFIGURATION
  // ============================================================================

  /// Duration to display the splash screen before auto-advancing
  static const Duration splashDuration = Duration(milliseconds: 1500);

  /// Minimum age requirement for using the app (COPPA compliance)
  ///
  /// Users under this age will be shown an exit dialog and cannot proceed.
  static const int minimumAge = 13;

  // ============================================================================
  // REVIEW PROMPT
  // ============================================================================

  /// Minimum app launches before we may ask for a store review
  static const int reviewMinLaunchCount = 8;

  /// Minimum days since first launch before we may ask for a store review
  static const int reviewMinDaysSinceFirstLaunch = 7;

  /// Minimum days since last review request (or dismiss) before asking again
  static const int reviewCooldownDays = 90;
}
