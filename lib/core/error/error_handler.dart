import 'dart:async';
import '../utils/app_logger.dart';
import '../../services/crashlytics_service.dart';
import '../../l10n/app_localizations.dart';
import 'app_error.dart';
import 'error_context.dart';
import 'error_mapper.dart';
import 'error_severity.dart';
import 'retry_policy.dart';

/// Centralized error handler for GratiStellar
///
/// Provides consistent error handling, logging, reporting, and retry logic
/// throughout the application.
///
/// Example usage:
/// ```dart
/// // Simple error handling
/// try {
///   await riskyOperation();
/// } catch (e, stack) {
///   final error = ErrorHandler.handle(
///     e,
///     stack,
///     context: ErrorContext.sync,
///   );
///   showUserMessage(error.userMessage);
/// }
///
/// // Automatic retry
/// try {
///   await ErrorHandler.withRetry(
///     operation: () => firestoreService.syncData(),
///     context: ErrorContext.sync,
///   );
/// } catch (e) {
///   // Only throws after all retries exhausted
/// }
/// ```
class ErrorHandler {
  ErrorHandler._(); // Private constructor - use static methods only

  /// Handle an error and return an AppError object
  ///
  /// This method categorizes the error, logs it, and optionally reports
  /// to Crashlytics. It does NOT show UI - that's the caller's responsibility.
  ///
  /// [exception] - The caught exception
  /// [stackTrace] - Optional stack trace
  /// [context] - Error context for categorization
  /// [l10n] - Optional localization object for user messages
  /// [metadata] - Optional additional context data
  ///
  /// Returns an [AppError] with user-friendly message and categorization.
  static AppError handle(
    dynamic exception,
    StackTrace? stackTrace, {
    required ErrorContext context,
    AppLocalizations? l10n,
    Map<String, dynamic>? metadata,
  }) {
    // Map exception to AppError
    final error = ErrorMapper.mapException(
      exception,
      stackTrace,
      context,
      l10n,
    );

    // Add any additional metadata
    if (metadata != null && error.metadata != null) {
      error.metadata!.addAll(metadata);
    }

    // Log error via AppLogger
    if (error.shouldLog) {
      _logError(error);
    }

    // Report to Crashlytics if critical/error
    if (error.shouldReportToCrashlytics) {
      _reportToCrashlytics(error);
    }

    return error;
  }

  /// Execute an operation with automatic retry logic
  ///
  /// This method wraps an async operation and automatically retries on failure
  /// using exponential backoff (scheduled in background). It handles BuildContext
  /// safely by NOT accepting or using it - the caller must show UI messages.
  ///
  /// Returns the result of the operation or throws the last error after all
  /// retries are exhausted.
  ///
  /// [operation] - The async operation to execute
  /// [context] - Error context for categorization
  /// [policy] - Retry policy (defaults to RetryPolicy.sync)
  /// [l10n] - Optional localization object
  /// [onRetry] - Optional callback invoked before each retry attempt
  ///
  /// Throws the final exception if all retries fail.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final result = await ErrorHandler.withRetry<bool>(
  ///     operation: () => firestoreService.syncData(),
  ///     context: ErrorContext.sync,
  ///     policy: RetryPolicy.sync,
  ///     onRetry: (attempt, delay) {
  ///       AppLogger.info('Retry #$attempt in ${delay.inMinutes}min');
  ///     },
  ///   );
  /// } catch (e, stack) {
  ///   final error = ErrorHandler.handle(e, stack, context: ErrorContext.sync);
  ///   if (mounted && context.mounted) {
  ///     showErrorMessage(error.userMessage);
  ///   }
  /// }
  /// ```
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    required ErrorContext context,
    RetryPolicy policy = RetryPolicy.sync,
    AppLocalizations? l10n,
    void Function(int attempt, Duration nextDelay)? onRetry,
  }) async {
    int attemptNumber = 0;
    dynamic lastException;
    StackTrace? lastStackTrace;

    while (attemptNumber <= policy.maxAttempts) {
      attemptNumber++;

      try {
        // Attempt the operation
        AppLogger.info(
          'Attempt $attemptNumber/${policy.maxAttempts + 1}',
          context.name.toUpperCase(),
        );
        return await operation();
      } catch (e, stack) {
        lastException = e;
        lastStackTrace = stack;

        // Map error to get retriability info
        final error = ErrorMapper.mapException(e, stack, context, l10n);

        // Log the error
        AppLogger.error(
          'Attempt $attemptNumber failed: ${error.technicalMessage}',
          context.name.toUpperCase(),
          e,
        );

        // Don't retry non-retriable errors (rate limits, validation, etc.)
        if (!error.isRetriable) {
          AppLogger.warning(
            'Error is not retriable, stopping retry attempts',
            context.name.toUpperCase(),
          );
          rethrow;
        }

        // Check if we have retries left
        if (attemptNumber > policy.maxAttempts) {
          AppLogger.error(
            'Max retry attempts reached (${policy.maxAttempts}), giving up',
            context.name.toUpperCase(),
          );
          rethrow;
        }

        // Calculate delay for next attempt
        final delay = policy.getDelayForAttempt(attemptNumber);

        AppLogger.info(
          'Scheduling retry #$attemptNumber in ${delay.inMinutes}m ${delay.inSeconds % 60}s...',
          context.name.toUpperCase(),
        );

        // Notify caller about retry
        onRetry?.call(attemptNumber, delay);

        // Wait before retrying (background scheduling)
        await Future.delayed(delay);
      }
    }

    // Should never reach here, but just in case
    Error.throwWithStackTrace(
      lastException,
      lastStackTrace ?? StackTrace.current,
    );
  }

  /// Log error details via AppLogger
  static void _logError(AppError error) {
    final contextTag = error.context.name.toUpperCase();

    switch (error.severity) {
      case ErrorSeverity.info:
        AppLogger.info(error.technicalMessage, contextTag);
        break;
      case ErrorSeverity.warning:
        AppLogger.warning(error.technicalMessage, contextTag);
        break;
      case ErrorSeverity.error:
      case ErrorSeverity.critical:
        AppLogger.error(
          error.technicalMessage,
          contextTag,
          error.originalError,
        );
        break;
    }

    // Log metadata if present
    if (error.metadata != null && error.metadata!.isNotEmpty) {
      AppLogger.debug('Error metadata: ${error.metadata}', contextTag);
    }
  }

  /// Report error to Crashlytics
  static void _reportToCrashlytics(AppError error) {
    final crashlytics = CrashlyticsService();

    // Set context keys
    crashlytics.setCustomKey('error_context', error.context.name);
    crashlytics.setCustomKey('error_severity', error.severity.name);
    crashlytics.setCustomKey('user_message', error.userMessage);

    // Add metadata as custom keys
    if (error.metadata != null) {
      error.metadata!.forEach((key, value) {
        crashlytics.setCustomKey('meta_$key', value.toString());
      });
    }

    // Report based on severity
    if (error.severity == ErrorSeverity.critical) {
      crashlytics.recordFatalError(
        error.originalError,
        error.stackTrace,
        reason: error.technicalMessage,
      );
    } else {
      crashlytics.recordError(
        error.originalError,
        error.stackTrace,
        reason: error.technicalMessage,
      );
    }
  }
}
