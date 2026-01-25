import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../galaxy_metadata.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../services/user_scoped_storage.dart';
import '../../../../services/user_profile_manager.dart';

/// Local data source for galaxy metadata operations
/// 
/// Uses user-scoped storage when UserProfileManager is provided,
/// falls back to global storage for backward compatibility.
class GalaxyLocalDataSource {
  static const String _galaxiesKey = 'galaxies_metadata';
  static const String _activeGalaxyKey = 'active_galaxy_id';

  final FlutterSecureStorage _secureStorage;
  final UserProfileManager? _userProfileManager;

  GalaxyLocalDataSource({
    FlutterSecureStorage? secureStorage,
    UserProfileManager? userProfileManager,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _userProfileManager = userProfileManager;

  /// Load all galaxy metadata from local storage
  Future<List<GalaxyMetadata>> loadGalaxies() async {
    if (_userProfileManager != null) {
      // Use user-scoped storage
      try {
        final userId = await _userProfileManager.getOrCreateActiveUserId();
        return await UserScopedStorage.loadGalaxies(userId);
      } catch (e) {
        AppLogger.error('⚠️ Error loading galaxies from user-scoped storage: $e');
        return [];
      }
    } else {
      // Fallback to global storage (backward compatibility)
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

        // If it's a decryption error, clear corrupted data
        if (e.toString().contains('BAD_DECRYPT') || e.toString().contains('BadPaddingException')) {
          AppLogger.warning('🔧 Detected encryption error - clearing corrupted galaxy data');
          try {
            await _secureStorage.delete(key: _galaxiesKey);
            AppLogger.success('✅ Cleared corrupted galaxy encryption data');
          } catch (clearError) {
            AppLogger.error('⚠️ Error clearing corrupted data: $clearError');
          }
        }

        return [];
      }
    }
  }

  /// Save all galaxy metadata to local storage
  Future<void> saveGalaxies(List<GalaxyMetadata> galaxies) async {
    if (_userProfileManager != null) {
      // Use user-scoped storage
      try {
        final userId = await _userProfileManager.getOrCreateActiveUserId();
        await UserScopedStorage.saveGalaxies(userId, galaxies);
        await UserScopedStorage.trackUserHasData(userId);
      } catch (e) {
        AppLogger.error('⚠️ Error saving galaxies to user-scoped storage: $e');
        rethrow;
      }
    } else {
      // Fallback to global storage (backward compatibility)
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
  }

  /// Get the active galaxy ID (user-scoped)
  Future<String?> getActiveGalaxyId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? activeId;
      if (_userProfileManager != null) {
        // Use user-scoped storage
        final userId = await _userProfileManager.getOrCreateActiveUserId();
        final userScopedKey = '${_activeGalaxyKey}_$userId';
        activeId = prefs.getString(userScopedKey);
      } else {
        // Fallback to global storage (backward compatibility)
        activeId = prefs.getString(_activeGalaxyKey);
      }
      
      // Return null for empty strings
      return (activeId == null || activeId.isEmpty) ? null : activeId;
    } catch (e) {
      AppLogger.error('⚠️ Error getting active galaxy ID: $e');
      return null;
    }
  }

  /// Set the active galaxy ID (user-scoped)
  Future<void> setActiveGalaxyId(String galaxyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_userProfileManager != null) {
        // Use user-scoped storage
        final userId = await _userProfileManager.getOrCreateActiveUserId();
        final userScopedKey = '${_activeGalaxyKey}_$userId';
        await prefs.setString(userScopedKey, galaxyId);
        AppLogger.success('✅ Set active galaxy: $galaxyId for user: $userId');
      } else {
        // Fallback to global storage (backward compatibility)
        await prefs.setString(_activeGalaxyKey, galaxyId);
        AppLogger.success('✅ Set active galaxy: $galaxyId');
      }
    } catch (e) {
      AppLogger.error('⚠️ Error setting active galaxy ID: $e');
      rethrow;
    }
  }

  /// Clear all galaxy data (used during sign out)
  ///
  /// [userId] - Optional user ID to clear data for. If not provided,
  /// will attempt to get the current user ID (which may fail after sign-out).
  Future<void> clearAll({String? userId}) async {
    try {
      // Clear global storage (backward compatibility)
      await _secureStorage.delete(key: _galaxiesKey);
      final prefs = await SharedPreferences.getInstance();

      if (_userProfileManager != null) {
        // Get user ID if not provided
        final targetUserId = userId ?? await _userProfileManager.getOrCreateActiveUserId();

        // Clear user-scoped active galaxy ID
        final userScopedKey = '${_activeGalaxyKey}_$targetUserId';
        await prefs.remove(userScopedKey);

        // CRITICAL: Also clear the user-scoped galaxy data from UserScopedStorage
        // This was missing before, causing galaxies to persist after sign-out
        final galaxiesKey = 'galaxies_metadata_$targetUserId';
        await _secureStorage.delete(key: galaxiesKey);

        AppLogger.data('🗑️ Cleared galaxy data for user: $targetUserId');
      } else {
        // Fallback to global storage (backward compatibility)
        await prefs.remove(_activeGalaxyKey);
        AppLogger.data('🗑️ Cleared all galaxy data from global storage');
      }
    } catch (e) {
      AppLogger.error('⚠️ Error clearing galaxy data: $e');
    }
  }
}