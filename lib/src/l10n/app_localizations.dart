import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('tr'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'AppLocalizations bulunamadı.');
    return value!;
  }

  static const _tr = <String, String>{
    'appTitle': 'Kur’an-ı Kerim',
    'navHome': 'Ana Sayfa',
    'navQuran': 'Kuran',
    'navPlans': 'Planlar',
    'navDiscover': 'Keşfedin',
    'navProfile': 'Siz',
    'settings': 'Ayarlar',
    'appearance': 'Görünüm',
    'appearanceDescription': 'Uygulama cihazınızın temasını takip edebilir veya görünümü kendiniz seçebilirsiniz.',
    'useDeviceTheme': 'Cihaz ayarını kullan',
    'useDeviceThemeDescription': 'Telefon aydınlıksa aydınlık, koyuysa koyu tema',
    'lightTheme': 'Aydınlık',
    'lightThemeDescription': 'Her zaman aydınlık görünüm',
    'darkTheme': 'Koyu',
    'darkThemeDescription': 'Her zaman koyu görünüm',
    'language': 'Uygulama dili',
    'languageDescription': 'Şimdilik Türkçe kullanıyoruz. Yeni diller eklendiğinde cihaz dili otomatik seçilebilecek.',
    'useDeviceLanguage': 'Cihaz dilini kullan',
    'useDeviceLanguageDescription': 'Desteklenen diller arasından telefonunuzun dilini seçer',
    'turkish': 'Türkçe',
    'turkishDescription': 'Uygulamayı her zaman Türkçe kullan',
    'reading': 'Okuma',
    'rememberPosition': 'Kaldığım yeri hatırla',
    'rememberPositionDescription': 'Otomatik olarak açık',
    'profile': 'Siz',
    'guest': 'Misafir',
    'guestDescription': 'Hesap açmadan da okuyabilirsiniz',
    'savedVerses': 'Kaydedilen ayetler',
    'notes': 'Notlar',
    'downloads': 'İndirilenler',
    'downloadsDescription': 'Mealler ve ses paketleri',
    'languageAndTranslation': 'Dil ve Meal',
    'currentLanguageAndTranslation': 'Türkçe · Varsayılan',
  };

  String _value(String key) {
    // Yeni bir dil eklerken burada dil haritası seçilecek. Eksik bir anahtar
    // olursa Türkçe güvenli geri dönüş olarak kalır.
    final map = switch (locale.languageCode) {
      _ => _tr,
    };
    return map[key] ?? _tr[key] ?? key;
  }

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
  String get turkishDescription => _value('turkishDescription');
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
  String get currentLanguageAndTranslation => _value('currentLanguageAndTranslation');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
