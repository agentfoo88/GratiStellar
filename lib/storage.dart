import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gratitude_stars.dart';
import 'utils/compression_utils.dart';
import 'core/utils/app_logger.dart';
import 'services/user_scoped_storage.dart';
import 'services/user_profile_manager.dart';
import 'galaxy_metadata.dart';

// Extension to add Gaussian distribution to Random
extension RandomGaussian on math.Random {
  double nextGaussian() {
    double u = 0, v = 0;
    while(u == 0) {
      u = nextDouble(); // Converting [0,1) to (0,1)
    }
    while(v == 0) {
      v = nextDouble();
    }
    return math.sqrt(-2.0 * math.log(u)) * math.cos(2.0 * math.pi * v);
  }
}

// Data model for a gratitude star with normalized coordinates
class GratitudeStar {
  final String id;
  final String text;
  final double worldX;
  final double worldY;
  final int colorPresetIndex;
  final Color? customColor;
  final double size;
  final DateTime createdAt;
  final DateTime updatedAt;  // Track last modification
  final int glowPatternIndex;
  final bool deleted;  // Soft delete flag
  final DateTime? deletedAt;  // Deletion timestamp
  final String galaxyId;

  // Animation Properties (added for performance)
  final double spinDirection;
  final double spinRate;
  final double pulseSpeedH;
  final double pulseSpeedV;
  final double pulsePhaseH;
  final double pulsePhaseV;
  final double pulseMinScaleH;
  final double pulseMinScaleV;

  // Getter for actual color (custom or palette)
  Color get color => customColor ?? StarColors.getColor(colorPresetIndex);

