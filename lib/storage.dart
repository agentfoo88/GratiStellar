import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'gratitude_stars.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  final String text;
  final double worldX; // Normalized coordinate 0.0-1.0
  final double worldY; // Normalized coordinate 0.0-1.0
  final int colorIndex; // Store index instead of Color for serialization
  final Color? customColor;  // Optional custom color
  final double size;
  final String id;
  final DateTime createdAt;
  final int glowPatternIndex;

  // Getter for actual color (custom or palette)
  Color get color => customColor ?? StarColors.getColor(colorIndex);

  GratitudeStar({
    required this.text,
    required this.worldX,
    required this.worldY,
    required this.colorIndex,
    this.customColor,
    this.size = 8.0,
    required this.id,
    required this.createdAt,
    required this.glowPatternIndex,
  });

  // Copy with new values
  GratitudeStar copyWith({
    String? text,
    double? worldX,
    double? worldY,
    int? colorIndex,
    Color? customColor,
    bool clearCustomColor = false,  // NEW: explicit flag to clear
    double? size,
    String? id,
    DateTime? createdAt,
    int? glowPatternIndex,
  }) {
    return GratitudeStar(
      text: text ?? this.text,
      worldX: worldX ?? this.worldX,
      worldY: worldY ?? this.worldY,
      colorIndex: colorIndex ?? this.colorIndex,
      customColor: clearCustomColor ? null : (customColor ?? this.customColor),  // FIXED
      size: size ?? this.size,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      glowPatternIndex: glowPatternIndex ?? this.glowPatternIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'worldX': worldX,
      'worldY': worldY,
      'colorIndex': colorIndex,
      'customColor': customColor?.toARGB32(),
      'size': size,
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'glowPatternIndex': glowPatternIndex,
    };
  }

  factory GratitudeStar.fromJson(Map<String, dynamic> json) {
    return GratitudeStar(
      text: json['text'],
      worldX: json['worldX'],
      worldY: json['worldY'],
      colorIndex: json['colorIndex'] ?? 0,
      customColor: json['customColor'] != null
          ? Color(json['customColor'])
          : null,
      size: json['size'] ?? 8.0,
      id: json['id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch
      ),
      glowPatternIndex: json['glowPatternIndex'] ?? 0,
    );
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