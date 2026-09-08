import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';

void main() {
  test('English Rowwad translation is bundled as the English device default', () {
    final english = translationById(englishTranslationId);
    expect(english, isNotNull);
    expect(english!.sourceKey, 'english_rwwad');
    expect(english.version, '1.0.19');
    expect(english.downloadable, isFalse);
    expect(english.bundled, isTrue);
    expect(english.assetPath, 'assets/data/translations/en_rwwad.json.gz');
    expect(defaultQuranSourceForLanguage('en'), englishTranslationId);
  });

  test('Turkish and Arabic device defaults map to offline sources', () {
    final turkish = translationById(bundledTurkishTranslationId);
    expect(turkish, isNotNull);
    expect(turkish!.bundled, isTrue);
    expect(defaultQuranSourceForLanguage('tr'), bundledTurkishTranslationId);
    expect(defaultQuranSourceForLanguage('ar'), arabicOriginalSourceId);
  });

  test('unsupported device languages fall back to bundled English', () {
    expect(defaultQuranSourceForLanguage('de'), englishTranslationId);
  });
}
