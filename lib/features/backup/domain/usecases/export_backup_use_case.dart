import 'package:share_plus/share_plus.dart';

import '../../../../galaxy_metadata.dart';
import '../../../../storage.dart';
import '../../data/repositories/backup_repository.dart';

/// Result of backup export operation
class ExportBackupResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;
  final BackupData? backup;

  ExportBackupResult({
    required this.success,
    this.filePath,
    this.errorMessage,
    this.backup,
  });

  factory ExportBackupResult.success(String filePath, BackupData backup) {
    return ExportBackupResult(
      success: true,
      filePath: filePath,
      backup: backup,
    );
  }

  factory ExportBackupResult.failure(String errorMessage) {
    return ExportBackupResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Use case for exporting backup
class ExportBackupUseCase {
  final BackupRepository _repository;

  ExportBackupUseCase(this._repository);

  /// Execute backup export
  /// 
  /// Collects all user data (stars, galaxies, preferences) and creates
  /// an encrypted backup file.
  Future<ExportBackupResult> execute({
    required List<GratitudeStar> stars,
    required List<GalaxyMetadata> galaxies,
    required double fontScale,
  }) async {
    try {
      // Prepare preferences
      final preferences = {
        'fontScale': fontScale,
      };

      // Create backup data
      final backup = await _repository.createBackup(
        stars: stars,
        galaxies: galaxies,
        preferences: preferences,
      );

      // Export to encrypted file
      final filePath = await _repository.exportBackup(backup);

      return ExportBackupResult.success(filePath, backup);
    } on BackupException catch (e) {
      return ExportBackupResult.failure(e.message);
    } catch (e) {
      return ExportBackupResult.failure('Unexpected error: $e');
    }
  }

  /// Share the backup file
  ///
  /// Opens the system share dialog to allow user to save/send the backup file
  Future<void> shareBackupFile(String filePath, String filename) async {
    try {
      final params = ShareParams(
        files: [XFile(filePath)],
        subject: 'GratiStellar Backup',
        text: 'Your GratiStellar data backup. Keep this file safe!',
      );

      await SharePlus.instance.share(params);
    } catch (e) {
      throw BackupException('Failed to share backup file', e);
    }
  }
}

