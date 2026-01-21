import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/app_config.dart';
import '../core/services/firebase_initializer.dart';
import '../core/utils/app_logger.dart';

/// Result of user profile migration
class MigrationResult {
  /// Whether migration triggered UI flows (e.g., missing critical fields)
  final bool shouldTriggerUI;

  /// Whether age gate should be shown
  final bool shouldShowAgeGate;

  /// Whether consent screen should be shown
  final bool shouldShowConsent;

  /// Fields that were added during migration
  final List<String> fieldsAdded;

  /// Migration version applied
  final String? migrationVersion;

  /// Profile data from Firebase (cached to avoid redundant reads)
  final Map<String, dynamic>? profileData;

  MigrationResult({
    required this.shouldTriggerUI,
    this.shouldShowAgeGate = false,
    this.shouldShowConsent = false,
    this.fieldsAdded = const [],
    this.migrationVersion,
    this.profileData,
  });
}

/// Service for migrating user profiles and adding missing fields
///
/// Handles versioned migrations to add missing fields to user profiles
/// in Firebase. Can trigger UI flows if critical fields are missing.
class UserProfileMigrationService {
  FirebaseFirestore? _firestoreInstance;

  /// Get FirebaseFirestore instance, ensuring Firebase is initialized first
  FirebaseFirestore get _firestore {
    if (_firestoreInstance == null) {
      if (!FirebaseInitializer.instance.isInitialized) {
        throw StateError(
          'Firebase not initialized. Cannot access migration services. '
          'The app may be running in offline mode.'
        );
      }
      _firestoreInstance = FirebaseFirestore.instance;
    }
    return _firestoreInstance!;
  }

  /// Current migration version - increment when adding new fields
  static const String currentMigrationVersion = '1.0';

  /// Fields that trigger UI flows if missing
  static const String fieldAgeGatePassed = 'ageGatePassed';
  static const String fieldPrivacyPolicyAccepted = 'privacyPolicyAccepted';
  static const String fieldPrivacyPolicyVersion = 'privacyPolicyVersion';
  static const String fieldOnboardingCompleted = 'onboardingCompleted';

  UserProfileMigrationService();

  /// Migrate user profile - add missing fields with defaults
  /// 
  /// Returns MigrationResult indicating if UI flows should be triggered
  /// 
  /// [userId] - Firebase user ID
  /// [profileData] - Current profile data from Firebase (can be null if profile doesn't exist)
  /// 
  /// Returns null if migration cannot be performed (e.g., no user ID)
  Future<MigrationResult?> migrateUserProfile({
    required String? userId,
    Map<String, dynamic>? profileData,
  }) async {
    if (userId == null) {
      AppLogger.data('⚠️ Cannot migrate profile: no user ID');
      return null;
    }

    try {
      AppLogger.data('🔄 Starting user profile migration for user: $userId');
      
      final fieldsAdded = <String>[];
      bool shouldShowAgeGate = false;
      bool shouldShowConsent = false;
      
      // Get current profile data or initialize empty map
      final currentData = profileData ?? <String, dynamic>{};
      final updatedData = Map<String, dynamic>.from(currentData);
      
      // Check and add ageGatePassed
      if (!updatedData.containsKey(fieldAgeGatePassed)) {
        updatedData[fieldAgeGatePassed] = false;
        fieldsAdded.add(fieldAgeGatePassed);
        shouldShowAgeGate = true;
        AppLogger.data('   ➕ Added missing field: $fieldAgeGatePassed = false');
      } else {
        // Check if it's false - might need to show age gate
        final ageGatePassed = updatedData[fieldAgeGatePassed] as bool? ?? false;
        if (!ageGatePassed) {
          shouldShowAgeGate = true;
        }
      }
      
      // Check and add privacyPolicyAccepted
      if (!updatedData.containsKey(fieldPrivacyPolicyAccepted)) {
        updatedData[fieldPrivacyPolicyAccepted] = false;
        fieldsAdded.add(fieldPrivacyPolicyAccepted);
        shouldShowConsent = true;
        AppLogger.data('   ➕ Added missing field: $fieldPrivacyPolicyAccepted = false');
      } else {
        // Check if it's false - might need to show consent
        final privacyAccepted = updatedData[fieldPrivacyPolicyAccepted] as bool? ?? false;
        if (!privacyAccepted) {
          shouldShowConsent = true;
        }
      }
      
      // Check and add privacyPolicyVersion
      if (!updatedData.containsKey(fieldPrivacyPolicyVersion)) {
        updatedData[fieldPrivacyPolicyVersion] = AppConfig.consentVersion;
        fieldsAdded.add(fieldPrivacyPolicyVersion);
        AppLogger.data('   ➕ Added missing field: $fieldPrivacyPolicyVersion = ${AppConfig.consentVersion}');
      }
      
      // Check and add onboardingCompleted
      if (!updatedData.containsKey(fieldOnboardingCompleted)) {
        updatedData[fieldOnboardingCompleted] = false;
        fieldsAdded.add(fieldOnboardingCompleted);
        AppLogger.data('   ➕ Added missing field: $fieldOnboardingCompleted = false');
      }
      
      // Add migration version
      updatedData['migrationVersion'] = currentMigrationVersion;
      
      // Save updated profile to Firebase if any fields were added
      if (fieldsAdded.isNotEmpty) {
        await _firestore.collection('users').doc(userId).set(
          updatedData,
          SetOptions(merge: true),
        );
        AppLogger.success('✅ Migrated user profile: added ${fieldsAdded.length} field(s)');
      } else {
        AppLogger.data('✅ User profile already up to date');
      }
      
      final shouldTriggerUI = shouldShowAgeGate || shouldShowConsent;
      
      return MigrationResult(
        shouldTriggerUI: shouldTriggerUI,
        shouldShowAgeGate: shouldShowAgeGate,
        shouldShowConsent: shouldShowConsent,
        fieldsAdded: fieldsAdded,
        migrationVersion: currentMigrationVersion,
        profileData: updatedData, // Return profile data to avoid redundant reads
      );
    } catch (e) {
      AppLogger.error('❌ Error migrating user profile: $e');
      // Return result indicating UI should be shown if migration fails
      // (safer to show onboarding than skip it)
      return MigrationResult(
        shouldTriggerUI: true,
        shouldShowAgeGate: true,
        shouldShowConsent: true,
        fieldsAdded: [],
      );
    }
  }

  /// Load user profile from Firebase and migrate if needed
  /// 
  /// Convenience method that loads profile, migrates, and returns result
  /// Returns profile data in MigrationResult to avoid redundant reads
  Future<MigrationResult?> loadAndMigrateProfile(String? userId) async {
    if (userId == null) {
      return null;
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final profileData = doc.data();
      
      final result = await migrateUserProfile(
        userId: userId,
        profileData: profileData,
      );
      
      // Ensure profileData is included in result (migrateUserProfile already includes it)
      return result;
    } catch (e) {
      AppLogger.error('❌ Error loading user profile for migration: $e');
      // Return result indicating UI should be shown on error
      return MigrationResult(
        shouldTriggerUI: true,
        shouldShowAgeGate: true,
        shouldShowConsent: true,
        fieldsAdded: [],
        profileData: null,
      );
    }
  }
}


