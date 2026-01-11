import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// WCAG (Web Content Accessibility Guidelines) contrast ratio validator
///
/// Provides utilities to check if color combinations meet accessibility
/// standards for text and UI components.
///
/// WCAG 2.1 Level AA Requirements:
/// - Normal text (< 18pt): 4.5:1 contrast minimum
/// - Large text (≥ 18pt or 14pt bold): 3:1 contrast minimum
/// - UI components: 3:1 contrast minimum
///
/// WCAG 2.1 Level AAA Requirements:
/// - Normal text: 7:1 contrast minimum
/// - Large text: 4.5:1 contrast minimum
///
/// Usage:
/// ```dart
/// // Check if combination meets AA
/// if (WCAGValidator.meetsAA(textColor, backgroundColor)) {
///   print('Accessible!');
/// }
///
/// // Get contrast ratio
/// final ratio = WCAGValidator.contrastRatio(color1, color2);
/// print('Contrast: ${ratio.toStringAsFixed(2)}:1');
///
/// // Get recommended text color
/// final textColor = WCAGValidator.getTextColor(backgroundColor);
/// ```
class WCAGValidator {
  // Private constructor to prevent instantiation
  WCAGValidator._();

  // ========================================
  // CONTRAST CALCULATION
  // ========================================

  /// Calculate relative luminance of a color
  ///
  /// Formula from WCAG 2.1: https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
  ///
  /// Returns value between 0 (darkest) and 1 (lightest)
  static double _relativeLuminance(Color color) {
    // Convert 8-bit RGB to 0-1 range
    final r = (color.r * 255.0).round().clamp(0, 255) / 255.0;
    final g = (color.g * 255.0).round().clamp(0, 255) / 255.0;
    final b = (color.b * 255.0).round().clamp(0, 255) / 255.0;

    // Apply gamma correction
    double adjust(double channel) {
      return channel <= 0.03928
          ? channel / 12.92
          : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }

    final rLuminance = adjust(r);
    final gLuminance = adjust(g);
    final bLuminance = adjust(b);

    // Calculate relative luminance using ITU-R BT.709 coefficients
    return 0.2126 * rLuminance + 0.7152 * gLuminance + 0.0722 * bLuminance;
  }

  /// Calculate contrast ratio between two colors
  ///
  /// Formula from WCAG 2.1: (L1 + 0.05) / (L2 + 0.05)
  /// where L1 is the lighter color and L2 is the darker color
  ///
  /// Returns contrast ratio between 1:1 (no contrast) and 21:1 (maximum)
  ///
  /// Example:
  /// ```dart
  /// final ratio = WCAGValidator.contrastRatio(Colors.white, Colors.black);
  /// print('Contrast: ${ratio.toStringAsFixed(2)}:1'); // Contrast: 21.00:1
  /// ```
  static double contrastRatio(Color foreground, Color background) {
    final lum1 = _relativeLuminance(foreground);
    final lum2 = _relativeLuminance(background);

    final lighter = math.max(lum1, lum2);
    final darker = math.min(lum1, lum2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  // ========================================
  // WCAG COMPLIANCE CHECKS
  // ========================================

  /// Check if combination meets WCAG 2.1 Level AA for normal text (4.5:1)
  ///
  /// Returns true if contrast ratio is 4.5:1 or higher
  ///
  /// Use this for:
  /// - Body text
  /// - Labels
  /// - Input fields
  /// - Any text smaller than 18pt (or 14pt bold)
  static bool meetsAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 4.5;
  }

  /// Check if combination meets WCAG 2.1 Level AAA for normal text (7:1)
  ///
  /// Returns true if contrast ratio is 7:1 or higher
  ///
  /// Enhanced accessibility level - recommended for:
  /// - Low vision users
  /// - Older users
  /// - Users with color blindness
  static bool meetsAAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 7.0;
  }

  /// Check if combination meets WCAG 2.1 Level AA for large text (3:1)
  ///
  /// Returns true if contrast ratio is 3:1 or higher
  ///
  /// Use this for:
  /// - Headings ≥ 18pt regular
  /// - Headings ≥ 14pt bold
  /// - Large decorative text
  static bool meetsAALarge(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 3.0;
  }

  /// Check if combination meets WCAG 2.1 Level AAA for large text (4.5:1)
  ///
  /// Returns true if contrast ratio is 4.5:1 or higher
  static bool meetsAAALarge(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 4.5;
  }

