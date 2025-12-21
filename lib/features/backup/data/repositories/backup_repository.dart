import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:crypto/crypto.dart';

import '../../../../galaxy_metadata.dart';
import '../../../../storage.dart';

/// Exception thrown when backup operations fail
class BackupException implements Exception {
  final String message;
  final dynamic originalError;

  BackupException(this.message, [this.originalError]);

  @override
  String toString() => 'BackupException: $message${originalError != null ? ' ($originalError)' : ''}';
}

/// Exception thrown when backup validation fails
class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Repository for managing backup and restore operations
class BackupRepository {
  static const String _backupVersion = '1.0';
  // Fixed encryption key for portability - backups can be restored on any device
  // This provides basic obfuscation. For stronger security, consider password-based encryption.
  static const String _fixedEncryptionKey = 'GratiStellar_Backup_Key_v1.0_2024';

  /// Create a backup of current data
  Future<BackupData> createBackup({
    required List<GratitudeStar> stars,
    required List<GalaxyMetadata> galaxies,
    required Map<String, dynamic> preferences,
    String? activeGalaxyId,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      return BackupData(
        version: _backupVersion,
        appVersion: packageInfo.version,
        createdAt: DateTime.now(),
        stars: stars,
        galaxies: galaxies.map((g) => g.toJson()).toList(),
        preferences: preferences,
        activeGalaxyId: activeGalaxyId,
        metadata: {
          'platform': Platform.operatingSystem,
          'deviceModel': await _getDeviceModel(),
        },
      );
    } catch (e) {
      throw BackupException('Failed to create backup', e);
    }
  }

  /// Export backup to encrypted file and return file path
  Future<String> exportBackup(BackupData backup) async {
    try {
      // Serialize to JSON
      final jsonString = json.encode(backup.toJson());
      
      // Encrypt data
      final encryptedData = await _encryptData(jsonString);
      
      // Generate filename with timestamp
      final timestamp = backup.createdAt.toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'gratistellar_backup_$timestamp.gratistellar';
      
      // Get temporary directory for the file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$filename';
      
      // Write encrypted data to file
      final file = File(filePath);
      await file.writeAsBytes(encryptedData);
      
      debugPrint('✅ Backup exported to: $filePath');
      return filePath;
    } catch (e) {
      throw BackupException('Failed to export backup', e);
    }
  }

  /// Import backup from encrypted file
  Future<BackupData> importBackup(String filePath) async {
    try {
      // Read encrypted file
      final file = File(filePath);
      if (!await file.exists()) {
        throw ValidationException('Backup file not found');
      }
      
      final encryptedData = await file.readAsBytes();
      
      // Decrypt data
      final jsonString = await _decryptData(encryptedData);

      // Parse JSON
      Map<String, dynamic> decoded;
      try {
        decoded = json.decode(jsonString) as Map<String, dynamic>;
      } on FormatException catch (e) {
        throw ValidationException(
          'Invalid backup file format: JSON parsing failed. '
          'The file may be corrupted or not a valid GratiStellar backup file. '
          'Error: ${e.message}'
        );
      } catch (e) {
        throw ValidationException(
          'Invalid backup file format: unexpected error during JSON parsing. '
          'Error: ${e.toString()}'
        );
      }

      // Create BackupData object
      BackupData backup;
      try {
        backup = BackupData.fromJson(decoded);
      } catch (e) {
        throw ValidationException(
          'Invalid backup file format: failed to parse backup data structure. '
          'The file may be corrupted or from an incompatible version. '
          'Error: ${e.toString()}'
        );
      }
      
      // Validate backup
      if (!backup.validate()) {
        throw ValidationException(
          'Backup file failed integrity check. '
          'The file may be corrupted or incomplete. '
          'Please verify the backup file was created correctly.'
        );
      }
      
      // Check version compatibility
      if (!_isVersionCompatible(backup.version)) {
        throw ValidationException(
          'Backup version ${backup.version} is not compatible with current version $_backupVersion. '
          'Please create a new backup with the current app version.'
        );
      }
      
      debugPrint('✅ Backup imported from: $filePath');
      debugPrint('   ${backup.getSummary()}');
      return backup;
    } catch (e) {
      if (e is ValidationException || e is BackupException) {
        rethrow;
      }
      throw BackupException('Failed to import backup', e);
    }
  }

  /// Validate a backup file without importing
  Future<BackupData?> validateBackupFile(String filePath) async {
    try {
      return await importBackup(filePath);
    } catch (e) {
      debugPrint('⚠️ Backup validation failed: $e');
      return null;
    }
  }

