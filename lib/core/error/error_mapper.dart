import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../../features/backup/data/repositories/backup_repository.dart';
import '../security/rate_limiter.dart';
import 'app_error.dart';
import 'error_context.dart';
import 'error_severity.dart';

/// Maps exceptions to AppError objects with user-friendly messages
///
/// This class centralizes all error message mapping logic, converting
/// technical exceptions into user-friendly, localized messages.
class ErrorMapper {
  ErrorMapper._(); // Private constructor - use static methods only

  /// Map an exception to an AppError
  ///
  /// [exception] - The caught exception
  /// [stackTrace] - Optional stack trace
  /// [context] - Error context for categorization
  /// [l10n] - Localization object for user messages (optional, uses fallback if null)
  static AppError mapException(
    dynamic exception,
    StackTrace? stackTrace,
    ErrorContext context,
    AppLocalizations? l10n,
  ) {
    // Firebase Auth Exceptions
    if (exception is FirebaseAuthException) {
      return _mapFirebaseAuthException(exception, stackTrace, l10n);
    }

    // Firebase Firestore Exceptions
    if (exception is FirebaseException) {
      return _mapFirebaseException(exception, stackTrace, context, l10n);
    }

    // Custom App Exceptions
    if (exception is RateLimitException) {
      return _mapRateLimitException(exception, stackTrace, l10n);
    }

    if (exception is BackupException) {
      return _mapBackupException(exception, stackTrace, l10n);
    }

    if (exception is ValidationException) {
      return _mapValidationException(exception, stackTrace, l10n);
    }

    // Standard Dart Exceptions
    if (exception is TimeoutException) {
      return _mapTimeoutException(exception, stackTrace, context, l10n);
    }

    // Fallback for unknown exceptions
    return _mapUnknownException(exception, stackTrace, context, l10n);
  }

  static AppError _mapFirebaseAuthException(
    FirebaseAuthException e,
    StackTrace? stackTrace,
    AppLocalizations? l10n,
  ) {
    String userMessage;
    ErrorSeverity severity;
    bool isRetriable = false;

    switch (e.code) {
      case 'email-already-in-use':
        userMessage = l10n?.errorEmailInUse ??
            'This email is already registered. Try signing in instead.';
        severity = ErrorSeverity.error;
        break;

      case 'invalid-email':
        userMessage = l10n?.errorInvalidEmail ??
            'Invalid email address format.';
        severity = ErrorSeverity.error;
        break;

      case 'weak-password':
        userMessage = l10n?.errorWeakPassword ??
            'Password is too weak. Use at least 6 characters.';
        severity = ErrorSeverity.error;
        break;

      case 'user-not-found':
        userMessage = l10n?.errorUserNotFound ??
            'No account found with this email.';
        severity = ErrorSeverity.error;
        break;

      case 'wrong-password':
        userMessage = l10n?.errorWrongPassword ??
            'Incorrect password. Please try again.';
        severity = ErrorSeverity.error;
        break;

      case 'invalid-credential':
        userMessage = l10n?.errorInvalidCredential ??
            'Invalid credentials. Please check your email and password.';
        severity = ErrorSeverity.error;
        break;

      case 'credential-already-in-use':
        userMessage = l10n?.errorCredentialInUse ??
            'This email is already linked to another account.';
        severity = ErrorSeverity.error;
        break;

      case 'too-many-requests':
        userMessage = l10n?.errorTooManyRequests ??
            'Too many failed attempts. Please try again later.';
        severity = ErrorSeverity.warning;
        isRetriable = true;
        break;

      case 'network-request-failed':
        userMessage = l10n?.errorNetworkFailed ??
            'Network error. Check your internet connection.';
        severity = ErrorSeverity.warning;
        isRetriable = true;
        break;

      default:
        userMessage = l10n?.errorGeneric ??
            'Authentication error. Please try again.';
        severity = ErrorSeverity.error;
    }

    return AppError(
      originalError: e,
      stackTrace: stackTrace,
      severity: severity,
      context: ErrorContext.auth,
      userMessage: userMessage,
      technicalMessage: 'FirebaseAuthException: ${e.code} - ${e.message}',
      isRetriable: isRetriable,
      metadata: {'code': e.code, 'plugin': e.plugin},
    );
  }

