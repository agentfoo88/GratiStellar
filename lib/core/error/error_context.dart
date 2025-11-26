/// Context types for errors in GratiStellar
///
/// Categorizes errors by the operation or feature area where they occurred.
/// Used for logging, filtering in Crashlytics, and determining appropriate
/// user messaging.
enum ErrorContext {
  /// Authentication operations (sign in, sign out, account management)
  auth,

  /// Cloud sync operations (upload, download, delta sync)
  sync,

  /// Database operations (Firestore reads/writes)
  database,

  /// Network connectivity issues
  network,

  /// Backup and restore operations
  backup,

  /// Local storage operations
  storage,

  /// UI-related errors (rendering, navigation)
  ui,

  /// Galaxy operations (switching, creating, renaming galaxies)
  galaxy,

  /// Input validation errors
  validation,

  /// Unknown or unclassified errors
  unknown,
}
