import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
    'languageDescription': 'Arayüz dili, Kuran ve meal dilinden bağımsızdır.',
    'useDeviceLanguage': 'Cihaz dilini kullan',
    'useDeviceLanguageDescription': 'Desteklenen diller arasından telefonunuzun dilini otomatik seçer',
    'turkish': 'Türkçe',
    'english': 'English',
    'arabic': 'العربية',
    'azerbaijani': 'Azərbaycanca',
    'russian': 'Русский',
    'turkishDescription': 'Uygulamayı Türkçe kullan',
    'englishDescription': 'Use the app in English',
    'arabicDescription': 'استخدم التطبيق باللغة العربية',
    'azerbaijaniDescription': 'Tətbiqi Azərbaycan dilində istifadə et',
    'russianDescription': 'Использовать приложение на русском языке',
    'quranLanguage': 'Kuran dili ve meal',
    'quranLanguageDescription': 'Okuduğunuz metni arayüz dilinden bağımsız seçin. Ek mealler daha sonra indirilebilir paketler olarak eklenecek.',
    'arabicOriginal': 'Arapça orijinal',
    'arabicOriginalDescription': 'Kuran metni · cihazda hazır',
    'turkishMeal': 'Türkçe meal · RWD',
    'turkishMealDescription': 'Rowad Tercüme Merkezi · cihazda hazır',
    'installed': 'Yüklü',
    'moreTranslationsSoon': 'İngilizce, Arapça açıklamalar, Azərbaycanca ve Rusça dahil ek lisanslı mealler katalogdan indirilebilecek.',
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
    'currentLanguageAndTranslation': 'Uygulama dili ve okuma metni',
  };

  static const _en = <String, String>{
    'appTitle': 'Quran',
    'navHome': 'Home',
    'navQuran': 'Quran',
    'navPlans': 'Plans',
    'navDiscover': 'Discover',
    'navProfile': 'You',
    'settings': 'Settings',
    'appearance': 'Appearance',
    'appearanceDescription': 'Follow your device theme or choose a fixed appearance.',
    'useDeviceTheme': 'Use device setting',
    'useDeviceThemeDescription': 'Light or dark automatically with your phone',
    'lightTheme': 'Light',
    'lightThemeDescription': 'Always use the light appearance',
    'darkTheme': 'Dark',
    'darkThemeDescription': 'Always use the dark appearance',
    'language': 'App language',
    'languageDescription': 'The interface language is independent from the Quran translation you read.',
    'useDeviceLanguage': 'Use device language',
    'useDeviceLanguageDescription': 'Automatically chooses a supported phone language',
    'turkish': 'Türkçe',
    'english': 'English',
    'arabic': 'العربية',
    'azerbaijani': 'Azərbaycanca',
    'russian': 'Русский',
    'turkishDescription': 'Uygulamayı Türkçe kullan',
    'englishDescription': 'Use the app in English',
    'arabicDescription': 'استخدم التطبيق باللغة العربية',
    'azerbaijaniDescription': 'Tətbiqi Azərbaycan dilində istifadə et',
    'russianDescription': 'Использовать приложение на русском языке',
    'quranLanguage': 'Quran language & translation',
    'quranLanguageDescription': 'Choose the text you read independently from the interface language. More translations will be downloadable later.',
    'arabicOriginal': 'Arabic original',
    'arabicOriginalDescription': 'Quran text · built in',
    'turkishMeal': 'Turkish translation · RWD',
    'turkishMealDescription': 'Rowad Translation Center · installed',
    'installed': 'Installed',
    'moreTranslationsSoon': 'Additional licensed translations, including English, Azerbaijani and Russian, will be available as downloadable packs.',
    'reading': 'Reading',
    'rememberPosition': 'Remember my position',
    'rememberPositionDescription': 'Automatically enabled',
    'profile': 'You',
    'guest': 'Guest',
    'guestDescription': 'You can read without creating an account',
    'savedVerses': 'Saved verses',
    'notes': 'Notes',
    'downloads': 'Downloads',
    'downloadsDescription': 'Translations and audio packs',
    'languageAndTranslation': 'Language & Translation',
    'currentLanguageAndTranslation': 'Interface and reading language',
  };

  static const _ar = <String, String>{
    'appTitle': 'القرآن الكريم',
    'navHome': 'الرئيسية',
    'navQuran': 'القرآن',
    'navPlans': 'الخطط',
    'navDiscover': 'استكشف',
    'navProfile': 'أنت',
    'settings': 'الإعدادات',
    'appearance': 'المظهر',
    'appearanceDescription': 'اتبع مظهر الجهاز أو اختر مظهراً ثابتاً.',
    'useDeviceTheme': 'استخدام إعداد الجهاز',
    'useDeviceThemeDescription': 'يتبع الوضع الفاتح أو الداكن في الهاتف',
    'lightTheme': 'فاتح',
    'lightThemeDescription': 'استخدام المظهر الفاتح دائماً',
    'darkTheme': 'داكن',
    'darkThemeDescription': 'استخدام المظهر الداكن دائماً',
    'language': 'لغة التطبيق',
    'languageDescription': 'لغة الواجهة مستقلة عن لغة ترجمة القرآن التي تقرؤها.',
    'useDeviceLanguage': 'استخدام لغة الجهاز',
    'useDeviceLanguageDescription': 'يختار تلقائياً لغة مدعومة من لغات الهاتف',
    'turkish': 'Türkçe',
    'english': 'English',
    'arabic': 'العربية',
    'azerbaijani': 'Azərbaycanca',
    'russian': 'Русский',
    'turkishDescription': 'Uygulamayı Türkçe kullan',
    'englishDescription': 'Use the app in English',
    'arabicDescription': 'استخدم التطبيق باللغة العربية',
    'azerbaijaniDescription': 'Tətbiqi Azərbaycan dilində istifadə et',
    'russianDescription': 'Использовать приложение на русском языке',
    'quranLanguage': 'لغة القرآن والترجمة',
    'quranLanguageDescription': 'اختر النص الذي تقرؤه بشكل مستقل عن لغة الواجهة. ستتوفر ترجمات إضافية للتنزيل لاحقاً.',
    'arabicOriginal': 'النص العربي الأصلي',
    'arabicOriginalDescription': 'نص القرآن · متوفر على الجهاز',
    'turkishMeal': 'الترجمة التركية · RWD',
    'turkishMealDescription': 'مركز رواد الترجمة · مثبتة',
    'installed': 'مثبت',
    'moreTranslationsSoon': 'ستتوفر ترجمات مرخصة إضافية، منها الإنجليزية والأذربيجانية والروسية، كحزم قابلة للتنزيل.',
    'reading': 'القراءة',
    'rememberPosition': 'تذكر موضع القراءة',
    'rememberPositionDescription': 'مفعّل تلقائياً',
    'profile': 'أنت',
    'guest': 'ضيف',
    'guestDescription': 'يمكنك القراءة دون إنشاء حساب',
    'savedVerses': 'الآيات المحفوظة',
    'notes': 'الملاحظات',
    'downloads': 'التنزيلات',
    'downloadsDescription': 'الترجمات والحزم الصوتية',
    'languageAndTranslation': 'اللغة والترجمة',
    'currentLanguageAndTranslation': 'لغة الواجهة ونص القراءة',
  };

  static const _az = <String, String>{
    'appTitle': 'Qurani-Kərim',
    'navHome': 'Ana səhifə',
    'navQuran': 'Quran',
    'navPlans': 'Planlar',
    'navDiscover': 'Kəşf et',
    'navProfile': 'Siz',
    'settings': 'Ayarlar',
    'appearance': 'Görünüş',
    'appearanceDescription': 'Cihaz mövzusunu izləyin və ya sabit görünüş seçin.',
    'useDeviceTheme': 'Cihaz ayarından istifadə et',
    'useDeviceThemeDescription': 'Telefonun açıq və ya tünd mövzusunu izləyir',
    'lightTheme': 'Açıq',
    'lightThemeDescription': 'Həmişə açıq görünüş',
    'darkTheme': 'Tünd',
    'darkThemeDescription': 'Həmişə tünd görünüş',
    'language': 'Tətbiq dili',
    'languageDescription': 'İnterfeys dili oxuduğunuz Quran tərcüməsinin dilindən asılı deyil.',
    'useDeviceLanguage': 'Cihaz dilindən istifadə et',
    'useDeviceLanguageDescription': 'Telefonun dəstəklənən dilini avtomatik seçir',
    'turkish': 'Türkçe',
    'english': 'English',
    'arabic': 'العربية',
    'azerbaijani': 'Azərbaycanca',
    'russian': 'Русский',
    'turkishDescription': 'Uygulamayı Türkçe kullan',
    'englishDescription': 'Use the app in English',
    'arabicDescription': 'استخدم التطبيق باللغة العربية',
    'azerbaijaniDescription': 'Tətbiqi Azərbaycan dilində istifadə et',
    'russianDescription': 'Использовать приложение на русском языке',
    'quranLanguage': 'Quran dili və tərcümə',
    'quranLanguageDescription': 'Oxuduğunuz mətni interfeys dilindən asılı olmayaraq seçin. Əlavə tərcümələr sonra endirilə biləcək.',
    'arabicOriginal': 'Ərəbcə orijinal',
    'arabicOriginalDescription': 'Quran mətni · cihazda hazırdır',
    'turkishMeal': 'Türkcə tərcümə · RWD',
    'turkishMealDescription': 'Rowad Tərcümə Mərkəzi · quraşdırılıb',
    'installed': 'Quraşdırılıb',
    'moreTranslationsSoon': 'İngilis, Azərbaycan və Rus dilləri daxil olmaqla əlavə lisenziyalı tərcümələr endirilə bilən paketlər kimi əlavə olunacaq.',
    'reading': 'Oxuma',
    'rememberPosition': 'Qaldığım yeri yadda saxla',
    'rememberPositionDescription': 'Avtomatik aktivdir',
    'profile': 'Siz',
    'guest': 'Qonaq',
    'guestDescription': 'Hesab yaratmadan da oxuya bilərsiniz',
    'savedVerses': 'Yadda saxlanılan ayələr',
    'notes': 'Qeydlər',
    'downloads': 'Endirilənlər',
    'downloadsDescription': 'Tərcümələr və audio paketlər',
    'languageAndTranslation': 'Dil və Tərcümə',
    'currentLanguageAndTranslation': 'İnterfeys və oxuma dili',
  };

  static const _ru = <String, String>{
    'appTitle': 'Коран',
    'navHome': 'Главная',
    'navQuran': 'Коран',
    'navPlans': 'Планы',
    'navDiscover': 'Обзор',
    'navProfile': 'Вы',
    'settings': 'Настройки',
    'appearance': 'Оформление',
    'appearanceDescription': 'Следовать теме устройства или выбрать постоянное оформление.',
    'useDeviceTheme': 'Использовать настройки устройства',
    'useDeviceThemeDescription': 'Автоматически светлая или тёмная тема телефона',
    'lightTheme': 'Светлая',
    'lightThemeDescription': 'Всегда использовать светлую тему',
    'darkTheme': 'Тёмная',
    'darkThemeDescription': 'Всегда использовать тёмную тему',
    'language': 'Язык приложения',
    'languageDescription': 'Язык интерфейса не зависит от языка перевода Корана.',
    'useDeviceLanguage': 'Использовать язык устройства',
    'useDeviceLanguageDescription': 'Автоматически выбирает поддерживаемый язык телефона',
    'turkish': 'Türkçe',
    'english': 'English',
    'arabic': 'العربية',
    'azerbaijani': 'Azərbaycanca',
    'russian': 'Русский',
    'turkishDescription': 'Uygulamayı Türkçe kullan',
    'englishDescription': 'Use the app in English',
    'arabicDescription': 'استخدم التطبيق باللغة العربية',
    'azerbaijaniDescription': 'Tətbiqi Azərbaycan dilində istifadə et',
    'russianDescription': 'Использовать приложение на русском языке',
    'quranLanguage': 'Язык Корана и перевод',
    'quranLanguageDescription': 'Выбирайте текст для чтения независимо от языка интерфейса. Дополнительные переводы можно будет скачать позже.',
    'arabicOriginal': 'Арабский оригинал',
    'arabicOriginalDescription': 'Текст Корана · встроен',
    'turkishMeal': 'Турецкий перевод · RWD',
    'turkishMealDescription': 'Центр переводов Rowad · установлен',
    'installed': 'Установлено',
    'moreTranslationsSoon': 'Дополнительные лицензированные переводы, включая английский, азербайджанский и русский, будут доступны как загружаемые пакеты.',
    'reading': 'Чтение',
    'rememberPosition': 'Запоминать место чтения',
    'rememberPositionDescription': 'Включено автоматически',
    'profile': 'Вы',
    'guest': 'Гость',
    'guestDescription': 'Можно читать без создания аккаунта',
    'savedVerses': 'Сохранённые аяты',
    'notes': 'Заметки',
    'downloads': 'Загрузки',
    'downloadsDescription': 'Переводы и аудиопакеты',
    'languageAndTranslation': 'Язык и перевод',
    'currentLanguageAndTranslation': 'Язык интерфейса и чтения',
  };

  Map<String, String> get _map => switch (locale.languageCode) {
        'en' => _en,
        'ar' => _ar,
        'az' => _az,
        'ru' => _ru,
        _ => _tr,
      };

  String _value(String key) => _map[key] ?? _en[key] ?? _tr[key] ?? key;

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
  String get currentLanguageAndTranslation => _value('currentLanguageAndTranslation');
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
