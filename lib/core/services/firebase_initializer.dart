import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';
import '../../firebase_options.dart';

/// Singleton service for managing Firebase initialization with retry logic
///
/// This service ensures Firebase is properly initialized before any Firebase
/// services are accessed. It implements retry logic with exponential backoff
/// to handle transient network issues and slow device performance.
class FirebaseInitializer {
  // Singleton instance
  static final FirebaseInitializer _instance = FirebaseInitializer._internal();
  factory FirebaseInitializer() => _instance;
  FirebaseInitializer._internal();

  /// Access the singleton instance
  static FirebaseInitializer get instance => _instance;

  // Initialization state
  Completer<bool>? _initCompleter;
  bool _isInitialized = false;
  bool _initializationFailed = false;
  String? _lastError;

  /// Check if Firebase has been successfully initialized
  bool get isInitialized => _isInitialized;

  /// Check if initialization failed after all retries
  bool get initializationFailed => _initializationFailed;

  /// Get the last error message if initialization failed
  String? get lastError => _lastError;

  /// Ensure Firebase is initialized, returns true if successful
  ///
  /// This method can be called multiple times safely. If initialization is
  /// already in progress, it will return the same Future. If initialization
  /// has already completed, it returns immediately.
  Future<bool> ensureInitialized() async {
    // Already initialized
    if (_isInitialized) {
      return true;
    }

    // Already failed
    if (_initializationFailed) {
      return false;
    }

    // Already initializing - return existing completer
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // Start new initialization
    return _initialize();
  }

  /// Initialize Firebase with retry logic
  ///
  /// Attempts to initialize Firebase up to 3 times with increasing timeouts:
  /// - Attempt 1: 5 seconds
  /// - Attempt 2: 10 seconds
  /// - Attempt 3: 15 seconds
  Future<bool> _initialize() async {
    _initCompleter = Completer<bool>();

    const maxAttempts = 3;
    final timeouts = [
      Duration(seconds: 5),
      Duration(seconds: 10),
      Duration(seconds: 15),
    ];

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        AppLogger.data('🔥 Firebase initialization attempt $attempt/$maxAttempts...');

        // Check if Firebase was already initialized (e.g., timed out but completed in background)
        if (Firebase.apps.isNotEmpty) {
          AppLogger.success('✅ Firebase was already initialized (completed in background)');
          _isInitialized = true;
          _initCompleter!.complete(true);
          return true;
        }

        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(
          timeouts[attempt - 1],
          onTimeout: () {
            throw TimeoutException(
              'Firebase initialization timed out after ${timeouts[attempt - 1].inSeconds}s'
            );
          },
        );

        // Verify Firebase is actually ready
        if (Firebase.apps.isEmpty) {
          throw Exception('Firebase apps list is empty after initialization');
        }

        // Success!
        _isInitialized = true;
        _initCompleter!.complete(true);
        AppLogger.success('✅ Firebase initialized successfully on attempt $attempt');
        return true;

      } catch (e) {
        _lastError = e.toString();

        // Check if the error is because Firebase is already initialized
        if (e.toString().contains('already exists')) {
          AppLogger.success('✅ Firebase already initialized (from previous attempt)');
          _isInitialized = true;
          _initCompleter!.complete(true);
          return true;
        }

        AppLogger.error('❌ Firebase initialization attempt $attempt failed: $e');

        // If this was the last attempt, mark as failed
        if (attempt == maxAttempts) {
          // One final check - maybe it initialized despite the error
          if (Firebase.apps.isNotEmpty) {
            AppLogger.success('✅ Firebase apps found despite error - considering initialized');
            _isInitialized = true;
            _initCompleter!.complete(true);
            return true;
          }

          _initializationFailed = true;
          _initCompleter!.complete(false);
          AppLogger.error('❌ Firebase initialization failed after $maxAttempts attempts');

          // Log detailed failure information
          if (kDebugMode) {
            AppLogger.error('🔍 Debug info:');
            AppLogger.error('   - Last error: $_lastError');
            AppLogger.error('   - Platform: ${DefaultFirebaseOptions.currentPlatform}');
            AppLogger.error('   - App will continue in offline mode');
          }

          return false;
        }

        // Wait a bit before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
        AppLogger.info('🔄 Retrying Firebase initialization...');
      }
    }

    // Should never reach here, but just in case
    _initializationFailed = true;
    _initCompleter!.complete(false);
    return false;
  }

  /// Reset the initializer state (for testing purposes)
  @visibleForTesting
  void reset() {
    _initCompleter = null;
    _isInitialized = false;
    _initializationFailed = false;
    _lastError = null;
  }
}
