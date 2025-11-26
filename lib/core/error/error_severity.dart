/// Severity levels for errors in GratiStellar
///
/// Used to categorize errors by their impact on user experience
/// and determine appropriate handling (logging, reporting, display).
enum ErrorSeverity {
  /// Informational message - user should know but no action required
  /// Example: "Background sync completed"
  info,

  /// Warning - degraded functionality but app continues to work
  /// Example: "Network temporarily unavailable, using cached data"
  warning,

  /// Error - operation failed but app is stable
  /// Example: "Failed to save changes"
  error,

  /// Critical - serious issue requiring immediate attention
  /// Example: "Database corrupted", "Auth token invalid"
  critical,
}
