const dhikrBuiltInLabels = <String, Map<String, String>>{
  'subhanallah': <String, String>{
    'tr': 'Sübhanallah', 'en': 'SubhanAllah', 'fr': 'SubhanAllah',
    'ar': 'سبحان الله', 'az': 'Sübhanallah', 'ru': 'Субханаллах',
  },
  'alhamdulillah': <String, String>{
    'tr': 'Elhamdülillah', 'en': 'Alhamdulillah', 'fr': 'Alhamdulillah',
    'ar': 'الحمد لله', 'az': 'Əlhəmdülillah', 'ru': 'Альхамдулиллях',
  },
  'allahu_akbar': <String, String>{
    'tr': 'Allahu Ekber', 'en': 'Allahu Akbar', 'fr': 'Allahu Akbar',
    'ar': 'الله أكبر', 'az': 'Allahu Əkbər', 'ru': 'Аллаху Акбар',
  },
  'salawat': <String, String>{
    'tr': 'Salavat', 'en': 'Salawat', 'fr': 'Salawat',
    'ar': 'الصلاة على النبي', 'az': 'Salavat', 'ru': 'Салават',
  },
};

String dhikrBuiltInLabel(String id, String languageCode, {required String fallback}) {
  return dhikrBuiltInLabels[id]?[languageCode] ??
      dhikrBuiltInLabels[id]?['en'] ??
      fallback;
}
