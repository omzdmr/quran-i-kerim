import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'strings/strings_ar.dart';
import 'strings/strings_az.dart';
import 'strings/strings_en.dart';
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
        _ => trStrings,
      };

  String _value(String key) =>
      _map[key] ?? enStrings[key] ?? trStrings[key] ?? key;

  String text(String key) => _value(key);

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
  String get useDeviceLanguageDescription => _value('useDeviceLanguageDescription');
  String get turkish => _value('turkish');
  String get english => _value('english');
  String get arabic => _value('arabic');
  String get azerbaijani => _value('azerbaijani');
  String get russian => _value('russian');
  String get turkishDescription => _value('turkishDescription');
  String get englishDescription => _value('englishDescription');
  String get arabicDescription => _value('arabicDescription');
  String get azerbaijaniDescription => _value('azerbaijaniDescription');
  String get russianDescription => _value('russianDescription');
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
  String get rememberPositionDescription => _value('rememberPositionDescription');
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
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
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
