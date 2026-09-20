import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/surah_catalog.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/data/translation_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled Turkish translation still loads through pack decoder',
    () async {
      final pack = await TranslationRepository.instance
          .loadBundledTurkishPack();

      expect(pack.translationId, 'turkish_rwwad');
      expect(pack.languageCode, 'tr');
      expect(pack.source, 'QuranEnc.com');
      expect(pack.verses.length, greaterThan(6000));
      expect(pack.verse(1, 1), isNotEmpty);
      expect(pack.verse(2, 255), isNotEmpty);
      expect(pack.verse(114, 6), isNotEmpty);
    },
  );

  test('Islamic Network translation uses one complete-edition request', () {
    final info = translationById(turkishVakfiTranslationId)!;
    final uri = islamicNetworkTranslationPackageUri(info);
    expect(uri.host, 'api.alquran.cloud');
    expect(uri.path, '/v1/quran/tr.vakfi');
  });

  test('QuranEnc footnote markers and source footnotes survive pack decoding', () {
    const verseWithMarkers = 'Texto [1] com notas [2] e [3].';
    const sourceFootnotes =
        '[1] Primeira nota. [2] Segunda nota. [3] Terceira nota.';
    final items = <Map<String, dynamic>>[];

    for (final surah in surahCatalog) {
      for (var ayah = 1; ayah <= surah.verseCount; ayah++) {
        items.add(<String, dynamic>{
          'sura': surah.number,
          'aya': ayah,
          'translation': surah.number == 4 && ayah == 3
              ? verseWithMarkers
              : 'Verse ${surah.number}:$ayah',
          if (surah.number == 4 && ayah == 3) 'footnotes': sourceFootnotes,
        });
      }
    }

    final encoded = Uint8List.fromList(
      gzip.encode(
        utf8.encode(
          jsonEncode(<String, dynamic>{
            'schema_version': 1,
            'source': 'QuranEnc.com',
            'source_key': 'portuguese_nasr',
            'language_iso_code': 'pt',
            'version': 'test-version',
            'items': items,
          }),
        ),
      ),
    );

    final pack = TranslationRepository.instance.decodeGzipPack(encoded);

    expect(pack.verse(4, 3), verseWithMarkers);
    expect(pack.footnote(4, 3), sourceFootnotes);
    expect(pack.footnote(4, 4), isNull);
    expect(pack.source, 'QuranEnc.com');
    expect(pack.version, 'test-version');
  });
}
