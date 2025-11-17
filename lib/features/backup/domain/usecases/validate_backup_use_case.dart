import '../../data/repositories/backup_repository.dart';
import '../../../../storage.dart';

/// Result of backup validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final BackupData? backup;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.backup,
  });

  factory ValidationResult.valid(BackupData backup) {
    return ValidationResult(
      isValid: true,
      backup: backup,
    );
  }

  factory ValidationResult.invalid(String errorMessage) {
    return ValidationResult(
      isValid: false,
      errorMessage: errorMessage,
    );
  }

  /// Get human-readable summary of backup contents
  String getSummary() {
    if (!isValid || backup == null) {
      return 'Invalid backup file';
    }
    return backup!.getSummary();
  }
}

/// Use case for validating backup files
class ValidateBackupUseCase {
  final BackupRepository _repository;

  ValidateBackupUseCase(this._repository);

  /// Validate a backup file
  /// 
  /// Checks file format, encryption, version compatibility, and data integrity
  /// without actually importing the data.
  Future<ValidationResult> execute(String filePath) async {
    try {
      final backup = await _repository.validateBackupFile(filePath);

      if (backup == null) {
        return ValidationResult.invalid('Backup file is invalid or corrupted');
      }

      if (!backup.validate()) {
        return ValidationResult.invalid('Backup file failed integrity check');
      }

      return ValidationResult.valid(backup);
    } on ValidationException catch (e) {
      return ValidationResult.invalid(e.message);
    } on BackupException catch (e) {
      return ValidationResult.invalid(e.message);
    } catch (e) {
      return ValidationResult.invalid('Unexpected error: $e');
    }
  }
}

