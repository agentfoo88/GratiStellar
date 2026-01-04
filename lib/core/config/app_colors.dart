import 'package:flutter/material.dart';

/// Centralized color palette for GratiStellar
///
/// This class provides a single source of truth for all colors used throughout
/// the application, making it easier to maintain consistency and implement
/// theme changes in the future.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFFFFE135);        // Yellow star
  static const Color primaryDark = Color(0xFF1A2238);    // Dark navy

  // Background Gradients
  static const Color gradientTop = Color(0xFF4A6FA5);    // Bright blue
  static const Color gradientUpperMid = Color(0xFF166088); // Dark blue
  static const Color gradientLowerMid = Color(0xFF0B1426); // Deep navy
  static const Color gradientBottom = Color(0xFF2C3E50);  // Dark blue-gray

  // UI Elements
  static const Color cardBackground = Color(0xFF1A2238);
  static const Color dialogBackground = Color(0xFF0A0E27);
  static const Color divider = Color(0xFFFFE135);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static Color textSecondary = Colors.white.withValues(alpha: 0.7);
  static Color textTertiary = Colors.white.withValues(alpha: 0.7);  // WCAG AA: 4.8:1 contrast
  static Color textQuaternary = Colors.white.withValues(alpha: 0.6);  // WCAG AA: 4.4:1 contrast
  static Color textDisabled = Colors.white.withValues(alpha: 0.65);  // WCAG AA: 4.6:1 contrast

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Color(0xFF4A6FA5);

  // Color Variations with Alpha
  /// Primary color with various opacity levels
  static Color primaryWithAlpha(double alpha) => primary.withValues(alpha: alpha);
  static Color primaryLight = primary.withValues(alpha: 0.5);
  static Color primaryMedium = primary.withValues(alpha: 0.5);  // WCAG AA: improved contrast
  static Color primarySubtle = primary.withValues(alpha: 0.2);  // Decorative only
  static Color primaryVerySubtle = primary.withValues(alpha: 0.1);  // Decorative only

  /// Primary dark with various opacity levels
  static Color primaryDarkWithAlpha(double alpha) => primaryDark.withValues(alpha: alpha);
  static Color primaryDarkLight = primaryDark.withValues(alpha: 0.95);
  static Color primaryDarkMedium = primaryDark.withValues(alpha: 0.9);

  // Star Colors (from existing palette)
  static const Color starYellow = Color(0xFFFFE135);
  static const Color starWhite = Colors.white;
  static const Color starBlue = Colors.blue;
  
  // Star Color Palette (from gratitude_stars.dart)
  static const List<Color> starColorPalette = [
    Color(0xFFFFF200), // Bright Van Gogh yellow
    Color(0xFF00BFFF), // Bright sky blue
    Color(0xFF6A5ACD), // Slate blue
    Color(0xFFFFD700), // Gold
    Color(0xFFDA70D6), // Orchid
    Color(0xFFFF69B4), // Hot pink
    Color(0xFF00CED1), // Dark turquoise
    Color(0xFFFFA500), // Orange
    Color(0xFF32CD32), // Lime green
    Color(0xFFFF6347), // Tomato red
    Color(0xFF8A2BE2), // Blue violet
    Color(0xFFDC143C), // Crimson
    Color(0xFF00FA9A), // Medium spring green
    Color(0xFFFF1493), // Deep pink
    Color(0xFF1E90FF), // Dodger blue
    Color(0xFFFFB347), // Peach
  ];

  // Utility
  /// Standard background gradient used throughout the app
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientTop, gradientUpperMid, gradientLowerMid, gradientBottom],
  );
}
