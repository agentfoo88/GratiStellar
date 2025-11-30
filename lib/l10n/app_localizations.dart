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

  /// Button to optionally choose star color during creation
  ///
  /// In en, this message translates to:
  /// **'Choose Star Color'**
  String get chooseColorButton;

  /// Button to collapse color picker and use random color
  ///
  /// In en, this message translates to:
  /// **'Use Random Color'**
  String get useRandomColor;

  /// Button to open advanced color picker
  ///
  /// In en, this message translates to:
  /// **'Custom Color'**
  String get customColorButton;

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
  /// **'Tap the star button to create your first star'**
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
  /// **'Move to Trash? (Recoverable for 30 days)'**
  String get deleteWarning;

  /// No description provided for @exitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit GratiStellar?'**
  String get exitTitle;

  /// No description provided for @exitMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit GratiStellar?'**
  String get exitMessage;

  /// No description provided for @exitButton.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitButton;

  /// No description provided for @trashMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trashMenuItem;

  /// No description provided for @trashScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trashScreenTitle;

  /// No description provided for @trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmpty;

  /// No description provided for @trashEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Deleted items appear here for 30 days'**
  String get trashEmptyDescription;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String daysRemaining(int count);

  /// No description provided for @restoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreButton;

  /// No description provided for @deleteForeverButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deleteForeverButton;

  /// No description provided for @restoreDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Item?'**
  String get restoreDialogTitle;

  /// No description provided for @restoreDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will restore the gratitude to your sky.'**
  String get restoreDialogContent;

  /// No description provided for @permanentDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently?'**
  String get permanentDeleteDialogTitle;

  /// No description provided for @permanentDeleteDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. The gratitude will be permanently deleted.'**
  String get permanentDeleteDialogContent;

  /// No description provided for @gratitudeRestored.
  ///
  /// In en, this message translates to:
  /// **'Gratitude restored'**
  String get gratitudeRestored;

  /// No description provided for @gratitudePermanentlyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Gratitude permanently deleted'**
  String get gratitudePermanentlyDeleted;

  /// No description provided for @deleteConfirmationContent.
  ///
  /// In en, this message translates to:
  /// **'Move to Trash? (Recoverable for 30 days)'**
  String get deleteConfirmationContent;

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
  /// **'Delay (seconds)'**
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

  /// Error when email is already in use during sign up
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try signing in instead.'**
  String get errorEmailInUse;

  /// Error when email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid email address format.'**
  String get errorInvalidEmail;

  /// Error when password doesn't meet requirements
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 6 characters.'**
  String get errorWeakPassword;

  /// Error when user account doesn't exist
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get errorUserNotFound;

  /// Error when password is incorrect
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get errorWrongPassword;

  /// Error when credentials are invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials. Please check your email and password.'**
  String get errorInvalidCredential;

  /// Error when credential is already in use
  ///
  /// In en, this message translates to:
  /// **'This email is already linked to another account.'**
  String get errorCredentialInUse;

  /// Error when too many auth attempts made
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please try again later.'**
  String get errorTooManyRequests;

  /// Error when network request fails
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your internet connection.'**
  String get errorNetworkFailed;

  /// Error when user session is lost
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get errorNoUserSignedIn;

  /// Error when trying to link an account that's already linked
  ///
  /// In en, this message translates to:
  /// **'This account is already linked to another user.'**
  String get errorAlreadyLinked;

  /// Generic fallback error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
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

  /// Default display name for anonymous users
  ///
  /// In en, this message translates to:
  /// **'Grateful User'**
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

  /// Sort option to display gratitude stars grouped by month
  ///
  /// In en, this message translates to:
  /// **'By Month'**
  String get sortByMonth;

  /// Sort option to display gratitude stars grouped by year
  ///
  /// In en, this message translates to:
  /// **'By Year'**
  String get sortByYear;

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

  /// Tooltip for restore button
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreTooltip;

  /// Tooltip for permanent delete button
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanentlyTooltip;

  /// No description provided for @errorLoadingTrash.
  ///
  /// In en, this message translates to:
  /// **'Error loading trash'**
  String get errorLoadingTrash;

  /// No description provided for @deletedOn.
  ///
  /// In en, this message translates to:
  /// **'Deleted {date}'**
  String deletedOn(String date);

  /// No description provided for @creatingGratitudeStar.
  ///
  /// In en, this message translates to:
  /// **'Creating gratitude star, please wait'**
  String get creatingGratitudeStar;

  /// No description provided for @addNewGratitudeStar.
  ///
  /// In en, this message translates to:
  /// **'Add new gratitude star'**
  String get addNewGratitudeStar;

  /// No description provided for @addStarHint.
  ///
  /// In en, this message translates to:
  /// **'Opens dialog to write your gratitude'**
  String get addStarHint;

  /// No description provided for @mindfulnessIntervalSlider.
  ///
  /// In en, this message translates to:
  /// **'Mindfulness delay slider'**
  String get mindfulnessIntervalSlider;

  /// No description provided for @mindfulnessIntervalHint.
  ///
  /// In en, this message translates to:
  /// **'Adjust time between gratitudes from 3 to 30 seconds'**
  String get mindfulnessIntervalHint;

  /// No description provided for @hideOtherGratitudes.
  ///
  /// In en, this message translates to:
  /// **'Hide other gratitudes'**
  String get hideOtherGratitudes;

  /// No description provided for @showAllGratitudes.
  ///
  /// In en, this message translates to:
  /// **'Show all gratitudes'**
  String get showAllGratitudes;

  /// No description provided for @switchToSingleStarView.
  ///
  /// In en, this message translates to:
  /// **'Switch to single star view'**
  String get switchToSingleStarView;

  /// No description provided for @showAllStarsInSky.
  ///
  /// In en, this message translates to:
  /// **'Show all stars in sky'**
  String get showAllStarsInSky;

  /// No description provided for @exitMindfulnessMode.
  ///
  /// In en, this message translates to:
  /// **'Exit mindfulness mode'**
  String get exitMindfulnessMode;

  /// No description provided for @enterMindfulnessMode.
  ///
  /// In en, this message translates to:
  /// **'Enter mindfulness mode'**
  String get enterMindfulnessMode;

  /// No description provided for @stopCyclingGratitudes.
  ///
  /// In en, this message translates to:
  /// **'Stop cycling through gratitudes'**
  String get stopCyclingGratitudes;

  /// No description provided for @startMindfulViewing.
  ///
  /// In en, this message translates to:
  /// **'Start mindful viewing of your gratitudes'**
  String get startMindfulViewing;

  /// No description provided for @actionButton.
  ///
  /// In en, this message translates to:
  /// **'Action button'**
  String get actionButton;

  /// No description provided for @tapToActivate.
  ///
  /// In en, this message translates to:
  /// **'Tap to activate'**
  String get tapToActivate;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get accountSettings;

  /// No description provided for @manageAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Manage your account and authentication'**
  String get manageAccountHint;

  /// No description provided for @viewGratitudesAsList.
  ///
  /// In en, this message translates to:
  /// **'View your gratitudes as a text list'**
  String get viewGratitudesAsList;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @fontSizeSlider.
  ///
  /// In en, this message translates to:
  /// **'Font size slider'**
  String get fontSizeSlider;

  /// No description provided for @adjustTextSize.
  ///
  /// In en, this message translates to:
  /// **'Adjust text size from 75% to 175%'**
  String get adjustTextSize;

  /// No description provided for @fontPreviewText.
  ///
  /// In en, this message translates to:
  /// **'Preview: The quick brown fox jumps'**
  String get fontPreviewText;

  /// No description provided for @trashWithCount.
  ///
  /// In en, this message translates to:
  /// **'Trash, {count} deleted items'**
  String trashWithCount(int count);

  /// No description provided for @viewDeletedGratitudes.
  ///
  /// In en, this message translates to:
  /// **'View and restore deleted gratitudes'**
  String get viewDeletedGratitudes;

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @sendFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Send feedback about the app'**
  String get sendFeedbackHint;

  /// No description provided for @closeAppHint.
  ///
  /// In en, this message translates to:
  /// **'Close the application'**
  String get closeAppHint;

  /// No description provided for @clearLayerCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Layer Cache'**
  String get clearLayerCache;

  /// No description provided for @regenerateBackgroundHint.
  ///
  /// In en, this message translates to:
  /// **'Regenerate background layers'**
  String get regenerateBackgroundHint;

  /// No description provided for @regenerateBackgroundLayers.
  ///
  /// In en, this message translates to:
  /// **'Regenerate background layers'**
  String get regenerateBackgroundLayers;

  /// No description provided for @clearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache?'**
  String get clearCacheTitle;

  /// No description provided for @clearCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'This will regenerate all background layers. The app will restart.'**
  String get clearCacheMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared. Restart the app to regenerate.'**
  String get cacheCleared;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({buildNumber})'**
  String version(String version, String buildNumber);

  /// No description provided for @openMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get openMenu;

  /// No description provided for @openNavigationMenu.
  ///
  /// In en, this message translates to:
  /// **'Open navigation menu'**
  String get openNavigationMenu;

  /// Template for sharing gratitude
  ///
  /// In en, this message translates to:
  /// **'{userName} shared their gratitude with you:\n{gratitudeText}\n\n- GratiStellar - your universe of gratitude'**
  String shareTemplate(String userName, String gratitudeText);

  /// Menu item for galaxy management
  ///
  /// In en, this message translates to:
  /// **'My Galaxies'**
  String get myGalaxies;

  /// Hint for galaxy management menu item
  ///
  /// In en, this message translates to:
  /// **'Create and switch between galaxy collections'**
  String get manageGalaxiesHint;

  /// Button text to create a new galaxy
  ///
  /// In en, this message translates to:
  /// **'Create New Galaxy'**
  String get createNewGalaxy;

  /// Hint for create new galaxy button
  ///
  /// In en, this message translates to:
  /// **'Start a new galaxy collection with a fresh sky'**
  String get startNewGalaxyWithFreshStars;

  /// Label for naming a galaxy
  ///
  /// In en, this message translates to:
  /// **'Name your galaxy:'**
  String get nameYourGalaxy;

  /// Label for galaxy name input field
  ///
  /// In en, this message translates to:
  /// **'Galaxy name'**
  String get galaxyNameField;

  /// Hint text for galaxy name field
  ///
  /// In en, this message translates to:
  /// **'e.g., 2025, Work Journal, Travel Memories'**
  String get galaxyNameHint;

  /// Hint for galaxy name accessibility
  ///
  /// In en, this message translates to:
  /// **'Enter a name for your galaxy'**
  String get enterGalaxyName;

  /// Description text for galaxy creation
  ///
  /// In en, this message translates to:
  /// **'Your current stars will remain in their galaxy and you can return anytime.'**
  String get createGalaxyDescription;

  /// Button text to confirm galaxy creation
  ///
  /// In en, this message translates to:
  /// **'Create Galaxy'**
  String get createGalaxy;

  /// Title for rename galaxy dialog
  ///
  /// In en, this message translates to:
  /// **'Rename Galaxy'**
  String get renameGalaxy;

  /// Hint for rename galaxy field
  ///
  /// In en, this message translates to:
  /// **'Enter new name for this galaxy'**
  String get enterNewGalaxyName;

  /// Empty state title when no galaxies exist
  ///
  /// In en, this message translates to:
  /// **'No galaxies yet'**
  String get noGalaxiesYet;

  /// Empty state description for first galaxy
  ///
  /// In en, this message translates to:
  /// **'Create your first galaxy to start organizing your gratitudes'**
  String get createYourFirstGalaxy;

  /// Badge text for active galaxy
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Accessibility hint for active galaxy
  ///
  /// In en, this message translates to:
  /// **'This is your currently active galaxy'**
  String get currentlyActiveGalaxy;

  /// Accessibility hint for switching galaxies
  ///
  /// In en, this message translates to:
  /// **'Tap to switch to this galaxy'**
  String get tapToSwitchToGalaxy;

  /// Accessibility label for active galaxy item
  ///
  /// In en, this message translates to:
  /// **'{name} (Active) - {starCount} stars'**
  String activeGalaxyItem(String name, int starCount);

  /// Success message when switching to a different galaxy
  ///
  /// In en, this message translates to:
  /// **'Switched to {galaxyName}'**
  String galaxySwitchedSuccess(String galaxyName);

  /// Error message when galaxy switch fails
  ///
  /// In en, this message translates to:
  /// **'Failed to switch galaxy: {error}'**
  String galaxySwitchFailed(String error);

  /// Success message when new galaxy is created
  ///
  /// In en, this message translates to:
  /// **'Created new galaxy: {name}'**
  String galaxyCreatedSuccess(String name);

  /// Error message when galaxy creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create galaxy: {error}'**
  String galaxyCreateFailed(String error);

  /// Success message when galaxy is renamed
  ///
  /// In en, this message translates to:
  /// **'Renamed galaxy to: {name}'**
  String galaxyRenamedSuccess(String name);

  /// Error message when galaxy rename fails
  ///
  /// In en, this message translates to:
  /// **'Failed to rename galaxy: {error}'**
  String galaxyRenameFailed(String error);

  /// Badge text shown on the currently active galaxy
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get galaxyActiveBadge;

  /// Loading message shown when regenerating star positions
  ///
  /// In en, this message translates to:
  /// **'Adjusting star field...'**
  String get adjustingStarFieldMessage;

  /// Debug menu title for force sync feature
  ///
  /// In en, this message translates to:
  /// **'🚨 RECOVER DATA FROM CLOUD'**
  String get debugRecoverDataTitle;

  /// Debug menu subtitle for force sync feature
  ///
  /// In en, this message translates to:
  /// **'Force full sync from Firebase'**
  String get debugRecoverDataSubtitle;

  /// Success message after debug force sync
  ///
  /// In en, this message translates to:
  /// **'Full sync complete! Check your stars.'**
  String get debugSyncCompleteMessage;

  /// Accessibility label for galaxy item
  ///
  /// In en, this message translates to:
  /// **'{name} - {starCount} stars'**
  String galaxyItem(String name, int starCount);

  /// Galaxy statistics subtitle
  ///
  /// In en, this message translates to:
  /// **'{starCount} stars • Created {date}'**
  String galaxyStats(int starCount, String date);

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Menu item and dialog title for exporting backup
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// Subtitle for export backup menu item
  ///
  /// In en, this message translates to:
  /// **'Create encrypted backup file'**
  String get exportBackupSubtitle;

  /// Description of what backup export does
  ///
  /// In en, this message translates to:
  /// **'Create an encrypted backup of all your gratitudes, galaxies, and preferences.'**
  String get exportBackupDescription;

  /// Header for list of backup contents
  ///
  /// In en, this message translates to:
  /// **'What\'s included:'**
  String get backupWhatsIncluded;

  /// Backup includes gratitudes
  ///
  /// In en, this message translates to:
  /// **'All gratitude entries'**
  String get backupIncludesGratitudes;

  /// Backup includes galaxies
  ///
  /// In en, this message translates to:
  /// **'All galaxies'**
  String get backupIncludesGalaxies;

  /// Backup includes preferences
  ///
  /// In en, this message translates to:
  /// **'App preferences'**
  String get backupIncludesPreferences;

  /// Backup is encrypted
  ///
  /// In en, this message translates to:
  /// **'Encrypted for security'**
  String get backupEncrypted;

  /// Button text to create backup
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// Status message while creating backup
  ///
  /// In en, this message translates to:
  /// **'Creating backup...'**
  String get creatingBackup;

  /// Success message after backup creation
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully!\n{summary}'**
  String backupCreatedSuccess(String summary);

  /// Simple success message for backup
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully!'**
  String get backupCreatedSimple;

  /// Error message when backup creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup'**
  String get backupCreateFailed;

  /// Menu item and dialog title for restoring backup
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// Subtitle for restore backup menu item
  ///
  /// In en, this message translates to:
  /// **'Import data from backup file'**
  String get restoreBackupSubtitle;

  /// Description of restore backup process
  ///
  /// In en, this message translates to:
  /// **'Select a backup file to restore your data.'**
  String get restoreBackupDescription;

  /// Button text to select backup file
  ///
  /// In en, this message translates to:
  /// **'Select Backup File'**
  String get selectBackupFile;

  /// Button text to change selected file
  ///
  /// In en, this message translates to:
  /// **'Change File'**
  String get changeFile;

  /// Label indicating backup file is valid
  ///
  /// In en, this message translates to:
  /// **'Valid Backup'**
  String get validBackup;

  /// Error for invalid backup file
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file'**
  String get invalidBackup;

  /// Shows when backup was created
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String backupCreated(String date);

  /// Shows app version of backup
  ///
  /// In en, this message translates to:
  /// **'App Version: {version}'**
  String backupAppVersion(String version);

  /// Label for restore strategy selection
  ///
  /// In en, this message translates to:
  /// **'Restore Strategy:'**
  String get restoreStrategy;

  /// Merge restore strategy option
  ///
  /// In en, this message translates to:
  /// **'Merge (Recommended)'**
  String get restoreStrategyMerge;

  /// Description of merge strategy
  ///
  /// In en, this message translates to:
  /// **'Keep all data, prefer newer versions'**
  String get restoreStrategyMergeDescription;

  /// Replace all restore strategy option
  ///
  /// In en, this message translates to:
  /// **'Replace All'**
  String get restoreStrategyReplace;

  /// Description of replace strategy
  ///
  /// In en, this message translates to:
  /// **'Delete current data, use only backup'**
  String get restoreStrategyReplaceDescription;

  /// Button text to restore backup
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// Status while validating backup file
  ///
  /// In en, this message translates to:
  /// **'Validating backup...'**
  String get validatingBackup;

  /// Status while restoring backup
  ///
  /// In en, this message translates to:
  /// **'Restoring backup...'**
  String get restoringBackup;

  /// Success message after restore
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully!\n{summary}'**
  String backupRestoredSuccess(String summary);

  /// Simple success message for restore
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully!'**
  String get backupRestoredSimple;

  /// Error message when restore fails
  ///
  /// In en, this message translates to:
  /// **'Failed to import backup'**
  String get backupRestoreFailed;

  /// Button text to retry an operation
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Error when sync operation fails
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Your changes will be retried automatically.'**
  String get errorSyncFailed;

  /// Error when operation times out
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please check your connection.'**
  String get errorTimeout;

  /// Error when user lacks permissions
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Please sign in again.'**
  String get errorPermissionDenied;

  /// Error when Firebase quota is exceeded
  ///
  /// In en, this message translates to:
  /// **'Daily quota exceeded. Please try again tomorrow.'**
  String get errorQuotaExceeded;

  /// Error when service is temporarily down
  ///
  /// In en, this message translates to:
  /// **'Service temporarily unavailable. Please try again.'**
  String get errorServiceUnavailable;

  /// Error when email or password is wrong during sign-in
  ///
  /// In en, this message translates to:
  /// **'Email or password incorrect. Double-check your credentials.'**
  String get errorEmailOrPasswordIncorrect;

  /// Title for first-star reminder prompt bottom sheet
  ///
  /// In en, this message translates to:
  /// **'You\'re off to a great start!'**
  String get reminderPromptTitle;

  /// Body text for reminder prompt
  ///
  /// In en, this message translates to:
  /// **'Would you like a daily reminder to reflect on your gratitude?'**
  String get reminderPromptBody;

  /// Additional context about smart reminder logic
  ///
  /// In en, this message translates to:
  /// **'We\'ll only remind you on days you haven\'t created a star yet.'**
  String get reminderPromptSubtext;

  /// Button to enable daily reminders
  ///
  /// In en, this message translates to:
  /// **'Enable Reminder ✨'**
  String get enableReminderButton;

  /// Accessibility hint for enable button
  ///
  /// In en, this message translates to:
  /// **'Set up daily gratitude reminder'**
  String get enableReminderHint;

  /// Button to dismiss reminder prompt
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLaterButton;

  /// Title for time picker dialog
  ///
  /// In en, this message translates to:
  /// **'Choose reminder time'**
  String get reminderTimePickerTitle;

  /// Toast message when reminder is enabled
  ///
  /// In en, this message translates to:
  /// **'Daily reminder enabled!'**
  String get reminderEnabledSuccess;

  /// Toast message when reminder is disabled
  ///
  /// In en, this message translates to:
  /// **'Daily reminder disabled'**
  String get reminderDisabledSuccess;

  /// Toast message when time is changed
  ///
  /// In en, this message translates to:
  /// **'Reminder time updated'**
  String get reminderTimeUpdatedSuccess;

  /// Error message when permission is denied
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied'**
  String get reminderPermissionDenied;

  /// Settings menu item title
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminderTitle;

  /// Accessibility label for reminder setting
  ///
  /// In en, this message translates to:
  /// **'Daily reminder setting'**
  String get dailyReminderSetting;

  /// Accessibility hint when enabled
  ///
  /// In en, this message translates to:
  /// **'Daily reminder is enabled, tap to change time'**
  String get dailyReminderEnabledHint;

  /// Accessibility hint when disabled
  ///
  /// In en, this message translates to:
  /// **'Enable daily gratitude reminder'**
  String get dailyReminderDisabledHint;

  /// Display text showing reminder time
  ///
  /// In en, this message translates to:
  /// **'Remind me at {time}'**
  String reminderTimeDisplay(String time);

  /// Age verification question for COPPA compliance
  ///
  /// In en, this message translates to:
  /// **'Are you 13 years or older?'**
  String get ageGateQuestion;

  /// Button to confirm user is 13 or older
  ///
  /// In en, this message translates to:
  /// **'Yes, I\'m 13 or older'**
  String get ageGateYesButton;

  /// Button to indicate user is under 13
  ///
  /// In en, this message translates to:
  /// **'No, I\'m under 13'**
  String get ageGateNoButton;

  /// Accessibility hint for yes button
  ///
  /// In en, this message translates to:
  /// **'Confirm you are 13 or older to continue'**
  String get ageGateYesHint;

  /// Accessibility hint for no button
  ///
  /// In en, this message translates to:
  /// **'Indicate you are under 13'**
  String get ageGateNoHint;

  /// Title for under-13 dialog
  ///
  /// In en, this message translates to:
  /// **'Age Requirement'**
  String get ageGateUnder13Title;

  /// Message shown to users under 13
  ///
  /// In en, this message translates to:
  /// **'You must be at least 13 years old to use GratiStellar. Thank you for your interest!'**
  String get ageGateUnder13Message;

  /// Title for consent screen
  ///
  /// In en, this message translates to:
  /// **'Privacy & Terms'**
  String get consentTitle;

  /// Introduction message for consent screen
  ///
  /// In en, this message translates to:
  /// **'Before we begin, please review our privacy practices:'**
  String get consentMessage;

  /// First privacy bullet point
  ///
  /// In en, this message translates to:
  /// **'Your data is stored securely and privately'**
  String get consentBullet1;

  /// Second privacy bullet point
  ///
  /// In en, this message translates to:
  /// **'We never share your gratitudes with anyone'**
  String get consentBullet2;

  /// Third privacy bullet point
  ///
  /// In en, this message translates to:
  /// **'You can export or delete your data anytime'**
  String get consentBullet3;

  /// First part of privacy policy checkbox text
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the '**
  String get consentPrivacyPart1;

  /// Clickable privacy policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get consentPrivacyLink;

  /// First part of terms checkbox text
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the '**
  String get consentTermsPart1;

  /// Clickable terms link text
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get consentTermsLink;

  /// Accessibility label for privacy checkbox
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy acceptance checkbox'**
  String get consentPrivacyCheckbox;

  /// Accessibility label for terms checkbox
  ///
  /// In en, this message translates to:
  /// **'Terms of Service acceptance checkbox'**
  String get consentTermsCheckbox;

  /// Button to accept policies and create account
  ///
  /// In en, this message translates to:
  /// **'Accept & Continue'**
  String get consentAcceptButton;

  /// Accessibility hint when button is enabled
  ///
  /// In en, this message translates to:
  /// **'Create account and start using GratiStellar'**
  String get consentAcceptHint;

  /// Accessibility hint when button is disabled
  ///
  /// In en, this message translates to:
  /// **'You must accept both policies to continue'**
  String get consentAcceptDisabledHint;

  /// Error message when URL fails to open
  ///
  /// In en, this message translates to:
  /// **'Could not open link. Please check your internet connection.'**
  String get consentUrlError;

  /// Error when no browser application is available
  ///
  /// In en, this message translates to:
  /// **'No browser app found. Please install a web browser to view this link.'**
  String get consentUrlErrorNoBrowser;

  /// Error when URL scheme is not supported
  ///
  /// In en, this message translates to:
  /// **'This link cannot be opened. The URL format is not supported.'**
  String get consentUrlErrorUnsupported;

  /// Error when network connection is unavailable
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to the internet. Please check your connection and try again.'**
  String get consentUrlErrorNetwork;

  /// Button to copy URL to clipboard as fallback
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get consentCopyUrlButton;

  /// Success message when URL is copied
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get consentUrlCopied;

  /// Button to retry opening URL
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get consentRetryButton;

  /// Title for name collection screen
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get nameCollectionTitle;

  /// Subtitle explaining why we ask for name
  ///
  /// In en, this message translates to:
  /// **'This helps personalize your gratitude journey'**
  String get nameCollectionSubtitle;

  /// Accessibility label for name input field
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameCollectionLabel;

  /// Accessibility hint for name input
  ///
  /// In en, this message translates to:
  /// **'Enter your name to continue'**
  String get nameCollectionHint;

  /// Placeholder text for name input
  ///
  /// In en, this message translates to:
  /// **'e.g., Alex'**
  String get nameCollectionPlaceholder;

  /// Button to create account with name
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get nameCollectionButton;

  /// Accessibility hint for continue button
  ///
  /// In en, this message translates to:
  /// **'Create your account and start using GratiStellar'**
  String get nameCollectionButtonHint;
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
