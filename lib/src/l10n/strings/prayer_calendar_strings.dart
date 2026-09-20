import '../app_localizations.dart';

const prayerCalendarStrings = <String, Map<String, String>>{
  'tr': {
    'title': "Takvim dosyasını paylaş",
    'explanation': "Seçili ayın beş namaz vaktini mevcut hesaplama ayarlarıyla paylaşır; güneş doğuşu dahil değildir. Dosya yer adını ve vakitleri içerir. Bu sabit bir kopyadır; ayarlar değişince güncellenmez. Takvime eklemeden önce içeriği kontrol et. Tekrar içe aktarma bazı takvimlerde çift kayıt oluşturabilir. Uygulama alarm eklemez; takvim uygulamanın varsayılan bildirim ayarlarını kontrol et.",
    'share': "Paylaş",
    'error': "Takvim dosyası paylaşılamadı. Tekrar dene.",
    'snapshot': "Hesaplanan namaz başlangıcıdır; cami kamet saati veya namazın bitiş sınırı değildir. Sabit kopya, otomatik güncellenmez.",
  },
  'en': {
    'title': "Share calendar file",
    'explanation': "Share the selected month’s five prayer times using your current calculation settings; sunrise is excluded. The file contains the place name and times. This is a fixed copy and will not update when settings change. Review it before importing. Re-importing may create duplicates in some calendars. No alarms are included; check your calendar app’s default reminders.",
    'share': "Share",
    'error': "Could not share the calendar file. Try again.",
    'snapshot': "Calculated prayer start, not mosque iqamah or the end of a prayer window. Fixed copy; does not update automatically.",
  },
  'ar': {
    'title': "مشاركة ملف التقويم",
    'explanation': "شارك أوقات الصلوات الخمس للشهر المحدد وفق إعدادات الحساب الحالية؛ لا يشمل الشروق. يحتوي الملف على اسم المكان والأوقات. هذه نسخة ثابتة لا تتحدث عند تغيير الإعدادات. راجعها قبل الاستيراد. قد يؤدي تكرار الاستيراد إلى سجلات مكررة. لا يتضمن الملف تنبيهات؛ تحقق من التذكيرات الافتراضية في تطبيق التقويم.",
    'share': "مشاركة",
    'error': "تعذّرت مشاركة ملف التقويم. حاول مرة أخرى.",
    'snapshot': "بداية صلاة محسوبة، وليست وقت إقامة المسجد أو نهاية وقت الصلاة. نسخة ثابتة لا تتحدث تلقائياً.",
  },
  'az': {
    'title': "Təqvim faylını paylaş",
    'explanation': "Seçilmiş ayın beş namaz vaxtını cari hesablama ayarları ilə paylaşır; günəşin doğması daxil deyil. Faylda yerin adı və vaxtlar var. Bu sabit nüsxədir, ayarlar dəyişəndə yenilənmir. İdxaldan əvvəl yoxlayın. Təkrar idxal bəzi təqvimlərdə təkrarlanan qeydlər yarada bilər. Siqnallar daxil deyil; təqvim tətbiqinin standart xatırlatmalarını yoxlayın.",
    'share': "Paylaş",
    'error': "Təqvim faylı paylaşıla bilmədi. Yenidən cəhd edin.",
    'snapshot': "Hesablanmış namaz başlanğıcıdır; məscidin iqamə vaxtı və ya namaz vaxtının sonu deyil. Sabit nüsxədir, avtomatik yenilənmir.",
  },
  'ru': {
    'title': "Поделиться файлом календаря",
    'explanation': "Выгрузите пять времён намаза за выбранный месяц с текущими настройками расчёта; восход не включён. Файл содержит название места и время. Это статичная копия, которая не обновляется при изменении настроек. Проверьте её перед импортом. Повторный импорт может создавать дубликаты. Напоминания не включены; проверьте настройки напоминаний вашего календаря.",
    'share': "Поделиться",
    'error': "Не удалось поделиться файлом календаря. Повторите попытку.",
    'snapshot': "Расчётное начало намаза, а не время икамата в мечети или конец времени молитвы. Статичная копия без автоматического обновления.",
  },
};

extension PrayerCalendarLocalization on AppLocalizations {
  String calendarText(String key) =>
      prayerCalendarStrings[locale.languageCode]?[key] ??
      prayerCalendarStrings['en']![key]!;
}
