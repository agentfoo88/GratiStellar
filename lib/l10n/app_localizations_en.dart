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
}