  GratitudeStar({
    required this.text,
    required this.worldX,
    required this.worldY,
    this.colorPresetIndex = 0,
    this.customColor,
    this.size = 12.0,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.glowPatternIndex = 0,
    this.deleted = false,
    this.deletedAt,
    this.galaxyId = 'default',
    required this.spinDirection,
    required this.spinRate,
    required this.pulseSpeedH,
    required this.pulseSpeedV,
    required this.pulsePhaseH,
    required this.pulsePhaseV,
    required this.pulseMinScaleH,
    required this.pulseMinScaleV,
  })  : id = id ?? _generateId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  // Generate a unique ID (simple implementation)
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        math.Random().nextInt(999999).toString();
  }

  // Copy with new values (single unified method)
  GratitudeStar copyWith({
    String? text,
    double? worldX,
    double? worldY,
    int? colorPresetIndex,
    Color? customColor,
    bool clearCustomColor = false,
    double? size,
    DateTime? updatedAt,
    bool? deleted,
    DateTime? deletedAt,
    String? galaxyId,
    double? spinDirection,
    double? spinRate,
    double? pulseSpeedH,
    double? pulseSpeedV,
    double? pulsePhaseH,
    double? pulsePhaseV,
    double? pulseMinScaleH,
    double? pulseMinScaleV,
  }) {
    return GratitudeStar(
      id: id,
      text: text ?? this.text,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      glowPatternIndex: glowPatternIndex,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      galaxyId: galaxyId ?? this.galaxyId,
      spinDirection: spinDirection ?? this.spinDirection,
      spinRate: spinRate ?? this.spinRate,
      pulseSpeedH: pulseSpeedH ?? this.pulseSpeedH,
      pulseSpeedV: pulseSpeedV ?? this.pulseSpeedV,
      pulsePhaseH: pulsePhaseH ?? this.pulsePhaseH,
      pulsePhaseV: pulsePhaseV ?? this.pulsePhaseV,
      pulseMinScaleH: pulseMinScaleH ?? this.pulseMinScaleH,
      pulseMinScaleV: pulseMinScaleV ?? this.pulseMinScaleV,
      worldX: worldX ?? this.worldX,
      worldY: worldY ?? this.worldY,
      colorPresetIndex: colorPresetIndex ?? this.colorPresetIndex,
      customColor: clearCustomColor ? null : (customColor ?? this.customColor),
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toJson() {
    // Try to compress text if it\'s long enough
    final compressedText = CompressionUtils.compressText(text);
    final isCompressed = compressedText != null;

    return {
      'id': id,
      'text': isCompressed ? compressedText : text,
      'compressed': isCompressed, // Flag to indicate compression
      'worldX': worldX,
      'worldY': worldY,
      'colorPresetIndex': colorPresetIndex,
      'customColor': customColor?.toARGB32(),
      'size': size,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'glowPatternIndex': glowPatternIndex,
      'deleted': deleted,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
      'galaxyId': galaxyId,
      // Add new animation properties for serialization
      'spinDirection': spinDirection,
      'spinRate': spinRate,
      'pulseSpeedH': pulseSpeedH,
      'pulseSpeedV': pulseSpeedV,
      'pulsePhaseH': pulsePhaseH,
      'pulsePhaseV': pulsePhaseV,
      'pulseMinScaleH': pulseMinScaleH,
      'pulseMinScaleV': pulseMinScaleV,
    };
  }

  factory GratitudeStar.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] ?? DateTime
            .now()
            .millisecondsSinceEpoch
    );

    // Decompress text if it was compressed
    final rawText = json['text'] ?? '';
    final isCompressed = json['compressed'] ?? false;
    final text = isCompressed
        ? CompressionUtils.decompressText(rawText)
        : rawText;

    // Provide default random values for animation properties for old stars
    // This ensures existing stars still animate correctly without breaking
    final dummyRandom = math.Random(
        json['id'].hashCode); // Use star ID hash for consistent randoms

    return GratitudeStar(
      text: text,
      worldX: (json['worldX'] ?? 0.5).toDouble(),
      worldY: (json['worldY'] ?? 0.5).toDouble(),
      colorPresetIndex: json['colorPresetIndex'] ?? 0,
      customColor: json['customColor'] != null
          ? Color(json['customColor'])
          : null,
      size: json['size'] ?? 8.0,
      id: json['id'],
      createdAt: createdAt,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : createdAt,
      glowPatternIndex: json['glowPatternIndex'] ?? 0,
      deleted: json['deleted'] ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['deletedAt'])
          : null,
      galaxyId: json['galaxyId'] ?? 'default',
      // Deserialize new animation properties, with defaults for older stars
      spinDirection: (json['spinDirection'] ??
          (dummyRandom.nextBool() ? 1.0 : -1.0)).toDouble(),
      spinRate: (json['spinRate'] ?? (StarConfig.spinRateMin +
          dummyRandom.nextDouble() *
              (StarConfig.spinRateMax - StarConfig.spinRateMin))).toDouble(),
      pulseSpeedH: (json['pulseSpeedH'] ?? (StarConfig.pulseSpeedMin +
          dummyRandom.nextDouble() *
              (StarConfig.pulseSpeedMax - StarConfig.pulseSpeedMin)))
          .toDouble(),
      pulseSpeedV: (json['pulseSpeedV'] ?? (StarConfig.pulseSpeedMin +
          dummyRandom.nextDouble() *
              (StarConfig.pulseSpeedMax - StarConfig.pulseSpeedMin)))
          .toDouble(),
      pulsePhaseH: (json['pulsePhaseH'] ??
          dummyRandom.nextDouble() * 2 * math.pi).toDouble(),
      pulsePhaseV: (json['pulsePhaseV'] ??
          dummyRandom.nextDouble() * 2 * math.pi).toDouble(),
      pulseMinScaleH: (json['pulseMinScaleH'] ??
          dummyRandom.nextDouble() * StarConfig.pulseMinScaleMax).toDouble(),
      pulseMinScaleV: (json['pulseMinScaleV'] ??
          dummyRandom.nextDouble() * StarConfig.pulseMinScaleMax).toDouble(),
    );
  }
}

// Feedback item for user feedback collection
class FeedbackItem {
  final String id;
  final String userId;
  final String? userEmail;        // From auth if available
  final String? displayName;      // From auth if available
  final String type;              // 'bug', 'feature', 'general'
  final String message;
  final String? contactEmail;     // Optional email for anonymous users
  final String appVersion;
  final String platform;          // 'iOS' or 'Android'
  final DateTime createdAt;

  FeedbackItem({
    required this.userId,
    this.userEmail,
    this.displayName,
    required this.type,
    required this.message,
    this.contactEmail,
    required this.appVersion,
    required this.platform,
    String? id,
    DateTime? createdAt,
  })  : id = id ?? _generateId(),
        createdAt = createdAt ?? DateTime.now();

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        math.Random().nextInt(999999).toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'displayName': displayName,
      'type': type,
      'message': message,
      'contactEmail': contactEmail,
      'appVersion': appVersion,
      'platform': platform,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

// Storage service for handling data persistence with encryption
class StorageService {
  static const String _starsKey = 'gratitude_stars';

