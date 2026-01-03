import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage.dart'; // For GratitudeStar
import '../galaxy_metadata.dart';
import '../core/utils/app_logger.dart';

/// User-scoped storage service for isolating data per user
/// 
/// Provides encrypted storage that is scoped to specific user IDs,
/// allowing multiple users to have local data simultaneously.
class UserScopedStorage {
  // Secure storage for encryption
  static const _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Base keys for different data types
  static const String _starsBaseKey = 'gratitude_stars';
  static const String _galaxiesBaseKey = 'galaxies_metadata';
  static const String _deviceIdKey = 'device_id';
  static const String _displayNameBaseKey = 'display_name';

  /// Generate a user-scoped storage key
  /// 
  /// [baseKey] - Base key for the data type (e.g., 'gratitude_stars')
  /// [userId] - User ID (null for anonymous users)
  /// 
  /// Returns a scoped key like 'gratitude_stars_user123' or 'gratitude_stars_anonymous_device456'
  static Future<String> _getUserKey(String baseKey, String? userId) async {
    if (userId == null) {
      // Anonymous user - use device-specific ID
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_deviceIdKey);
      
      if (deviceId == null) {
        // Generate a unique device ID
        deviceId = _generateDeviceId();
        await prefs.setString(_deviceIdKey, deviceId);
        AppLogger.data('📱 Generated device ID: $deviceId');
      }
      
      return '${baseKey}_anonymous_$deviceId';
    }
    
