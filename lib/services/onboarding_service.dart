import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/app_logger.dart';
import '../screens/gratitude_screen.dart';
import '../screens/onboarding/splash_screen.dart';

/// Service to manage onboarding state and flow
///
/// Uses SharedPreferences to persist onboarding completion status across app launches.
/// Provides methods to check and update onboarding state.
class OnboardingService {
  // SharedPreferences keys
  static const String _ageGateKey = 'age_gate_passed';
  static const String _onboardingKey = 'onboarding_completed';

  /// Check if the user has completed the full onboarding flow
  Future<bool> isOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isComplete = prefs.getBool(_onboardingKey) ?? false;
      AppLogger.data('📋 Onboarding complete: $isComplete');
      return isComplete;
    } catch (e) {
      AppLogger.error('❌ Error checking onboarding status: $e');
      return false; // Safe default: show onboarding if check fails
    }
  }

  /// Check if the user has passed the age gate (13+ verification)
  Future<bool> hasPassedAgeGate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPassed = prefs.getBool(_ageGateKey) ?? false;
      AppLogger.data('🎂 Age gate passed: $hasPassed');
      return hasPassed;
    } catch (e) {
      AppLogger.error('❌ Error checking age gate status: $e');
      return false; // Safe default: show age gate if check fails
    }
  }

  /// Mark that the user has passed the age gate
  Future<void> markAgeGatePassed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_ageGateKey, true);
      AppLogger.success('✅ Age gate marked as passed');
    } catch (e) {
      AppLogger.error('❌ Error marking age gate as passed: $e');
      // Don't rethrow - this is not critical enough to block the flow
    }
  }

  /// Mark that the user has completed the full onboarding process
  Future<void> markOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
      AppLogger.success('✅ Onboarding marked as complete');
    } catch (e) {
      AppLogger.error('❌ Error marking onboarding as complete: $e');
      // Don't rethrow - this is not critical enough to block the flow
    }
  }

  /// Determine the initial screen based on onboarding status
  ///
  /// Returns:
  /// - GratitudeScreen if onboarding is complete
  /// - SplashScreen if onboarding is not complete (starts onboarding flow)
  Future<Widget> getInitialScreen() async {
    final onboardingComplete = await isOnboardingComplete();

    if (onboardingComplete) {
      AppLogger.info('🎯 Onboarding complete, returning GratitudeScreen');
      return GratitudeScreen();
    }

    AppLogger.info('🚀 Starting onboarding flow with SplashScreen');
    return SplashScreen();
  }

  /// Reset onboarding state (for development/testing purposes)
  ///
  /// This clears both the age gate and onboarding completion flags,
  /// allowing the onboarding flow to be tested repeatedly.
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ageGateKey);
      await prefs.remove(_onboardingKey);
      AppLogger.warning('⚠️ Onboarding state reset (development mode)');
    } catch (e) {
      AppLogger.error('❌ Error resetting onboarding: $e');
    }
  }
}
