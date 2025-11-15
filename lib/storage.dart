import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gratitude_stars.dart';
import 'utils/compression_utils.dart';

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
  static Future<List<GratitudeStar>> loadGratitudeStars() async {
    try {
      // Try secure storage first (encrypted)
      final encryptedData = await _secureStorage.read(key: _starsKey);

      if (encryptedData != null) {
        // Decrypt and parse
        final starsJsonList = json.decode(encryptedData) as List;
        return starsJsonList.map((starJson) {
          return GratitudeStar.fromJson(starJson);
        }).toList();
      }

      // Fallback: Check old unencrypted storage for migration
      final prefs = await SharedPreferences.getInstance();
      final oldStarsJson = prefs.getStringList(_starsKey);

      if (oldStarsJson != null && oldStarsJson.isNotEmpty) {
        print('📦 Migrating ${oldStarsJson.length} stars from unencrypted to encrypted storage');

        // Parse old data
        final stars = oldStarsJson.map((starString) {
          final starData = json.decode(starString);
          return GratitudeStar.fromJson(starData);
        }).toList();

        // SAFETY CHECK 1: Verify save succeeded
        final saveSucceeded = await saveGratitudeStars(stars);

        if (!saveSucceeded) {
          print('⚠️ Migration failed - keeping old data as backup');
          return stars;
        }

        // SAFETY CHECK 2: Verify we can read back encrypted data
        try {
          final encryptedData = await _secureStorage.read(key: _starsKey);
          if (encryptedData == null || encryptedData.isEmpty) {
            print('⚠️ Could not verify encrypted data - keeping old data as backup');
            return stars;
          }

          // Verify it parses correctly
          final verification = json.decode(encryptedData) as List;
          if (verification.length != stars.length) {
            print('⚠️ Encrypted data mismatch - keeping old data as backup');
            return stars;
          }
        } catch (e) {
          print('⚠️ Verification failed: $e - keeping old data as backup');
          return stars;
        }

        // ONLY NOW delete old unencrypted data
        await prefs.remove(_starsKey);
        print('✅ Migration complete - old data removed');

        return stars;
      }

      // No data found
      return [];
    } catch (e) {
      debugPrint('❌ Error loading gratitude stars: $e');
      return [];
    }
  }

  // Save gratitude stars to encrypted storage
  static Future<bool> saveGratitudeStars(List<GratitudeStar> stars) async {
    try {
      // Convert to JSON
      final starsJsonList = stars.map((star) => star.toJson()).toList();
      final jsonString = json.encode(starsJsonList);

      // Save encrypted
      await _secureStorage.write(key: _starsKey, value: jsonString);

      return true;
    } catch (e) {
      debugPrint('❌ Error saving gratitude stars: $e');
      return false;
    }
  }

  // Clear all encrypted data (called on sign out)
  static Future<void> clearAllData() async {
    try {
      await _secureStorage.delete(key: _starsKey);

      // Also clear SharedPreferences as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_starsKey);
      await prefs.remove('last_synced_at');
      await prefs.remove('anonymous_uid');
      await prefs.remove('local_data_owner_uid');

      print('🗑️ Cleared all local storage');
    } catch (e) {
      debugPrint('⚠️ Error clearing storage: $e');
    }
  }

  // Save last sync timestamp
  static Future<void> saveLastSyncTime(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_synced_at', timestamp.millisecondsSinceEpoch);
      print('💾 Saved last sync time: $timestamp');
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
      print('🗑️ Cleared last sync time');
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
      print('💾 Saved font scale: $scale');
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