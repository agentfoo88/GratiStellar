import 'dart:io';

import 'package:file_saver/file_saver.dart';

import '../../../../galaxy_metadata.dart';
import '../../../../storage.dart';
import '../../data/repositories/backup_repository.dart';
import '../models/backup_format.dart';

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
  /// a backup file in the specified format.
  ///
  /// IMPORTANT: [stars] parameter must include ALL stars from ALL galaxies,
  /// not just the currently active galaxy. Use StorageService.loadGratitudeStars()
  /// to get the complete unfiltered list.
  ///
  /// [format] The backup format to use (encrypted or plaintext). Defaults to encrypted.
  Future<ExportBackupResult> execute({
    required List<GratitudeStar> stars,
    required List<GalaxyMetadata> galaxies,
    required double fontScale,
    String? activeGalaxyId,
    BackupFormat format = BackupFormat.encrypted,
  }) async {
    try {
      // Prepare preferences
      final selectedPalettePreset = await StorageService.getSelectedPalettePreset();
      final preferences = {
        'fontScale': fontScale,
        'selectedPalettePreset': selectedPalettePreset,
      };

      // Create backup data
      final backup = await _repository.createBackup(
        stars: stars,
        galaxies: galaxies,
        preferences: preferences,
        activeGalaxyId: activeGalaxyId,
      );

      // Export to file with specified format
      final filePath = await _repository.exportBackup(backup, format: format);

      return ExportBackupResult.success(filePath, backup);
    } on BackupException catch (e) {
      return ExportBackupResult.failure(e.message);
    } catch (e) {
      return ExportBackupResult.failure('Unexpected error: $e');
    }
  }

  /// Save the backup file with guaranteed extension
  ///
  /// Opens a "Save As" dialog to allow user to save the backup file.
  /// Returns the saved file path on success, or null if user canceled.
  ///
  /// [format] The backup format to determine the correct file extension
  Future<String?> saveBackupFile(String filePath, String filename, BackupFormat format) async {
    try {
      // Read the backup file
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Extract filename without extension (file_saver adds it automatically)
      final nameWithoutExt = filename
          .replaceAll('.gratistellar-plain', '')
          .replaceAll('.gratistellar', '');

      // Save with format-specific extension
      final savedPath = await FileSaver.instance.saveAs(
        name: nameWithoutExt,
        bytes: bytes,
        fileExtension: format.fileExtension,
        mimeType: MimeType.other,
      );

      // savedPath is null if user canceled, otherwise contains the saved file path
      return savedPath;
    } catch (e) {
      throw BackupException('Failed to save backup file', e);
    }
  }
}

