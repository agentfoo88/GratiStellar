import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../galaxy_metadata.dart';
import '../../../../core/utils/app_logger.dart';

/// Local data source for galaxy metadata operations
class GalaxyLocalDataSource {
  static const String _galaxiesKey = 'galaxies_metadata';
  static const String _activeGalaxyKey = 'active_galaxy_id';

  final FlutterSecureStorage _secureStorage;

  GalaxyLocalDataSource({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Load all galaxy metadata from local storage
  Future<List<GalaxyMetadata>> loadGalaxies() async {
    try {
      final jsonString = await _secureStorage.read(key: _galaxiesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => GalaxyMetadata.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('⚠️ Error loading galaxies from local storage: $e');
      return [];
    }
  }

  /// Save all galaxy metadata to local storage
  Future<void> saveGalaxies(List<GalaxyMetadata> galaxies) async {
    try {
      final jsonList = galaxies.map((g) => g.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _secureStorage.write(key: _galaxiesKey, value: jsonString);
      AppLogger.data('💾 Saved ${galaxies.length} galaxies to local storage');
    } catch (e) {
      AppLogger.error('⚠️ Error saving galaxies to local storage: $e');
      rethrow;
    }
  }

  /// Get the active galaxy ID
  Future<String?> getActiveGalaxyId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeGalaxyKey);
    } catch (e) {
      AppLogger.error('⚠️ Error getting active galaxy ID: $e');
      return null;
    }
  }

  /// Set the active galaxy ID
  Future<void> setActiveGalaxyId(String galaxyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeGalaxyKey, galaxyId);
      AppLogger.success('✅ Set active galaxy: $galaxyId');
    } catch (e) {
      AppLogger.error('⚠️ Error setting active galaxy ID: $e');
      rethrow;
    }
  }

  /// Clear all galaxy data (used during sign out)
  Future<void> clearAll() async {
    try {
      await _secureStorage.delete(key: _galaxiesKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeGalaxyKey);
      AppLogger.data('🗑️ Cleared all galaxy data from local storage');
    } catch (e) {
      AppLogger.error('⚠️ Error clearing galaxy data: $e');
    }
  }
}