    return '${baseKey}_$userId';
  }

  /// Generate a unique device ID
  static String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(999999);
    return 'device_${timestamp}_$random';
  }

  /// Load gratitude stars for a specific user
  static Future<List<GratitudeStar>> loadStars(String? userId) async {
    try {
      final key = await _getUserKey(_starsBaseKey, userId);
      final encryptedData = await _secureStorage.read(key: key);

      if (encryptedData == null || encryptedData.isEmpty) {
        return [];
      }

      // Decrypt and parse
      final decoded = json.decode(encryptedData);
      if (decoded is! List) {
        AppLogger.error('Invalid stars format: expected List, got ${decoded.runtimeType}');
        throw FormatException('Invalid stars data format');
      }
      
      final stars = decoded.map<GratitudeStar>((starJson) {
        return GratitudeStar.fromJson(starJson as Map<String, dynamic>);
      }).toList();
      
      AppLogger.data('📥 Loaded ${stars.length} stars for user: ${userId ?? 'anonymous'}');
      return stars;
    } catch (e) {
      AppLogger.error('⚠️ Error loading stars for user ${userId ?? 'anonymous'}: $e');
      
      // If it's a decryption error, clear corrupted data
      if (e.toString().contains('BAD_DECRYPT') || e.toString().contains('BadPaddingException')) {
        AppLogger.warning('🔧 Detected encryption error - clearing corrupted data');
        try {
          final key = await _getUserKey(_starsBaseKey, userId);
          await _secureStorage.delete(key: key);
          AppLogger.success('✅ Cleared corrupted encrypted data');
        } catch (clearError) {
          AppLogger.error('⚠️ Error clearing corrupted data: $clearError');
        }
      }
      
      return [];
    }
  }

  /// Save gratitude stars for a specific user
  static Future<bool> saveStars(String? userId, List<GratitudeStar> stars) async {
    try {
      final key = await _getUserKey(_starsBaseKey, userId);
      
      // Convert to JSON
      final starsJsonList = stars.map((star) => star.toJson()).toList();
      final jsonString = json.encode(starsJsonList);

      // Save encrypted
      await _secureStorage.write(key: key, value: jsonString);
      
      AppLogger.data('💾 Saved ${stars.length} stars for user: ${userId ?? 'anonymous'}');
      return true;
    } catch (e) {
      AppLogger.error('❌ Error saving stars for user ${userId ?? 'anonymous'}: $e');
      return false;
    }
  }

  /// Load galaxy metadata for a specific user
  static Future<List<GalaxyMetadata>> loadGalaxies(String? userId) async {
    try {
      final key = await _getUserKey(_galaxiesBaseKey, userId);
      final jsonString = await _secureStorage.read(key: key);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final galaxies = jsonList
          .map((json) => GalaxyMetadata.fromJson(json as Map<String, dynamic>))
          .toList();
      
      AppLogger.data('📥 Loaded ${galaxies.length} galaxies for user: ${userId ?? 'anonymous'}');
      return galaxies;
    } catch (e) {
      AppLogger.error('⚠️ Error loading galaxies for user ${userId ?? 'anonymous'}: $e');

      // If it's a decryption error, clear corrupted data
      if (e.toString().contains('BAD_DECRYPT') || e.toString().contains('BadPaddingException')) {
        AppLogger.warning('🔧 Detected encryption error - clearing corrupted galaxy data');
        try {
          final key = await _getUserKey(_galaxiesBaseKey, userId);
          await _secureStorage.delete(key: key);
          AppLogger.success('✅ Cleared corrupted galaxy encryption data');
        } catch (clearError) {
          AppLogger.error('⚠️ Error clearing corrupted data: $clearError');
        }
      }

      return [];
    }
  }

  /// Save galaxy metadata for a specific user
  static Future<void> saveGalaxies(String? userId, List<GalaxyMetadata> galaxies) async {
    try {
      final key = await _getUserKey(_galaxiesBaseKey, userId);
      final jsonList = galaxies.map((g) => g.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await _secureStorage.write(key: key, value: jsonString);
      AppLogger.data('💾 Saved ${galaxies.length} galaxies for user: ${userId ?? 'anonymous'}');
    } catch (e) {
      AppLogger.error('⚠️ Error saving galaxies for user ${userId ?? 'anonymous'}: $e');
      rethrow;
    }
  }

  /// Clear all data for a specific user
  static Future<void> clearUserData(String userId) async {
    try {
      final starsKey = await _getUserKey(_starsBaseKey, userId);
      final galaxiesKey = await _getUserKey(_galaxiesBaseKey, userId);
      
      await _secureStorage.delete(key: starsKey);
      await _secureStorage.delete(key: galaxiesKey);
      
      // For anonymous users, clear display name (but preserve device_id)
      if (userId.startsWith('anonymous_')) {
        final deviceId = await getDeviceIdFromUserId(userId);
        if (deviceId != null) {
          // Clear display name for this specific device ID
          final displayNameKey = '${_displayNameBaseKey}_anonymous_$deviceId';
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(displayNameKey);
          
          // NOTE: device_id is NOT cleared - it's persistent per device
          // This allows multiple anonymous profiles on the same device
          
          AppLogger.data('🗑️ Cleared display name for anonymous user (device_id preserved)');
        }
      }
      
      // Clear user-scoped onboarding state
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed_$userId');
      await prefs.remove('age_gate_passed_$userId');
      
      // Untrack user from local_user_ids
      await untrackUser(userId);
      
      AppLogger.data('🗑️ Cleared all data for user: $userId');
    } catch (e) {
      AppLogger.error('⚠️ Error clearing data for user $userId: $e');
      rethrow;
    }
  }

  /// Get list of user IDs that have local data
  /// 
  /// Scans storage for all user-scoped keys and extracts user IDs
  static Future<List<String>> getLocalUserIds() async {
    try {
      // Note: FlutterSecureStorage doesn't support listing all keys directly
      // We'll use SharedPreferences to track user IDs with data
      final prefs = await SharedPreferences.getInstance();
      final userIdsJson = prefs.getString('local_user_ids');
      
      if (userIdsJson == null || userIdsJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> userIdsList = json.decode(userIdsJson);
      return userIdsList.cast<String>();
    } catch (e) {
      AppLogger.error('⚠️ Error getting local user IDs: $e');
      return [];
    }
  }

  /// Track that a user has local data
  static Future<void> trackUserHasData(String userId) async {
    try {
      final userIds = await getLocalUserIds();
      if (!userIds.contains(userId)) {
        userIds.add(userId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('local_user_ids', json.encode(userIds));
        AppLogger.data('📝 Tracked user with data: $userId');
      }
    } catch (e) {
      AppLogger.error('⚠️ Error tracking user data: $e');
    }
  }

  /// Remove user from tracking when their data is cleared
  static Future<void> untrackUser(String userId) async {
    try {
      final userIds = await getLocalUserIds();
      userIds.remove(userId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_user_ids', json.encode(userIds));
      AppLogger.data('📝 Untracked user: $userId');
    } catch (e) {
      AppLogger.error('⚠️ Error untracking user: $e');
    }
  }

  /// Get anonymous user's display name from local storage
  /// 
  /// [deviceId] - The device ID (without 'anonymous_' prefix)
  /// Returns the display name or null if not set
  static Future<String?> getAnonymousDisplayName(String deviceId) async {
    try {
      final key = '${_displayNameBaseKey}_anonymous_$deviceId';
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(key);
      return name;
    } catch (e) {
      AppLogger.error('⚠️ Error getting anonymous display name: $e');
      return null;
    }
  }

  /// Set anonymous user's display name in local storage
  /// 
  /// [deviceId] - The device ID (without 'anonymous_' prefix)
  /// [name] - The display name to save
  static Future<void> setAnonymousDisplayName(String deviceId, String name) async {
    try {
      final key = '${_displayNameBaseKey}_anonymous_$deviceId';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, name);
      AppLogger.data('💾 Saved anonymous display name: $name for device: $deviceId');
    } catch (e) {
      AppLogger.error('⚠️ Error saving anonymous display name: $e');
      rethrow;
    }
  }

  /// Get device ID from a user ID (handles both Firebase UID and device-based IDs)
  /// 
  /// [userId] - The user ID (Firebase UID or device-based ID like 'anonymous_device_xxx')
  /// Returns the device ID (without 'anonymous_' prefix) or null if not found
  static Future<String?> getDeviceIdFromUserId(String userId) async {
    if (userId.startsWith('anonymous_')) {
      // Device-based anonymous ID (new format)
      return userId.replaceFirst('anonymous_', '');
    } else {
      // Firebase anonymous UID (old format) - get device ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_deviceIdKey);
    }
  }

  /// Get display name for a user (anonymous or authenticated)
  /// 
  /// [userId] - The user ID (null for anonymous, Firebase UID, or device-scoped ID)
  /// Returns the display name or default if not set
  static Future<String> getDisplayName(String? userId, {String defaultName = 'Grateful User'}) async {
    if (userId == null) {
      return defaultName;
    }
    
    // For authenticated users (email accounts), this will be handled by AuthService
    // We can't determine if it's an email user here, so we'll try to get device ID
    // If it's an email user, getDeviceIdFromUserId will return null, and we'll use default
    
    final deviceId = await getDeviceIdFromUserId(userId);
    if (deviceId == null) {
      // No device ID found - likely an email user or invalid userId
      return defaultName;
    }
    
    final name = await getAnonymousDisplayName(deviceId);
    return name ?? defaultName;
  }
}

