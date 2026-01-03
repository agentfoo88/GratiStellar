import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_logger.dart';
import '../../starfield.dart'; // For VanGoghConfig

/// Represents a palette preset with themed colors
class PalettePreset {
  final String id;
  final String l10nKey;
  final List<Color> colors;

  const PalettePreset({
    required this.id,
    required this.l10nKey,
    required this.colors,
  });
}

/// Configuration for palette presets with brightness validation
class PalettePresetConfig {
  // Background star max brightness calculation
  // Background stars: brightness range 0.25-0.65, multiplied by VanGoghConfig.brightnessMultiplier (0.8)
  // Max background brightness = 0.65 * 0.8 = 0.52
  static const double _backgroundStarMaxBrightness = 0.65 * VanGoghConfig.brightnessMultiplier; // 0.52
  
  // Minimum brightness for gratitude stars (must exceed background stars)
  // Add safety margin of 20% to ensure visibility
  static const double _minGratitudeStarBrightness = _backgroundStarMaxBrightness * 1.2; // ~0.624

  /// Calculate relative luminance of a color (WCAG formula)
  /// Returns value between 0.0 (darkest) and 1.0 (brightest)
  static double calculateRelativeLuminance(Color color) {
    // Use normalized RGB values (already in 0-1 range)
    final r = color.r;
    final g = color.g;
    final b = color.b;

    // Apply gamma correction
    final rLinear = r <= 0.03928 ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4) as double;
    final gLinear = g <= 0.03928 ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4) as double;
    final bLinear = b <= 0.03928 ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4) as double;

    // Calculate relative luminance using WCAG formula
    return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
  }

  /// Validate that a color meets minimum brightness requirement
  /// Returns true if color is bright enough to be visible against background stars
  static bool validateBrightness(Color color) {
    final luminance = calculateRelativeLuminance(color);
    return luminance >= _minGratitudeStarBrightness;
  }

  /// Ensure a color meets minimum brightness by boosting if needed
  /// Returns original color if already bright enough, otherwise boosted version
  static Color ensureMinimumBrightness(Color color, {double boostFactor = 0.15}) {
    if (validateBrightness(color)) {
      return color;
    }

    // Boost brightness by lerping toward white
    final boostedColor = Color.lerp(color, Colors.white, boostFactor);
    if (boostedColor == null) {
      return color; // Fallback
    }

    // Verify boosted color meets requirement
    if (validateBrightness(boostedColor)) {
      AppLogger.data('✨ Boosted color brightness: ${color.toString()} -> ${boostedColor.toString()}');
      return boostedColor;
    }

    // If still not bright enough, boost more aggressively
    final moreBoosted = Color.lerp(color, Colors.white, boostFactor * 2);
    return moreBoosted ?? boostedColor;
  }

  /// Increase saturation of a colour by moving it toward its most saturated version
  /// Uses HSL-like approach: increases saturation while maintaining lightness
  static Color increaseSaturation(Color color, {double saturationBoost = 0.3}) {
    // Convert RGB to HSL-like values
    final r = color.r;
    final g = color.g;
    final b = color.b;
    
    final max = math.max(math.max(r, g), b);
    final min = math.min(math.min(r, g), b);
    final delta = max - min;
    
    // If already saturated (delta is large), return as-is
    if (delta > 0.7) {
      return color;
    }
    
    // Increase saturation by moving toward pure colour
    // Find the dominant channel and boost it
    Color targetColor;
    if (r >= g && r >= b) {
      // Red dominant
      targetColor = Color.fromRGBO(
        (1.0 * 255).round().clamp(0, 255),
        ((g + (1.0 - g) * saturationBoost) * 255).round().clamp(0, 255),
        ((b + (1.0 - b) * saturationBoost) * 255).round().clamp(0, 255),
        1.0,
      );
    } else if (g >= r && g >= b) {
      // Green dominant
      targetColor = Color.fromRGBO(
        ((r + (1.0 - r) * saturationBoost) * 255).round().clamp(0, 255),
        (1.0 * 255).round().clamp(0, 255),
        ((b + (1.0 - b) * saturationBoost) * 255).round().clamp(0, 255),
        1.0,
      );
    } else {
      // Blue dominant
      targetColor = Color.fromRGBO(
        ((r + (1.0 - r) * saturationBoost) * 255).round().clamp(0, 255),
        ((g + (1.0 - g) * saturationBoost) * 255).round().clamp(0, 255),
        (1.0 * 255).round().clamp(0, 255),
        1.0,
      );
    }
    
    // Blend toward target while maintaining lightness
    final saturated = Color.lerp(color, targetColor, saturationBoost);
    return saturated ?? color;
  }

  /// Get all available palette presets
  static List<PalettePreset> getPresets() {
    return [
      // Warm Whites - Cream, ivory, warm white, soft yellow tones (increased saturation)
      PalettePreset(
        id: 'warm_whites',
        l10nKey: 'palettePresetWarmWhites',
        colors: [
          const Color(0xFFFFFEF0), // Ivory
          const Color(0xFFFFFACD), // Lemon chiffon
          const Color(0xFFFFF8DC), // Cornsilk
          const Color(0xFFFFF5EE), // Seashell
          const Color(0xFFFFE4B5), // Moccasin
          const Color(0xFFFFDAB9), // Peach puff
          const Color(0xFFFFE4E1), // Misty rose
          const Color(0xFFFFF0F5), // Lavender blush
        ].map((c) => increaseSaturation(ensureMinimumBrightness(c), saturationBoost: 0.25)).toList(),
      ),

      // Realistic Star Colors - White, blue-white, yellow, orange, red (astronomical) (increased saturation)
      PalettePreset(
        id: 'realistic_stars',
        l10nKey: 'palettePresetRealisticStars',
        colors: [
          const Color(0xFFFFFFFF), // White
          const Color(0xFFE6F3FF), // Blue-white
          const Color(0xFFFFF8E1), // Yellow-white
          const Color(0xFFFFE082), // Yellow
          const Color(0xFFFFB74D), // Orange
          const Color(0xFFFF8A65), // Red-orange
          const Color(0xFFFF6B6B), // Red
          const Color(0xFFFFB3BA), // Light red
        ].map((c) => increaseSaturation(ensureMinimumBrightness(c), saturationBoost: 0.3)).toList(),
      ),

      // Cool Blues - Various shades of blue, cyan, teal (increased saturation)
      PalettePreset(
        id: 'cool_blues',
        l10nKey: 'palettePresetCoolBlues',
        colors: [
          const Color(0xFF87CEEB), // Sky blue
          const Color(0xFF00BFFF), // Deep sky blue
          const Color(0xFF1E90FF), // Dodger blue
          const Color(0xFF00CED1), // Dark turquoise
          const Color(0xFF40E0D0), // Turquoise
          const Color(0xFF48D1CC), // Medium turquoise
          const Color(0xFF00FFFF), // Cyan
          const Color(0xFFB0E0E6), // Powder blue
        ].map((c) => increaseSaturation(ensureMinimumBrightness(c), saturationBoost: 0.3)).toList(),
      ),

      // Vibrant Colors - Bright, saturated colors (current palette)
      PalettePreset(
        id: 'vibrant',
        l10nKey: 'palettePresetVibrant',
        colors: [
          const Color(0xFFFFF200), // Bright Van Gogh yellow
          const Color(0xFF00BFFF), // Bright sky blue
          const Color(0xFF6A5ACD), // Slate blue
          const Color(0xFFFFD700), // Gold
          const Color(0xFFDA70D6), // Orchid
          const Color(0xFFFF69B4), // Hot pink
          const Color(0xFF00CED1), // Dark turquoise
          const Color(0xFFFFA500), // Orange
          const Color(0xFF32CD32), // Lime green
          const Color(0xFFFF6347), // Tomato red
          const Color(0xFF8A2BE2), // Blue violet
          const Color(0xFFDC143C), // Crimson
          const Color(0xFF00FA9A), // Medium spring green
          const Color(0xFFFF1493), // Deep pink
          const Color(0xFF1E90FF), // Dodger blue
          const Color(0xFFFFB347), // Peach
        ].map((c) => ensureMinimumBrightness(c)).toList(),
      ),

      // Pastel Dreams - Soft pastel versions of colours (increased saturation)
      PalettePreset(
        id: 'pastel_dreams',
        l10nKey: 'palettePresetPastelDreams',
        colors: [
          const Color(0xFFFFE5F1), // Pastel pink
          const Color(0xFFE0BBE4), // Pastel purple
          const Color(0xFFDDA0DD), // Plum
          const Color(0xFFB19CD9), // Light purple
          const Color(0xFFFFD1DC), // Light pink
          const Color(0xFFFFB6C1), // Light pink
          const Color(0xFFFFC0CB), // Pink
          const Color(0xFFFFE4E1), // Misty rose
        ].map((c) => increaseSaturation(ensureMinimumBrightness(c), saturationBoost: 0.2)).toList(),
      ),
    ];
  }

  /// Get preset by ID
  static PalettePreset? getPresetById(String id) {
    return getPresets().firstWhere(
      (preset) => preset.id == id,
      orElse: () => getPresets().firstWhere((p) => p.id == 'vibrant'), // Default fallback
    );
  }

  /// Get default preset (Vibrant)
  static PalettePreset getDefaultPreset() {
    return getPresets().firstWhere((p) => p.id == 'vibrant');
  }
}

