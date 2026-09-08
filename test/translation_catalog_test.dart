import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/quran_audio_catalog.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';

void main() {
  test(
    'English Rowwad translation is bundled as the English device default',
    () {
      final english = translationById(englishTranslationId);
      expect(english, isNotNull);
      expect(english!.sourceKey, 'english_rwwad');
      expect(english.version, '1.0.19');
      expect(english.downloadable, isFalse);
      expect(english.bundled, isTrue);
      expect(english.assetPath, 'assets/data/translations/en_rwwad.json.gz');
      expect(defaultQuranSourceForLanguage('en'), englishTranslationId);
    },
  );

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

  test(
    'audio catalog keeps recordings attached to their exact text source',
    () {
      final arabic = quranAudioForSource(arabicOriginalSourceId);
      final english = primaryQuranAudioForSource(englishTranslationId);
      final vakfi = primaryQuranAudioForSource(turkishVakfiTranslationId);

      expect(arabic.length, greaterThanOrEqualTo(10));
      expect(arabic.first.title, 'Mishary Rashid Alafasy');
      expect(
        arabic.every((item) => item.kind == QuranAudioKind.recitation),
        isTrue,
      );
      expect(english, isNotNull);
      expect(english!.providerKey, 'english_rwwad');
      expect(vakfi, isNotNull);
      expect(vakfi!.providerKey, 'tr.vakfi-audio');
      expect(hasQuranAudioForSource(bundledTurkishTranslationId), isFalse);
      expect(
        quranAudioCatalog
            .where((item) => item.kind == QuranAudioKind.translation)
            .length,
        greaterThanOrEqualTo(12),
      );
    },
  );

  test('Turkish catalog exposes multiple human translations', () {
    final turkish = translationCatalog
        .where((item) => item.languageCode == 'tr')
        .toList();
    expect(turkish.length, greaterThanOrEqualTo(4));
    expect(
      translationById(turkishShabanTranslationId)?.sourceKey,
      'turkish_shaban',
    );
    expect(
      translationById(turkishAliOzekTranslationId)?.sourceKey,
      'turkish_shahin',
    );
    expect(
      translationById(turkishVakfiTranslationId)?.provider,
      TranslationProvider.islamicNetwork,
    );
  });
}
