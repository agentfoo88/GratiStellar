import 'package:flutter/material.dart';

/// Represents the four seasons
enum Season {
  spring,
  summer,
  autumn,
  winter;

  String get displayName {
    switch (this) {
      case Season.spring:
        return 'Spring';
      case Season.summer:
        return 'Summer';
      case Season.autumn:
        return 'Autumn';
      case Season.winter:
        return 'Winter';
    }
  }

  String get icon {
    switch (this) {
      case Season.spring:
        return '🌿';
      case Season.summer:
        return '☀️';
      case Season.autumn:
        return '🍂';
      case Season.winter:
        return '❄️';
    }
  }
}

/// Represents the hemisphere (north or south)
enum Hemisphere {
  north,
  south;
}

/// Configuration for seasonal gradient generation
/// Uses base gradient (66%) + seasonal tint (33%) blending system
class SeasonConfig {
  // Base gradient stops (66% of final gradient) - App's blue-purple starfield
  static const List<Color> baseGradientStops = [
    Color(0xFF2D1B69), // Top (0%): Deep purple-blue - rgb(45, 27, 105)
    Color(0xFF1E3A8A), // 30%: Rich blue - rgb(30, 58, 138)
    Color(0xFF1E40AF), // 70%: Slightly lighter blue - rgb(30, 64, 175)
    Color(0xFF3730A3), // Bottom (100%): Purple-blue - rgb(55, 48, 163)
  ];

  // Seasonal tint colors (33% of final gradient) - Overlays
  static const Color springTintColor = Color(0xFF1E4A3A); // Greenish tint - rgb(30, 74, 58)
  static const Color summerTintColor = Color(0xFF5A3A3A); // Reddish tint - rgb(90, 58, 58)
  static const Color autumnTintColor = Color(0xFF4A3A5A); // Purpleish tint - rgb(74, 58, 90)
  static const Color winterTintColor = Color(0xFF1E3A5A); // Blueish tint - rgb(30, 58, 90)

  /// Get seasonal tint color
  static Color getTintColor(Season season) {
    switch (season) {
      case Season.spring:
        return springTintColor;
      case Season.summer:
        return summerTintColor;
      case Season.autumn:
        return autumnTintColor;
      case Season.winter:
        return winterTintColor;
    }
  }

  /// Get base color for a season (deprecated - use getTintColor instead)
  @Deprecated('Use getTintColor instead')
  static Color getBaseColor(Season season) {
    return getTintColor(season);
  }

  /// Convert hex color to RGB array [r, g, b]
  static List<int> hexToRgb(Color color) {
    return [
      (color.r * 255.0).round().clamp(0, 255),
      (color.g * 255.0).round().clamp(0, 255),
      (color.b * 255.0).round().clamp(0, 255),
    ];
  }

