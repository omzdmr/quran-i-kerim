import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'strings/backup_strings.dart';
import 'strings/feature_strings.dart';
import 'strings/home_quick_action_strings.dart';
import 'strings/home_recent_reading_strings.dart';
import 'strings/home_verse_strings.dart';
import 'strings/plan_strings.dart';
import 'strings/prayer_notification_diagnostics_strings.dart';
import 'strings/prayer_notification_strings.dart';
import 'strings/reader_audio_transport_strings.dart';
import 'strings/reader_media_strings.dart';
import 'strings/reader_navigation_strings.dart';
import 'strings/reader_note_strings.dart';
import 'strings/strings_ar.dart';
import 'strings/strings_az.dart';
import 'strings/strings_en.dart';
import 'strings/strings_fr.dart';
import 'strings/strings_ru.dart';
import 'strings/strings_tr.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('tr'),
    Locale('en'),
    Locale('ar'),
    Locale('az'),
    Locale('ru'),
    Locale('fr'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'AppLocalizations not found.');
    return value!;
  }

  Map<String, String> get _map => switch (locale.languageCode) {
    'en' => enStrings,
    'ar' => arStrings,
    'az' => azStrings,
    'ru' => ruStrings,
    'fr' => frStrings,
    _ => trStrings,
  };

  String? _featureValue(String key) =>
      backupStrings[locale.languageCode]?[key] ??
      featureStrings[locale.languageCode]?[key] ??
      homeQuickActionStrings[locale.languageCode]?[key] ??
      homeRecentReadingStrings[locale.languageCode]?[key] ??
      homeVerseStrings[locale.languageCode]?[key] ??
      planStrings[locale.languageCode]?[key] ??
      prayerNotificationDiagnosticsStrings[locale.languageCode]?[key] ??
      readerAudioTransportStrings[locale.languageCode]?[key] ??
      readerMediaStrings[locale.languageCode]?[key] ??
      readerNavigationStrings[locale.languageCode]?[key] ??
      readerNoteStrings[locale.languageCode]?[key] ??
      backupStrings['en']?[key] ??
      featureStrings['en']?[key] ??
      homeQuickActionStrings['en']?[key] ??
      homeRecentReadingStrings['en']?[key] ??
      homeVerseStrings['en']?[key] ??
      planStrings['en']?[key] ??
      prayerNotificationDiagnosticsStrings['en']?[key] ??
      readerAudioTransportStrings['en']?[key] ??
      readerMediaStrings['en']?[key] ??
      readerNavigationStrings['en']?[key] ??
      readerNoteStrings['en']?[key] ??
      backupStrings['tr']?[key] ??
      featureStrings['tr']?[key] ??
      homeQuickActionStrings['tr']?[key] ??
      homeRecentReadingStrings['tr']?[key] ??
      homeVerseStrings['tr']?[key] ??
      planStrings['tr']?[key] ??
      prayerNotificationDiagnosticsStrings['tr']?[key] ??
      readerAudioTransportStrings['tr']?[key] ??
      readerMediaStrings['tr']?[key] ??
      readerNavigationStrings['tr']?[key] ??
      readerNoteStrings['tr']?[key];

  String _value(String key) =>
      _map[key] ??
      _featureValue(key) ??
      enStrings[key] ??
      trStrings[key] ??
      key;

  String _prayerNotificationValue(String key) =>
      prayerNotificationStrings[locale.languageCode]?[key] ??
      prayerNotificationStrings['en']?[key] ??
      prayerNotificationStrings['tr']?[key] ??
      key;

  String text(String key) => _value(key);

  String prayerNotificationTitle(String prayerId) =>
      _prayerNotificationValue('title').replaceAll(
        '{prayer}',
        _value(prayerId),
      );

  String prayerNotificationBody(String prayerId) =>
      _prayerNotificationValue('body').replaceAll(
        '{prayer}',
        _value(prayerId),
      );

  String get prayerNotificationChannel =>
      _prayerNotificationValue('channel');
  String get prayerNotificationChannelDescription =>
      _prayerNotificationValue('channelDescription');

  String get appTitle => _value('appTitle');
  String get navHome => _value('navHome');
  String get navQuran => _value('navQuran');
  String get navPlans => _value('navPlans');
  String get navDiscover => _value('navDiscover');
  String get navProfile => _value('navProfile');
  String get settings => _value('settings');
  String get appearance => _value('appearance');
  String get appearanceDescription => _value('appearanceDescription');
  String get useDeviceTheme => _value('useDeviceTheme');
  String get useDeviceThemeDescription => _value('useDeviceThemeDescription');
  String get lightTheme => _value('lightTheme');
  String get lightThemeDescription => _value('lightThemeDescription');
  String get darkTheme => _value('darkTheme');
  String get darkThemeDescription => _value('darkThemeDescription');
  String get language => _value('language');
  String get languageDescription => _value('languageDescription');
  String get useDeviceLanguage => _value('useDeviceLanguage');
  String get useDeviceLanguageDescription =>
      _value('useDeviceLanguageDescription');
  String get turkish => _value('turkish');
  String get english => _value('english');
  String get arabic => _value('arabic');
  String get azerbaijani => _value('azerbaijani');
  String get russian => _value('russian');
  String get french => _value('french');
  String get turkishDescription => _value('turkishDescription');
  String get englishDescription => _value('englishDescription');
  String get arabicDescription => _value('arabicDescription');
  String get azerbaijaniDescription => _value('azerbaijaniDescription');
  String get russianDescription => _value('russianDescription');
  String get frenchDescription => _value('frenchDescription');
  String get quranLanguage => _value('quranLanguage');
  String get quranLanguageDescription => _value('quranLanguageDescription');
  String get arabicOriginal => _value('arabicOriginal');
  String get arabicOriginalDescription => _value('arabicOriginalDescription');
  String get turkishMeal => _value('turkishMeal');
  String get turkishMealDescription => _value('turkishMealDescription');
  String get installed => _value('installed');
  String get moreTranslationsSoon => _value('moreTranslationsSoon');
  String get reading => _value('reading');
  String get rememberPosition => _value('rememberPosition');
  String get rememberPositionDescription =>
      _value('rememberPositionDescription');
  String get profile => _value('profile');
  String get guest => _value('guest');
  String get guestDescription => _value('guestDescription');
  String get savedVerses => _value('savedVerses');
  String get notes => _value('notes');
  String get downloads => _value('downloads');
  String get downloadsDescription => _value('downloadsDescription');
  String get languageAndTranslation => _value('languageAndTranslation');
  String get currentLanguageAndTranslation =>
      _value('currentLanguageAndTranslation');

  // Frequently used surface labels. Keeping typed getters for these avoids
  // scattering string keys through primary UI code while text(String) remains
  // available for the larger feature vocabulary.
  String get today => _value('today');
  String get save => _value('save');
  String get prayerTimes => _value('prayerTimes');
  String get translationLoading => _value('translationLoading');
  String get invalidPassage => _value('invalidPassage');
  String get passageTitle => _value('passageTitle');
  String get passageReadFullSurah => _value('passageReadFullSurah');
  String get passageTextSource => _value('passageTextSource');
  String get passageUnavailable => _value('passageUnavailable');
  String get homeVerseExpand => _value('homeVerseExpand');
  String get homeVerseCollapse => _value('homeVerseCollapse');
  String get homeVerseReadSurah => _value('homeVerseReadSurah');
  String get readerPersonalNote => _value('readerPersonalNote');
  String get readerEditNote => _value('readerEditNote');
  String get readerOpenArchive => _value('readerOpenArchive');
  String get readerVerseNoteTooltip => _value('readerVerseNoteTooltip');
  String get readerVerseFootnoteTooltip => _value('readerVerseFootnoteTooltip');
  String get readerAudioPlay => _value('readerAudioPlay');
  String get readerAudioPause => _value('readerAudioPause');
  String get readerAudioPreviousVerse => _value('readerAudioPreviousVerse');
  String get readerAudioNextVerse => _value('readerAudioNextVerse');
  String get readerMediaChannel => _value('readerMediaChannel');

  String readerMediaTitle(int surah, int ayah) => _value('readerMediaTitle')
      .replaceAll('{surah}', '$surah')
      .replaceAll('{ayah}', '$ayah');

  String readerMediaArtist(String source, int ayah, int verseCount) =>
      _value('readerMediaArtist')
          .replaceAll('{source}', source)
          .replaceAll('{ayah}', '$ayah')
          .replaceAll('{verseCount}', '$verseCount');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
