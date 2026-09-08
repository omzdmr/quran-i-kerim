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
    'moreTranslationsSoon': 'İngilizce, Azərbaycanca ve Rusça dahil ek lisanslı mealler katalogdan indirilebilecek.',
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
    'today': 'Bugün',
    'community': 'Topluluk',
    'goodMorning': 'Günaydın',
    'goodDay': 'İyi günler',
    'goodEvening': 'İyi akşamlar',
    'dailyVerse': 'Günün Ayeti',
    'save': 'Kaydet',
    'listen': 'Dinle',
    'share': 'Paylaş',
    'more': 'Daha fazla',
    'translationLoading': 'Meal yükleniyor…',
    'translationUnavailable': 'Türkçe meal şu anda gösterilemiyor.',
    'continueReading': 'Kaldığınız yerden devam edin',
    'todayFiveMinutes': 'Bugünün 5 Dakikası',
    'spendTimeQuran': 'Bugün Kuran ile biraz zaman geçirin.',
    'minutes46': '4–6 dakika',
    'moreForYou': 'Sizin için daha fazlası',
    'needPlaceToStart': 'Başlayacak bir yere mi ihtiyacınız var?',
    'choosePlanHelp': 'Kuran’da zaman geçirmenize yardımcı olacak bir plan seçin.',
    'explorePlans': 'Planları keşfet',
    'readTogether': 'Birlikte okumak',
    'communitySoon': 'Özel arkadaş grupları ve birlikte okuma planları daha sonraki sürümlerde burada yer alacak.',
    'discoverTitle': 'Keşfedin',
    'discoverSearchHint': 'Ayet, konu veya plan ara',
    'prayerTimes': 'Namaz Vakitleri',
    'prayerSubtitle': 'Geri sayım · Kıble · Aylık vakitler',
    'dhikrCounter': 'Zikirmatik',
    'morningEvening': 'Sabah / Akşam',
    'readingPlans': 'Okuma Planları',
    'verses': 'Ayetler',
    'tafsirs': 'Tefsirler',
    'audioQuran': 'Sesli Kuran',
    'patience': 'Sabır',
    'anxiety': 'Kaygı',
    'anger': 'Öfke',
    'hope': 'Umut',
    'gratitude': 'Şükür',
    'peace': 'Huzur',
    'fear': 'Korku',
    'family': 'Aile',
    'myPlans': 'Okuma Planlarım',
    'findPlans': 'Planlar Bul',
    'saved': 'Kaydedildi',
    'completed': 'Tamamlandı',
    'ramadan': 'Ramazan',
    'allQuran': 'Kuran’ın Tümü',
    'viewAll': 'Hepsini Gör  ›',
    'start': 'Başla',
    'day7': '7 Gün',
    'day5': '5 Gün',
    'day10': '10 Gün',
    'day30': '30 Gün',
    'day90': '90 Gün',
    'year1': '1 Yıl',
    'innerPeace': 'İç Huzuru',
    'makeTimeRest': 'Dinlenmek için Zaman Ayırmak',
    'trust': 'Tevekkül',
    'quran30': '30 Günde Kuran’a Başlangıç',
    'quran90': '90 Günde Kuran Okuma',
    'quranYear': 'Bir Yılda Kuran',
    'ramadanKhatm': 'Ramazan Hatmi',
    'lastTenNights': 'Son On Gece',
    'prepareRamadan': 'Ramazan’a Hazırlık',
  };

  static const _en = <String, String>{
    'appTitle': 'Quran', 'navHome': 'Home', 'navQuran': 'Quran', 'navPlans': 'Plans', 'navDiscover': 'Discover', 'navProfile': 'You',
    'settings': 'Settings', 'appearance': 'Appearance', 'appearanceDescription': 'Follow your device theme or choose a fixed appearance.',
    'useDeviceTheme': 'Use device setting', 'useDeviceThemeDescription': 'Light or dark automatically with your phone', 'lightTheme': 'Light', 'lightThemeDescription': 'Always use the light appearance', 'darkTheme': 'Dark', 'darkThemeDescription': 'Always use the dark appearance',
    'language': 'App language', 'languageDescription': 'The interface language is independent from the Quran translation you read.', 'useDeviceLanguage': 'Use device language', 'useDeviceLanguageDescription': 'Automatically chooses a supported phone language',
    'turkish': 'Türkçe', 'english': 'English', 'arabic': 'العربية', 'azerbaijani': 'Azərbaycanca', 'russian': 'Русский',
    'turkishDescription': 'Uygulamayı Türkçe kullan', 'englishDescription': 'Use the app in English', 'arabicDescription': 'استخدم التطبيق باللغة العربية', 'azerbaijaniDescription': 'Tətbiqi Azərbaycan dilində istifadə et', 'russianDescription': 'Использовать приложение на русском языке',
    'quranLanguage': 'Quran language & translation', 'quranLanguageDescription': 'Choose the text you read independently from the interface language. More translations will be downloadable later.', 'arabicOriginal': 'Arabic original', 'arabicOriginalDescription': 'Quran text · built in', 'turkishMeal': 'Turkish translation · RWD', 'turkishMealDescription': 'Rowad Translation Center · installed', 'installed': 'Installed', 'moreTranslationsSoon': 'More licensed translations, including English, Azerbaijani and Russian, will be downloadable from the catalog.',
    'reading': 'Reading', 'rememberPosition': 'Remember my position', 'rememberPositionDescription': 'Automatically enabled', 'profile': 'You', 'guest': 'Guest', 'guestDescription': 'You can read without creating an account', 'savedVerses': 'Saved verses', 'notes': 'Notes', 'downloads': 'Downloads', 'downloadsDescription': 'Translations and audio packs', 'languageAndTranslation': 'Language & Translation', 'currentLanguageAndTranslation': 'Interface and reading language',
    'today': 'Today', 'community': 'Community', 'goodMorning': 'Good morning', 'goodDay': 'Good afternoon', 'goodEvening': 'Good evening', 'dailyVerse': 'Verse of the Day', 'save': 'Save', 'listen': 'Listen', 'share': 'Share', 'more': 'More', 'translationLoading': 'Loading translation…', 'translationUnavailable': 'The Turkish translation is unavailable right now.', 'continueReading': 'Continue where you left off', 'todayFiveMinutes': 'Today’s 5 Minutes', 'spendTimeQuran': 'Spend a little time with the Quran today.', 'minutes46': '4–6 minutes', 'moreForYou': 'More for you', 'needPlaceToStart': 'Need a place to start?', 'choosePlanHelp': 'Choose a plan that helps you spend time in the Quran.', 'explorePlans': 'Explore plans', 'readTogether': 'Read together', 'communitySoon': 'Private friend groups and shared reading plans will appear here in a later release.',
    'discoverTitle': 'Discover', 'discoverSearchHint': 'Search verses, topics or plans', 'prayerTimes': 'Prayer Times', 'prayerSubtitle': 'Countdown · Qibla · Monthly times', 'dhikrCounter': 'Dhikr Counter', 'morningEvening': 'Morning / Evening', 'readingPlans': 'Reading Plans', 'verses': 'Verses', 'tafsirs': 'Tafsir', 'audioQuran': 'Audio Quran', 'patience': 'Patience', 'anxiety': 'Anxiety', 'anger': 'Anger', 'hope': 'Hope', 'gratitude': 'Gratitude', 'peace': 'Peace', 'fear': 'Fear', 'family': 'Family',
    'myPlans': 'My Plans', 'findPlans': 'Find Plans', 'saved': 'Saved', 'completed': 'Completed', 'ramadan': 'Ramadan', 'allQuran': 'Whole Quran', 'viewAll': 'View All  ›', 'start': 'Start', 'day7': '7 Days', 'day5': '5 Days', 'day10': '10 Days', 'day30': '30 Days', 'day90': '90 Days', 'year1': '1 Year', 'innerPeace': 'Inner Peace', 'makeTimeRest': 'Make Time to Rest', 'trust': 'Trust in God', 'quran30': 'Start the Quran in 30 Days', 'quran90': 'Read the Quran in 90 Days', 'quranYear': 'Quran in One Year', 'ramadanKhatm': 'Ramadan Khatm', 'lastTenNights': 'The Last Ten Nights', 'prepareRamadan': 'Preparing for Ramadan',
  };

  static const _ar = <String, String>{
    'appTitle': 'القرآن الكريم', 'navHome': 'الرئيسية', 'navQuran': 'القرآن', 'navPlans': 'الخطط', 'navDiscover': 'استكشف', 'navProfile': 'أنت',
    'settings': 'الإعدادات', 'appearance': 'المظهر', 'appearanceDescription': 'اتبع مظهر الجهاز أو اختر مظهراً ثابتاً.', 'useDeviceTheme': 'استخدام إعداد الجهاز', 'useDeviceThemeDescription': 'يتبع الوضع الفاتح أو الداكن في الهاتف', 'lightTheme': 'فاتح', 'lightThemeDescription': 'استخدام المظهر الفاتح دائماً', 'darkTheme': 'داكن', 'darkThemeDescription': 'استخدام المظهر الداكن دائماً',
    'language': 'لغة التطبيق', 'languageDescription': 'لغة الواجهة مستقلة عن لغة ترجمة القرآن التي تقرؤها.', 'useDeviceLanguage': 'استخدام لغة الجهاز', 'useDeviceLanguageDescription': 'يختار تلقائياً لغة مدعومة من لغات الهاتف',
    'turkish': 'Türkçe', 'english': 'English', 'arabic': 'العربية', 'azerbaijani': 'Azərbaycanca', 'russian': 'Русский', 'turkishDescription': 'Uygulamayı Türkçe kullan', 'englishDescription': 'Use the app in English', 'arabicDescription': 'استخدم التطبيق باللغة العربية', 'azerbaijaniDescription': 'Tətbiqi Azərbaycan dilində istifadə et', 'russianDescription': 'Использовать приложение на русском языке',
    'quranLanguage': 'لغة القرآن والترجمة', 'quranLanguageDescription': 'اختر النص الذي تقرؤه بشكل مستقل عن لغة الواجهة. ستتوفر ترجمات إضافية للتنزيل لاحقاً.', 'arabicOriginal': 'النص العربي الأصلي', 'arabicOriginalDescription': 'نص القرآن · متوفر على الجهاز', 'turkishMeal': 'الترجمة التركية · RWD', 'turkishMealDescription': 'مركز رواد الترجمة · مثبتة', 'installed': 'مثبت', 'moreTranslationsSoon': 'ستتوفر ترجمات مرخصة إضافية، منها الإنجليزية والأذربيجانية والروسية، للتنزيل من الكتالوج.',
    'reading': 'القراءة', 'rememberPosition': 'تذكر موضع القراءة', 'rememberPositionDescription': 'مفعّل تلقائياً', 'profile': 'أنت', 'guest': 'ضيف', 'guestDescription': 'يمكنك القراءة دون إنشاء حساب', 'savedVerses': 'الآيات المحفوظة', 'notes': 'الملاحظات', 'downloads': 'التنزيلات', 'downloadsDescription': 'الترجمات والحزم الصوتية', 'languageAndTranslation': 'اللغة والترجمة', 'currentLanguageAndTranslation': 'لغة الواجهة ونص القراءة',
    'today': 'اليوم', 'community': 'المجتمع', 'goodMorning': 'صباح الخير', 'goodDay': 'نهارك سعيد', 'goodEvening': 'مساء الخير', 'dailyVerse': 'آية اليوم', 'save': 'حفظ', 'listen': 'استماع', 'share': 'مشاركة', 'more': 'المزيد', 'translationLoading': 'جارٍ تحميل الترجمة…', 'translationUnavailable': 'الترجمة التركية غير متاحة حالياً.', 'continueReading': 'تابع من حيث توقفت', 'todayFiveMinutes': 'خمس دقائق اليوم', 'spendTimeQuran': 'اقض بعض الوقت مع القرآن اليوم.', 'minutes46': '4–6 دقائق', 'moreForYou': 'المزيد لك', 'needPlaceToStart': 'تحتاج إلى نقطة بداية؟', 'choosePlanHelp': 'اختر خطة تساعدك على قضاء وقت مع القرآن.', 'explorePlans': 'استكشف الخطط', 'readTogether': 'القراءة معاً', 'communitySoon': 'ستظهر مجموعات الأصدقاء الخاصة وخطط القراءة المشتركة هنا في إصدار لاحق.',
    'discoverTitle': 'استكشف', 'discoverSearchHint': 'ابحث عن آية أو موضوع أو خطة', 'prayerTimes': 'مواقيت الصلاة', 'prayerSubtitle': 'العد التنازلي · القبلة · المواقيت الشهرية', 'dhikrCounter': 'عداد الذكر', 'morningEvening': 'أذكار الصباح / المساء', 'readingPlans': 'خطط القراءة', 'verses': 'الآيات', 'tafsirs': 'التفسير', 'audioQuran': 'القرآن الصوتي', 'patience': 'الصبر', 'anxiety': 'القلق', 'anger': 'الغضب', 'hope': 'الأمل', 'gratitude': 'الشكر', 'peace': 'السكينة', 'fear': 'الخوف', 'family': 'الأسرة',
    'myPlans': 'خططي', 'findPlans': 'اكتشف الخطط', 'saved': 'المحفوظة', 'completed': 'المكتملة', 'ramadan': 'رمضان', 'allQuran': 'القرآن كاملاً', 'viewAll': 'عرض الكل  ›', 'start': 'ابدأ', 'day7': '7 أيام', 'day5': '5 أيام', 'day10': '10 أيام', 'day30': '30 يوماً', 'day90': '90 يوماً', 'year1': 'سنة', 'innerPeace': 'السكينة الداخلية', 'makeTimeRest': 'وقت للراحة', 'trust': 'التوكل', 'quran30': 'ابدأ القرآن في 30 يوماً', 'quran90': 'قراءة القرآن في 90 يوماً', 'quranYear': 'القرآن في سنة', 'ramadanKhatm': 'ختمة رمضان', 'lastTenNights': 'العشر الأواخر', 'prepareRamadan': 'الاستعداد لرمضان',
  };

  static const _az = <String, String>{
    'appTitle': 'Qurani-Kərim', 'navHome': 'Ana səhifə', 'navQuran': 'Quran', 'navPlans': 'Planlar', 'navDiscover': 'Kəşf et', 'navProfile': 'Siz',
    'settings': 'Ayarlar', 'appearance': 'Görünüş', 'appearanceDescription': 'Cihaz mövzusunu izləyin və ya sabit görünüş seçin.', 'useDeviceTheme': 'Cihaz ayarından istifadə et', 'useDeviceThemeDescription': 'Telefonun açıq və ya tünd mövzusunu izləyir', 'lightTheme': 'Açıq', 'lightThemeDescription': 'Həmişə açıq görünüş', 'darkTheme': 'Tünd', 'darkThemeDescription': 'Həmişə tünd görünüş',
    'language': 'Tətbiq dili', 'languageDescription': 'İnterfeys dili oxuduğunuz Quran tərcüməsinin dilindən asılı deyil.', 'useDeviceLanguage': 'Cihaz dilindən istifadə et', 'useDeviceLanguageDescription': 'Telefonun dəstəklənən dilini avtomatik seçir',
    'turkish': 'Türkçe', 'english': 'English', 'arabic': 'العربية', 'azerbaijani': 'Azərbaycanca', 'russian': 'Русский', 'turkishDescription': 'Uygulamayı Türkçe kullan', 'englishDescription': 'Use the app in English', 'arabicDescription': 'استخدم التطبيق باللغة العربية', 'azerbaijaniDescription': 'Tətbiqi Azərbaycan dilində istifadə et', 'russianDescription': 'Использовать приложение на русском языке',
    'quranLanguage': 'Quran dili və tərcümə', 'quranLanguageDescription': 'Oxuduğunuz mətni interfeys dilindən asılı olmayaraq seçin. Əlavə tərcümələr sonra endirilə biləcək.', 'arabicOriginal': 'Ərəbcə orijinal', 'arabicOriginalDescription': 'Quran mətni · cihazda hazırdır', 'turkishMeal': 'Türkcə tərcümə · RWD', 'turkishMealDescription': 'Rowad Tərcümə Mərkəzi · quraşdırılıb', 'installed': 'Quraşdırılıb', 'moreTranslationsSoon': 'İngilis, Azərbaycan və Rus dilləri daxil olmaqla əlavə lisenziyalı tərcümələr kataloqdan endirilə biləcək.',
    'reading': 'Oxuma', 'rememberPosition': 'Qaldığım yeri yadda saxla', 'rememberPositionDescription': 'Avtomatik aktivdir', 'profile': 'Siz', 'guest': 'Qonaq', 'guestDescription': 'Hesab yaratmadan da oxuya bilərsiniz', 'savedVerses': 'Yadda saxlanılan ayələr', 'notes': 'Qeydlər', 'downloads': 'Endirilənlər', 'downloadsDescription': 'Tərcümələr və audio paketlər', 'languageAndTranslation': 'Dil və Tərcümə', 'currentLanguageAndTranslation': 'İnterfeys və oxuma dili',
    'today': 'Bu gün', 'community': 'İcma', 'goodMorning': 'Sabahınız xeyir', 'goodDay': 'Gününüz xeyir', 'goodEvening': 'Axşamınız xeyir', 'dailyVerse': 'Günün ayəsi', 'save': 'Yadda saxla', 'listen': 'Dinlə', 'share': 'Paylaş', 'more': 'Daha çox', 'translationLoading': 'Tərcümə yüklənir…', 'translationUnavailable': 'Türkcə tərcümə hazırda göstərilə bilmir.', 'continueReading': 'Qaldığınız yerdən davam edin', 'todayFiveMinutes': 'Bu günün 5 dəqiqəsi', 'spendTimeQuran': 'Bu gün Quranla bir az vaxt keçirin.', 'minutes46': '4–6 dəqiqə', 'moreForYou': 'Sizin üçün daha çox', 'needPlaceToStart': 'Başlamaq üçün yer lazımdır?', 'choosePlanHelp': 'Quranla vaxt keçirməyə kömək edən plan seçin.', 'explorePlans': 'Planları kəşf et', 'readTogether': 'Birlikdə oxumaq', 'communitySoon': 'Şəxsi dost qrupları və ortaq oxuma planları sonrakı buraxılışda burada olacaq.',
    'discoverTitle': 'Kəşf et', 'discoverSearchHint': 'Ayə, mövzu və ya plan axtar', 'prayerTimes': 'Namaz vaxtları', 'prayerSubtitle': 'Geri sayım · Qiblə · Aylıq vaxtlar', 'dhikrCounter': 'Zikrmətik', 'morningEvening': 'Səhər / Axşam', 'readingPlans': 'Oxuma planları', 'verses': 'Ayələr', 'tafsirs': 'Təfsirlər', 'audioQuran': 'Səsli Quran', 'patience': 'Səbir', 'anxiety': 'Narahatlıq', 'anger': 'Qəzəb', 'hope': 'Ümid', 'gratitude': 'Şükür', 'peace': 'Hüzur', 'fear': 'Qorxu', 'family': 'Ailə',
    'myPlans': 'Planlarım', 'findPlans': 'Plan tap', 'saved': 'Yadda saxlanılan', 'completed': 'Tamamlanan', 'ramadan': 'Ramazan', 'allQuran': 'Bütün Quran', 'viewAll': 'Hamısını gör  ›', 'start': 'Başla', 'day7': '7 gün', 'day5': '5 gün', 'day10': '10 gün', 'day30': '30 gün', 'day90': '90 gün', 'year1': '1 il', 'innerPeace': 'Daxili hüzur', 'makeTimeRest': 'Dincəlməyə vaxt ayır', 'trust': 'Təvəkkül', 'quran30': '30 gündə Qurana başla', 'quran90': '90 gündə Quran oxu', 'quranYear': 'Bir ildə Quran', 'ramadanKhatm': 'Ramazan xətmi', 'lastTenNights': 'Son on gecə', 'prepareRamadan': 'Ramazana hazırlıq',
  };

  static const _ru = <String, String>{
    'appTitle': 'Коран', 'navHome': 'Главная', 'navQuran': 'Коран', 'navPlans': 'Планы', 'navDiscover': 'Обзор', 'navProfile': 'Вы',
    'settings': 'Настройки', 'appearance': 'Оформление', 'appearanceDescription': 'Следовать теме устройства или выбрать постоянное оформление.', 'useDeviceTheme': 'Использовать настройки устройства', 'useDeviceThemeDescription': 'Автоматически светлая или тёмная тема телефона', 'lightTheme': 'Светлая', 'lightThemeDescription': 'Всегда использовать светлую тему', 'darkTheme': 'Тёмная', 'darkThemeDescription': 'Всегда использовать тёмную тему',
    'language': 'Язык приложения', 'languageDescription': 'Язык интерфейса не зависит от языка перевода Корана.', 'useDeviceLanguage': 'Использовать язык устройства', 'useDeviceLanguageDescription': 'Автоматически выбирает поддерживаемый язык телефона',
    'turkish': 'Türkçe', 'english': 'English', 'arabic': 'العربية', 'azerbaijani': 'Azərbaycanca', 'russian': 'Русский', 'turkishDescription': 'Uygulamayı Türkçe kullan', 'englishDescription': 'Use the app in English', 'arabicDescription': 'استخدم التطبيق باللغة العربية', 'azerbaijaniDescription': 'Tətbiqi Azərbaycan dilində istifadə et', 'russianDescription': 'Использовать приложение на русском языке',
    'quranLanguage': 'Язык Корана и перевод', 'quranLanguageDescription': 'Выбирайте текст для чтения независимо от языка интерфейса. Дополнительные переводы можно будет скачать позже.', 'arabicOriginal': 'Арабский оригинал', 'arabicOriginalDescription': 'Текст Корана · встроен', 'turkishMeal': 'Турецкий перевод · RWD', 'turkishMealDescription': 'Центр переводов Rowad · установлен', 'installed': 'Установлено', 'moreTranslationsSoon': 'Дополнительные лицензированные переводы, включая английский, азербайджанский и русский, можно будет скачать из каталога.',
    'reading': 'Чтение', 'rememberPosition': 'Запоминать место чтения', 'rememberPositionDescription': 'Включено автоматически', 'profile': 'Вы', 'guest': 'Гость', 'guestDescription': 'Можно читать без создания аккаунта', 'savedVerses': 'Сохранённые аяты', 'notes': 'Заметки', 'downloads': 'Загрузки', 'downloadsDescription': 'Переводы и аудиопакеты', 'languageAndTranslation': 'Язык и перевод', 'currentLanguageAndTranslation': 'Язык интерфейса и чтения',
    'today': 'Сегодня', 'community': 'Сообщество', 'goodMorning': 'Доброе утро', 'goodDay': 'Добрый день', 'goodEvening': 'Добрый вечер', 'dailyVerse': 'Аят дня', 'save': 'Сохранить', 'listen': 'Слушать', 'share': 'Поделиться', 'more': 'Ещё', 'translationLoading': 'Загрузка перевода…', 'translationUnavailable': 'Турецкий перевод сейчас недоступен.', 'continueReading': 'Продолжить с места остановки', 'todayFiveMinutes': '5 минут сегодня', 'spendTimeQuran': 'Проведите сегодня немного времени с Кораном.', 'minutes46': '4–6 минут', 'moreForYou': 'Больше для вас', 'needPlaceToStart': 'Не знаете, с чего начать?', 'choosePlanHelp': 'Выберите план, который поможет проводить время с Кораном.', 'explorePlans': 'Открыть планы', 'readTogether': 'Читать вместе', 'communitySoon': 'Закрытые группы друзей и совместные планы чтения появятся здесь в следующей версии.',
    'discoverTitle': 'Обзор', 'discoverSearchHint': 'Искать аят, тему или план', 'prayerTimes': 'Время намаза', 'prayerSubtitle': 'Отсчёт · Кибла · Время на месяц', 'dhikrCounter': 'Счётчик зикра', 'morningEvening': 'Утро / Вечер', 'readingPlans': 'Планы чтения', 'verses': 'Аяты', 'tafsirs': 'Тафсиры', 'audioQuran': 'Аудио Коран', 'patience': 'Терпение', 'anxiety': 'Тревога', 'anger': 'Гнев', 'hope': 'Надежда', 'gratitude': 'Благодарность', 'peace': 'Покой', 'fear': 'Страх', 'family': 'Семья',
    'myPlans': 'Мои планы', 'findPlans': 'Найти планы', 'saved': 'Сохранённые', 'completed': 'Завершённые', 'ramadan': 'Рамадан', 'allQuran': 'Весь Коран', 'viewAll': 'Смотреть все  ›', 'start': 'Начать', 'day7': '7 дней', 'day5': '5 дней', 'day10': '10 дней', 'day30': '30 дней', 'day90': '90 дней', 'year1': '1 год', 'innerPeace': 'Внутренний покой', 'makeTimeRest': 'Найти время для отдыха', 'trust': 'Упование', 'quran30': 'Начать Коран за 30 дней', 'quran90': 'Прочитать Коран за 90 дней', 'quranYear': 'Коран за год', 'ramadanKhatm': 'Хатм в Рамадан', 'lastTenNights': 'Последние десять ночей', 'prepareRamadan': 'Подготовка к Рамадану',
  };

  Map<String, String> get _map => switch (locale.languageCode) {
        'en' => _en,
        'ar' => _ar,
        'az' => _az,
        'ru' => _ru,
        _ => _tr,
      };

  String _value(String key) => _map[key] ?? _en[key] ?? _tr[key] ?? key;
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
  String get currentLanguageAndTranslation => _value('currentLanguageAndTranslation');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
        (supported) => supported.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
