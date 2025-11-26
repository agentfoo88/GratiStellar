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
  String get chooseColorButton => 'Choose Star Color';

  @override
  String get useRandomColor => 'Use Random Color';

  @override
  String get customColorButton => 'Custom Color';

  @override
  String get statsTotal => 'Total';

  @override
  String get statsThisWeek => 'This Week';

  @override
  String get statsToday => 'Today';

  @override
  String get emptyStateTitle => 'Your constellation awaits';

  @override
  String get emptyStateSubtitle =>
      'Tap the star button to create your first star';

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
  String get deleteWarning => 'Move to Trash? (Recoverable for 30 days)';

  @override
  String get exitTitle => 'Exit GratiStellar?';

  @override
  String get exitMessage => 'Are you sure you want to exit GratiStellar?';

  @override
  String get exitButton => 'Exit';

  @override
  String get trashMenuItem => 'Trash';

  @override
  String get trashScreenTitle => 'Trash';

  @override
  String get trashEmpty => 'Trash is empty';

  @override
  String get trashEmptyDescription => 'Deleted items appear here for 30 days';

  @override
  String daysRemaining(int count) {
    return '$count days left';
  }

  @override
  String get restoreButton => 'Restore';

  @override
  String get deleteForeverButton => 'Delete Forever';

  @override
  String get restoreDialogTitle => 'Restore Item?';

  @override
  String get restoreDialogContent =>
      'This will restore the gratitude to your sky.';

  @override
  String get permanentDeleteDialogTitle => 'Delete Permanently?';

  @override
  String get permanentDeleteDialogContent =>
      'This action cannot be undone. The gratitude will be permanently deleted.';

  @override
  String get gratitudeRestored => 'Gratitude restored';

  @override
  String get gratitudePermanentlyDeleted => 'Gratitude permanently deleted';

  @override
  String get deleteConfirmationContent =>
      'Move to Trash? (Recoverable for 30 days)';

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
  String get mindfulnessIntervalLabel => 'Delay (seconds)';

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
  String get errorUserNotFound => 'No account found with this email.';

  @override
  String get errorWrongPassword => 'Incorrect password. Please try again.';

  @override
  String get errorInvalidCredential =>
      'Invalid credentials. Please check your email and password.';

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
  String get errorNoUserSignedIn => 'Session expired. Please sign in again.';

  @override
  String get errorAlreadyLinked =>
      'This account is already linked to another user.';

  @override
  String get errorGeneric => 'An unexpected error occurred.';

  @override
  String get signOutButton => 'Sign Out';

  @override
  String get signOutTitle => 'Sign Out';

  @override
  String get signOutMessage =>
      'Are you sure you want to sign out?\n\nYour data will remain synced to your account.';

  @override
  String get accountMenuItem => 'Account';

  @override
  String get signInWithEmailMenuItem => 'Sign In with Email';

  @override
  String get defaultUserName => 'User';

  @override
  String get accountTitle => 'Account';

  @override
  String get displayNameLabel => 'Display Name';

  @override
  String get changeDisplayName => 'Change Display Name';

  @override
  String get updateButton => 'Update';

  @override
  String get displayNameUpdated => 'Display name updated successfully!';

  @override
  String get sortNewestFirst => 'Newest First';

  @override
  String get sortOldestFirst => 'Oldest First';

  @override
  String get sortAlphabeticalAZ => 'A → Z';

  @override
  String get sortAlphabeticalZA => 'Z → A';

  @override
  String get sortByColor => 'By Color';

  @override
  String get sortByMonth => 'By Month';

  @override
  String get sortByYear => 'By Year';

  @override
  String get feedbackMenuItem => 'Send Feedback';

  @override
  String get feedbackDialogTitle => 'Send Feedback';

  @override
  String get feedbackTypeLabel => 'Type';

  @override
  String get feedbackTypeBug => 'Bug/Error';

  @override
  String get feedbackTypeFeature => 'Feature Request';

  @override
  String get feedbackTypeGeneral => 'General Feedback';

  @override
  String get feedbackMessageLabel => 'Message';

  @override
  String get feedbackMessageHint => 'Describe your feedback...';

  @override
  String get feedbackMessageRequired => 'Please enter your feedback';

  @override
  String get feedbackEmailLabel => 'Contact Email (Optional)';

  @override
  String get feedbackEmailHint => 'For follow-up on this feedback';

  @override
  String get feedbackEmailInvalid => 'Please enter a valid email';

  @override
  String get feedbackSubmit => 'Submit';

  @override
  String get feedbackSuccess => 'Thank you for your feedback!';

  @override
  String get feedbackError => 'Failed to submit feedback. Please try again.';

  @override
  String get restoreTooltip => 'Restore';

  @override
  String get deletePermanentlyTooltip => 'Delete Permanently';

  @override
  String get errorLoadingTrash => 'Error loading trash';

  @override
  String deletedOn(String date) {
    return 'Deleted $date';
  }

  @override
  String get creatingGratitudeStar => 'Creating gratitude star, please wait';

  @override
  String get addNewGratitudeStar => 'Add new gratitude star';

  @override
  String get addStarHint => 'Opens dialog to write your gratitude';

  @override
  String get mindfulnessIntervalSlider => 'Mindfulness delay slider';

  @override
  String get mindfulnessIntervalHint =>
      'Adjust time between gratitudes from 3 to 30 seconds';

  @override
  String get hideOtherGratitudes => 'Hide other gratitudes';

  @override
  String get showAllGratitudes => 'Show all gratitudes';

  @override
  String get switchToSingleStarView => 'Switch to single star view';

  @override
  String get showAllStarsInSky => 'Show all stars in sky';

  @override
  String get exitMindfulnessMode => 'Exit mindfulness mode';

  @override
  String get enterMindfulnessMode => 'Enter mindfulness mode';

  @override
  String get stopCyclingGratitudes => 'Stop cycling through gratitudes';

  @override
  String get startMindfulViewing => 'Start mindful viewing of your gratitudes';

  @override
  String get actionButton => 'Action button';

  @override
  String get tapToActivate => 'Tap to activate';

  @override
  String get accountSettings => 'Account settings';

  @override
  String get manageAccountHint => 'Manage your account and authentication';

  @override
  String get viewGratitudesAsList => 'View your gratitudes as a text list';

  @override
  String get fontSize => 'Font Size';

  @override
  String get fontSizeSlider => 'Font size slider';

  @override
  String get adjustTextSize => 'Adjust text size from 75% to 175%';

  @override
  String get fontPreviewText => 'Preview: The quick brown fox jumps';

  @override
  String trashWithCount(int count) {
    return 'Trash, $count deleted items';
  }

  @override
  String get viewDeletedGratitudes => 'View and restore deleted gratitudes';

  @override
  String get trash => 'Trash';

  @override
  String get sendFeedbackHint => 'Send feedback about the app';

  @override
  String get closeAppHint => 'Close the application';

  @override
  String get clearLayerCache => 'Clear Layer Cache';

  @override
  String get regenerateBackgroundHint => 'Regenerate background layers';

  @override
  String get regenerateBackgroundLayers => 'Regenerate background layers';

  @override
  String get clearCacheTitle => 'Clear Cache?';

  @override
  String get clearCacheMessage =>
      'This will regenerate all background layers. The app will restart.';

  @override
  String get cancel => 'Cancel';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get cacheCleared => 'Cache cleared. Restart the app to regenerate.';

  @override
  String version(String version, String buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get openMenu => 'Open menu';

  @override
  String get openNavigationMenu => 'Open navigation menu';

  @override
  String shareTemplate(String userName, String gratitudeText) {
    return '$userName shared their gratitude with you:\n$gratitudeText\n\n- GratiStellar - your universe of gratitude';
  }

  @override
  String get myGalaxies => 'My Galaxies';

  @override
  String get manageGalaxiesHint =>
      'Create and switch between galaxy collections';

  @override
  String get createNewGalaxy => 'Create New Galaxy';

  @override
  String get startNewGalaxyWithFreshStars =>
      'Start a new galaxy collection with a fresh sky';

  @override
  String get nameYourGalaxy => 'Name your galaxy:';

  @override
  String get galaxyNameField => 'Galaxy name';

  @override
  String get galaxyNameHint => 'e.g., 2025, Work Journal, Travel Memories';

  @override
  String get enterGalaxyName => 'Enter a name for your galaxy';

  @override
  String get createGalaxyDescription =>
      'Your current stars will remain in their galaxy and you can return anytime.';

  @override
  String get createGalaxy => 'Create Galaxy';

  @override
  String get renameGalaxy => 'Rename Galaxy';

  @override
  String get enterNewGalaxyName => 'Enter new name for this galaxy';

  @override
  String get noGalaxiesYet => 'No galaxies yet';

  @override
  String get createYourFirstGalaxy =>
      'Create your first galaxy to start organizing your gratitudes';

  @override
  String get active => 'Active';

  @override
  String get currentlyActiveGalaxy => 'This is your currently active galaxy';

  @override
  String get tapToSwitchToGalaxy => 'Tap to switch to this galaxy';

  @override
  String activeGalaxyItem(String name, int starCount) {
    return '$name (Active) - $starCount stars';
  }

  @override
  String galaxySwitchedSuccess(String galaxyName) {
    return 'Switched to $galaxyName';
  }

  @override
  String galaxySwitchFailed(String error) {
    return 'Failed to switch galaxy: $error';
  }

  @override
  String galaxyCreatedSuccess(String name) {
    return 'Created new galaxy: $name';
  }

  @override
  String galaxyCreateFailed(String error) {
    return 'Failed to create galaxy: $error';
  }

  @override
  String galaxyRenamedSuccess(String name) {
    return 'Renamed galaxy to: $name';
  }

  @override
  String galaxyRenameFailed(String error) {
    return 'Failed to rename galaxy: $error';
  }

  @override
  String get galaxyActiveBadge => 'ACTIVE';

  @override
  String get adjustingStarFieldMessage => 'Adjusting star field...';

  @override
  String get debugRecoverDataTitle => '🚨 RECOVER DATA FROM CLOUD';

  @override
  String get debugRecoverDataSubtitle => 'Force full sync from Firebase';

  @override
  String get debugSyncCompleteMessage =>
      'Full sync complete! Check your stars.';

  @override
  String galaxyItem(String name, int starCount) {
    return '$name - $starCount stars';
  }

  @override
  String galaxyStats(int starCount, String date) {
    return '$starCount stars • Created $date';
  }

  @override
  String get save => 'Save';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get exportBackupSubtitle => 'Create encrypted backup file';

  @override
  String get exportBackupDescription =>
      'Create an encrypted backup of all your gratitudes, galaxies, and preferences.';

  @override
  String get backupWhatsIncluded => 'What\'s included:';

  @override
  String get backupIncludesGratitudes => 'All gratitude entries';

  @override
  String get backupIncludesGalaxies => 'All galaxies';

  @override
  String get backupIncludesPreferences => 'App preferences';

  @override
  String get backupEncrypted => 'Encrypted for security';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get creatingBackup => 'Creating backup...';

  @override
  String backupCreatedSuccess(String summary) {
    return 'Backup created successfully!\n$summary';
  }

  @override
  String get backupCreatedSimple => 'Backup created successfully!';

  @override
  String get backupCreateFailed => 'Failed to create backup';

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get restoreBackupSubtitle => 'Import data from backup file';

  @override
  String get restoreBackupDescription =>
      'Select a backup file to restore your data.';

  @override
  String get selectBackupFile => 'Select Backup File';

  @override
  String get changeFile => 'Change File';

  @override
  String get validBackup => 'Valid Backup';

  @override
  String get invalidBackup => 'Invalid backup file';

  @override
  String backupCreated(String date) {
    return 'Created: $date';
  }

  @override
  String backupAppVersion(String version) {
    return 'App Version: $version';
  }

  @override
  String get restoreStrategy => 'Restore Strategy:';

  @override
  String get restoreStrategyMerge => 'Merge (Recommended)';

  @override
  String get restoreStrategyMergeDescription =>
      'Keep all data, prefer newer versions';

  @override
  String get restoreStrategyReplace => 'Replace All';

  @override
  String get restoreStrategyReplaceDescription =>
      'Delete current data, use only backup';

  @override
  String get restore => 'Restore';

  @override
  String get validatingBackup => 'Validating backup...';

  @override
  String get restoringBackup => 'Restoring backup...';

  @override
  String backupRestoredSuccess(String summary) {
    return 'Backup restored successfully!\n$summary';
  }

  @override
  String get backupRestoredSimple => 'Backup restored successfully!';

  @override
  String get backupRestoreFailed => 'Failed to import backup';

  @override
  String get retry => 'Retry';

  @override
  String get errorSyncFailed =>
      'Sync failed. Your changes will be retried automatically.';

  @override
  String get errorTimeout => 'Request timed out. Please check your connection.';

  @override
  String get errorPermissionDenied =>
      'Permission denied. Please sign in again.';

  @override
  String get errorQuotaExceeded =>
      'Daily quota exceeded. Please try again tomorrow.';

  @override
  String get errorServiceUnavailable =>
      'Service temporarily unavailable. Please try again.';

  @override
  String get errorEmailOrPasswordIncorrect =>
      'Email or password incorrect. Double-check your credentials.';
}
