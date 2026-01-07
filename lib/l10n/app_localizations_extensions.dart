import 'dart:math';
import 'app_localizations.dart';

/// Extension methods for AppLocalizations to support random prompt selection
extension AppLocalizationsExtensions on AppLocalizations {
  /// Total number of gratitude prompts available
  ///
  /// **IMPORTANT:** When adding new prompts, only this constant needs to be updated!
  /// Add new prompts to app_en.arb as createStarHint1, createStarHint2, etc.
  /// and increment this number to match.
  static const int _totalPrompts = 30;

  /// Random number generator for prompt selection
  static final Random _random = Random();

  /// Returns a random gratitude creation prompt from the available bank
  ///
  /// This method randomly selects one of the createStarHintN prompts
  /// defined in the localization files. The selection changes each time
  /// the method is called, providing variety to users.
  ///
  /// To add new prompts:
  /// 1. Add "createStarHintN": "Your new prompt" to app_en.arb (where N is the next number)
  /// 2. Increment _totalPrompts constant above
  /// 3. Add the new case to the switch statement below
  /// 4. Run: flutter gen-l10n
  ///
  /// That's it! No other code changes needed.
  String getRandomCreateStarHint() {
    final promptNumber = _random.nextInt(_totalPrompts) + 1; // 1 to 30

    // Use switch for type-safe prompt selection
    // This ensures compile-time checking - if a prompt doesn't exist, build will fail
    return switch (promptNumber) {
      1 => createStarHint1,
      2 => createStarHint2,
      3 => createStarHint3,
      4 => createStarHint4,
      5 => createStarHint5,
      6 => createStarHint6,
      7 => createStarHint7,
      8 => createStarHint8,
      9 => createStarHint9,
      10 => createStarHint10,
      11 => createStarHint11,
      12 => createStarHint12,
      13 => createStarHint13,
      14 => createStarHint14,
      15 => createStarHint15,
      16 => createStarHint16,
      17 => createStarHint17,
      18 => createStarHint18,
      19 => createStarHint19,
      20 => createStarHint20,
      21 => createStarHint21,
      22 => createStarHint22,
      23 => createStarHint23,
      24 => createStarHint24,
      25 => createStarHint25,
      26 => createStarHint26,
      27 => createStarHint27,
      28 => createStarHint28,
      29 => createStarHint29,
      30 => createStarHint30,
      _ => createStarHint1, // Fallback to first prompt
    };
  }
}
