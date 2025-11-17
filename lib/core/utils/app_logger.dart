import 'package:flutter/foundation.dart';

/// Centralized logger for the application
/// 
/// Uses Flutter's debugPrint() which only outputs in debug mode
/// and is automatically stripped from release builds.
class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();

  /// Log an informational message
  /// Use for: Normal app flow, state changes, lifecycle events
  static void info(String message, [String? tag]) {
    _log('ℹ️', tag ?? 'INFO', message);
  }

  /// Log a success message
  /// Use for: Successful operations, completions
  static void success(String message, [String? tag]) {
    _log('✅', tag ?? 'SUCCESS', message);
  }

  /// Log a warning message
  /// Use for: Recoverable issues, deprecated paths, concerns
  static void warning(String message, [String? tag]) {
    _log('⚠️', tag ?? 'WARNING', message);
  }

  /// Log an error message
  /// Use for: Failures, exceptions, critical issues
  static void error(String message, [String? tag, Object? error]) {
    _log('❌', tag ?? 'ERROR', message);
    if (error != null) {
      debugPrint('   Error details: $error');
    }
  }

  /// Log a debug message
  /// Use for: Detailed debugging info, state dumps, verbose output
  static void debug(String message, [String? tag]) {
    _log('🔍', tag ?? 'DEBUG', message);
  }

  /// Log the start of an operation
  /// Use for: Tracking operation lifecycles
  static void start(String message, [String? tag]) {
    _log('🚀', tag ?? 'START', message);
  }

  /// Log data synchronization events
  /// Use for: Sync operations, API calls
  static void sync(String message, [String? tag]) {
    _log('🔄', tag ?? 'SYNC', message);
  }

  /// Log data-related events
  /// Use for: Data loading, saving, transformations
  static void data(String message, [String? tag]) {
    _log('📦', tag ?? 'DATA', message);
  }

  /// Log network-related events  
  /// Use for: HTTP requests, API calls, connectivity
  static void network(String message, [String? tag]) {
    _log('🌐', tag ?? 'NETWORK', message);
  }

  /// Log authentication events
  /// Use for: Sign in, sign out, auth state changes
  static void auth(String message, [String? tag]) {
    _log('🔐', tag ?? 'AUTH', message);
  }

  /// Internal logging method
  static void _log(String emoji, String tag, String message) {
    // Only log in debug mode
    if (kDebugMode) {
      debugPrint('$emoji [$tag] $message');
    }
  }

  /// Log with custom formatting (for special cases)
  static void custom(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}

