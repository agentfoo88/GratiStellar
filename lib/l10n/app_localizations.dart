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

  /// The app title
  ///
  /// In en, this message translates to:
  /// **'GratiStellar'**
  String get appTitle;

  /// The app subtitle
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

  /// No description provided for @semanticOpenMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get semanticOpenMenu;

  /// No description provided for @semanticOpenMenuHint.
  ///
  /// In en, this message translates to:
  /// **'Opens navigation drawer'**
  String get semanticOpenMenuHint;

  /// No description provided for @semanticAddStar.
  ///
  /// In en, this message translates to:
  /// **'Add new gratitude star'**
  String get semanticAddStar;

  /// No description provided for @semanticAddStarHint.
  ///
  /// In en, this message translates to:
  /// **'Opens dialog to create a new gratitude'**
  String get semanticAddStarHint;

  /// No description provided for @semanticShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all gratitudes'**
  String get semanticShowAll;

  /// No description provided for @semanticMindfulness.
  ///
  /// In en, this message translates to:
  /// **'Mindfulness mode'**
  String get semanticMindfulness;

  /// No description provided for @semanticToggleActive.
  ///
  /// In en, this message translates to:
  /// **'Currently active, tap to disable'**
  String get semanticToggleActive;

  /// No description provided for @semanticToggleInactive.
  ///
  /// In en, this message translates to:
  /// **'Tap to enable'**
  String get semanticToggleInactive;

  /// No description provided for @semanticStatLabel.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String semanticStatLabel(String label, String value);

  /// No description provided for @semanticStatIndicator.
  ///
  /// In en, this message translates to:
  /// **'{label} indicator'**
  String semanticStatIndicator(String label);

  /// No description provided for @semanticGratitude.
  ///
  /// In en, this message translates to:
  /// **'Gratitude: {text}'**
  String semanticGratitude(String text);

  /// No description provided for @semanticEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No gratitude stars yet. Tap the add button to create your first star.'**
  String get semanticEmptyState;

  /// No description provided for @semanticZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get semanticZoomIn;

  /// No description provided for @semanticZoomInHint.
  ///
  /// In en, this message translates to:
  /// **'Increase zoom level'**
  String get semanticZoomInHint;

  /// No description provided for @semanticZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get semanticZoomOut;

  /// No description provided for @semanticZoomOutHint.
  ///
  /// In en, this message translates to:
  /// **'Decrease zoom level'**
  String get semanticZoomOutHint;

  /// No description provided for @semanticZoomReset.
  ///
  /// In en, this message translates to:
  /// **'Reset zoom to 100 percent'**
  String get semanticZoomReset;

  /// No description provided for @semanticFitAll.
  ///
  /// In en, this message translates to:
  /// **'Fit all stars in view'**
  String get semanticFitAll;

  /// Title for sign in screen
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInTitle;

  /// Title for sign up screen
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUpTitle;

  /// Subtitle for sign in screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data across devices'**
  String get signInSubtitle;

  /// Subtitle for sign up screen
  ///
  /// In en, this message translates to:
  /// **'Link your email to backup your gratitude stars'**
  String get signUpSubtitle;

  /// Label for email input field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Hint text for email input
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get emailHint;

  /// Label for password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Hint text for password input
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordHint;

  /// Button text for sign in
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// Button text for sign up
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUpButton;

  /// Text asking if user has account
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Text asking if user needs to create account
  ///
  /// In en, this message translates to:
  /// **'No account with this email?'**
  String get needToLinkAccount;

  /// Toggle button text to switch to sign in
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInToggle;

  /// Toggle button text to switch to sign up
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUpToggle;

  /// Success message after creating account
  ///
  /// In en, this message translates to:
  /// **'Account created! Your data is now backed up.'**
  String get accountCreatedSuccess;

  /// Success message after signing in
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully!'**
  String get signInSuccess;

  /// Error when email or password is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter both email and password'**
  String get errorEmailPassword;

  /// Error when email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get errorValidEmail;

  /// Error when password is too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get errorPasswordLength;

  /// Error when email is already in use
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try signing in instead.'**
  String get errorEmailInUse;

  /// Error for invalid email format
  ///
  /// In en, this message translates to:
  /// **'Invalid email address format.'**
  String get errorInvalidEmail;

  /// Error for weak password
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 6 characters.'**
  String get errorWeakPassword;

  /// Error when user account not found
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.\n\nTap \"Create Account\" below to link your data.'**
  String get errorUserNotFound;

  /// Error for wrong password
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get errorWrongPassword;

  /// Error for invalid credentials
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.\n\nTap \"Create Account\" below to link your data.'**
  String get errorInvalidCredential;

  /// Error when credential already in use
  ///
  /// In en, this message translates to:
  /// **'This email is already linked to another account.'**
  String get errorCredentialInUse;

  /// Error for too many requests
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please try again later.'**
  String get errorTooManyRequests;

  /// Error for network failure
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your internet connection.'**
  String get errorNetworkFailed;

  /// Error when no user is signed in
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please restart the app.'**
  String get errorNoUserSignedIn;

  /// Error when account already linked
  ///
  /// In en, this message translates to:
  /// **'Your account is already linked to an email address.'**
  String get errorAlreadyLinked;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorGeneric;

  /// Button to sign out
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutButton;

  /// Title for sign out confirmation
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutTitle;

  /// Message for sign out confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?\n\nYour data will remain synced to your account.'**
  String get signOutMessage;

  /// Menu item for account settings
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountMenuItem;

  /// Menu item to sign in with email
  ///
  /// In en, this message translates to:
  /// **'Sign In with Email'**
  String get signInWithEmailMenuItem;

  /// Default display name when user has no name set
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUserName;

  /// Title for account section
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// Label for display name field
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayNameLabel;

  /// Button to change display name
  ///
  /// In en, this message translates to:
  /// **'Change Display Name'**
  String get changeDisplayName;

  /// Button to update information
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// Success message after updating display name
  ///
  /// In en, this message translates to:
  /// **'Display name updated successfully!'**
  String get displayNameUpdated;

  /// Sort option to display gratitude stars from newest to oldest
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get sortNewestFirst;

  /// Sort option to display gratitude stars from oldest to newest
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get sortOldestFirst;

  /// Sort option to display gratitude stars alphabetically from A to Z
  ///
  /// In en, this message translates to:
  /// **'A → Z'**
  String get sortAlphabeticalAZ;

  /// Sort option to display gratitude stars alphabetically from Z to A
  ///
  /// In en, this message translates to:
  /// **'Z → A'**
  String get sortAlphabeticalZA;

  /// Sort option to display gratitude stars grouped by color
  ///
  /// In en, this message translates to:
  /// **'By Color'**
  String get sortByColor;

  /// Menu item for sending feedback
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get feedbackMenuItem;

  /// Title for feedback dialog
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get feedbackDialogTitle;

  /// Label for feedback type dropdown
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get feedbackTypeLabel;

  /// Feedback type option for bugs
  ///
  /// In en, this message translates to:
  /// **'Bug/Error'**
  String get feedbackTypeBug;

  /// Feedback type option for feature requests
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get feedbackTypeFeature;

  /// Feedback type option for general feedback
  ///
  /// In en, this message translates to:
  /// **'General Feedback'**
  String get feedbackTypeGeneral;

  /// Label for feedback message field
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get feedbackMessageLabel;

  /// Hint text for feedback message
  ///
  /// In en, this message translates to:
  /// **'Describe your feedback...'**
  String get feedbackMessageHint;

  /// Error when feedback message is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your feedback'**
  String get feedbackMessageRequired;

  /// Label for optional contact email
  ///
  /// In en, this message translates to:
  /// **'Contact Email (Optional)'**
  String get feedbackEmailLabel;

  /// Hint for contact email field
  ///
  /// In en, this message translates to:
  /// **'For follow-up on this feedback'**
  String get feedbackEmailHint;

  /// Error for invalid email format
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get feedbackEmailInvalid;

  /// Button text to submit feedback
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get feedbackSubmit;

  /// Success message after submitting feedback
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get feedbackSuccess;

  /// Error message when feedback submission fails
  ///
  /// In en, this message translates to:
  /// **'Failed to submit feedback. Please try again.'**
  String get feedbackError;
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
