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
  static Color textTertiary = Colors.white.withValues(alpha: 0.5);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Color(0xFF4A6FA5);

  // Star Colors (from existing palette)
  static const Color starYellow = Color(0xFFFFE135);
  static const Color starWhite = Colors.white;
  static const Color starBlue = Colors.blue;

  // Utility
  /// Standard background gradient used throughout the app
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientTop, gradientUpperMid, gradientLowerMid, gradientBottom],
  );
}
