/// Backup format options for data export
enum BackupFormat {
  /// Encrypted backup with XOR encryption (recommended for regular backups)
  encrypted,

  /// Plaintext JSON backup for GDPR compliance and data portability
  plaintext,
}

/// Extension methods for BackupFormat
extension BackupFormatExtension on BackupFormat {
  /// Get the file extension for this backup format
  String get fileExtension {
    switch (this) {
      case BackupFormat.encrypted:
        return 'gratistellar';
      case BackupFormat.plaintext:
        return 'gratistellar-plain';
    }
  }

  /// Get the display name for this backup format
  String get displayName {
    switch (this) {
      case BackupFormat.encrypted:
        return 'Encrypted (Recommended)';
      case BackupFormat.plaintext:
        return 'Plaintext (GDPR Export)';
    }
  }
}