  // Secure storage for encryption
  static const _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Load gratitude stars from encrypted storage
  // Now uses user-scoped storage - migrates global data if found
  static Future<List<GratitudeStar>> loadGratitudeStars({UserProfileManager? userProfileManager}) async {
    try {
      // First, check if we need to migrate global storage to user-scoped storage
      await _migrateGlobalToUserScoped(userProfileManager);

      // Get current user ID
      String? userId;
      if (userProfileManager != null) {
        userId = await userProfileManager.getOrCreateActiveUserId();
      } else {
        // Fallback: try to get from auth service directly
        // This is for backward compatibility during transition
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('active_user_id');
      }

      // Load from user-scoped storage
      final stars = await UserScopedStorage.loadStars(userId);
      
      if (stars.isNotEmpty) {
        AppLogger.data('📥 Loaded ${stars.length} stars from user-scoped storage');
        return stars;
      }

      // Fallback: Check old unencrypted storage for migration (legacy support)
      final prefs = await SharedPreferences.getInstance();
      final oldStarsJson = prefs.getStringList(_starsKey);

      if (oldStarsJson != null && oldStarsJson.isNotEmpty) {
        AppLogger.data('📦 Migrating ${oldStarsJson.length} stars from unencrypted to user-scoped storage');

        // Parse old data
        final stars = oldStarsJson.map((starString) {
          final starData = json.decode(starString);
          return GratitudeStar.fromJson(starData);
        }).toList();

        // Migrate to user-scoped storage
        if (userId != null) {
          await UserScopedStorage.saveStars(userId, stars);
          await UserScopedStorage.trackUserHasData(userId);
        } else {
          // No user ID - save to global storage temporarily
          await saveGratitudeStars(stars);
        }

        // Delete old unencrypted data
        await prefs.remove(_starsKey);
        AppLogger.success('✅ Migration complete - old data migrated to user-scoped storage');

        return stars;
      }

      // No data found
      return [];
    } catch (e) {
      debugPrint('❌ Error loading gratitude stars: $e');
      return [];
    }
  }

  /// Migrate global storage to user-scoped storage
  /// 
  /// Checks if global storage exists and migrates it to current user's scoped storage
  static Future<void> _migrateGlobalToUserScoped(UserProfileManager? userProfileManager) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationDone = prefs.getBool('global_to_user_scoped_migration_done') ?? false;
      
      if (migrationDone) {
        // Migration already completed
        return;
      }

      // Check if global storage exists
      final encryptedData = await _secureStorage.read(key: _starsKey);
      
