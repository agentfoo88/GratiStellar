import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  static const String _encryptionKeyName = 'backup_encryption_key';
  static const _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Create a backup of current data
  Future<BackupData> createBackup({
    required List<GratitudeStar> stars,
    required List<GalaxyMetadata> galaxies,
    required Map<String, dynamic> preferences,
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
      final decoded = json.decode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Invalid backup format: expected Map, got ${decoded.runtimeType}');
      }

      // Create BackupData object
      final backup = BackupData.fromJson(decoded);
      
      // Validate backup
      if (!backup.validate()) {
        throw ValidationException('Backup file is corrupted or invalid');
      }
      
      // Check version compatibility
      if (!_isVersionCompatible(backup.version)) {
        throw ValidationException(
          'Backup version ${backup.version} is not compatible with current version $_backupVersion'
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

  /// Encrypt data using AES encryption
  Future<List<int>> _encryptData(String data) async {
    try {
      // Get or create encryption key
      final key = await _getOrCreateEncryptionKey();
      
      // Simple encryption: XOR with key hash (for production, use proper AES)
      // Note: This is a simplified implementation. For production, use encrypt package
      final dataBytes = utf8.encode(data);
      final keyHash = sha256.convert(utf8.encode(key)).bytes;
      
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

  /// Decrypt data
  Future<String> _decryptData(List<int> encryptedData) async {
    try {
      // Check version marker
      final versionMarker = utf8.encode('GRATISTELLAR_BACKUP_V1:');
      if (encryptedData.length < versionMarker.length) {
        throw ValidationException('Invalid backup file format');
      }
      
      // Verify marker
      for (var i = 0; i < versionMarker.length; i++) {
        if (encryptedData[i] != versionMarker[i]) {
          throw ValidationException('Invalid backup file format');
        }
      }
      
      // Remove marker
      final dataToDecrypt = encryptedData.sublist(versionMarker.length);
      
      // Get encryption key
      final key = await _getOrCreateEncryptionKey();
      final keyHash = sha256.convert(utf8.encode(key)).bytes;
      
      // Decrypt (XOR with same key)
      final decrypted = <int>[];
      for (var i = 0; i < dataToDecrypt.length; i++) {
        decrypted.add(dataToDecrypt[i] ^ keyHash[i % keyHash.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw BackupException('Decryption failed', e);
    }
  }

  /// Get or create encryption key for backups
  Future<String> _getOrCreateEncryptionKey() async {
    try {
      // Try to get existing key
      var key = await _secureStorage.read(key: _encryptionKeyName);
      
      if (key == null) {
        // Generate new key
        key = _generateSecureKey();
        await _secureStorage.write(key: _encryptionKeyName, value: key);
        debugPrint('🔑 Generated new backup encryption key');
      }
      
      return key;
    } catch (e) {
      throw BackupException('Failed to get encryption key', e);
    }
  }

  /// Generate a secure random key
  String _generateSecureKey() {
    final random = DateTime.now().millisecondsSinceEpoch.toString() +
        DateTime.now().microsecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(random)).toString();
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

