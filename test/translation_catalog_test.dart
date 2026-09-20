import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/quran_audio_catalog.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';

void main() {
  setUp(() {
    // Runtime discovery mutates the in-memory catalogue. Reset to the immutable
    // curated baseline so every test starts from the same local-first state.
    registerDiscoveredTranslations(const <TranslationInfo>[]);
  });

  tearDown(() {
    registerDiscoveredTranslations(const <TranslationInfo>[]);
  });

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
        greaterThanOrEqualTo(13),
      );
    },
  );

  test('QuranEnc audio catalog matches currently published API keys', () {
    final keys = quranAudioCatalog
        .where(
          (item) =>
              item.kind == QuranAudioKind.translation &&
              item.provider == QuranAudioProvider.quranEnc,
        )
        .map((item) => item.providerKey)
        .toSet();

    expect(
      keys,
      equals(<String>{
        'english_rwwad',
        'french_rashid',
        'portuguese_nasr',
        'dutch_center',
        'tagalog_rwwad',
        'chinese_suliman',
        'vietnamese_rwwad',
        'persian_ih',
        'assamese_rafeeq',
        'sinhalese_mahir',
        'somali_yacob',
      }),
    );
    expect(primaryQuranAudioForSource('azeri_musayev'), isNull);
    expect(primaryQuranAudioForSource('tamil_omar_brief'), isNull);
    expect(translationById('azeri_musayev')?.hasAudio, isFalse);
    expect(translationById('tamil_omar_brief')?.hasAudio, isFalse);
  });

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

  test('new discovery snapshot removes stale upstream-only translations', () {
    const stale = TranslationInfo(
      id: 'test_removed_upstream',
      code: 'QENC-ZZ',
      languageCode: 'zz',
      name: 'Temporary upstream translation',
      publisher: 'QuranEnc.com',
      source: 'QuranEnc.com',
      sourceKey: 'test_removed_upstream',
      version: '1.0.0',
      bundled: false,
      available: true,
      downloadable: true,
      description: 'Old localized description',
      lastUpdated: '1700000000',
    );
    const current = TranslationInfo(
      id: 'test_current_upstream',
      code: 'QENC-YY',
      languageCode: 'yy',
      name: 'Current upstream translation',
      publisher: 'QuranEnc.com',
      source: 'QuranEnc.com',
      sourceKey: 'test_current_upstream',
      version: '2.0.0',
      bundled: false,
      available: true,
      downloadable: true,
      description: 'Current localized description',
      lastUpdated: '1800000000',
    );

    registerDiscoveredTranslations(const <TranslationInfo>[stale, current]);
    expect(translationById(stale.id), isNotNull);
    expect(translationById(current.id), isNotNull);

    registerDiscoveredTranslations(const <TranslationInfo>[current]);
    expect(translationById(stale.id), isNull);
    expect(translationById(current.id)?.version, '2.0.0');
    expect(
      translationById(current.id)?.description,
      'Current localized description',
    );
    expect(translationById(current.id)?.lastUpdated, '1800000000');
  });

  test('curated QuranEnc source receives upstream metadata safely', () {
    final before = translationById('tagalog_rwwad');
    expect(before, isNotNull);

    const upstream = TranslationInfo(
      id: 'tagalog_rwwad',
      code: 'QENC-TL',
      languageCode: 'tl',
      name: 'Upstream Tagalog title',
      publisher: 'Do not replace curated publisher',
      source: 'QuranEnc.com',
      sourceKey: 'tagalog_rwwad',
      version: '9.9.9',
      bundled: false,
      available: true,
      downloadable: true,
      description: 'Localized upstream description',
      lastUpdated: '1900000000',
    );

    registerDiscoveredTranslations(const <TranslationInfo>[upstream]);
    final merged = translationById('tagalog_rwwad');
    expect(merged, isNotNull);
    expect(merged!.name, 'Upstream Tagalog title');
    expect(merged.version, '9.9.9');
    expect(merged.code, 'RWD-TL');
    expect(merged.publisher, before!.publisher);
    expect(merged.sourceKey, before.sourceKey);
    expect(merged.hasAudio, isTrue);
    expect(merged.description, 'Localized upstream description');
    expect(merged.lastUpdated, '1900000000');
  });

  test('bundled translation keeps the version of its packaged bytes', () {
    const upstream = TranslationInfo(
      id: englishTranslationId,
      code: 'QENC-EN',
      languageCode: 'en',
      name: 'New upstream English title',
      publisher: 'QuranEnc.com',
      source: 'QuranEnc.com',
      sourceKey: 'english_rwwad',
      version: '99.0.0',
      bundled: false,
      available: true,
      downloadable: true,
      description: 'New upstream description',
      lastUpdated: '2000000000',
    );

    registerDiscoveredTranslations(const <TranslationInfo>[upstream]);
    final english = translationById(englishTranslationId);
    expect(english, isNotNull);
    expect(english!.version, '1.0.19');
    expect(english.name, 'English Translation');
    expect(english.bundled, isTrue);
    expect(english.description, isNull);
    expect(english.lastUpdated, isNull);
  });
}
