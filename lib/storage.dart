import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';  // ADD THIS - provides Color class
import 'gratitude_stars.dart';  // ADD THIS - provides StarColors

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
      'customColor': customColor?.value,
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

// Storage service for handling data persistence
class StorageService {
  static const String _starsKey = 'gratitude_stars';

  // Load gratitude stars from storage
  static Future<List<GratitudeStar>> loadGratitudeStars() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final starsJson = prefs.getStringList(_starsKey) ?? [];

      return starsJson.map((starString) {
        final starData = json.decode(starString);
        return GratitudeStar.fromJson(starData);
      }).toList();
    } catch (e) {
      // Using debugPrint for better Flutter integration
      debugPrint('Error loading gratitude stars: $e');
      return [];
    }
  }

  // Save gratitude stars to storage
  static Future<bool> saveGratitudeStars(List<GratitudeStar> stars) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final starsJson = stars.map((star) {
        return json.encode(star.toJson());
      }).toList();
      await prefs.setStringList(_starsKey, starsJson);
      return true;
    } catch (e) {
      debugPrint('Error saving gratitude stars: $e');
      return false;
    }
  }

  // Calculate statistics
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