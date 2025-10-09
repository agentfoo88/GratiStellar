// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GratiStellar';

  @override
  String get appSubtitle => 'Your personal universe of gratitude';

  @override
  String get loadingMessage => 'Preparing your personal universe...';

  @override
  String get createStarModalTitle => 'Birth a New Star';

  @override
  String get createStarHint => 'What lights up your heart today?';

  @override
  String get createStarButton => 'Create Star';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get closeButton => 'Close';

  @override
  String get statsTotal => 'Total';

  @override
  String get statsThisWeek => 'This Week';

  @override
  String get statsToday => 'Today';

  @override
  String get emptyStateTitle => 'Your constellation awaits';

  @override
  String get emptyStateSubtitle => 'Tap the + button to birth your first star';

  @override
  String get editButton => 'Edit';

  @override
  String get shareButton => 'Share';

  @override
  String get deleteButton => 'Delete';

  @override
  String get saveButton => 'Save';

  @override
  String get changeColorButton => 'Change Color';

  @override
  String get editGratitudeHint => 'Edit your gratitude...';

  @override
  String get deleteConfirmTitle => 'Delete this gratitude?';

  @override
  String get deleteWarning => 'This action cannot be undone.';

  @override
  String get exitTitle => 'Exit GratiStellar?';

  @override
  String get exitMessage => 'Are you sure you want to exit the app?';

  @override
  String get exitButton => 'Exit';

  @override
  String get comingSoonTitle => 'Coming Soon';

  @override
  String get colorPreviewTitle => 'Color Preview';

  @override
  String get presetColorsTitle => 'Preset Colors';

  @override
  String get customColorTitle => 'Custom Color';

  @override
  String get hexColorLabel => 'Hex Color';

  @override
  String get hexColorHint => '#FFE135';

  @override
  String get applyButton => 'Apply';

  @override
  String get loginMenuItem => 'Login';

  @override
  String get listViewMenuItem => 'List View';

  @override
  String get mindfulnessIntervalLabel => 'Interval (seconds)';

  @override
  String get mindfulnessNoStarsTitle => 'No stars yet';

  @override
  String get mindfulnessNoStarsMessage =>
      'Add a star first to use mindfulness mode';

  @override
  String get listViewTitle => 'Your Gratitude Stars';

  @override
  String get jumpToStarButton => 'Jump to Star';

  @override
  String get todayLabel => 'Today';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String daysAgoLabel(int count) {
    return '$count days ago';
  }

  @override
  String get semanticOpenMenu => 'Open menu';

  @override
  String get semanticOpenMenuHint => 'Opens navigation drawer';

  @override
  String get semanticAddStar => 'Add new gratitude star';

  @override
  String get semanticAddStarHint => 'Opens dialog to create a new gratitude';

  @override
  String get semanticShowAll => 'Show all gratitudes';

  @override
  String get semanticMindfulness => 'Mindfulness mode';

  @override
  String get semanticToggleActive => 'Currently active, tap to disable';

  @override
  String get semanticToggleInactive => 'Tap to enable';

  @override
  String semanticStatLabel(String label, String value) {
    return '$label: $value';
  }

  @override
  String semanticStatIndicator(String label) {
    return '$label indicator';
  }

  @override
  String semanticGratitude(String text) {
    return 'Gratitude: $text';
  }

  @override
  String get semanticEmptyState =>
      'No gratitude stars yet. Tap the add button to create your first star.';

  @override
  String get semanticZoomIn => 'Zoom in';

  @override
  String get semanticZoomInHint => 'Increase zoom level';

  @override
  String get semanticZoomOut => 'Zoom out';

  @override
  String get semanticZoomOutHint => 'Decrease zoom level';

  @override
  String get semanticZoomReset => 'Reset zoom to 100 percent';

  @override
  String get semanticFitAll => 'Fit all stars in view';

  @override
  String get signInTitle => 'Sign In';

  @override
  String get signUpTitle => 'Create Account';

  @override
  String get signInSubtitle => 'Sign in to sync your data across devices';

  @override
  String get signUpSubtitle => 'Link your email to backup your gratitude stars';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'your@email.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'At least 6 characters';

  @override
  String get signInButton => 'Sign In';

  @override
  String get signUpButton => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get needToLinkAccount => 'No account with this email?';

  @override
  String get signInToggle => 'Sign In';

  @override
  String get signUpToggle => 'Create Account';

  @override
  String get accountCreatedSuccess =>
      'Account created! Your data is now backed up.';

  @override
  String get signInSuccess => 'Signed in successfully!';

  @override
  String get errorEmailPassword => 'Please enter both email and password';

  @override
  String get errorValidEmail => 'Please enter a valid email address';

  @override
  String get errorPasswordLength => 'Password must be at least 6 characters';

  @override
  String get errorEmailInUse =>
      'This email is already registered. Try signing in instead.';

  @override
  String get errorInvalidEmail => 'Invalid email address format.';

  @override
  String get errorWeakPassword =>
      'Password is too weak. Use at least 6 characters.';

  @override
  String get errorUserNotFound =>
      'No account found with this email.\n\nTap \"Create Account\" below to link your data.';

  @override
  String get errorWrongPassword => 'Incorrect password. Please try again.';

  @override
  String get errorInvalidCredential =>
      'No account found with this email.\n\nTap \"Create Account\" below to link your data.';

  @override
  String get errorCredentialInUse =>
      'This email is already linked to another account.';

  @override
  String get errorTooManyRequests =>
      'Too many failed attempts. Please try again later.';

  @override
  String get errorNetworkFailed =>
      'Network error. Check your internet connection.';

  @override
  String get errorNoUserSignedIn => 'Session expired. Please restart the app.';

  @override
  String get errorAlreadyLinked =>
      'Your account is already linked to an email address.';

  @override
  String get errorGeneric => 'An error occurred. Please try again.';
}
