import 'dart:io' show Platform;
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

  /// Initialize Crashlytics and set up error handlers
  Future<void> initialize() async {
    if (_initialized) return;

    try {
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
      AppLogger.error('✅ Crashlytics initialized');
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
    FirebaseCrashlytics.instance.log(message);
  }

  /// Set a custom key-value pair
  void setCustomKey(String key, dynamic value) {
    FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Record a non-fatal error
  void recordError(dynamic error, StackTrace? stack, {String? reason}) {
    FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
  }

  /// Record a fatal error
  void recordFatalError(dynamic error, StackTrace? stack, {String? reason}) {
    FirebaseCrashlytics.instance.recordError(error, stack, reason: reason, fatal: true);
  }

  /// Set user identifier (for tracking issues per user)
  Future<void> setUserIdentifier(String id) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(id);
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