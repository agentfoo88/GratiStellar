

/// Client-side rate limiting to prevent abuse
/// Tracks operations and enforces limits
class RateLimiter {
  // Track requests per operation type
  static final Map<String, List<DateTime>> _requestHistory = {};

  // Rate limit configurations (requests per time window)
  static const Map<String, RateLimitConfig> _limits = {
    // Firestore operations (these need protection)
    'firestore_write': RateLimitConfig(maxRequests: 100, windowMinutes: 1),
    'sync_operation': RateLimitConfig(maxRequests: 5, windowMinutes: 5),

    // User actions (generous limits - UI animations provide natural throttling)
    'create_gratitude': RateLimitConfig(maxRequests: 60, windowMinutes: 1),
    'delete_gratitude': RateLimitConfig(maxRequests: 30, windowMinutes: 1),
  };

  /// Check if operation is allowed under rate limit
  /// Returns true if allowed, false if rate limited
  static bool checkLimit(String operation) {
    final config = _limits[operation];
    if (config == null) return true; // No limit configured

    final now = DateTime.now();
    final windowStart = now.subtract(Duration(minutes: config.windowMinutes));

    // Get or create history for this operation
    _requestHistory[operation] ??= [];
    final history = _requestHistory[operation]!;

    // Remove old requests outside window
    history.removeWhere((time) => time.isBefore(windowStart));

    // Check if under limit
    if (history.length >= config.maxRequests) {
      print('⚠️ Rate limit exceeded for $operation (${history.length}/${config.maxRequests})');
      return false;
    }

    // Record this request
    history.add(now);
    return true;
  }

  /// Get remaining requests for an operation
  static int getRemainingRequests(String operation) {
    final config = _limits[operation];
    if (config == null) return 999;

    final now = DateTime.now();
    final windowStart = now.subtract(Duration(minutes: config.windowMinutes));

    final history = _requestHistory[operation] ?? [];
    final recentRequests = history.where((time) => time.isAfter(windowStart)).length;

    return (config.maxRequests - recentRequests).clamp(0, config.maxRequests);
  }

  /// Get time until rate limit resets
  static Duration? getTimeUntilReset(String operation) {
    final config = _limits[operation];
    if (config == null) return null;

    final history = _requestHistory[operation];
    if (history == null || history.isEmpty) return Duration.zero;

    final oldest = history.first;
    final resetTime = oldest.add(Duration(minutes: config.windowMinutes));
    final now = DateTime.now();

    if (resetTime.isBefore(now)) return Duration.zero;
    return resetTime.difference(now);
  }

  /// Reset rate limits (for testing or after user action)
  static void reset([String? operation]) {
    if (operation != null) {
      _requestHistory.remove(operation);
    } else {
      _requestHistory.clear();
    }
  }
}

class RateLimitConfig {
  final int maxRequests;
  final int windowMinutes;

  const RateLimitConfig({
    required this.maxRequests,
    required this.windowMinutes,
  });
}

/// Exception thrown when rate limit is exceeded
class RateLimitException implements Exception {
  final String operation;
  final Duration? retryAfter;

  const RateLimitException(this.operation, [this.retryAfter]);

  @override
  String toString() {
    if (retryAfter != null) {
      final seconds = retryAfter!.inSeconds;
      return 'Rate limit exceeded for $operation. Try again in $seconds seconds.';
    }
    return 'Rate limit exceeded for $operation.';
  }
}