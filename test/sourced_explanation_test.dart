import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/sourced_explanation.dart';
import 'package:quran_i_kerim/src/data/translation_pack.dart';

void main() {
  test('translation footnote preserves exact source text and provenance', () {
    const raw = '  [1] First source note.\n[2] Second source note.  ';
    const pack = TranslationPack(
      translationId: 'portuguese_nasr',
      languageCode: 'pt',
      version: '2.0.0',
      source: 'QuranEnc.com',
      verses: <String, String>{'4:3': 'Sample translation'},
      footnotes: <String, String>{'4:3': raw},
    );

    final explanation = sourcedTranslationFootnote(
      pack: pack,
      surah: 4,
      ayah: 3,
    );

    expect(explanation, isNotNull);
    expect(explanation!.text, raw);
    expect(explanation.reference, '4:3');
    expect(explanation.sourceId, 'portuguese_nasr');
    expect(explanation.languageCode, 'pt');
    expect(explanation.source, 'QuranEnc.com');
    expect(explanation.version, '2.0.0');
  });

  test('empty and invalid source notes are not exposed', () {
    const pack = TranslationPack(
      translationId: 'source',
      languageCode: 'en',
      version: '1',
      source: 'Example source',
      verses: <String, String>{},
      footnotes: <String, String>{'1:1': '   \n  '},
    );

    expect(
      sourcedTranslationFootnote(pack: pack, surah: 1, ayah: 1),
      isNull,
    );
    expect(
      sourcedTranslationFootnote(pack: pack, surah: 1, ayah: 2),
      isNull,
    );
    expect(
      sourcedTranslationFootnote(pack: pack, surah: 0, ayah: 1),
      isNull,
    );
  });
}
