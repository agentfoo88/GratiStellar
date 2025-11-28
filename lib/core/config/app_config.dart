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
  ///
  /// ⚠️ IMPORTANT: Update this with your actual privacy policy URL before production!
  /// This placeholder URL should be replaced with your hosted privacy policy.
  static const String privacyPolicyUrl =
      'https://gratistellar.github.io/legal/PRIVACY_POLICY';

  /// Terms of Service URL
  ///
  /// ⚠️ IMPORTANT: Update this with your actual terms of service URL before production!
  /// This placeholder URL should be replaced with your hosted terms of service.
  static const String termsOfServiceUrl =
      'https://gratistellar.github.io/legal/TERMS_OF_SERVICE';

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
}
