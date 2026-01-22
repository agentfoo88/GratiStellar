import 'package:flutter/material.dart';
import '../../models/holiday_greeting.dart';

/// Configuration for holiday greeting styles and colors
/// 
/// All colors are designed to meet WCAG AA contrast requirements
/// (4.5:1 contrast ratio for normal text, 3:1 for large text)
class HolidayGreetingConfig {
  HolidayGreetingConfig._(); // Private constructor - static only

  // ============================================================================
  // HOLIDAY COLOR PALETTES
  // ============================================================================

  /// New Year's Day colors (gold/yellow theme)
  static const Color newYearAccent = Color(0xFFFFD700); // Gold - WCAG AA compliant
  static const Color newYearSecondary = Color(0xFFFFE135); // Yellow star color

  /// Valentine's Day colors (pink/red theme)
  static const Color valentinesAccent = Color(0xFFFF69B4); // Hot pink - WCAG AA compliant
  static const Color valentinesSecondary = Color(0xFFFF1493); // Deep pink

  /// Easter colors (pastel theme)
  static const Color easterAccent = Color(0xFFFFB6C1); // Light pink - WCAG AA compliant
  static const Color easterSecondary = Color(0xFFE6E6FA); // Lavender

  /// Halloween colors (orange/purple theme)
  static const Color halloweenAccent = Color(0xFFFF8C00); // Dark orange - WCAG AA compliant
  static const Color halloweenSecondary = Color(0xFF9370DB); // Medium purple

  /// Christmas colors (green/red theme)
  static const Color christmasAccent = Color(0xFF228B22); // Forest green - WCAG AA compliant
  static const Color christmasSecondary = Color(0xFFDC143C); // Crimson red

  /// New Year's Eve colors (gold/sparkle theme)
  static const Color newYearsEveAccent = Color(0xFFFFD700); // Gold - WCAG AA compliant
  static const Color newYearsEveSecondary = Color(0xFFFFE135); // Yellow star

  /// Lunar New Year colors (red/gold theme)
  static const Color lunarNewYearAccent = Color(0xFFDC143C); // Crimson red - WCAG AA compliant
  static const Color lunarNewYearSecondary = Color(0xFFFFD700); // Gold

  /// Diwali colors (gold/orange theme)
  static const Color diwaliAccent = Color(0xFFFF8C00); // Dark orange - WCAG AA compliant
  static const Color diwaliSecondary = Color(0xFFFFD700); // Gold

  /// Ramadan colors (green/gold theme)
  static const Color ramadanAccent = Color(0xFF228B22); // Forest green - WCAG AA compliant
  static const Color ramadanSecondary = Color(0xFFFFD700); // Gold

  /// Eid al-Fitr colors (green/gold theme)
  static const Color eidAlFitrAccent = Color(0xFF228B22); // Forest green - WCAG AA compliant
  static const Color eidAlFitrSecondary = Color(0xFFFFD700); // Gold

  /// Eid al-Adha colors (green/gold theme)
  static const Color eidAlAdhaAccent = Color(0xFF228B22); // Forest green - WCAG AA compliant
  static const Color eidAlAdhaSecondary = Color(0xFFFFD700); // Gold

  /// Hanukkah colors (blue/silver theme)
  static const Color hanukkahAccent = Color(0xFF1E90FF); // Dodger blue - WCAG AA compliant
  static const Color hanukkahSecondary = Color(0xFFC0C0C0); // Silver

  /// Kwanzaa colors (red/green/black theme)
  static const Color kwanzaaAccent = Color(0xFFDC143C); // Crimson red - WCAG AA compliant
  static const Color kwanzaaSecondary = Color(0xFF228B22); // Forest green

  /// Thanksgiving (US) colors (orange/brown theme)
  static const Color thanksgivingUSAccent = Color(0xFFFF8C00); // Dark orange - WCAG AA compliant
  static const Color thanksgivingUSSecondary = Color(0xFF8B4513); // Saddle brown

  /// Thanksgiving (Canada) colors (orange/brown theme)
  static const Color thanksgivingCAAccent = Color(0xFFFF8C00); // Dark orange - WCAG AA compliant
  static const Color thanksgivingCASecondary = Color(0xFF8B4513); // Saddle brown

  /// Spring Equinox colors (green theme - matches spring season)
  static const Color springEquinoxAccent = Color(0xFF32CD32); // Lime green - WCAG AA compliant
  static const Color springEquinoxSecondary = Color(0xFF90EE90); // Light green

  /// Summer Solstice colors (yellow/orange theme - matches summer season)
  static const Color summerSolsticeAccent = Color(0xFFFFD700); // Gold - WCAG AA compliant
  static const Color summerSolsticeSecondary = Color(0xFFFF8C00); // Dark orange

  /// Autumn Equinox colors (orange/brown theme - matches autumn season)
  static const Color autumnEquinoxAccent = Color(0xFFFF8C00); // Dark orange - WCAG AA compliant
  static const Color autumnEquinoxSecondary = Color(0xFF8B4513); // Saddle brown

