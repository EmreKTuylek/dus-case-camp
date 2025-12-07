import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageTurkish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @newWeekNotifications.
  ///
  /// In en, this message translates to:
  /// **'New Week Notifications'**
  String get newWeekNotifications;

  /// No description provided for @newWeekNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a new week starts.'**
  String get newWeekNotificationsDesc;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get navLeaderboard;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DUS Case Camp'**
  String get appTitle;

  /// No description provided for @fillYourGaps.
  ///
  /// In en, this message translates to:
  /// **'Fill Your Gaps'**
  String get fillYourGaps;

  /// No description provided for @greatWork.
  ///
  /// In en, this message translates to:
  /// **'Great work! No immediate gaps found.'**
  String get greatWork;

  /// No description provided for @latestCases.
  ///
  /// In en, this message translates to:
  /// **'Latest Cases'**
  String get latestCases;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noCases.
  ///
  /// In en, this message translates to:
  /// **'No cases available yet.'**
  String get noCases;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get tabBadges;

  /// No description provided for @tabCertificates.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get tabCertificates;

  /// No description provided for @cardSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get cardSchool;

  /// No description provided for @cardYear.
  ///
  /// In en, this message translates to:
  /// **'Year of Study'**
  String get cardYear;

  /// No description provided for @cardFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get cardFavorites;

  /// No description provided for @cardWatchLater.
  ///
  /// In en, this message translates to:
  /// **'Watch Later'**
  String get cardWatchLater;

  /// No description provided for @cardAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get cardAdmin;

  /// No description provided for @cardSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get cardSettings;

  /// No description provided for @btnLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get btnLogout;

  /// No description provided for @noBadges.
  ///
  /// In en, this message translates to:
  /// **'No badges yet. Keep studying!'**
  String get noBadges;

  /// No description provided for @noCertificates.
  ///
  /// In en, this message translates to:
  /// **'No certificates yet. Complete modules to earn them!'**
  String get noCertificates;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search cases...'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Filter by Difficulty'**
  String get filterDifficulty;

  /// No description provided for @filterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get filterAny;

  /// No description provided for @noCasesFound.
  ///
  /// In en, this message translates to:
  /// **'No cases found matching filters.'**
  String get noCasesFound;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @tabWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get tabWeekly;

  /// No description provided for @tabMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get tabMonthly;

  /// No description provided for @tabAllTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get tabAllTime;

  /// No description provided for @noRankings.
  ///
  /// In en, this message translates to:
  /// **'No rankings for this period yet.'**
  String get noRankings;

  /// No description provided for @unknownStudent.
  ///
  /// In en, this message translates to:
  /// **'Unknown Student'**
  String get unknownStudent;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get progressTitle;

  /// No description provided for @noAnalytics.
  ///
  /// In en, this message translates to:
  /// **'No analytics data yet. Submit a case!'**
  String get noAnalytics;

  /// No description provided for @weeklyPerformance.
  ///
  /// In en, this message translates to:
  /// **'Weekly Performance'**
  String get weeklyPerformance;

  /// No description provided for @specialtyStrengths.
  ///
  /// In en, this message translates to:
  /// **'Specialty Strengths'**
  String get specialtyStrengths;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @statCasesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Cases Completed'**
  String get statCasesCompleted;

  /// No description provided for @statTotalScore.
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get statTotalScore;

  /// No description provided for @notEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data.'**
  String get notEnoughData;

  /// No description provided for @activeDays.
  ///
  /// In en, this message translates to:
  /// **'Active Days'**
  String get activeDays;

  /// No description provided for @keepStreak.
  ///
  /// In en, this message translates to:
  /// **'Keep up the streak!'**
  String get keepStreak;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