  /// Check if combination meets WCAG 2.1 UI component contrast (3:1)
  ///
  /// Returns true if contrast ratio is 3:1 or higher
  ///
  /// Use this for:
  /// - Borders
  /// - Focus indicators
  /// - Icons
  /// - UI controls
  static bool meetsUIComponent(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 3.0;
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Get recommended text color for a background color
  ///
  /// Automatically selects between [AppTheme.textPrimary] (white) and
  /// [AppTheme.textOnLight] (dark blue) based on background luminance
  ///
  /// Returns:
  /// - Dark text for light backgrounds (luminance > 0.5)
  /// - Light text for dark backgrounds (luminance ≤ 0.5)
  ///
  /// Example:
  /// ```dart
  /// final textColor = WCAGValidator.getTextColor(backgroundColor);
  /// Text('Hello', style: TextStyle(color: textColor));
  /// ```
  static Color getTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? AppTheme.textOnLight
        : AppTheme.textPrimary;
  }

  /// Get compliance level string for a contrast ratio
  ///
  /// Returns human-readable compliance level:
  /// - "AAA (Normal & Large)" for 7:1+
  /// - "AA (Normal) & AAA (Large)" for 4.5:1 - 6.99:1
  /// - "AA (Large only)" for 3:1 - 4.49:1
  /// - "FAIL" for < 3:1
  static String getComplianceLevel(double ratio) {
    if (ratio >= 7.0) {
      return 'AAA (Normal & Large)';
    } else if (ratio >= 4.5) {
      return 'AA (Normal) & AAA (Large)';
    } else if (ratio >= 3.0) {
      return 'AA (Large only)';
    } else {
      return 'FAIL';
    }
  }

  /// Format contrast ratio as string
  ///
  /// Returns formatted ratio like "4.51:1" or "21.00:1"
  static String formatRatio(double ratio) {
    return '${ratio.toStringAsFixed(2)}:1';
  }

  // ========================================
  // VALIDATION UTILITIES
  // ========================================

  /// Validate a color combination and print details (debug only)
  ///
  /// Prints:
  /// - Contrast ratio
  /// - WCAG compliance levels
  /// - Pass/fail for each standard
  ///
  /// Example:
  /// ```dart
  /// if (kDebugMode) {
  ///   WCAGValidator.debugValidate(
  ///     textColor,
  ///     backgroundColor,
  ///     label: 'Dialog Title',
  ///   );
  /// }
  /// ```
  static void debugValidate(
    Color foreground,
    Color background, {
    String? label,
  }) {
    final ratio = contrastRatio(foreground, background);
    final complianceLevel = getComplianceLevel(ratio);

    debugPrint('');
    debugPrint('═══ WCAG Validation ${label != null ? '($label)' : ''} ═══');
    debugPrint('Foreground: ${foreground.toString()}');
    debugPrint('Background: ${background.toString()}');
    debugPrint('Contrast Ratio: ${formatRatio(ratio)}');
    debugPrint('Compliance Level: $complianceLevel');
    debugPrint('');
    debugPrint('WCAG 2.1 Level AA:');
    debugPrint('  Normal text: ${meetsAA(foreground, background) ? '✓ PASS' : '✗ FAIL'}');
    debugPrint('  Large text: ${meetsAALarge(foreground, background) ? '✓ PASS' : '✗ FAIL'}');
    debugPrint('  UI components: ${meetsUIComponent(foreground, background) ? '✓ PASS' : '✗ FAIL'}');
    debugPrint('');
    debugPrint('WCAG 2.1 Level AAA:');
    debugPrint('  Normal text: ${meetsAAA(foreground, background) ? '✓ PASS' : '✗ FAIL'}');
    debugPrint('  Large text: ${meetsAAALarge(foreground, background) ? '✓ PASS' : '✗ FAIL'}');
    debugPrint('═══════════════════════════════════════');
    debugPrint('');
  }

  /// Assert that a color combination meets minimum WCAG AA standard
  ///
  /// Throws assertion error in debug mode if combination fails
  ///
  /// Use in tests or debug builds to catch accessibility issues early
  static void assertMeetsAA(
    Color foreground,
    Color background, {
    String? message,
  }) {
    assert(
      meetsAA(foreground, background),
      message ??
          'WCAG AA violation: ${formatRatio(contrastRatio(foreground, background))} '
              '(minimum 4.5:1 required)',
    );
  }
}
