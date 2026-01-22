import '../models/holiday_greeting.dart';
import '../core/config/holiday_greeting_config.dart';
import '../core/config/season_config.dart';
import '../core/utils/app_logger.dart';

/// Service for determining and managing holiday greetings
/// 
/// Handles date calculations for various holiday types including:
/// - Fixed date holidays (New Year, Christmas, etc.)
/// - Relative date holidays (Easter, Thanksgiving)
/// - Lunar calendar holidays (Lunar New Year, Diwali, Ramadan, etc.)
class HolidayGreetingService {
  HolidayGreetingService._(); // Private constructor

  /// Singleton instance
  static final HolidayGreetingService instance = HolidayGreetingService._();

  // Cache for current greeting with TTL (24 hours)
  HolidayGreeting? _cachedGreeting;
  DateTime? _cachedDate;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTTL = Duration(hours: 24);

  /// Get the current greeting based on today's date
  /// 
  /// Returns null if no holiday is active today
  HolidayGreeting? getCurrentGreeting() {
    return getGreetingForDate(DateTime.now());
  }

  /// Get greeting for a specific date (useful for testing)
  /// 
  /// Returns null if no holiday is active on the given date
  /// 
  /// [hemisphere] defaults to Northern Hemisphere
  HolidayGreeting? getGreetingForDate(DateTime date, {Hemisphere hemisphere = Hemisphere.north}) {
    final dateOnly = DateTime(date.year, date.month, date.day);

    // Check cache first (with TTL validation)
    if (_cachedGreeting != null &&
        _cachedDate != null &&
        isSameDay(_cachedDate!, dateOnly) &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheTTL) {
      return _cachedGreeting;
    }

    // Check all holidays in priority order (most specific first)
    final holidays = _getAllHolidays(dateOnly.year, hemisphere: hemisphere);

    for (final holiday in holidays) {
      if (holiday.isDateInRange(dateOnly)) {
        _cachedGreeting = holiday;
        _cachedDate = dateOnly;
        _cacheTimestamp = DateTime.now();
        AppLogger.data('🎉 Active holiday: ${holiday.type}');
        return holiday;
      }
    }

    // No holiday active
    _cachedGreeting = null;
    _cachedDate = dateOnly;
    _cacheTimestamp = DateTime.now();
    return null;
  }

  /// Check if a specific holiday is active on a given date
  bool isHolidayActive(HolidayType holidayType, DateTime date) {
    final greeting = getGreetingForDate(date);
    return greeting?.type == holidayType;
  }

  /// Get all holidays for a given year
  /// 
  /// Returns holidays in priority order (most specific first)
  /// 
  /// [hemisphere] defaults to Northern Hemisphere
  List<HolidayGreeting> _getAllHolidays(int year, {Hemisphere hemisphere = Hemisphere.north}) {
    final holidays = <HolidayGreeting>[];

    // Fixed date holidays
    holidays.addAll(_getFixedDateHolidays(year));

    // Relative date holidays
    holidays.addAll(_getRelativeDateHolidays(year, hemisphere: hemisphere));

    // Lunar calendar holidays
    holidays.addAll(_getLunarCalendarHolidays(year));

    // Sort by start date, then by specificity (single-day events prioritized)
    holidays.sort((a, b) {
      final dateCompare = a.startDate.compareTo(b.startDate);
      if (dateCompare != 0) return dateCompare;
      // If same start date, prefer single-day events (shorter duration)
      final aDuration = a.endDate.difference(a.startDate).inDays;
      final bDuration = b.endDate.difference(b.startDate).inDays;
      return aDuration.compareTo(bDuration);
    });

    return holidays;
  }

  /// Get fixed date holidays for a year
  List<HolidayGreeting> _getFixedDateHolidays(int year) {
    return [
      // New Year's Day - January 1
      HolidayGreeting(
        type: HolidayType.newYear,
        greetingKey: 'greetingNewYear',
        subtitleKey: 'greetingNewYearSubtitle',
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 1, 1),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.newYear),
      ),

