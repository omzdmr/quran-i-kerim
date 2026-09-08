import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'translation_pack.dart';

/// Local-first translation loader.
///
/// The first Turkish translation is still bundled for zero-network reading.
/// Downloaded translations will use the versioned QuranEnc pack format handled
/// by the same decoder, so the reader does not need separate code paths for
/// bundled and downloaded content.
class TranslationRepository {
  TranslationRepository._();

  static final TranslationRepository instance = TranslationRepository._();

  static const String bundledTurkishAsset =
      'assets/data/translations/tr_rwwad.json.gz';

  Future<TranslationPack>? _turkishPackFuture;

  Future<TranslationPack> loadBundledTurkishPack() => _turkishPackFuture ??=
      _loadAssetPack(
        bundledTurkishAsset,
        fallbackTranslationId: 'turkish_rwwad',
        fallbackLanguageCode: 'tr',
        fallbackVersion: '1.0.4',
        fallbackSource: 'QuranEnc.com',
      );

  /// Backwards-compatible map view used by the current reader/search screens.
  Future<Map<String, String>> loadBundledTurkish() async =>
      (await loadBundledTurkishPack()).verses;

  Future<String?> turkishVerse(int surah, int ayah) async =>
      (await loadBundledTurkishPack()).verse(surah, ayah);

  /// Loads an offline pack previously downloaded to app-private storage.
  Future<TranslationPack> loadDownloadedPack(File file) async {
    final bytes = await file.readAsBytes();
    return decodeGzipPack(bytes);
  }

  Future<TranslationPack> _loadAssetPack(
    String assetPath, {
    required String fallbackTranslationId,
    required String fallbackLanguageCode,
    required String fallbackVersion,
    required String fallbackSource,
  }) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return decodeGzipPack(
      bytes,
      fallbackTranslationId: fallbackTranslationId,
      fallbackLanguageCode: fallbackLanguageCode,
      fallbackVersion: fallbackVersion,
      fallbackSource: fallbackSource,
    );
  }

  TranslationPack decodeGzipPack(
    Uint8List bytes, {
    String fallbackTranslationId = 'unknown',
    String fallbackLanguageCode = 'und',
    String fallbackVersion = 'unknown',
    String fallbackSource = 'unknown',
  }) {
    final decodedBytes = gzip.decode(bytes);
    final decoded = jsonDecode(utf8.decode(decodedBytes));

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Translation pack is not a JSON object.');
    }

    // Legacy v0 pack: a flat {"surah:ayah": "translation"} map. We keep
    // support so existing test/release artifacts remain readable.
    if (!decoded.containsKey('schema_version')) {
      final verses = decoded.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      _validateVerses(verses);
      return TranslationPack(
        translationId: fallbackTranslationId,
        languageCode: fallbackLanguageCode,
        version: fallbackVersion,
        source: fallbackSource,
        verses: Map<String, String>.unmodifiable(verses),
        footnotes: const <String, String>{},
      );
    }

    final schemaVersion = decoded['schema_version'];
    if (schemaVersion != 1) {
      throw FormatException('Unsupported translation pack schema: $schemaVersion');
    }

    final rawItems = decoded['items'];
    if (rawItems is! List) {
      throw const FormatException('Translation pack items are missing.');
    }

    final verses = <String, String>{};
    final footnotes = <String, String>{};
    for (final raw in rawItems) {
      if (raw is! Map) {
        throw const FormatException('Invalid translation pack item.');
      }
      final surah = int.tryParse('${raw['sura']}');
      final ayah = int.tryParse('${raw['aya']}');
      final translation = raw['translation'];
      if (surah == null || surah < 1 || surah > 114 || ayah == null || ayah < 1) {
        throw FormatException('Invalid verse identity: ${raw['sura']}:${raw['aya']}');
      }
      if (translation is! String || translation.trim().isEmpty) {
        throw FormatException('Empty translation at $surah:$ayah');
      }
      final key = '$surah:$ayah';
      if (verses.containsKey(key)) {
        throw FormatException('Duplicate translation verse: $key');
      }
      verses[key] = translation;

      final footnote = raw['footnotes'];
      if (footnote is String && footnote.isNotEmpty) {
        footnotes[key] = footnote;
      }
    }

    _validateVerses(verses);

    return TranslationPack(
      translationId: '${decoded['source_key'] ?? fallbackTranslationId}',
      languageCode: '${decoded['language_iso_code'] ?? fallbackLanguageCode}',
      version: '${decoded['version'] ?? fallbackVersion}',
      source: '${decoded['source'] ?? fallbackSource}',
      verses: Map<String, String>.unmodifiable(verses),
      footnotes: Map<String, String>.unmodifiable(footnotes),
    );
  }

  void _validateVerses(Map<String, String> verses) {
    if (verses.length < 6000) {
      throw FormatException(
        'Translation pack looks incomplete: ${verses.length} verses found.',
      );
    }

    final seenSurahs = <int>{};
    for (final entry in verses.entries) {
      final separator = entry.key.indexOf(':');
      if (separator < 1 || separator == entry.key.length - 1) {
        throw FormatException('Invalid verse key: ${entry.key}');
      }
      final surah = int.tryParse(entry.key.substring(0, separator));
      final ayah = int.tryParse(entry.key.substring(separator + 1));
      if (surah == null || surah < 1 || surah > 114 || ayah == null || ayah < 1) {
        throw FormatException('Invalid verse key: ${entry.key}');
      }
      if (entry.value.trim().isEmpty) {
        throw FormatException('Empty translation at ${entry.key}');
      }
      seenSurahs.add(surah);
    }

    if (seenSurahs.length != 114) {
      throw FormatException(
        'Translation pack is missing surahs: ${114 - seenSurahs.length}',
      );
    }
  }
}