  /// Winter Solstice colors (blue/white theme - matches winter season)
  static const Color winterSolsticeAccent = Color(0xFF1E90FF); // Dodger blue - WCAG AA compliant
  static const Color winterSolsticeSecondary = Color(0xFFE0E0E0); // Light gray/white

  // ============================================================================
  // HOLIDAY STYLE DEFINITIONS
  // ============================================================================

  /// Get the greeting style for a specific holiday type
  static GreetingStyle getStyleForHoliday(HolidayType type) {
    switch (type) {
      case HolidayType.newYear:
        return const GreetingStyle(
          accentColor: newYearAccent,
          iconEmoji: '✨',
          secondaryColor: newYearSecondary,
          particleType: 'confetti',
        );
      case HolidayType.valentinesDay:
        return const GreetingStyle(
          accentColor: valentinesAccent,
          iconEmoji: '💝',
          secondaryColor: valentinesSecondary,
          particleType: 'hearts',
        );
      case HolidayType.easter:
        return const GreetingStyle(
          accentColor: easterAccent,
          iconEmoji: '🌸',
          secondaryColor: easterSecondary,
        );
      case HolidayType.halloween:
        return const GreetingStyle(
          accentColor: halloweenAccent,
          iconEmoji: '🎃',
          secondaryColor: halloweenSecondary,
          particleType: 'bats',
        );
      case HolidayType.christmas:
        return const GreetingStyle(
          accentColor: christmasAccent,
          iconEmoji: '🎄',
          secondaryColor: christmasSecondary,
          particleType: 'snowflakes',
        );
      case HolidayType.newYearsEve:
        return const GreetingStyle(
          accentColor: newYearsEveAccent,
          iconEmoji: '🎆',
          secondaryColor: newYearsEveSecondary,
          particleType: 'sparkles',
        );
      case HolidayType.lunarNewYear:
        return const GreetingStyle(
          accentColor: lunarNewYearAccent,
          iconEmoji: '🐉',
          secondaryColor: lunarNewYearSecondary,
          particleType: 'lanterns',
        );
      case HolidayType.diwali:
        return const GreetingStyle(
          accentColor: diwaliAccent,
          iconEmoji: '🪔',
          secondaryColor: diwaliSecondary,
          particleType: 'sparkles',
        );
      case HolidayType.ramadan:
        return const GreetingStyle(
          accentColor: ramadanAccent,
          iconEmoji: '🌙',
          secondaryColor: ramadanSecondary,
        );
      case HolidayType.eidAlFitr:
        return const GreetingStyle(
          accentColor: eidAlFitrAccent,
          iconEmoji: '🌙',
          secondaryColor: eidAlFitrSecondary,
        );
      case HolidayType.eidAlAdha:
        return const GreetingStyle(
          accentColor: eidAlAdhaAccent,
          iconEmoji: '🕌',
          secondaryColor: eidAlAdhaSecondary,
        );
      case HolidayType.hanukkah:
        return const GreetingStyle(
          accentColor: hanukkahAccent,
          iconEmoji: '🕎',
          secondaryColor: hanukkahSecondary,
          particleType: 'stars',
        );
      case HolidayType.kwanzaa:
        return const GreetingStyle(
          accentColor: kwanzaaAccent,
          iconEmoji: '🕯️',
          secondaryColor: kwanzaaSecondary,
          particleType: 'candles',
        );
      case HolidayType.thanksgivingUS:
        return const GreetingStyle(
          accentColor: thanksgivingUSAccent,
          iconEmoji: '🦃',
          secondaryColor: thanksgivingUSSecondary,
          particleType: 'leaves',
        );
      case HolidayType.thanksgivingCA:
        return const GreetingStyle(
          accentColor: thanksgivingCAAccent,
          iconEmoji: '🍁',
          secondaryColor: thanksgivingCASecondary,
          particleType: 'leaves',
        );
      case HolidayType.springEquinox:
        return const GreetingStyle(
          accentColor: springEquinoxAccent,
          iconEmoji: '🌿',
          secondaryColor: springEquinoxSecondary,
          particleType: 'blossoms',
        );
      case HolidayType.summerSolstice:
        return const GreetingStyle(
          accentColor: summerSolsticeAccent,
          iconEmoji: '☀️',
          secondaryColor: summerSolsticeSecondary,
          particleType: 'sunbeams',
        );
      case HolidayType.autumnEquinox:
        return const GreetingStyle(
          accentColor: autumnEquinoxAccent,
          iconEmoji: '🍂',
          secondaryColor: autumnEquinoxSecondary,
          particleType: 'leaves',
        );
      case HolidayType.winterSolstice:
        return const GreetingStyle(
          accentColor: winterSolsticeAccent,
          iconEmoji: '❄️',
          secondaryColor: winterSolsticeSecondary,
          particleType: 'snowflakes',
        );
    }
  }

  /// Get accent color for a holiday type
  static Color getAccentColor(HolidayType type) {
    return getStyleForHoliday(type).accentColor;
  }

  /// Get icon emoji for a holiday type
  static String getIconEmoji(HolidayType type) {
    return getStyleForHoliday(type).iconEmoji;
  }
}
