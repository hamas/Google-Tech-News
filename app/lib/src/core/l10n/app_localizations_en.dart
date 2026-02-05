// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Google Tech News';

  @override
  String get latestNews => 'Latest News';

  @override
  String get savedArticles => 'Saved Articles';

  @override
  String get settings => 'Settings';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get sendFeedbackSubtitle => 'Report bugs or request features';

  @override
  String get localPrivate => '100% Local & Private';

  @override
  String get localPrivateSubtitle =>
      'Zero data sent to external AI APIs. All processing happens on-device.';

  @override
  String get version => 'Version';

  @override
  String get versionSubtitle => '1.1.0-Zero (Release)';

  @override
  String get backToTop => 'Back to Top';

  @override
  String get refresh => 'Refresh';

  @override
  String get search => 'Search news...';

  @override
  String get noArticlesFound => 'No articles found';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get share => 'Share';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get removeBookmark => 'Remove Bookmark';
}
