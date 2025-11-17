#!/usr/bin/env python
import '../../../../galaxy_metadata.dart';
import '../../../../storage.dart';
import '../../data/repositories/backup_repository.dart';

/// Strategy for merging backup data with existing data
enum MergeStrategy {
  /// Replace all existing data with backup data
  replaceAll,
  
  /// Merge data, keeping newer versions based on updatedAt
  mergeKeepNewer,
}

/// Result of backup import operation
class ImportBackupResult {
  final bool success;
  final String? errorMessage;
  final BackupData? backup;
  final List<GratitudeStar>? mergedStars;
  final List<GalaxyMetadata>? mergedGalaxies;
  final Map<String, dynamic>? mergedPreferences;

  ImportBackupResult({
    required this.success,
    this.errorMessage,
    this.backup,
    this.mergedStars,
    this.mergedGalaxies,
    this.mergedPreferences,
  });

  factory ImportBackupResult.success({
    required BackupData backup,
    required List<GratitudeStar> mergedStars,
    required List<GalaxyMetadata> mergedGalaxies,
    required Map<String, dynamic> mergedPreferences,
  }) {
    return ImportBackupResult(
      success: true,
      backup: backup,
      mergedStars: mergedStars,
      mergedGalaxies: mergedGalaxies,
      mergedPreferences: mergedPreferences,
    );
  }

  factory ImportBackupResult.failure(String errorMessage) {
    return ImportBackupResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Use case for importing backup
class ImportBackupUseCase {
  final BackupRepository _repository;

  ImportBackupUseCase(this._repository);

  /// Execute backup import with merge strategy
  /// 
  /// Imports backup file and merges with existing data according to strategy
  Future<ImportBackupResult> execute({
    required String filePath,
    required List<GratitudeStar> currentStars,
    required List<GalaxyMetadata> currentGalaxies,
    required Map<String, dynamic> currentPreferences,
    required MergeStrategy strategy,
  }) async {
    try {
      // Import and validate backup
      final backup = await _repository.importBackup(filePath);

      // Apply merge strategy
      late List<GratitudeStar> mergedStars;
      late List<GalaxyMetadata> mergedGalaxies;
      late Map<String, dynamic> mergedPreferences;

      switch (strategy) {
        case MergeStrategy.replaceAll:
          // Replace all data with backup
          mergedStars = backup.stars;
          mergedGalaxies = backup.galaxies
              .map((json) => GalaxyMetadata.fromJson(json))
              .toList();
          mergedPreferences = backup.preferences;
          break;

        case MergeStrategy.mergeKeepNewer:
          // Merge data, keeping newer versions
          mergedStars = _repository.mergeStars(currentStars, backup.stars);
          mergedGalaxies = _repository.mergeGalaxies(
            currentGalaxies,
            backup.galaxies,
          );
          mergedPreferences = _mergePreferences(
            currentPreferences,
            backup.preferences,
          );
          break;
      }

      return ImportBackupResult.success(
        backup: backup,
        mergedStars: mergedStars,
        mergedGalaxies: mergedGalaxies,
        mergedPreferences: mergedPreferences,
      );
    } on ValidationException catch (e) {
      return ImportBackupResult.failure(e.message);
    } on BackupException catch (e) {
      return ImportBackupResult.failure(e.message);
    } catch (e) {
      return ImportBackupResult.failure('Unexpected error: $e');
    }
  }

  /// Merge preferences (backup takes precedence for now)
  Map<String, dynamic> _mergePreferences(
    Map<String, dynamic> current,
    Map<String, dynamic> backup,
  ) {
    // For now, backup preferences take precedence
    // Could be enhanced to be more selective in the future
    return {...current, ...backup};
  }
}

