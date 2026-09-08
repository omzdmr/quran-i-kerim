import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'translation_catalog.dart';
import 'translation_pack.dart';

/// Local-first translation loader and installer.
///
/// Turkish stays bundled so the app always has an offline translation. Extra
/// translations are fetched from QuranEnc only when the user explicitly asks
/// for them, validated, gzip-compressed, and stored in app-private storage.
class TranslationRepository {
  TranslationRepository._();

  static final TranslationRepository instance = TranslationRepository._();

  static const String bundledTurkishAsset =
      'assets/data/translations/tr_rwwad.json.gz';
  static const String _quranEncHost = 'quranenc.com';
  static const String _userAgent = 'quran-i-kerim/0.4 translation-downloader';

  Future<TranslationPack>? _turkishPackFuture;
  final Map<String, Future<TranslationPack>> _downloadedPackFutures =
      <String, Future<TranslationPack>>{};

  Future<TranslationPack> loadBundledTurkishPack() => _turkishPackFuture ??=
      _loadAssetPack(
        bundledTurkishAsset,
        fallbackTranslationId: bundledTurkishTranslationId,
        fallbackLanguageCode: 'tr',
        fallbackVersion: '1.0.4',
        fallbackSource: 'QuranEnc.com',
      );

  Future<Map<String, String>> loadBundledTurkish() async =>
      (await loadBundledTurkishPack()).verses;

  Future<String?> turkishVerse(int surah, int ayah) async =>
      (await loadBundledTurkishPack()).verse(surah, ayah);

  /// Returns verses for a selected translation source. Arabic original has no
  /// translation map and is handled by the Quran text package in the reader.
  Future<Map<String, String>> loadSourceVerses(String sourceId) async {
    if (sourceId == arabicOriginalSourceId) return const <String, String>{};
    if (sourceId == bundledTurkishTranslationId) return loadBundledTurkish();
    final info = translationById(sourceId);
    if (info == null) {
      throw StateError('Unknown translation source: $sourceId');
    }
    return (await loadInstalledPack(info)).verses;
  }

  Future<TranslationPack> loadInstalledPack(TranslationInfo info) async {
    if (info.bundled) return loadBundledTurkishPack();
    return _downloadedPackFutures.putIfAbsent(info.id, () async {
      final file = await _downloadFile(info.id);
      if (!await file.exists()) {
        throw StateError('Translation is not installed: ${info.id}');
      }
      final bytes = await file.readAsBytes();
      return decodeGzipPack(
        bytes,
        fallbackTranslationId: info.id,
        fallbackLanguageCode: info.languageCode,
        fallbackVersion: info.version,
        fallbackSource: info.source,
      );
    });
  }

  Future<bool> isInstalled(String sourceId) async {
    if (sourceId == arabicOriginalSourceId ||
        sourceId == bundledTurkishTranslationId) {
      return true;
    }
    final info = translationById(sourceId);
    if (info == null) return false;
    final file = await _downloadFile(info.id);
    return file.exists();
  }

  Future<void> deleteInstalledTranslation(String sourceId) async {
    if (sourceId == arabicOriginalSourceId ||
        sourceId == bundledTurkishTranslationId) {
      return;
    }
    final file = await _downloadFile(sourceId);
    if (await file.exists()) await file.delete();
    _downloadedPackFutures.remove(sourceId);
  }