  static AppError _mapFirebaseException(
    FirebaseException e,
    StackTrace? stackTrace,
    ErrorContext context,
    AppLocalizations? l10n,
  ) {
    String userMessage;
    ErrorSeverity severity;
    bool isRetriable = false;

    switch (e.code) {
      case 'resource-exhausted':
        userMessage = l10n?.errorQuotaExceeded ??
            'Daily quota exceeded. Please try again tomorrow.';
        severity = ErrorSeverity.error;
        isRetriable = false;
        break;

      case 'unavailable':
        userMessage = l10n?.errorServiceUnavailable ??
            'Service temporarily unavailable. Please try again.';
        severity = ErrorSeverity.warning;
        isRetriable = true;
        break;

      case 'deadline-exceeded':
      case 'timeout':
        userMessage = l10n?.errorTimeout ??
            'Request timed out. Please check your connection.';
        severity = ErrorSeverity.warning;
        isRetriable = true;
        break;

      case 'permission-denied':
        userMessage = l10n?.errorPermissionDenied ??
            'Permission denied. Please sign in again.';
        severity = ErrorSeverity.error;
        isRetriable = false;
        break;

      case 'not-found':
        userMessage = 'Requested data not found.';
        severity = ErrorSeverity.error;
        isRetriable = false;
        break;

      default:
        userMessage = l10n?.errorSyncFailed ??
            'Sync error. Your changes will be retried automatically.';
        severity = ErrorSeverity.warning;
        isRetriable = true;
    }

    return AppError(
      originalError: e,
      stackTrace: stackTrace,
      severity: severity,
      context: context,
      userMessage: userMessage,
      technicalMessage: 'FirebaseException: ${e.code} - ${e.message}',
      isRetriable: isRetriable,
      metadata: {'code': e.code, 'plugin': e.plugin},
    );
  }

  static AppError _mapRateLimitException(
    RateLimitException e,
    StackTrace? stackTrace,
    AppLocalizations? l10n,
  ) {
    final retryAfter = e.retryAfter ?? Duration.zero;
    final minutes = retryAfter.inMinutes;

    String userMessage;
    if (minutes > 0) {
      userMessage =
          'Rate limit exceeded. Please try again in $minutes minute${minutes != 1 ? 's' : ''}.';
    } else {
      userMessage = 'Too many requests. Please wait a moment and try again.';
    }

    return AppError(
      originalError: e,
      stackTrace: stackTrace,
      severity: ErrorSeverity.warning,
      context: ErrorContext.sync,
      userMessage: userMessage,
      technicalMessage: 'RateLimitException: ${e.operation}',
      isRetriable: false, // Don't auto-retry rate limits
      retryAfter: retryAfter,
      metadata: {'operation': e.operation},
    );
  }

  static AppError _mapBackupException(
    BackupException e,
    StackTrace? stackTrace,
    AppLocalizations? l10n,
  ) {
    return AppError(
      originalError: e,
      stackTrace: stackTrace,
      severity: ErrorSeverity.error,
      context: ErrorContext.backup,
      userMessage: e.message,
      technicalMessage: 'BackupException: ${e.message}',
      isRetriable: false,
    );
  }

  static AppError _mapValidationException(
    ValidationException e,
    StackTrace? stackTrace,
    AppLocalizations? l10n,
  ) {
    return AppError(
      originalError: e,
      stackTrace: stackTrace,
      severity: ErrorSeverity.error,
      context: ErrorContext.validation,
      userMessage: e.message,
      technicalMessage: 'ValidationException: ${e.message}',
      isRetriable: false,
    );
  }

  static AppError _mapTimeoutException(
    TimeoutException e,
    StackTrace? stackTrace,
    ErrorContext context,
    AppLocalizations? l10n,
  ) {
    return AppError(
      originalError: e,
      stackTrace: stackTrace,
      severity: ErrorSeverity.warning,
      context: context,
      userMessage: l10n?.errorTimeout ??
          'Operation timed out. Please check your connection and try again.',
      technicalMessage: 'TimeoutException: ${e.message ?? 'No message'}',
      isRetriable: true,
      metadata: {'duration': e.duration?.inSeconds},
    );
  }

  static AppError _mapUnknownException(
    dynamic e,
    StackTrace? stackTrace,
    ErrorContext context,
    AppLocalizations? l10n,
  ) {
    // Extract meaningful message from exception
    String technicalMessage = e.toString();
    String userMessage = l10n?.errorGeneric ?? 'An unexpected error occurred.';
    ErrorContext finalContext = context;

    // Try to provide more context for common error strings
    if (technicalMessage.contains('No user signed in')) {
      userMessage = 'Session expired. Please restart the app.';
      finalContext = ErrorContext.auth;
    } else if (technicalMessage.toLowerCase().contains('network')) {
      userMessage = l10n?.errorNetworkFailed ??
          'Network error. Please check your connection.';
      finalContext = ErrorContext.network;
    }

    return AppError(
      originalError: e,
      stackTrace: stackTrace,
      severity: ErrorSeverity.error,
      context: finalContext,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      isRetriable: false,
    );
  }
}