      if (encryptedData != null && encryptedData.isNotEmpty) {
        AppLogger.data('📦 Migrating global storage to user-scoped storage...');

        // Parse global data
        final decoded = json.decode(encryptedData);
        if (decoded is List) {
          final stars = decoded.map<GratitudeStar>((starJson) {
            return GratitudeStar.fromJson(starJson as Map<String, dynamic>);
          }).toList();

          // Get current user ID
          String? userId;
          if (userProfileManager != null) {
            userId = await userProfileManager.getOrCreateActiveUserId();
          } else {
            // Try to get from saved preferences
            final prefs = await SharedPreferences.getInstance();
            userId = prefs.getString('active_user_id');
            if (userId == null) {
              // Create anonymous profile for migration
              final deviceId = prefs.getString('device_id') ?? 'device_${DateTime.now().millisecondsSinceEpoch}';
              userId = 'anonymous_$deviceId';
              await prefs.setString('active_user_id', userId);
            }
          }

          if (stars.isNotEmpty) {
            // Save to user-scoped storage
            await UserScopedStorage.saveStars(userId, stars);
            await UserScopedStorage.trackUserHasData(userId);
            
            // Also migrate galaxies if they exist (check global galaxy storage)
            try {
              final galaxyKey = 'galaxies_metadata';
              final galaxyData = await _secureStorage.read(key: galaxyKey);
              if (galaxyData != null && galaxyData.isNotEmpty) {
                final decoded = json.decode(galaxyData);
                if (decoded is List) {
                  final galaxies = decoded.map((g) => GalaxyMetadata.fromJson(g as Map<String, dynamic>)).toList();
                  if (galaxies.isNotEmpty) {
                    await UserScopedStorage.saveGalaxies(userId, galaxies);
                    AppLogger.data('📦 Migrated ${galaxies.length} galaxies to user-scoped storage');
                  }
                }
              }
            } catch (e) {
              AppLogger.warning('⚠️ Could not migrate galaxies: $e');
            }

            // Mark migration as done
            await prefs.setBool('global_to_user_scoped_migration_done', true);
            
            // Keep global storage as backup for now (can be cleared later)
            AppLogger.success('✅ Migrated ${stars.length} stars to user-scoped storage for user: $userId');
          }
        }
      } else {
        // No global data - mark migration as done
        await prefs.setBool('global_to_user_scoped_migration_done', true);
      }
    } catch (e) {
      AppLogger.error('⚠️ Error migrating global to user-scoped storage: $e');
      // Don't throw - allow app to continue
    }
  }

  // Save gratitude stars to encrypted storage
  // Now uses user-scoped storage when userId is provided
  static Future<bool> saveGratitudeStars(
    List<GratitudeStar> stars, {
    UserProfileManager? userProfileManager,
    String? userId,
  }) async {
    try {
      // Determine user ID
      String? finalUserId = userId;
      if (finalUserId == null && userProfileManager != null) {
        finalUserId = await userProfileManager.getOrCreateActiveUserId();
      }

      if (finalUserId != null) {
        // Use user-scoped storage
        final success = await UserScopedStorage.saveStars(finalUserId, stars);
        if (success) {
          await UserScopedStorage.trackUserHasData(finalUserId);
        }
        return success;
      } else {
        // Fallback to global storage (backward compatibility)
        final starsJsonList = stars.map((star) => star.toJson()).toList();
        final jsonString = json.encode(starsJsonList);
        await _secureStorage.write(key: _starsKey, value: jsonString);
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error saving gratitude stars: $e');
      return false;
    }
  }

  // Clear all encrypted data (called on sign out)
  static Future<void> clearAllData() async {
    try {
      // Get current user ID from SharedPreferences (fallback method)
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('active_user_id');
      
      // If no active user ID, try to get device ID for anonymous users
      if (userId == null) {
        userId = prefs.getString('device_id');
        if (userId != null) {
          userId = 'anonymous_$userId';
        }
      }
      
      // Clear user-scoped storage for current user if we have a userId
      if (userId != null) {
        await UserScopedStorage.clearUserData(userId);
      }
      
      // Also clear old global storage keys
      await _secureStorage.delete(key: _starsKey);

      // Also clear SharedPreferences as backup
      await prefs.remove(_starsKey);
      await prefs.remove('last_synced_at');
      await prefs.remove('anonymous_uid');
      await prefs.remove('local_data_owner_uid');
      await prefs.remove('active_user_id');

      // Clear reminder preferences on sign-out
      await prefs.remove('reminder_enabled');
      await prefs.remove('reminder_hour');
      await prefs.remove('reminder_minute');
      await prefs.remove('reminder_prompt_shown');

      // Clear default color preferences on sign-out
      await prefs.remove(_defaultColorPresetKey);
      await prefs.remove(_defaultColorCustomKey);

      AppLogger.data('🗑️ Cleared all local storage');
    } catch (e) {
      debugPrint('⚠️ Error clearing storage: $e');
    }
  }

  // Save last sync timestamp
  static Future<void> saveLastSyncTime(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_synced_at', timestamp.millisecondsSinceEpoch);
      AppLogger.sync('💾 Saved last sync time: $timestamp');
    } catch (e) {
      debugPrint('⚠️ Error saving last sync time: $e');
    }
  }

  // Get last sync timestamp
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_synced_at');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Error getting last sync time: $e');
      return null;
    }
  }

  // Clear last sync timestamp
  static Future<void> clearLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_synced_at');
      AppLogger.sync('🗑️ Cleared last sync time');
    } catch (e) {
      debugPrint('⚠️ Error clearing last sync time: $e');
    }
  }

  // Font scale preference
  static const String _fontScaleKey = 'user_font_scale';

  static Future<void> saveFontScale(double scale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontScaleKey, scale);
      AppLogger.data('💾 Saved font scale: $scale');
    } catch (e) {
      debugPrint('⚠️ Error saving font scale: $e');
    }
  }

  static Future<double> getFontScale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_fontScaleKey) ?? 1.0; // Default 100%
    } catch (e) {
      debugPrint('⚠️ Error getting font scale: $e');
      return 1.0;
    }
  }

  // Default color preference
  static const String _defaultColorPresetKey = 'default_color_preset_index';
  static const String _defaultColorCustomKey = 'default_color_custom_argb';

  /// Get default color preference
  /// Returns tuple: (presetIndex, customColor)
  /// - (int, null) = preset color selected
  /// - (null, Color) = custom color selected
  /// - null = no default set
  static Future<(int?, Color?)?> getDefaultColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetIndex = prefs.getInt(_defaultColorPresetKey);
      final customArgb = prefs.getInt(_defaultColorCustomKey);

      if (presetIndex != null) {
        // Validate preset index is within bounds
        if (presetIndex >= 0 && presetIndex < StarColors.palette.length) {
          return (presetIndex, null);
        }
        // Invalid index, clear it
        await prefs.remove(_defaultColorPresetKey);
        return null;
      } else if (customArgb != null) {
        return (null, Color(customArgb));
      }
      return null; // No default set
    } catch (e) {
      debugPrint('⚠️ Error getting default color: $e');
      return null;
    }
  }

  /// Save default preset color by index
  static Future<void> saveDefaultPresetColor(int presetIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_defaultColorPresetKey, presetIndex);
      await prefs.remove(_defaultColorCustomKey); // Clear custom
      AppLogger.data('💾 Saved default preset color: $presetIndex');
    } catch (e) {
      debugPrint('⚠️ Error saving default preset color: $e');
    }
  }

  /// Save default custom color
  static Future<void> saveDefaultCustomColor(Color color) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_defaultColorCustomKey, color.toARGB32());
      await prefs.remove(_defaultColorPresetKey); // Clear preset
      AppLogger.data('💾 Saved default custom color: ${color.toARGB32()}');
    } catch (e) {
      debugPrint('⚠️ Error saving default custom color: $e');
    }
  }

  /// Clear default color preference
  static Future<void> clearDefaultColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_defaultColorPresetKey);
      await prefs.remove(_defaultColorCustomKey);
      AppLogger.data('🗑️ Cleared default color');
    } catch (e) {
      debugPrint('⚠️ Error clearing default color: $e');
    }
  }

  // Calculate statistics (unchanged)
  static int getTotalStars(List<GratitudeStar> stars) => stars.length;

  static int getThisWeekStars(List<GratitudeStar> stars) {
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));
    return stars.where((star) => star.createdAt.isAfter(weekAgo)).length;
  }

  static bool getAddedToday(List<GratitudeStar> stars) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return stars.any((star) =>
    star.createdAt.isAfter(today) &&
        star.createdAt.isBefore(today.add(Duration(days: 1)))
    );
  }
}

