import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_i_kerim/src/data/transliteration_repository.dart';

void main() {
  Map<String, String> completeFixture() {
    final values = <String, String>{};
    for (var surah = 1; surah <= 114; surah++) {
      for (var ayah = 1; ayah <= quran.getVerseCount(surah); ayah++) {
        values['$surah:$ayah'] = 'transliteration-$surah-$ayah';
      }
    }
    return values;
  }

  List<int> encode(Map<String, String> values) =>
      gzip.encode(utf8.encode(jsonEncode(values)));

  test('bundled transliteration decoder preserves provider text', () {
    final fixture = completeFixture();
    const providerText = '  Fa-inna maAAa alAAusri yusran  ';
    fixture['94:5'] = providerText;

    final decoded = decodeBundledTransliteration(encode(fixture));

    expect(decoded['94:5'], providerText);
    expect(decoded.length, 6236);
  });

  test('bundled transliteration decoder rejects incomplete coverage', () {
    final incomplete = <String, String>{
      '1:1': 'bismi',
      '2:255': 'ayat al-kursi',
      '114:6': 'mina aljinnati wannas',
    };

    expect(
      () => decodeBundledTransliteration(encode(incomplete)),
      throwsA(isA<FormatException>()),
    );
  });

  test('bundled transliteration decoder rejects empty provider text', () {
    final fixture = completeFixture();
    fixture['94:5'] = '   ';

    expect(
      () => decodeBundledTransliteration(encode(fixture)),
      throwsA(isA<FormatException>()),
    );
  });
}