  /// Convert RGB values to Color
  static Color rgbToColor(int r, int g, int b) {
    return Color.fromARGB(255, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
  }

  /// Interpolate between two colors
  /// Returns blended color based on factor (0.0 = color1, 1.0 = color2)
  static Color interpolateColor(Color color1, Color color2, double factor) {
    final rgb1 = hexToRgb(color1);
    final rgb2 = hexToRgb(color2);

    final r = rgb1[0] + (rgb2[0] - rgb1[0]) * factor;
    final g = rgb1[1] + (rgb2[1] - rgb1[1]) * factor;
    final b = rgb1[2] + (rgb2[2] - rgb1[2]) * factor;

    return rgbToColor(r.round(), g.round(), b.round());
  }

  /// Blend base gradient with seasonal tint
  /// Formula: Final RGB = (Base RGB × 0.66) + (Seasonal Tint RGB × 0.33)
  static Color blendWithTint(Color baseColor, Color tintColor) {
    final baseRgb = hexToRgb(baseColor);
    final tintRgb = hexToRgb(tintColor);

    final r = (baseRgb[0] * 0.66 + tintRgb[0] * 0.33).round();
    final g = (baseRgb[1] * 0.66 + tintRgb[1] * 0.33).round();
    final b = (baseRgb[2] * 0.66 + tintRgb[2] * 0.33).round();

    return rgbToColor(r, g, b);
  }

  /// Generate seasonal gradient with base gradient + seasonal tint blending
  /// Returns 4 stops: [0%, 30%, 70%, 100%]
  static List<Color> generateSeasonalGradient(
    Season season,
    double progress,
    Season nextSeason,
  ) {
    // Interpolate seasonal tint based on progress through season
    final currentTint = getTintColor(season);
    final nextTint = getTintColor(nextSeason);
    final blendedTint = interpolateColor(currentTint, nextTint, progress);

    // Blend each base gradient stop with the seasonal tint
    return baseGradientStops.map((baseColor) {
      return blendWithTint(baseColor, blendedTint);
    }).toList();
  }

  /// Generate gradient stops for manual season override (no interpolation)
  /// Returns 4 stops: [0%, 30%, 70%, 100%]
  static List<Color> generateGradientStops(Season season) {
    final tintColor = getTintColor(season);

    // Blend each base gradient stop with the seasonal tint
    return baseGradientStops.map((baseColor) {
      return blendWithTint(baseColor, tintColor);
    }).toList();
  }

  /// Get next season in cycle
  static Season getNextSeason(Season season) {
    switch (season) {
      case Season.spring:
        return Season.summer;
      case Season.summer:
        return Season.autumn;
      case Season.autumn:
        return Season.winter;
      case Season.winter:
        return Season.spring;
    }
  }

  /// Calculate current season based on date and hemisphere
  /// Matches website's calculateSeason() function
  static SeasonInfo calculateSeason(DateTime date, Hemisphere hemisphere) {
    final year = date.year;
    final month = date.month; // 1-12
    final day = date.day;

    Season seasonName;
    DateTime seasonStart;
    DateTime nextSeasonStart;

    if (hemisphere == Hemisphere.north) {
      // Northern Hemisphere seasons
      if ((month == 3 && day >= 20) || 
          (month == 4) || 
          (month == 5) || 
          (month == 6 && day <= 20)) {
        // Spring: Mar 20 - Jun 20
        seasonName = Season.spring;
        seasonStart = DateTime(year, 3, 20);
        nextSeasonStart = DateTime(year, 6, 21);
      } else if ((month == 6 && day >= 21) || 
                 (month == 7) || 
                 (month == 8) || 
                 (month == 9 && day <= 21)) {
        // Summer: Jun 21 - Sep 21
        seasonName = Season.summer;
        seasonStart = DateTime(year, 6, 21);
        nextSeasonStart = DateTime(year, 9, 22);
      } else if ((month == 9 && day >= 22) || 
                 (month == 10) || 
                 (month == 11) || 
                 (month == 12 && day <= 20)) {
        // Autumn: Sep 22 - Dec 20
        seasonName = Season.autumn;
        seasonStart = DateTime(year, 9, 22);
        nextSeasonStart = DateTime(year, 12, 21);
      } else {
        // Winter: Dec 21 - Mar 19
        seasonName = Season.winter;
        seasonStart = DateTime(year, 12, 21);
        nextSeasonStart = DateTime(year, 3, 20);
      }
    } else {
      // Southern Hemisphere (reversed seasons)
      if ((month == 9 && day >= 22) || 
          (month == 10) || 
          (month == 11) || 
          (month == 12 && day <= 20)) {
        // Spring: Sep 22 - Dec 20
        seasonName = Season.spring;
        seasonStart = DateTime(year, 9, 22);
        nextSeasonStart = DateTime(year, 12, 21);
      } else if ((month == 12 && day >= 21) || 
                 (month == 1) || 
                 (month == 2) || 
                 (month == 3 && day <= 19)) {
        // Summer: Dec 21 - Mar 19
        seasonName = Season.summer;
        seasonStart = DateTime(year, 12, 21);
        nextSeasonStart = DateTime(year, 3, 20);
      } else if ((month == 3 && day >= 20) || 
                 (month == 4) || 
                 (month == 5) || 
                 (month == 6 && day <= 20)) {
        // Autumn: Mar 20 - Jun 20
        seasonName = Season.autumn;
        seasonStart = DateTime(year, 3, 20);
        nextSeasonStart = DateTime(year, 6, 21);
      } else {
        // Winter: Jun 21 - Sep 21
        seasonName = Season.winter;
        seasonStart = DateTime(year, 6, 21);
        nextSeasonStart = DateTime(year, 9, 22);
      }
    }

    // Calculate progress through current season (0-1)
    final totalSeasonDuration = nextSeasonStart.difference(seasonStart).inMilliseconds;
    final elapsed = date.difference(seasonStart).inMilliseconds;
    final progress = (elapsed / totalSeasonDuration).clamp(0.0, 1.0);

    return SeasonInfo(
      season: seasonName,
      progress: progress,
      nextSeason: getNextSeason(seasonName),
    );
  }
}

/// Information about the current season
class SeasonInfo {
  final Season season;
  final double progress; // 0.0 to 1.0
  final Season nextSeason;

  SeasonInfo({
    required this.season,
    required this.progress,
    required this.nextSeason,
  });
}