/// Backup data model for export/import functionality
class BackupData {
  final String version;
  final String appVersion;
  final DateTime createdAt;
  final List<GratitudeStar> stars;
  final List<Map<String, dynamic>> galaxies;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic>? metadata;
  final String? activeGalaxyId;

  BackupData({
    required this.version,
    required this.appVersion,
    required this.createdAt,
    required this.stars,
    required this.galaxies,
    required this.preferences,
    this.metadata,
    this.activeGalaxyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'appVersion': appVersion,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'stars': stars.map((star) => star.toJson()).toList(),
      'galaxies': galaxies,
      'preferences': preferences,
      'metadata': metadata,
      'activeGalaxyId': activeGalaxyId,
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as String,
      appVersion: json['appVersion'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      stars: (json['stars'] as List)
          .map((starJson) => GratitudeStar.fromJson(starJson))
          .toList(),
      galaxies: List<Map<String, dynamic>>.from(json['galaxies'] ?? []),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      activeGalaxyId: json['activeGalaxyId'] as String?,
    );
  }

  /// Get a summary of backup contents for display
  /// Excludes deleted galaxies from count
  String getSummary() {
    final starCount = stars.where((s) => !s.deleted).length;
    final deletedCount = stars.where((s) => s.deleted).length;
    
    // Filter out deleted galaxies from count
    final activeGalaxyCount = galaxies.where((g) {
      final deleted = g['deleted'] as bool? ?? false;
      return !deleted;
    }).length;
    
    final parts = <String>[];
    parts.add('$starCount gratitude${starCount == 1 ? '' : 's'}');
    if (deletedCount > 0) {
      parts.add('$deletedCount deleted');
    }
    parts.add('$activeGalaxyCount ${activeGalaxyCount == 1 ? 'galaxy' : 'galaxies'}');
    
    return parts.join(', ');
  }

  /// Validate backup data integrity
  bool validate() {
    try {
      // Check version format
      if (version.isEmpty) return false;
      
      // Check app version
      if (appVersion.isEmpty) return false;
      
      // Validate stars have required fields
      for (final star in stars) {
        if (star.id.isEmpty || star.text.isEmpty) return false;
      }
      
      // Validate galaxies have required fields
      for (final galaxy in galaxies) {
        if (galaxy['id'] == null || galaxy['name'] == null) return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}