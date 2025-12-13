// font_scaling.dart
// Comprehensive font scaling system for GratiStellar

import 'package:flutter/material.dart';

class FontScaling {
  // Screen size breakpoints
  static const double mobileBreakpoint = 500.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

// Font sizes per Material Design (+2px)
// Mobile (< 500px)
  static const double mobileHeadline = 34.0;  // 32 + 2
  static const double mobileTitle = 24.0;     // 22 + 2
  static const double mobileBody = 18.0;      // 16 + 2
  static const double mobileCaption = 16.0;   // 14 + 2
  static const double mobileButton = 16.0;    // 14 + 2

// Tablet (500-900px) - Larger for better readability
  static const double tabletHeadline = 40.0;  // Increased from 30.0
  static const double tabletTitle = 28.0;     // Increased from 22.0
  static const double tabletBody = 20.0;      // Increased from 16.0
  static const double tabletCaption = 18.0;   // Increased from 14.0
  static const double tabletButton = 18.0;    // Increased from 14.0

// Desktop (> 900px)
  static const double desktopHeadline = 26.0; // 24 + 2
  static const double desktopTitle = 20.0;    // 18 + 2
  static const double desktopBody = 16.0;     // 14 + 2
  static const double desktopCaption = 13.0;  // 11 + 2
  static const double desktopButton = 13.0;   // 11 + 2

  // Font weight constants
  static const FontWeight lightWeight = FontWeight.w600;     // Semi-bold (was w500)
  static const FontWeight normalWeight = FontWeight.w700;    // Bold (was w600)
  static const FontWeight mediumWeight = FontWeight.w800;    // Extra-bold (was w700)
  static const FontWeight boldWeight = FontWeight.w900;      // Black (was w800)

  // Predefined text styles with responsive sizing
  static TextStyle getHeadingLarge(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileHeadline
        : screenWidth < tabletBreakpoint
        ? tabletHeadline
        : desktopHeadline;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: lightWeight,
      color: color ?? Colors.white,
      letterSpacing: 2.0,
    );
  }

  static TextStyle getHeadingMedium(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileTitle
        : screenWidth < tabletBreakpoint
        ? tabletTitle
        : desktopTitle;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: mediumWeight,
      color: color ?? Colors.white,
    );
  }

  static TextStyle getHeadingSmall(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileTitle
        : screenWidth < tabletBreakpoint
        ? tabletTitle
        : desktopTitle;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: mediumWeight,
      color: color ?? Colors.white,
    );
  }

  static TextStyle getBodyLarge(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileBody
        : screenWidth < tabletBreakpoint
        ? tabletBody
        : desktopBody;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: normalWeight,
      color: color ?? Colors.white,
    );
  }

  static TextStyle getBodyMedium(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileBody
        : screenWidth < tabletBreakpoint
        ? tabletBody
        : desktopBody;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: normalWeight,
      color: color ?? Colors.white,
    );
  }

  static TextStyle getBodySmall(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileBody
        : screenWidth < tabletBreakpoint
        ? tabletBody
        : desktopBody;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: normalWeight,
      color: color ?? Colors.white,
    );
  }

  static TextStyle getCaption(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileCaption
        : screenWidth < tabletBreakpoint
        ? tabletCaption
        : desktopCaption;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: normalWeight,
      color: color ?? Colors.white.withValues(alpha: 0.7),
    );
  }

  static TextStyle getButtonText(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileButton
        : screenWidth < tabletBreakpoint
        ? tabletButton
        : desktopButton;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: mediumWeight,
      color: color ?? Colors.white,
    );
  }

  static TextStyle getLabel(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileCaption
        : screenWidth < tabletBreakpoint
        ? tabletCaption
        : desktopCaption;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: mediumWeight,
      color: color ?? Colors.white,
    );
  }

  // Special styles for app-specific elements
  static TextStyle getAppTitle(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileHeadline
        : screenWidth < tabletBreakpoint
        ? tabletHeadline
        : desktopHeadline;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: lightWeight,
      color: Color(0xFFFFE135),
      letterSpacing: 3.0,
    );
  }

  static TextStyle getSubtitle(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileBody
        : screenWidth < tabletBreakpoint
        ? tabletBody
        : desktopBody;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: normalWeight,
      color: Colors.white.withValues(alpha: 0.8),
      fontStyle: FontStyle.italic,
    );
  }

  static TextStyle getStatsNumber(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileTitle
        : screenWidth < tabletBreakpoint
        ? tabletTitle
        : desktopTitle;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: mediumWeight,
      color: Colors.white.withValues(alpha: 0.9),
    );
  }

  static TextStyle getStatsLabel(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileCaption
        : screenWidth < tabletBreakpoint
        ? tabletCaption
        : desktopCaption;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: normalWeight,
      color: Colors.white.withValues(alpha: 0.6),
    );
  }

  static TextStyle getModalTitle(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileTitle
        : screenWidth < tabletBreakpoint
        ? tabletTitle
        : desktopTitle;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: lightWeight,
      color: Color(0xFFFFE135),
    );
  }

  static TextStyle getInputHint(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileBody
        : screenWidth < tabletBreakpoint
        ? tabletBody
        : desktopBody;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: normalWeight,
      color: Colors.white.withValues(alpha: 0.4),
    );
  }

  static TextStyle getInputText(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileBody
        : screenWidth < tabletBreakpoint
        ? tabletBody
        : desktopBody;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: normalWeight,
      color: Colors.white,
    );
  }

  static TextStyle getEmptyStateTitle(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileTitle
        : screenWidth < tabletBreakpoint
        ? tabletTitle
        : desktopTitle;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: lightWeight,
      color: Colors.white.withValues(alpha: 0.6),
    );
  }

  static TextStyle getEmptyStateSubtitle(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final fontSize = screenWidth < mobileBreakpoint
        ? mobileBody
        : screenWidth < tabletBreakpoint
        ? tabletBody
        : desktopBody;

    return TextStyle(
      fontFamily: 'JosefinSans',
      fontSize: fontSize,
      fontWeight: normalWeight,
      color: Colors.white.withValues(alpha: 0.4),
    );
  }

  // Utility method to get responsive padding/spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    // Simple multiplier based on screen size
    if (screenWidth < mobileBreakpoint) {
      return baseSpacing * 0.9; // Slightly smaller on mobile
    } else if (screenWidth < tabletBreakpoint) {
      return baseSpacing * 1.0; // Base size on tablet
    } else {
      return baseSpacing * 1.1; // Slightly larger on desktop
    }
  }

  // Utility method to get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    // Simple multiplier based on screen size
    if (screenWidth < mobileBreakpoint) {
      return baseSize * 0.9; // Slightly smaller on mobile
    } else if (screenWidth < tabletBreakpoint) {
      return baseSize * 1.0; // Base size on tablet
    } else {
      return baseSize * 1.1; // Slightly larger on desktop
    }
  }
}