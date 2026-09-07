import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the bundled Turkish translation once and keeps it in memory.
///
/// The build workflow places the compressed QuranEnc/Rowwad JSON in assets.
/// Keeping the source compressed saves install size; decoding happens locally
/// and never requires a network request at app runtime.
class TranslationRepository {
  TranslationRepository._();

  static final TranslationRepository instance = TranslationRepository._();

  static const String bundledTurkishAsset =
      'assets/data/translations/tr_rwwad.json.gz';

  Future<Map<String, String>>? _turkishFuture;

  Future<Map<String, String>> loadBundledTurkish() =>
      _turkishFuture ??= _loadGzipJson(bundledTurkishAsset);

  Future<String?> turkishVerse(int surah, int ayah) async {
    final verses = await loadBundledTurkish();
    return verses['$surah:$ayah'];
  }

  Future<Map<String, String>> _loadGzipJson(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final decodedBytes = gzip.decode(bytes);
    final decoded = jsonDecode(utf8.decode(decodedBytes));

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Meal paketi beklenen JSON biçiminde değil.');
    }

    final result = decoded.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    if (result.length < 6200) {
      throw FormatException(
        'Meal paketi eksik görünüyor: ${result.length} ayet bulundu.',
      );
    }
    return result;
  }
}