  /// Merge backup data with current data
  /// Returns merged list of stars (keeps newer version based on updatedAt)
  List<GratitudeStar> mergeStars(
    List<GratitudeStar> currentStars,
    List<GratitudeStar> backupStars,
  ) {
    final starMap = <String, GratitudeStar>{};
    
    // Add all current stars
    for (final star in currentStars) {
      starMap[star.id] = star;
    }
    
    // Merge backup stars (keep newer version)
    for (final backupStar in backupStars) {
      final currentStar = starMap[backupStar.id];
      
      if (currentStar == null) {
        // New star from backup
        starMap[backupStar.id] = backupStar;
      } else {
        // Keep newer version
        if (backupStar.updatedAt.isAfter(currentStar.updatedAt)) {
          starMap[backupStar.id] = backupStar;
        }
      }
    }
    
    return starMap.values.toList();
  }

  /// Merge galaxy metadata
  List<GalaxyMetadata> mergeGalaxies(
    List<GalaxyMetadata> currentGalaxies,
    List<Map<String, dynamic>> backupGalaxies,
  ) {
    final galaxyMap = <String, GalaxyMetadata>{};
    
    // Add all current galaxies
    for (final galaxy in currentGalaxies) {
      galaxyMap[galaxy.id] = galaxy;
    }
    
    // Merge backup galaxies
    for (final backupGalaxyJson in backupGalaxies) {
      final backupGalaxy = GalaxyMetadata.fromJson(backupGalaxyJson);
      
      if (!galaxyMap.containsKey(backupGalaxy.id)) {
        // New galaxy from backup
        galaxyMap[backupGalaxy.id] = backupGalaxy;
      }
      // Note: We don't update existing galaxies to preserve user's current structure
    }
    
    return galaxyMap.values.toList();
  }

  // ============================================================================
  // PRIVATE METHODS - Encryption & Utilities
  // ============================================================================

  /// Encrypt data using XOR encryption with fixed key for portability
  /// 
  /// Uses a fixed key so backups can be restored on any device.
  /// This provides basic obfuscation. For stronger security, consider password-based encryption.
  Future<List<int>> _encryptData(String data) async {
    try {
      // Use fixed encryption key for portability across devices
      final dataBytes = utf8.encode(data);
      final keyHash = sha256.convert(utf8.encode(_fixedEncryptionKey)).bytes;
      
      final encrypted = <int>[];
      for (var i = 0; i < dataBytes.length; i++) {
        encrypted.add(dataBytes[i] ^ keyHash[i % keyHash.length]);
      }
      
      // Prepend version marker
      final versionMarker = utf8.encode('GRATISTELLAR_BACKUP_V1:');
      return [...versionMarker, ...encrypted];
    } catch (e) {
      throw BackupException('Encryption failed', e);
    }
  }

  /// Decrypt data using fixed key for portability
  Future<String> _decryptData(List<int> encryptedData) async {
    try {
      // Check version marker
      final versionMarker = utf8.encode('GRATISTELLAR_BACKUP_V1:');
      if (encryptedData.length < versionMarker.length) {
        throw ValidationException('Invalid backup file format: file too short');
      }
      
      // Verify marker
      for (var i = 0; i < versionMarker.length; i++) {
        if (encryptedData[i] != versionMarker[i]) {
          throw ValidationException(
            'Invalid backup file format: missing or incorrect version marker. '
            'This may be an old backup format or corrupted file.'
          );
        }
      }
      
      // Remove marker
      final dataToDecrypt = encryptedData.sublist(versionMarker.length);
      
      if (dataToDecrypt.isEmpty) {
        throw ValidationException('Invalid backup file format: empty data');
      }
      
      // Use fixed encryption key for portability
      final keyHash = sha256.convert(utf8.encode(_fixedEncryptionKey)).bytes;
      
      // Decrypt (XOR with same key)
      final decrypted = <int>[];
      for (var i = 0; i < dataToDecrypt.length; i++) {
        decrypted.add(dataToDecrypt[i] ^ keyHash[i % keyHash.length]);
      }
      
      try {
        return utf8.decode(decrypted);
      } catch (e) {
        throw ValidationException(
          'Decryption failed: invalid UTF-8 data. '
          'The backup file may be corrupted or was created with a different encryption key.'
        );
      }
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw BackupException('Decryption failed: ${e.toString()}', e);
    }
  }


  /// Check if backup version is compatible
  bool _isVersionCompatible(String backupVersion) {
    // For now, only accept exact version match
    // In future, could support backward compatibility
    return backupVersion == _backupVersion;
  }

  /// Get device model for metadata
  Future<String> _getDeviceModel() async {
    try {
      if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}

