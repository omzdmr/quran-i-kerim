import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';

void main() {
  test('English Rowwad translation is enabled for verified download', () {
    final english = translationById(englishTranslationId);
    expect(english, isNotNull);
    expect(english!.sourceKey, 'english_rwwad');
    expect(english.version, '1.0.19');
    expect(english.downloadable, isTrue);
    expect(english.bundled, isFalse);
  });

  test('Turkish translation remains bundled and Arabic remains a source id', () {
    final turkish = translationById(bundledTurkishTranslationId);
    expect(turkish, isNotNull);
    expect(turkish!.bundled, isTrue);
    expect(arabicOriginalSourceId, 'arabic_original');
  });
}