  /// Downloads an official QuranEnc translation and preserves upstream items,
  /// including transcript/footnote fields, inside our local pack.
  Future<void> downloadTranslation(
    TranslationInfo info, {
    ValueChanged<double>? onProgress,
  }) async {
    if (info.bundled) {
      onProgress?.call(1);
      return;
    }
    if (!info.downloadable) {
      throw StateError('Translation is not enabled for download: ${info.id}');
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);
    try {
      onProgress?.call(.01);
      final catalogUri = Uri.https(
        _quranEncHost,
        '/api/v1/translations/list/${info.languageCode}',
        const <String, String>{'localization': 'en'},
      );
      final catalogPayload = await _getJson(client, catalogUri);
      final catalog = _resultList(catalogPayload, context: 'translations/list');
      Map<String, dynamic>? upstream;
      for (final raw in catalog) {
        if ('${raw['key'] ?? ''}' == info.sourceKey) {
          upstream = raw;
          break;
        }
      }
      if (upstream == null) {
        throw StateError(
          'QuranEnc no longer exposes translation key ${info.sourceKey}.',
        );
      }
      final upstreamVersion = '${upstream['version'] ?? ''}'.trim();
      if (upstreamVersion.isNotEmpty && upstreamVersion != info.version) {
        throw StateError(
          'Translation version changed from ${info.version} to $upstreamVersion. '
          'The catalog must be reviewed before installing it.',
        );
      }

      final items = <Map<String, dynamic>>[];
      final seen = <String>{};
      const concurrency = 6;
      for (var start = 1; start <= 114; start += concurrency) {
        final end = math.min(start + concurrency - 1, 114);
        final chunks = await Future.wait([
          for (var surah = start; surah <= end; surah++)
            _fetchSurah(client, info, surah),
        ]);
        for (final chunk in chunks) {
          for (final raw in chunk) {
            final surah = int.tryParse('${raw['sura']}');
            final ayah = int.tryParse('${raw['aya']}');
            final translation = raw['translation'];
            if (surah == null ||
                surah < 1 ||
                surah > 114 ||
                ayah == null ||
                ayah < 1 ||
                translation is! String ||
                translation.trim().isEmpty) {
              throw const FormatException('QuranEnc returned an invalid verse.');
            }
            final key = '$surah:$ayah';
            if (!seen.add(key)) {
              throw FormatException('QuranEnc returned duplicate verse $key.');
            }
            items.add(Map<String, dynamic>.from(raw));
          }
        }
        onProgress?.call(.03 + .94 * (end / 114));
      }

      if (items.length < 6000) {
        throw FormatException(
          'Downloaded translation looks incomplete: ${items.length} verses.',
        );
      }

      final package = <String, dynamic>{
        'schema_version': 1,
        'source': info.source,
        'source_key': info.sourceKey,
        'language_iso_code': info.languageCode,
        'version': upstreamVersion.isEmpty ? info.version : upstreamVersion,
        'last_update': upstream['last_update'],
        'title': upstream['title'],
        'description': upstream['description'],
        'terms': const <String, dynamic>{
          'no_modification': true,
          'publisher_and_source_required': true,
          'version_required': true,
          'keep_transcript_information': true,
          'update_to_latest_required': true,
          'no_inappropriate_ads_with_translation': true,
        },
        'items': items,
      };

      final encoded = utf8.encode(jsonEncode(package));
      final compressed = Uint8List.fromList(gzip.encode(encoded));

      // Decode before replacing an existing pack. A network hiccup should not
      // turn a good offline copy into a corrupted one.
      decodeGzipPack(
        compressed,
        fallbackTranslationId: info.id,
        fallbackLanguageCode: info.languageCode,
        fallbackVersion: info.version,
        fallbackSource: info.source,
      );

      final file = await _downloadFile(info.id);
      final temp = File('${file.path}.tmp');
      await temp.writeAsBytes(compressed, flush: true);
      if (await file.exists()) await file.delete();
      await temp.rename(file.path);
      _downloadedPackFutures.remove(info.id);
      onProgress?.call(1);
    } finally {
      client.close(force: true);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSurah(
    HttpClient client,
    TranslationInfo info,
    int surah,
  ) async {
    final uri = Uri.https(
      _quranEncHost,
      '/api/v1/translation/sura/${info.sourceKey}/$surah',
    );
    final payload = await _getJson(client, uri);
    return _resultList(payload, context: 'sura $surah');
  }

  Future<dynamic> _getJson(HttpClient client, Uri uri) async {
    final request = await client.getUrl(uri);
    request.headers
      ..set(HttpHeaders.userAgentHeader, _userAgent)
      ..set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException(
        'QuranEnc returned HTTP ${response.statusCode}.',
        uri: uri,
      );
    }
    final bytes = await response.fold<List<int>>(
      <int>[],
      (buffer, data) => buffer..addAll(data),
    );
    return jsonDecode(utf8.decode(bytes));
  }

  List<Map<String, dynamic>> _resultList(
    dynamic payload, {
    required String context,
  }) {
    dynamic raw = payload;
    if (raw is Map && raw['result'] is List) raw = raw['result'];
    if (raw is! List) {
      throw FormatException('Unexpected QuranEnc response for $context.');
    }
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  Future<File> _downloadFile(String sourceId) async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/translations');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}/$sourceId.json.gz');
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
