import 'error_severity.dart';
import 'error_context.dart';

/// Represents a categorized error with user-friendly messaging
///
/// This class wraps exceptions with additional metadata to enable
/// consistent error handling, logging, and user feedback across the app.
class AppError {
  /// The original exception that occurred
  final dynamic originalError;

  /// Stack trace if available
  final StackTrace? stackTrace;

  /// Error severity level
  final ErrorSeverity severity;

  /// Context where error occurred
  final ErrorContext context;

  /// User-friendly message (localized when possible)
  ///
  /// This message is safe to display to users - it never contains
  /// technical details or raw exception strings.
  final String userMessage;

  /// Technical message for logging and debugging
  ///
  /// Contains detailed information for developers. Not shown to users.
  final String technicalMessage;

  /// Whether this error can be retried
  ///
  /// True for transient failures (network issues, timeouts).
  /// False for permanent failures (validation errors, rate limits, permissions).
  final bool isRetriable;

  /// Suggested retry delay (for rate limits)
  ///
  /// When set, indicates how long to wait before retrying.
  final Duration? retryAfter;

  /// Additional context data for debugging
  ///
  /// Can include error codes, operation details, etc.
  final Map<String, dynamic>? metadata;

  /// Timestamp when error occurred
  final DateTime timestamp;

  AppError({
    required this.originalError,
    this.stackTrace,
    required this.severity,
    required this.context,
    required this.userMessage,
    required this.technicalMessage,
    this.isRetriable = false,
    this.retryAfter,
    this.metadata,
  }) : timestamp = DateTime.now();

  /// Whether this error should be reported to Crashlytics
  ///
  /// Critical and error severity levels are reported for monitoring.
  bool get shouldReportToCrashlytics {
    return severity == ErrorSeverity.critical ||
           severity == ErrorSeverity.error;
  }

  /// Whether this error should be logged
  ///
  /// All errors are logged via AppLogger for debugging purposes.
  bool get shouldLog => true;

  @override
  String toString() => 'AppError($severity, $context): $technicalMessage';
}
