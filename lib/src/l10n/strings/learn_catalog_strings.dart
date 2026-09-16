const learnCatalogStrings = <String, Map<String, String>>{
  'tr': <String, String>{
    'learnLessonProgressSummaryV1': '{completed} / {total} ders tamamlandı',
  },
  'en': <String, String>{
    'learnLessonProgressSummaryV1': '{completed} of {total} lessons completed',
  },
  'ar': <String, String>{
    'learnLessonProgressSummaryV1': 'اكتمل {completed} من {total} دروس',
  },
  'az': <String, String>{
    'learnLessonProgressSummaryV1': '{total} dərsdən {completed}-i tamamlandı',
  },
  'ru': <String, String>{
    'learnLessonProgressSummaryV1': 'Завершено уроков: {completed} из {total}',
  },
};

String learnCatalogText(String languageCode, String key) =>
    learnCatalogStrings[languageCode]?[key] ??
    learnCatalogStrings['en']?[key] ??
    learnCatalogStrings['tr']?[key] ??
    key;
