import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'GratiStellar'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal universe of gratitude'**
  String get appSubtitle;

  /// No description provided for @loadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Preparing your personal universe...'**
  String get loadingMessage;

  /// No description provided for @createStarModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Birth a New Star'**
  String get createStarModalTitle;

  /// No description provided for @createStarHint.
  ///
  /// In en, this message translates to:
  /// **'What lights up your heart today?'**
  String get createStarHint;

  /// No description provided for @createStarButton.
  ///
  /// In en, this message translates to:
  /// **'Create Star'**
  String get createStarButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @statsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statsTotal;

  /// No description provided for @statsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get statsThisWeek;

  /// No description provided for @statsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statsToday;

  /// No description provided for @emptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Your constellation awaits'**
  String get emptyStateTitle;

  /// No description provided for @emptyStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to birth your first star'**
  String get emptyStateSubtitle;

  /// No description provided for @editButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButton;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @changeColorButton.
  ///
  /// In en, this message translates to:
  /// **'Change Color'**
  String get changeColorButton;

  /// No description provided for @editGratitudeHint.
  ///
  /// In en, this message translates to:
  /// **'Edit your gratitude...'**
  String get editGratitudeHint;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this gratitude?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteWarning;

  /// No description provided for @exitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit GratiStellar?'**
  String get exitTitle;

  /// No description provided for @exitMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the app?'**
  String get exitMessage;

  /// No description provided for @exitButton.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitButton;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoonTitle;

  /// No description provided for @colorPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Color Preview'**
  String get colorPreviewTitle;

  /// No description provided for @presetColorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Preset Colors'**
  String get presetColorsTitle;

  /// No description provided for @customColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Color'**
  String get customColorTitle;

  /// No description provided for @hexColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Hex Color'**
  String get hexColorLabel;

  /// No description provided for @hexColorHint.
  ///
  /// In en, this message translates to:
  /// **'#FFE135'**
  String get hexColorHint;

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @loginMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginMenuItem;

  /// No description provided for @listViewMenuItem.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listViewMenuItem;

  /// No description provided for @mindfulnessIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Interval (seconds)'**
  String get mindfulnessIntervalLabel;

  /// No description provided for @mindfulnessNoStarsTitle.
  ///
  /// In en, this message translates to:
  /// **'No stars yet'**
  String get mindfulnessNoStarsTitle;

  /// No description provided for @mindfulnessNoStarsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a star first to use mindfulness mode'**
  String get mindfulnessNoStarsMessage;

  /// No description provided for @listViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Gratitude Stars'**
  String get listViewTitle;

  /// No description provided for @jumpToStarButton.
  ///
  /// In en, this message translates to:
  /// **'Jump to Star'**
  String get jumpToStarButton;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// No description provided for @daysAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgoLabel(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
