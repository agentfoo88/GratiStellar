// font_scaling.dart
// Comprehensive font scaling system for GratiStellar

import 'package:flutter/material.dart';
import 'dart:math' as math;

class FontScaling {
  // Screen size breakpoints
  static const double mobileBreakpoint = 500.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Base font sizes for different screen categories
  static const double mobileBaseFontSize = 22.0;
  static const double tabletBaseFontSize = 18.0;
  static const double desktopBaseFontSize = 24.0;

  // Font weight constants
  static const FontWeight lightWeight = FontWeight.w300;
  static const FontWeight normalWeight = FontWeight.w500; // Your requested default
  static const FontWeight mediumWeight = FontWeight.w500;
  static const FontWeight semiBoldWeight = FontWeight.w600;
  static const FontWeight boldWeight = FontWeight.w700;

  // Get device category
  static DeviceCategory getDeviceCategory(double screenWidth) {
    if (screenWidth < mobileBreakpoint) return DeviceCategory.mobile;
    if (screenWidth < tabletBreakpoint) return DeviceCategory.tablet;
    if (screenWidth < desktopBreakpoint) return DeviceCategory.desktop;
    return DeviceCategory.largeDesktop;
  }

  // Get base font size for screen
  static double getBaseFontSize(double screenWidth) {
    final category = getDeviceCategory(screenWidth);
    switch (category) {
      case DeviceCategory.mobile:
        return mobileBaseFontSize;
      case DeviceCategory.tablet:
        return tabletBaseFontSize;
      case DeviceCategory.desktop:
      case DeviceCategory.largeDesktop:
        return desktopBaseFontSize;
    }
  }

  // Scale factor for smooth transitions between breakpoints
  static double getScaleFactor(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      // Mobile: scale from 0.8 to 1.0
      return math.max(0.8, math.min(1.0, screenWidth / mobileBreakpoint));
    } else if (screenWidth < tabletBreakpoint) {
      // Tablet: scale from 1.0 to 1.2
      final progress = (screenWidth - mobileBreakpoint) / (tabletBreakpoint - mobileBreakpoint);
      return 1.0 + (progress * 0.2);
    } else if (screenWidth < desktopBreakpoint) {
      // Desktop: scale from 1.2 to 1.4
      final progress = (screenWidth - tabletBreakpoint) / (desktopBreakpoint - tabletBreakpoint);
      return 1.2 + (progress * 0.2);
    } else {
      // Large desktop: cap at 1.5x
      return math.min(1.5, 1.4 + (screenWidth - desktopBreakpoint) / 1000);
    }
  }

  // Calculate responsive font size
  static double responsiveSize(double baseSize, double screenWidth) {
    final deviceBaseFontSize = getBaseFontSize(screenWidth);
    final scaleFactor = getScaleFactor(screenWidth);
    return (baseSize * (deviceBaseFontSize / desktopBaseFontSize)) * scaleFactor;
  }

  // Predefined text styles with responsive sizing
  static TextStyle getHeadingLarge(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(48.0, screenWidth),
      fontWeight: lightWeight,
      color: color ?? Colors.white,
      letterSpacing: 2.0,
    );
  }

  static TextStyle getHeadingMedium(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(32.0, screenWidth),
      fontWeight: normalWeight,
      color: color ?? Colors.white,
      letterSpacing: 1.0,
    );
  }

  static TextStyle getHeadingSmall(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(24.0, screenWidth),
      fontWeight: mediumWeight,
      color: color ?? Colors.white,
    );
  }

  static TextStyle getBodyLarge(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(18.0, screenWidth),
      fontWeight: normalWeight,
      color: color ?? Colors.white,
      height: 1.4,
    );
  }

  static TextStyle getBodyMedium(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(16.0, screenWidth),
      fontWeight: normalWeight,
      color: color ?? Colors.white,
      height: 1.4,
    );
  }

  static TextStyle getBodySmall(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(14.0, screenWidth),
      fontWeight: normalWeight,
      color: color ?? Colors.white,
      height: 1.3,
    );
  }

  static TextStyle getCaption(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(12.0, screenWidth),
      fontWeight: normalWeight,
      color: color ?? Colors.white.withValues(alpha: 0.7),
    );
  }

  static TextStyle getButtonText(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(16.0, screenWidth),
      fontWeight: mediumWeight,
      color: color ?? Colors.white,
    );
  }

  static TextStyle getLabel(BuildContext context, {Color? color}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(14.0, screenWidth),
      fontWeight: mediumWeight,
      color: color ?? Colors.white,
    );
  }

  // Special styles for app-specific elements
  static TextStyle getAppTitle(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(48.0, screenWidth),
      fontWeight: lightWeight,
      color: Color(0xFFFFE135),
      letterSpacing: 3.0,
    );
  }

  static TextStyle getSubtitle(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(18.0, screenWidth),
      fontWeight: normalWeight,
      color: Colors.white.withValues(alpha: 0.8),
      fontStyle: FontStyle.italic,
    );
  }

  static TextStyle getStatsNumber(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(20.0, screenWidth),
      fontWeight: mediumWeight,
      color: Colors.white.withValues(alpha: 0.9),
    );
  }

  static TextStyle getStatsLabel(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(12.0, screenWidth),
      fontWeight: normalWeight,
      color: Colors.white.withValues(alpha: 0.6),
    );
  }

  static TextStyle getModalTitle(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(24.0, screenWidth),
      fontWeight: lightWeight,
      color: Color(0xFFFFE135),
    );
  }

  static TextStyle getInputHint(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(16.0, screenWidth),
      fontWeight: normalWeight,
      color: Colors.white.withValues(alpha: 0.4),
    );
  }

  static TextStyle getInputText(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(16.0, screenWidth),
      fontWeight: normalWeight,
      color: Colors.white,
    );
  }

  static TextStyle getEmptyStateTitle(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(24.0, screenWidth),
      fontWeight: lightWeight,
      color: Colors.white.withValues(alpha: 0.6),
    );
  }

  static TextStyle getEmptyStateSubtitle(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextStyle(
      fontSize: responsiveSize(16.0, screenWidth),
      fontWeight: normalWeight,
      color: Colors.white.withValues(alpha: 0.4),
    );
  }

  // Utility method to get responsive padding/spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = getScaleFactor(screenWidth);
    return baseSpacing * scaleFactor;
  }

  // Utility method to get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = getScaleFactor(screenWidth);
    return baseSize * scaleFactor;
  }
}

enum DeviceCategory {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}