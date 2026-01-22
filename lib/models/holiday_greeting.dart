import 'package:flutter/material.dart';

/// Represents different types of holidays/events
enum HolidayType {
  newYear,
  valentinesDay,
  easter,
  halloween,
  christmas,
  newYearsEve,
  lunarNewYear,
  diwali,
  ramadan,
  eidAlFitr,
  eidAlAdha,
  hanukkah,
  kwanzaa,
  thanksgivingUS,
  thanksgivingCA,
  springEquinox,
  summerSolstice,
  autumnEquinox,
  winterSolstice,
}

/// Visual style configuration for holiday greetings
/// 
/// Ensures WCAG AA compliance for color contrast
class GreetingStyle {
  /// Primary accent color for the holiday
  /// Should meet WCAG AA contrast ratio (4.5:1) against background
  final Color accentColor;
  
  /// Emoji icon(s) to display with the greeting
  final String iconEmoji;
  
  /// Optional secondary color for gradient effects
  final Color? secondaryColor;
  
  /// Optional particle effect type (future enhancement)
  final String? particleType;

  const GreetingStyle({
    required this.accentColor,
    required this.iconEmoji,
    this.secondaryColor,
    this.particleType,
  });

  /// Create a gradient from accent colors if secondary color is provided
  LinearGradient? get gradient {
    if (secondaryColor != null) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accentColor, secondaryColor!],
      );
    }
    return null;
  }
}

/// Represents a holiday greeting with its associated metadata
class HolidayGreeting {
  /// Type of holiday
  final HolidayType type;
  
  /// Localization key for the greeting text
  final String greetingKey;
  
  /// Localization key for the subtitle (optional)
  final String? subtitleKey;
  
  /// Start date of the holiday (inclusive)
  final DateTime startDate;
  
  /// End date of the holiday (inclusive)
  final DateTime endDate;
  
  /// Visual style for the holiday greeting
  final GreetingStyle style;

  const HolidayGreeting({
    required this.type,
    required this.greetingKey,
    this.subtitleKey,
    required this.startDate,
    required this.endDate,
    required this.style,
  });

  /// Check if a given date falls within this holiday's date range
  bool isDateInRange(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    
    // Check if date is on start date, end date, or between them
    return (dateOnly.isAtSameMomentAs(startOnly) ||
            dateOnly.isAtSameMomentAs(endOnly) ||
            (dateOnly.isAfter(startOnly) && dateOnly.isBefore(endOnly.add(const Duration(days: 1)))));
  }

  @override
  String toString() => 'HolidayGreeting(type: $type, dates: ${startDate.toIso8601String()} - ${endDate.toIso8601String()})';
}
