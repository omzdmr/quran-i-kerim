import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

const bundledTransliterationAssetPath =
    'assets/data/transliterations/en_transliteration.json.gz';
const bundledTransliterationSourceLabel =
    'Al Quran Cloud · en.transliteration';

Map<String, String> decodeBundledTransliteration(List<int> bytes) {
  final decoded = jsonDecode(utf8.decode(gzip.decode(bytes)));
  if (decoded is! Map) {
    throw const FormatException('Transliteration bundle must be a JSON object.');
  }

  final verses = <String, String>{};
  final surahs = <int>{};
  for (final entry in decoded.entries) {
    final key = '${entry.key}';
    final separator = key.indexOf(':');
    if (separator <= 0 || separator >= key.length - 1) {
      throw FormatException('Invalid transliteration verse key: $key');
    }
    final surah = int.tryParse(key.substring(0, separator));
    final ayah = int.tryParse(key.substring(separator + 1));
    final value = entry.value;
    if (surah == null ||
        surah < 1 ||
        surah > 114 ||
        ayah == null ||
        ayah < 1 ||
        value is! String ||
        value.trim().isEmpty) {
      throw FormatException('Invalid transliteration entry: $key');
    }
    surahs.add(surah);
    verses[key] = value;
  }

  if (surahs.length != 114 || verses.length != 6236) {
    throw FormatException(
      'Transliteration bundle looks incomplete: ${verses.length} verses, '
      '${surahs.length} surahs.',
    );
  }
  for (final key in const <String>['1:1', '2:255', '114:6']) {
    if (!verses.containsKey(key)) {
      throw FormatException('Transliteration bundle is missing $key.');
    }
  }
  return Map<String, String>.unmodifiable(verses);
}

class TransliterationRepository {
  TransliterationRepository._();

  static final TransliterationRepository instance = TransliterationRepository._();

  Future<Map<String, String>>? _bundledFuture;

  Future<Map<String, String>> loadBundled() {
    return _bundledFuture ??= _loadBundledAsset();
  }

  Future<String?> verse(int surah, int ayah) async =>
      (await loadBundled())['$surah:$ayah'];

  Future<Map<String, String>> _loadBundledAsset() async {
    final data = await rootBundle.load(bundledTransliterationAssetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return decodeBundledTransliteration(bytes);
  }
}