      // Valentine's Day - February 14
      HolidayGreeting(
        type: HolidayType.valentinesDay,
        greetingKey: 'greetingValentines',
        subtitleKey: 'greetingValentinesSubtitle',
        startDate: DateTime(year, 2, 14),
        endDate: DateTime(year, 2, 14),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.valentinesDay),
      ),

      // Halloween - October 31
      HolidayGreeting(
        type: HolidayType.halloween,
        greetingKey: 'greetingHalloween',
        subtitleKey: 'greetingHalloweenSubtitle',
        startDate: DateTime(year, 10, 31),
        endDate: DateTime(year, 10, 31),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.halloween),
      ),

      // Christmas - December 25
      HolidayGreeting(
        type: HolidayType.christmas,
        greetingKey: 'greetingChristmas',
        subtitleKey: 'greetingChristmasSubtitle',
        startDate: DateTime(year, 12, 25),
        endDate: DateTime(year, 12, 25),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.christmas),
      ),

      // New Year's Eve - December 31
      HolidayGreeting(
        type: HolidayType.newYearsEve,
        greetingKey: 'greetingNewYearsEve',
        subtitleKey: 'greetingNewYearsEveSubtitle',
        startDate: DateTime(year, 12, 31),
        endDate: DateTime(year, 12, 31),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.newYearsEve),
      ),
    ];
  }

  /// Get relative date holidays for a year
  /// 
  /// [hemisphere] defaults to Northern Hemisphere
  List<HolidayGreeting> _getRelativeDateHolidays(int year, {Hemisphere hemisphere = Hemisphere.north}) {
    return [
      // Easter - First Sunday after the first full moon after March 21
      HolidayGreeting(
        type: HolidayType.easter,
        greetingKey: 'greetingEaster',
        subtitleKey: 'greetingEasterSubtitle',
        startDate: _calculateEaster(year),
        endDate: _calculateEaster(year),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.easter),
      ),

      // US Thanksgiving - Fourth Thursday in November
      HolidayGreeting(
        type: HolidayType.thanksgivingUS,
        greetingKey: 'greetingThanksgivingUS',
        subtitleKey: 'greetingThanksgivingUSSubtitle',
        startDate: _calculateUSThanksgiving(year),
        endDate: _calculateUSThanksgiving(year),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.thanksgivingUS),
      ),

      // Canadian Thanksgiving - Second Monday in October
      HolidayGreeting(
        type: HolidayType.thanksgivingCA,
        greetingKey: 'greetingThanksgivingCA',
        subtitleKey: 'greetingThanksgivingCASubtitle',
        startDate: _calculateCanadianThanksgiving(year),
        endDate: _calculateCanadianThanksgiving(year),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.thanksgivingCA),
      ),

      // Kwanzaa - December 26 (start date only, single-day display)
      HolidayGreeting(
        type: HolidayType.kwanzaa,
        greetingKey: 'greetingKwanzaa',
        subtitleKey: 'greetingKwanzaaSubtitle',
        startDate: DateTime(year, 12, 26),
        endDate: DateTime(year, 12, 26),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.kwanzaa),
      ),

      // Spring Equinox - March 20-21
      HolidayGreeting(
        type: HolidayType.springEquinox,
        greetingKey: 'greetingSpringEquinox',
        subtitleKey: 'greetingSpringEquinoxSubtitle',
        startDate: _calculateSpringEquinox(year, hemisphere: hemisphere),
        endDate: _calculateSpringEquinox(year, hemisphere: hemisphere),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.springEquinox),
      ),

      // Summer Solstice - June 20-21
      HolidayGreeting(
        type: HolidayType.summerSolstice,
        greetingKey: 'greetingSummerSolstice',
        subtitleKey: 'greetingSummerSolsticeSubtitle',
        startDate: _calculateSummerSolstice(year, hemisphere: hemisphere),
        endDate: _calculateSummerSolstice(year, hemisphere: hemisphere),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.summerSolstice),
      ),

      // Autumn Equinox - September 22-23
      HolidayGreeting(
        type: HolidayType.autumnEquinox,
        greetingKey: 'greetingAutumnEquinox',
        subtitleKey: 'greetingAutumnEquinoxSubtitle',
        startDate: _calculateAutumnEquinox(year, hemisphere: hemisphere),
        endDate: _calculateAutumnEquinox(year, hemisphere: hemisphere),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.autumnEquinox),
      ),

      // Winter Solstice - December 21-22
      HolidayGreeting(
        type: HolidayType.winterSolstice,
        greetingKey: 'greetingWinterSolstice',
        subtitleKey: 'greetingWinterSolsticeSubtitle',
        startDate: _calculateWinterSolstice(year, hemisphere: hemisphere),
        endDate: _calculateWinterSolstice(year, hemisphere: hemisphere),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.winterSolstice),
      ),
    ];
  }

  /// Lookup table for accurate lunar holiday dates (2026-2036)
  /// 
  /// Format: year -> Map<HolidayType, DateTime>
  static final Map<int, Map<HolidayType, DateTime>> _lunarHolidayLookup = {
    2026: {
      HolidayType.lunarNewYear: DateTime(2026, 2, 17),
      HolidayType.diwali: DateTime(2026, 11, 8),
      HolidayType.ramadan: DateTime(2026, 2, 18),
      HolidayType.eidAlFitr: DateTime(2026, 3, 20),
      HolidayType.eidAlAdha: DateTime(2026, 5, 29),
      HolidayType.hanukkah: DateTime(2026, 12, 15),
    },
    2027: {
      HolidayType.lunarNewYear: DateTime(2027, 2, 6),
      HolidayType.diwali: DateTime(2027, 10, 28),
      HolidayType.ramadan: DateTime(2027, 2, 7),
      HolidayType.eidAlFitr: DateTime(2027, 3, 9),
      HolidayType.eidAlAdha: DateTime(2027, 5, 18),
      HolidayType.hanukkah: DateTime(2027, 12, 5),
    },
    2028: {
      HolidayType.lunarNewYear: DateTime(2028, 1, 26),
      HolidayType.diwali: DateTime(2028, 11, 15),
      HolidayType.ramadan: DateTime(2028, 1, 27),
      HolidayType.eidAlFitr: DateTime(2028, 2, 26),
      HolidayType.eidAlAdha: DateTime(2028, 5, 6),
      HolidayType.hanukkah: DateTime(2028, 12, 23),
    },
    2029: {
      HolidayType.lunarNewYear: DateTime(2029, 2, 13),
      HolidayType.diwali: DateTime(2029, 11, 4),
      HolidayType.ramadan: DateTime(2029, 2, 15),
      HolidayType.eidAlFitr: DateTime(2029, 3, 16),
      HolidayType.eidAlAdha: DateTime(2029, 5, 25),
      HolidayType.hanukkah: DateTime(2029, 12, 12),
    },
    2030: {
      HolidayType.lunarNewYear: DateTime(2030, 2, 3),
      HolidayType.diwali: DateTime(2030, 10, 25),
      HolidayType.ramadan: DateTime(2030, 2, 4),
      HolidayType.eidAlFitr: DateTime(2030, 3, 6),
      HolidayType.eidAlAdha: DateTime(2030, 5, 15),
      HolidayType.hanukkah: DateTime(2030, 12, 1),
    },
    2031: {
      HolidayType.lunarNewYear: DateTime(2031, 1, 23),
      HolidayType.diwali: DateTime(2031, 11, 13),
      HolidayType.ramadan: DateTime(2031, 1, 24),
      HolidayType.eidAlFitr: DateTime(2031, 2, 23),
      HolidayType.eidAlAdha: DateTime(2031, 5, 4),
      HolidayType.hanukkah: DateTime(2031, 12, 20),
    },
    2032: {
      HolidayType.lunarNewYear: DateTime(2032, 2, 11),
      HolidayType.diwali: DateTime(2032, 11, 1),
      HolidayType.ramadan: DateTime(2032, 2, 12),
      HolidayType.eidAlFitr: DateTime(2032, 3, 12),
      HolidayType.eidAlAdha: DateTime(2032, 5, 22),
      HolidayType.hanukkah: DateTime(2032, 12, 9),
    },
    2033: {
      HolidayType.lunarNewYear: DateTime(2033, 1, 31),
      HolidayType.diwali: DateTime(2033, 10, 22),
      HolidayType.ramadan: DateTime(2033, 2, 1),
      HolidayType.eidAlFitr: DateTime(2033, 3, 2),
      HolidayType.eidAlAdha: DateTime(2033, 5, 11),
      HolidayType.hanukkah: DateTime(2033, 11, 28),
    },
    2034: {
      HolidayType.lunarNewYear: DateTime(2034, 2, 19),
      HolidayType.diwali: DateTime(2034, 11, 10),
      HolidayType.ramadan: DateTime(2034, 2, 20),
      HolidayType.eidAlFitr: DateTime(2034, 3, 21),
      HolidayType.eidAlAdha: DateTime(2034, 5, 31),
      HolidayType.hanukkah: DateTime(2034, 12, 18),
    },
    2035: {
      HolidayType.lunarNewYear: DateTime(2035, 2, 8),
      HolidayType.diwali: DateTime(2035, 10, 30),
      HolidayType.ramadan: DateTime(2035, 2, 9),
      HolidayType.eidAlFitr: DateTime(2035, 3, 11),
      HolidayType.eidAlAdha: DateTime(2035, 5, 20),
      HolidayType.hanukkah: DateTime(2035, 12, 7),
    },
    2036: {
      HolidayType.lunarNewYear: DateTime(2036, 1, 28),
      HolidayType.diwali: DateTime(2036, 11, 18),
      HolidayType.ramadan: DateTime(2036, 1, 29),
      HolidayType.eidAlFitr: DateTime(2036, 2, 28),
      HolidayType.eidAlAdha: DateTime(2036, 5, 8),
      HolidayType.hanukkah: DateTime(2036, 12, 25),
    },
  };

  /// Get lunar calendar holidays for a year
  /// 
  /// Uses lookup table for years 2026-2036, falls back to approximations for other years.
  List<HolidayGreeting> _getLunarCalendarHolidays(int year) {
    final lookup = _lunarHolidayLookup[year];
    
    return [
      // Lunar New Year
      HolidayGreeting(
        type: HolidayType.lunarNewYear,
        greetingKey: 'greetingLunarNewYear',
        subtitleKey: 'greetingLunarNewYearSubtitle',
        startDate: lookup?[HolidayType.lunarNewYear] ?? _calculateLunarNewYear(year),
        endDate: lookup?[HolidayType.lunarNewYear] ?? _calculateLunarNewYear(year),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.lunarNewYear),
      ),

      // Diwali
      HolidayGreeting(
        type: HolidayType.diwali,
        greetingKey: 'greetingDiwali',
        subtitleKey: 'greetingDiwaliSubtitle',
        startDate: lookup?[HolidayType.diwali] ?? _calculateDiwali(year),
        endDate: lookup?[HolidayType.diwali] ?? _calculateDiwali(year),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.diwali),
      ),

      // Ramadan - start date only (single-day display)
      HolidayGreeting(
        type: HolidayType.ramadan,
        greetingKey: 'greetingRamadan',
        subtitleKey: 'greetingRamadanSubtitle',
        startDate: lookup?[HolidayType.ramadan] ?? _calculateRamadanStart(year),
        endDate: lookup?[HolidayType.ramadan] ?? _calculateRamadanStart(year),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.ramadan),
      ),

      // Eid al-Fitr
      HolidayGreeting(
        type: HolidayType.eidAlFitr,
        greetingKey: 'greetingEidAlFitr',
        subtitleKey: 'greetingEidAlFitrSubtitle',
        startDate: lookup?[HolidayType.eidAlFitr] ?? _calculateEidAlFitr(year),
        endDate: lookup?[HolidayType.eidAlFitr] ?? _calculateEidAlFitr(year),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.eidAlFitr),
      ),

      // Eid al-Adha
      HolidayGreeting(
        type: HolidayType.eidAlAdha,
        greetingKey: 'greetingEidAlAdha',
        subtitleKey: 'greetingEidAlAdhaSubtitle',
        startDate: lookup?[HolidayType.eidAlAdha] ?? _calculateEidAlAdha(year),
        endDate: lookup?[HolidayType.eidAlAdha] ?? _calculateEidAlAdha(year),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.eidAlAdha),
      ),

      // Hanukkah - start date only (single-day display)
      HolidayGreeting(
        type: HolidayType.hanukkah,
        greetingKey: 'greetingHanukkah',
        subtitleKey: 'greetingHanukkahSubtitle',
        startDate: lookup?[HolidayType.hanukkah] ?? _calculateHanukkahStart(year),
        endDate: lookup?[HolidayType.hanukkah] ?? _calculateHanukkahStart(year),
        style: HolidayGreetingConfig.getStyleForHoliday(HolidayType.hanukkah),
      ),
    ];
  }

  // ============================================================================
  // DATE CALCULATION METHODS
  // ============================================================================

  /// Calculate Easter date using Computus algorithm (Anonymous Gregorian)
  /// Accurate for years 1900-2099
  DateTime _calculateEaster(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;

    return DateTime(year, month, day);
  }

  /// Calculate US Thanksgiving (Fourth Thursday in November)
  DateTime _calculateUSThanksgiving(int year) {
    // Start with November 1st
    final nov1 = DateTime(year, 11, 1);
    // Find the first Thursday
    final firstThursday = nov1.add(Duration(days: (4 - nov1.weekday) % 7));
    // Add 3 weeks to get the fourth Thursday
    return firstThursday.add(const Duration(days: 21));
  }

  /// Calculate Canadian Thanksgiving (Second Monday in October)
  DateTime _calculateCanadianThanksgiving(int year) {
    // Start with October 1st
    final oct1 = DateTime(year, 10, 1);
    // Find the first Monday
    final firstMonday = oct1.add(Duration(days: (1 - oct1.weekday) % 7));
    // Add 1 week to get the second Monday
    return firstMonday.add(const Duration(days: 7));
  }

  /// Calculate Lunar New Year (approximate)
  /// 
  /// This is a simplified approximation. For accurate dates,
  /// consider using a dedicated lunar calendar library.
  DateTime _calculateLunarNewYear(int year) {
    // Approximate: Usually between January 21 and February 20
    // Using a simple approximation based on year
    final baseDate = DateTime(year, 1, 21);
    final offset = (year * 11) % 30; // Rough approximation
    return baseDate.add(Duration(days: offset));
  }

  /// Calculate Diwali (approximate)
  /// 
  /// This is a simplified approximation. Actual dates vary by region.
  DateTime _calculateDiwali(int year) {
    // Approximate: Usually between October 15 and November 15
    // Using a simple approximation
    final baseDate = DateTime(year, 10, 15);
    final offset = (year * 11) % 30; // Rough approximation
    return baseDate.add(Duration(days: offset));
  }

  /// Calculate Ramadan start (approximate)
  /// 
  /// Ramadan moves ~11 days earlier each year.
  /// This is a simplified approximation.
  DateTime _calculateRamadanStart(int year) {
    // Approximate: Base date for 2024 Ramadan start (March 11)
    final baseYear = 2024;
    final baseDate = DateTime(baseYear, 3, 11);
    final yearsDiff = year - baseYear;
    final daysOffset = yearsDiff * 11;
    return baseDate.add(Duration(days: daysOffset));
  }

  /// Calculate Ramadan end (29-30 days after start)
  DateTime _calculateRamadanEnd(int year) {
    final start = _calculateRamadanStart(year);
    return start.add(const Duration(days: 29)); // Approximate 30-day month
  }

  /// Calculate Eid al-Fitr (end of Ramadan)
  DateTime _calculateEidAlFitr(int year) {
    return _calculateRamadanEnd(year).add(const Duration(days: 1));
  }

  /// Calculate Eid al-Adha (~70 days after Eid al-Fitr)
  DateTime _calculateEidAlAdha(int year) {
    final eidAlFitr = _calculateEidAlFitr(year);
    return eidAlFitr.add(const Duration(days: 70));
  }

  /// Calculate Hanukkah start (approximate)
  /// 
  /// This is a simplified approximation. For accurate dates,
  /// consider using a Hebrew calendar library.
  DateTime _calculateHanukkahStart(int year) {
    // Approximate: Usually between late November and late December
    final baseDate = DateTime(year, 11, 25);
    final offset = (year * 11) % 30; // Rough approximation
    return baseDate.add(Duration(days: offset));
  }

  /// Calculate Spring Equinox (Vernal Equinox)
  /// 
  /// Typically March 20 or 21 in Northern Hemisphere, September 22-23 in Southern.
  /// This uses a simplified approximation. For precise astronomical
  /// calculations, consider using an astronomical library.
  DateTime _calculateSpringEquinox(int year, {Hemisphere hemisphere = Hemisphere.north}) {
    if (hemisphere == Hemisphere.south) {
      // Southern Hemisphere: September 22-23
      if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
        return DateTime(year, 9, 22);
      } else {
        return DateTime(year, 9, 23);
      }
    } else {
      // Northern Hemisphere: March 20-21
      if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
        return DateTime(year, 3, 20);
      } else {
        return DateTime(year, 3, 20);
      }
    }
  }

  /// Calculate Summer Solstice
  /// 
  /// Typically June 20 or 21 in Northern Hemisphere, December 21-22 in Southern.
  /// This uses a simplified approximation.
  DateTime _calculateSummerSolstice(int year, {Hemisphere hemisphere = Hemisphere.north}) {
    if (hemisphere == Hemisphere.south) {
      // Southern Hemisphere: December 21-22
      if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
        return DateTime(year, 12, 21);
      } else {
        return DateTime(year, 12, 22);
      }
    } else {
      // Northern Hemisphere: June 20-21
      if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
        return DateTime(year, 6, 20);
      } else {
        return DateTime(year, 6, 21);
      }
    }
  }

  /// Calculate Autumn Equinox
  /// 
  /// Typically September 22 or 23 in Northern Hemisphere, March 20-21 in Southern.
  /// This uses a simplified approximation.
  DateTime _calculateAutumnEquinox(int year, {Hemisphere hemisphere = Hemisphere.north}) {
    if (hemisphere == Hemisphere.south) {
      // Southern Hemisphere: March 20-21
      if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
        return DateTime(year, 3, 20);
      } else {
        return DateTime(year, 3, 20);
      }
    } else {
      // Northern Hemisphere: September 22-23
      if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
        return DateTime(year, 9, 22);
      } else {
        return DateTime(year, 9, 23);
      }
    }
  }

  /// Calculate Winter Solstice
  /// 
  /// Typically December 21 or 22 in Northern Hemisphere, June 20-21 in Southern.
  /// This uses a simplified approximation.
  DateTime _calculateWinterSolstice(int year, {Hemisphere hemisphere = Hemisphere.north}) {
    if (hemisphere == Hemisphere.south) {
      // Southern Hemisphere: June 20-21
      if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
        return DateTime(year, 6, 20);
      } else {
        return DateTime(year, 6, 21);
      }
    } else {
      // Northern Hemisphere: December 21-22
      if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
        return DateTime(year, 12, 21);
      } else {
        return DateTime(year, 12, 22);
      }
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Check if two dates are on the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Clear the cache (useful for testing or when date changes)
  void clearCache() {
    _cachedGreeting = null;
    _cachedDate = null;
    _cacheTimestamp = null;
  }
}
