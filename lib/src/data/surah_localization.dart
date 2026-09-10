import 'package:quran/quran.dart' as quran;

// Azerbaijani conventional display names, kept locally so the reader remains
// offline-first and does not depend on a network lookup for navigation labels.
const _azSurahNames = <String>[
  'Fatihə','Bəqərə','Ali-İmran','Nisa','Maidə','Ənam','Əraf','Ənfal','Tövbə','Yunus','Hud','Yusuf','Rəd','İbrahim','Hicr','Nəhl','İsra','Kəhf','Məryəm','Taha','Ənbiya','Həcc','Muminun','Nur','Fürqan','Şüəra','Nəml','Qəsəs','Ənkəbut','Rum','Loğman','Səcdə','Əhzab','Səbə','Fatir','Yasin','Saffat','Sad','Zümər','Mumin','Füssilət','Şura','Züxrüf','Düxan','Casiyə','Əhqaf','Mühəmməd','Fəth','Hücürat','Qaf','Zariyat','Tur','Nəcm','Qəmər','Rəhman','Vaqiə','Hədid','Mücadilə','Həşr','Mümtəhinə','Səff','Cümə','Münafiqun','Təğabün','Talaq','Təhrim','Mülk','Qələm','Haqqə','Məaric','Nuh','Cinn','Müzzəmmil','Müddəssir','Qiyamət','İnsan','Mürsəlat','Nəbə','Naziat','Əbəsə','Təkvir','İnfitar','Mütəffifin','İnşiqaq','Büruc','Tariq','Əla','Ğaşiyə','Fəcr','Bələd','Şəms','Leyl','Züha','İnşirah','Tin','Ələq','Qədr','Bəyyinə','Zilzal','Adiyat','Qariə','Təkasür','Əsr','Hüməzə','Fil','Qüreyş','Maun','Kövsər','Kafirun','Nəsr','Məsəd','İxlas','Fələq','Nas',
];

// QuranEnc Chinese (Muhammad Suleiman) navigation names. Keeping these in the
// APK avoids a network request simply to render a surah title.
const _zhSurahNames = <String>[
  '法谛海','百格勒','阿黎仪姆兰','尼萨仪','马以代','艾奈阿姆','艾尔拉弗','安法勒','讨白','优努斯','呼德','优素福','赖尔得','易卜拉欣','希只尔','奈哈勒','伊斯拉','凯海府','麦尔彦','塔哈','安比雅','哈知','慕米农','努尔','弗尔干','抒尔拉','奈木勒','改赛素','安凯逋特','鲁姆','鲁格曼','赛直德','艾哈萨卜','赛伯邑','法颓尔','雅辛','萨法特','萨德','助迈尔','阿斐尔','奉绥来特','舒拉','助赫鲁弗','睹罕','查西叶','艾哈戛弗','穆罕默德','费特哈','侯吉拉特','戛弗','达里雅特','突尔','奈智姆','改买尔','安赖哈曼','瓦格尔','哈迪德','穆扎迪莱','哈什尔','慕姆太哈奈','蒜弗','主麻','莫拿非古乃','台昂卜尼','特俩格','台哈列姆','姆勒克','改赖姆','哈盖','买阿列支','努哈','精尼','孟赞密鲁','孟荡西尔','格雅迈','印萨尼','姆尔赛拉特','奈白易','那寂阿特','阿百塞','太克威尔','引斐塔尔','穆团斐弗乃','引史卡格','补鲁智','塔里格','艾尔拉','阿史叶','斐智尔','白赖德','晒姆斯','赖以里','堵哈','晒尔哈','梯尼','阿赖格','盖德尔','佰以奈','宰利宰莱','阿底雅特','戛里尔','太卡素尔','阿斯尔','胡买宰','斐里','古莱什','马欧尼','考赛尔','卡斐伦','奈斯尔','麦瑟迪','以赫拉斯','法赖格','拿斯',
];

const _nonLatinFallbackLanguages = <String>{
  'ar','fa','ur','ps','ku','prs','ug','bn','hi','si','as','ta','te','ml','nqo',
  'km','ne','th','gu','am','kn','ka','my','pa','ko','lo','mr',
};

String localizedSurahName(int surahNumber, String languageCode) {
  final safe = surahNumber.clamp(1, 114).toInt();
  final language = languageCode.toLowerCase();
  return switch (language) {
    'ar' => quran.getSurahNameArabic(safe),
    'tr' => quran.getSurahNameTurkish(safe),
    'az' => _azSurahNames[safe - 1],
    'ru' => quran.getSurahNameRussian(safe),
    'fr' => quran.getSurahNameFrench(safe),
    'zh' => _zhSurahNames[safe - 1],
    _ when _nonLatinFallbackLanguages.contains(language) =>
      quran.getSurahNameArabic(safe),
    _ => quran.getSurahName(safe),
  };
}

List<String> surahSearchAliases(int surahNumber, String languageCode) {
  final safe = surahNumber.clamp(1, 114).toInt();
  return <String>{
    localizedSurahName(safe, languageCode),
    quran.getSurahName(safe),
    quran.getSurahNameEnglish(safe),
    quran.getSurahNameTurkish(safe),
    quran.getSurahNameFrench(safe),
    quran.getSurahNameRussian(safe),
    quran.getSurahNameArabic(safe),
    _azSurahNames[safe - 1],
    _zhSurahNames[safe - 1],
  }.toList(growable: false);
}
