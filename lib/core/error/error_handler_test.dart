import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../security/rate_limiter.dart';
import '../utils/app_logger.dart';
import 'error_handler.dart';
import 'error_context.dart';
import 'retry_policy.dart';

/// Test file to verify ErrorHandler functionality
///
/// This file demonstrates usage patterns and can be used to manually
/// test the error handling system. Delete this file once testing is complete.
class ErrorHandlerTest {
  /// Test 1: Simple error handling
  static void testSimpleErrorHandling() {
    AppLogger.info('=== Test 1: Simple Error Handling ===', 'TEST');

    try {
      // Simulate a Firebase auth error
      throw FirebaseAuthException(
        code: 'wrong-password',
        message: 'The password is invalid',
      );
    } catch (e, stack) {
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.auth,
      );

      AppLogger.debug('Original error: $e', 'TEST');
      AppLogger.debug('User message: ${error.userMessage}', 'TEST');
      AppLogger.debug('Technical message: ${error.technicalMessage}', 'TEST');
      AppLogger.debug('Severity: ${error.severity}', 'TEST');
      AppLogger.debug('Is retriable: ${error.isRetriable}', 'TEST');
      AppLogger.debug('Should report to Crashlytics: ${error.shouldReportToCrashlytics}', 'TEST');
    }
  }

  /// Test 2: Rate limit exception handling
  static void testRateLimitException() {
    AppLogger.info('=== Test 2: Rate Limit Exception ===', 'TEST');

    try {
      throw RateLimitException('sync_operation', Duration(minutes: 5));
    } catch (e, stack) {
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.sync,
      );

      AppLogger.debug('User message: ${error.userMessage}', 'TEST');
      AppLogger.debug('Retry after: ${error.retryAfter}', 'TEST');
      AppLogger.debug('Is retriable: ${error.isRetriable}', 'TEST');
    }
  }

  /// Test 3: Timeout exception
  static void testTimeoutException() {
    AppLogger.info('=== Test 3: Timeout Exception ===', 'TEST');

    try {
      throw TimeoutException('Operation timed out', Duration(seconds: 30));
    } catch (e, stack) {
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.network,
      );

      AppLogger.debug('User message: ${error.userMessage}', 'TEST');
      AppLogger.debug('Is retriable: ${error.isRetriable}', 'TEST');
      AppLogger.debug('Metadata: ${error.metadata}', 'TEST');
    }
  }

  /// Test 4: Firebase Firestore exception
  static void testFirestoreException() {
    AppLogger.info('=== Test 4: Firestore Exception ===', 'TEST');

    try {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions',
      );
    } catch (e, stack) {
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.database,
      );

      AppLogger.debug('User message: ${error.userMessage}', 'TEST');
      AppLogger.debug('Is retriable: ${error.isRetriable}', 'TEST');
      AppLogger.debug('Severity: ${error.severity}', 'TEST');
    }
  }

  /// Test 5: Unknown exception fallback
  static void testUnknownException() {
    AppLogger.info('=== Test 5: Unknown Exception ===', 'TEST');

    try {
      throw Exception('Something unexpected happened');
    } catch (e, stack) {
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.unknown,
      );

      AppLogger.debug('User message: ${error.userMessage}', 'TEST');
      AppLogger.debug('Technical message: ${error.technicalMessage}', 'TEST');
    }
  }

  /// Test 6: Retry policy calculations
  static void testRetryPolicy() {
    AppLogger.info('=== Test 6: Retry Policy ===', 'TEST');

    AppLogger.info('Sync policy (exponential backoff):', 'TEST');
    for (int i = 1; i <= 3; i++) {
      final delay = RetryPolicy.sync.getDelayForAttempt(i);
      AppLogger.debug('  Attempt $i: ${delay.inMinutes}min ${delay.inSeconds % 60}sec', 'TEST');
    }

    AppLogger.info('Quick policy (constant delay):', 'TEST');
    for (int i = 1; i <= 2; i++) {
      final delay = RetryPolicy.quick.getDelayForAttempt(i);
      AppLogger.debug('  Attempt $i: ${delay.inSeconds}sec', 'TEST');
    }
  }

  /// Test 7: Simulated retry with failure (no actual delay)
  static Future<void> testRetryLogic() async {
    AppLogger.info('=== Test 7: Retry Logic (Simulated) ===', 'TEST');

    int attempts = 0;

    try {
      // Simulate an operation that fails multiple times
      await ErrorHandler.withRetry<void>(
        operation: () async {
          attempts++;
          AppLogger.debug('Operation attempt #$attempts', 'TEST');

          if (attempts < 3) {
            // Fail first 2 attempts with retriable error
            throw FirebaseException(
              plugin: 'test',
              code: 'unavailable',
              message: 'Service unavailable',
            );
          }

          // Succeed on 3rd attempt
          AppLogger.success('Operation succeeded!', 'TEST');
        },
        context: ErrorContext.sync,
        policy: RetryPolicy(
          maxAttempts: 3,
          baseDelaySeconds: 1, // Short delay for testing
          useExponentialBackoff: false,
        ),
        onRetry: (attempt, delay) {
          AppLogger.debug('  -> Retry #$attempt scheduled in ${delay.inSeconds}s', 'TEST');
        },
      );
    } catch (e) {
      AppLogger.error('Final error after all retries: $e', 'TEST');
    }
  }

  /// Test 8: Non-retriable error (should not retry)
  static Future<void> testNonRetriableError() async {
    AppLogger.info('=== Test 8: Non-Retriable Error ===', 'TEST');

    int attempts = 0;

    try {
      await ErrorHandler.withRetry<void>(
        operation: () async {
          attempts++;
          AppLogger.debug('Operation attempt #$attempts', 'TEST');

          // Throw non-retriable error (rate limit)
          throw RateLimitException('sync_operation', Duration(minutes: 5));
        },
        context: ErrorContext.sync,
        policy: RetryPolicy(
          maxAttempts: 3,
          baseDelaySeconds: 1,
        ),
      );
    } catch (e, stack) {
      final error = ErrorHandler.handle(e, stack, context: ErrorContext.sync);
      AppLogger.info('Stopped immediately (no retry): ${error.userMessage}', 'TEST');
      AppLogger.info('Total attempts: $attempts (should be 1)', 'TEST');
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    AppLogger.info('╔════════════════════════════════════════════╗', 'TEST');
    AppLogger.info('║  GratiStellar ErrorHandler Test Suite     ║', 'TEST');
    AppLogger.info('╚════════════════════════════════════════════╝', 'TEST');

    testSimpleErrorHandling();
    testRateLimitException();
    testTimeoutException();
    testFirestoreException();
    testUnknownException();
    testRetryPolicy();

    await testRetryLogic();
    await testNonRetriableError();

    AppLogger.info('╔════════════════════════════════════════════╗', 'TEST');
    AppLogger.info('║  All tests completed!                      ║', 'TEST');
    AppLogger.info('╚════════════════════════════════════════════╝', 'TEST');
  }
}

/// Uncomment to run tests from main.dart:
///
/// import 'core/error/error_handler_test.dart';
///
/// void main() async {
///   await ErrorHandlerTest.runAllTests();
///   runApp(MyApp());
/// }
