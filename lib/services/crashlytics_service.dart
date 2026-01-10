import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/app_logger.dart';

/// Service for crash reporting and analytics
class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  bool _initialized = false;

  /// Check if Firebase is available
  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Initialize Crashlytics and set up error handlers
  Future<void> initialize() async {
    if (_initialized) return;

    if (!_isFirebaseAvailable) {
      AppLogger.warning('⚠️ Firebase not available, skipping Crashlytics initialization');
      return;
    }

    try {
      // Re-enable Crashlytics collection (it's disabled in AndroidManifest.xml)
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // Set up Flutter error handler
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      // Catch async errors not caught by Flutter framework
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Log device information
      await _logDeviceInfo();

      _initialized = true;
      AppLogger.success('✅ Crashlytics initialized');
    } catch (e) {
      AppLogger.error('⚠️ Failed to initialize Crashlytics: $e');
    }
  }

  /// Log device information for debugging
  Future<void> _logDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;

        FirebaseCrashlytics.instance.setCustomKey('android_version', androidInfo.version.sdkInt);
        FirebaseCrashlytics.instance.setCustomKey('device_model', androidInfo.model);
        FirebaseCrashlytics.instance.setCustomKey('manufacturer', androidInfo.manufacturer);
        FirebaseCrashlytics.instance.setCustomKey('device_brand', androidInfo.brand);
        FirebaseCrashlytics.instance.setCustomKey('android_release', androidInfo.version.release);

        AppLogger.info('📱 Device: ${androidInfo.manufacturer} ${androidInfo.model} (Android ${androidInfo.version.sdkInt})');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;

        FirebaseCrashlytics.instance.setCustomKey('ios_version', iosInfo.systemVersion);
        FirebaseCrashlytics.instance.setCustomKey('device_model', iosInfo.model);
        FirebaseCrashlytics.instance.setCustomKey('device_name', iosInfo.name);

        AppLogger.info('📱 Device: ${iosInfo.model} (iOS ${iosInfo.systemVersion})');
      }
    } catch (e) {
      AppLogger.warning('⚠️ Could not get device info: $e');
    }
  }

  /// Log a message to Crashlytics
  void log(String message) {
    if (!_initialized || !_isFirebaseAvailable) return;
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (e) {
      AppLogger.warning('⚠️ Failed to log to Crashlytics: $e');
    }
  }

  /// Set a custom key-value pair
  void setCustomKey(String key, dynamic value) {
    if (!_initialized || !_isFirebaseAvailable) return;
    try {
      FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      AppLogger.warning('⚠️ Failed to set custom key: $e');
    }
  }

  /// Record a non-fatal error
  void recordError(dynamic error, StackTrace? stack, {String? reason}) {
    if (!_initialized || !_isFirebaseAvailable) return;
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
    } catch (e) {
      AppLogger.warning('⚠️ Failed to record error to Crashlytics: $e');
    }
  }

  /// Record a fatal error
  void recordFatalError(dynamic error, StackTrace? stack, {String? reason}) {
    if (!_initialized || !_isFirebaseAvailable) return;
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, reason: reason, fatal: true);
    } catch (e) {
      AppLogger.warning('⚠️ Failed to record fatal error to Crashlytics: $e');
    }
  }

  /// Set user identifier (for tracking issues per user)
  Future<void> setUserIdentifier(String id) async {
    if (!_initialized || !_isFirebaseAvailable) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(id);
    } catch (e) {
      AppLogger.warning('⚠️ Failed to set user identifier: $e');
    }
  }

  /// Check if running on Android version < 28 (Android 9)
  Future<bool> isOldAndroidDevice() async {
    if (!Platform.isAndroid) return false;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt < 28;
    } catch (e) {
      return false;
    }
  }
}