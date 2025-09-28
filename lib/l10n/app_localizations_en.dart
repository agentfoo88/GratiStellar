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
}
