import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/app_logger.dart';
import '../screens/gratitude_screen.dart';
import '../screens/onboarding/age_gate_screen.dart';
import '../screens/onboarding/consent_screen.dart';
import 'auth_service.dart';
import 'user_profile_migration_service.dart';
import 'user_profile_manager.dart';

/// Service to manage onboarding state and flow
///
/// Uses SharedPreferences to persist onboarding completion status per user.
/// Provides methods to check and update onboarding state for specific users.
class OnboardingService {
  final UserProfileManager? _userProfileManager;

  // SharedPreferences keys (user-scoped)
  static const String _ageGateKeyPrefix = 'age_gate_passed_';
  static const String _onboardingKeyPrefix = 'onboarding_completed_';
  
  // Legacy global keys (for migration)
  static const String _legacyAgeGateKey = 'age_gate_passed';
  static const String _legacyOnboardingKey = 'onboarding_completed';

  OnboardingService({UserProfileManager? userProfileManager})
      : _userProfileManager = userProfileManager;

  /// Get user-scoped key for age gate
  String _getAgeGateKey(String userId) => '$_ageGateKeyPrefix$userId';

  /// Get user-scoped key for onboarding
  String _getOnboardingKey(String userId) => '$_onboardingKeyPrefix$userId';

  /// Check if the user has completed the full onboarding flow
  Future<bool> isOnboardingComplete([String? userId]) async {
    try {
      // Get userId if not provided
      String? finalUserId = userId;
      if (finalUserId == null && _userProfileManager != null) {
        finalUserId = await _userProfileManager.getOrCreateActiveUserId();
      }
      
      if (finalUserId == null) {
        AppLogger.warning('⚠️ No userId provided for onboarding check');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final isComplete = prefs.getBool(_getOnboardingKey(finalUserId)) ?? false;
      AppLogger.data('📋 Onboarding complete for $finalUserId: $isComplete');
      return isComplete;
    } catch (e) {
      AppLogger.error('❌ Error checking onboarding status: $e');
      return false; // Safe default: show onboarding if check fails
    }
  }

  /// Check if the user has passed the age gate (13+ verification)
  Future<bool> hasPassedAgeGate([String? userId]) async {
    try {
      // Get userId if not provided
      String? finalUserId = userId;
      if (finalUserId == null && _userProfileManager != null) {
        finalUserId = await _userProfileManager.getOrCreateActiveUserId();
      }
      
      if (finalUserId == null) {
        AppLogger.warning('⚠️ No userId provided for age gate check');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final hasPassed = prefs.getBool(_getAgeGateKey(finalUserId)) ?? false;
      AppLogger.data('🎂 Age gate passed for $finalUserId: $hasPassed');
      return hasPassed;
    } catch (e) {
      AppLogger.error('❌ Error checking age gate status: $e');
      return false; // Safe default: show age gate if check fails
    }
  }

  /// Mark that the user has passed the age gate
  Future<void> markAgeGatePassed([String? userId]) async {
    try {
      // Get userId if not provided
      String? finalUserId = userId;
      if (finalUserId == null && _userProfileManager != null) {
        finalUserId = await _userProfileManager.getOrCreateActiveUserId();
      }
      
      if (finalUserId == null) {
        AppLogger.warning('⚠️ No userId provided for marking age gate');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_getAgeGateKey(finalUserId), true);
      AppLogger.success('✅ Age gate marked as passed for $finalUserId');
    } catch (e) {
      AppLogger.error('❌ Error marking age gate as passed: $e');
      // Don't rethrow - this is not critical enough to block the flow
    }
  }

  /// Mark that the user has completed the full onboarding process
  Future<void> markOnboardingComplete([String? userId]) async {
    try {
      // Get userId if not provided
      String? finalUserId = userId;
      if (finalUserId == null && _userProfileManager != null) {
        finalUserId = await _userProfileManager.getOrCreateActiveUserId();
      }
      
      if (finalUserId == null) {
        AppLogger.warning('⚠️ No userId provided for marking onboarding complete');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_getOnboardingKey(finalUserId), true);
      AppLogger.success('✅ Onboarding marked as complete for $finalUserId');
    } catch (e) {
      AppLogger.error('❌ Error marking onboarding as complete: $e');
      // Don't rethrow - this is not critical enough to block the flow
    }
  }

  /// Migrate global onboarding flags to user-scoped storage
  /// 
  /// Checks for legacy global flags and copies them to the current user's scoped keys
  Future<void> _migrateGlobalToUserScoped(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if migration already done
      final migrationKey = 'onboarding_migration_done_$userId';
      if (prefs.getBool(migrationKey) ?? false) {
        return; // Already migrated
      }

      // Check for legacy global flags
      final legacyAgeGate = prefs.getBool(_legacyAgeGateKey);
      final legacyOnboarding = prefs.getBool(_legacyOnboardingKey);

      if (legacyAgeGate != null || legacyOnboarding != null) {
        AppLogger.data('📦 Migrating global onboarding flags to user-scoped for $userId');
        
        // Copy to user-scoped keys
        if (legacyAgeGate != null) {
          await prefs.setBool(_getAgeGateKey(userId), legacyAgeGate);
        }
        if (legacyOnboarding != null) {
          await prefs.setBool(_getOnboardingKey(userId), legacyOnboarding);
        }
        
        // Mark migration as done
        await prefs.setBool(migrationKey, true);
        
        // Clear legacy global flags (only after successful migration)
        await prefs.remove(_legacyAgeGateKey);
        await prefs.remove(_legacyOnboardingKey);
        
        AppLogger.success('✅ Migrated onboarding flags to user-scoped storage');
      } else {
        // No legacy flags - mark migration as done anyway
        await prefs.setBool(migrationKey, true);
      }
    } catch (e) {
      AppLogger.error('⚠️ Error migrating onboarding flags: $e');
      // Don't rethrow - allow app to continue
    }
  }

  /// Determine the initial screen based on onboarding status
  ///
  /// Checks both local state and Firebase profile (if user is signed in).
  /// Returns:
  /// - GratitudeScreen if onboarding is complete (locally or in Firebase)
  /// - AgeGateScreen or ConsentScreen if onboarding is not complete (starts onboarding flow)
  Future<Widget> getInitialScreen() async {
    // Get user ID first
    String? userId;
    if (_userProfileManager != null) {
      userId = await _userProfileManager.getOrCreateActiveUserId();
    } else {
      // Fallback: try to get from auth service
      final authService = AuthService();
      if (authService.isSignedIn && authService.hasEmailAccount) {
        userId = authService.currentUser?.uid;
      }
    }

    if (userId == null) {
      AppLogger.warning('⚠️ No userId available, starting onboarding');
      return const AgeGateScreen();
    }

    // Migrate global flags to user-scoped if needed
    await _migrateGlobalToUserScoped(userId);

    // Check local state first
    final localOnboardingComplete = await isOnboardingComplete(userId);
    final localAgeGatePassed = await hasPassedAgeGate(userId);

    // If user is signed in, check Firebase profile
    final authService = AuthService();
    if (authService.isSignedIn && authService.hasEmailAccount) {
      final emailUserId = authService.currentUser?.uid;
      if (emailUserId != null && emailUserId == userId) {
        try {
          // Sync and migrate profile from Firebase
          final migrationService = UserProfileMigrationService();
          final migrationResult = await migrationService.loadAndMigrateProfile(emailUserId);
          
          if (migrationResult != null) {
            // Check Firebase profile for onboarding status
            final firestore = FirebaseFirestore.instance;
            final doc = await firestore.collection('users').doc(emailUserId).get();
            final profileData = doc.data();
            final firebaseOnboardingComplete = profileData?['onboardingCompleted'] as bool? ?? false;
            final firebaseAgeGatePassed = profileData?['ageGatePassed'] as bool? ?? false;
            
            // If Firebase says onboarding complete, return main screen
            if (firebaseOnboardingComplete) {
              AppLogger.info('🎯 Onboarding complete in Firebase, returning GratitudeScreen');
              // Sync local state if needed
              if (!localOnboardingComplete) {
                await markOnboardingComplete(userId);
              }
              if (!localAgeGatePassed && firebaseAgeGatePassed) {
                await markAgeGatePassed(userId);
              }
              return GratitudeScreen();
            }
          }
        } catch (e) {
          AppLogger.error('⚠️ Error checking Firebase onboarding status: $e');
          // Continue with local check if Firebase check fails
        }
      }
    }

    // Use local state
    if (localOnboardingComplete) {
      AppLogger.info('🎯 Onboarding complete locally, returning GratitudeScreen');
      return GratitudeScreen();
    }

    // Onboarding not complete - determine which screen to show
    // If age gate passed, go to consent screen, otherwise age gate screen
    AppLogger.info('🚀 Starting onboarding flow');
    if (localAgeGatePassed) {
      return const ConsentScreen();
    } else {
      return const AgeGateScreen();
    }
  }

  /// Reset onboarding state (for development/testing purposes)
  ///
  /// This clears both the age gate and onboarding completion flags,
  /// allowing the onboarding flow to be tested repeatedly.
  Future<void> resetOnboarding([String? userId]) async {
    try {
      // Get userId if not provided
      String? finalUserId = userId;
      if (finalUserId == null && _userProfileManager != null) {
        finalUserId = await _userProfileManager.getOrCreateActiveUserId();
      }
      
      if (finalUserId == null) {
        AppLogger.warning('⚠️ No userId provided for resetting onboarding');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getAgeGateKey(finalUserId));
      await prefs.remove(_getOnboardingKey(finalUserId));
      AppLogger.warning('⚠️ Onboarding state reset for $finalUserId (development mode)');
    } catch (e) {
      AppLogger.error('❌ Error resetting onboarding: $e');
    }
  }
}
