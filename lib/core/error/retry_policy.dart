import 'dart:math';

/// Configuration for retry behavior with exponential backoff
///
/// Defines how many times to retry an operation and the delay between attempts.
class RetryPolicy {
  /// Maximum number of retry attempts
  final int maxAttempts;

  /// Base delay for exponential backoff (in seconds)
  final int baseDelaySeconds;

  /// Maximum delay cap (in minutes)
  final int maxDelayMinutes;

  /// Whether to use exponential backoff
  ///
  /// If true: delays increase exponentially (2min, 4min, 8min)
  /// If false: delays are constant (baseDelaySeconds for each attempt)
  final bool useExponentialBackoff;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelaySeconds = 120, // 2 minutes
    this.maxDelayMinutes = 8,
    this.useExponentialBackoff = true,
  });

  /// Calculate delay for given attempt number (1-based)
  ///
  /// For exponential backoff with baseDelaySeconds=120 (2 minutes):
  /// - Attempt 1: 2 minutes
  /// - Attempt 2: 4 minutes
  /// - Attempt 3: 8 minutes (capped at maxDelayMinutes)
  Duration getDelayForAttempt(int attemptNumber) {
    if (!useExponentialBackoff) {
      return Duration(seconds: baseDelaySeconds);
    }

    // Exponential backoff: baseDelay * 2^(attemptNumber - 1)
    final baseMinutes = baseDelaySeconds ~/ 60;
    final delayMinutes = baseMinutes * pow(2, attemptNumber - 1).toInt();
    final cappedMinutes = min(delayMinutes, maxDelayMinutes);

    return Duration(minutes: cappedMinutes);
  }

  /// Standard retry policy for sync operations
  ///
  /// Matches existing GratiStellar sync retry pattern:
  /// 3 attempts with 2min, 4min, 8min delays
  static const sync = RetryPolicy(
    maxAttempts: 3,
    baseDelaySeconds: 120, // 2 minutes
    maxDelayMinutes: 8,
    useExponentialBackoff: true,
  );

  /// Quick retry policy for less critical operations
  ///
  /// Useful for operations that fail quickly and can be retried immediately
  static const quick = RetryPolicy(
    maxAttempts: 2,
    baseDelaySeconds: 30, // 30 seconds
    maxDelayMinutes: 2,
    useExponentialBackoff: false,
  );

  /// No retry policy
  ///
  /// Use for operations that should never retry automatically
  /// (validation errors, user input errors, rate limits)
  static const none = RetryPolicy(maxAttempts: 0);
}
