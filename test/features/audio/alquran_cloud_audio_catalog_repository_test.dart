import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/audio/data/alquran_cloud_audio_catalog_repository.dart';
import 'package:quran_i_kerim/src/features/audio/domain/quran_audio_source.dart';

void main() {
  const payload = '''
{
  "code": 200,
  "status": "OK",
  "data": [
    {
      "identifier": "ar.reader-one",
      "language": "ar",
      "name": "Reader One",
      "englishName": "Reader One",
      "format": "audio",
      "type": "versebyverse"
    },
    {
      "identifier": "ar.reader-two",
      "language": "ar",
      "name": "Reader Two",
      "englishName": "Reader Two",
      "format": "audio",
      "type": "versebyverse"
    },
    {
      "identifier": "tr.translation-reader",
      "language": "tr",
      "name": "Türkçe Meal",
      "englishName": "Turkish Translation",
      "format": "audio",
      "type": "translation"
    },
    {
      "identifier": "en.synthetic-tts",
      "language": "en",
      "name": "Synthetic TTS",
      "englishName": "Synthetic TTS",
      "format": "audio",
      "type": "translation"
    },
    {
      "identifier": "en.text-only",
      "language": "en",
      "name": "Text",
      "englishName": "Text",
      "format": "text",
      "type": "translation"
    }
  ]
}
''';

  test('parses all human audio editions and rejects text/TTS entries', () {
    final catalog = AlQuranCloudAudioCatalogRepository.parseCatalog(payload);

    expect(catalog.sources, hasLength(3));
    expect(catalog.languageCodes, <String>['ar', 'tr']);
    expect(
      catalog.sources.every(
        (source) =>
            source.providerName == 'Al Quran Cloud / Islamic Network' &&
            source.termsUri.host == 'alquran.cloud',
      ),
      isTrue,
    );
  });

  test('groups alternative human reciters by language and kind', () {
    final catalog = AlQuranCloudAudioCatalogRepository.parseCatalog(payload);

    final arabic = catalog.alternatives(
      languageCode: 'ar',
      kind: QuranAudioKind.quran,
    );
    final turkishMeal = catalog.alternatives(
      languageCode: 'tr',
      kind: QuranAudioKind.translation,
    );

    expect(
      arabic.map((source) => source.identifier),
      <String>['ar.reader-one', 'ar.reader-two'],
    );
    expect(turkishMeal, hasLength(1));
    expect(turkishMeal.single.isTranslation, isTrue);
  });

  test('fails closed for malformed catalog payloads', () {
    expect(
      () => AlQuranCloudAudioCatalogRepository.parseCatalog('{"data":{}}'),
      throwsFormatException,
    );
  });
}
