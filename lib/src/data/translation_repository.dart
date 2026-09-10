import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'translation_catalog.dart';
import 'translation_pack.dart';

/// Raised when the user explicitly cancels an in-flight translation download.
class TranslationDownloadCancelledException implements Exception {
  const TranslationDownloadCancelledException();

  @override
  String toString() => 'Translation download cancelled.';
}

/// Local-first translation loader and installer.
///
/// Small defaults stay bundled. QuranEnc catalogue metadata is cached locally
/// and translation bodies are downloaded only after an explicit user choice.
Uri islamicNetworkTranslationPackageUri(TranslationInfo info) =>
    Uri.https('api.alquran.cloud', '/v1/quran/${info.sourceKey}');

class TranslationRepository {
  TranslationRepository._();

  static final TranslationRepository instance = TranslationRepository._();

  static const String _quranEncHost = 'quranenc.com';
  static const String _userAgent = 'quran-i-kerim/0.5 translation-downloader';
  static const Duration _catalogMaxAge = Duration(days: 7);

  final Map<String, Future<TranslationPack>> _bundledPackFutures =
      <String, Future<TranslationPack>>{};
  final Map<String, Future<TranslationPack>> _downloadedPackFutures =
      <String, Future<TranslationPack>>{};
  final Map<String, Future<void>> _activeDownloads = <String, Future<void>>{};
  final Map<String, HttpClient> _downloadClients = <String, HttpClient>{};
  final Set<String> _cancelledDownloads = <String>{};

  Future<TranslationPack> loadBundledTurkishPack() =>
      loadBundledPack(translationById(bundledTurkishTranslationId)!);

  Future<Map<String, String>> loadBundledTurkish() async =>
      (await loadBundledTurkishPack()).verses;

  Future<String?> turkishVerse(int surah, int ayah) async =>
      (await loadBundledTurkishPack()).verse(surah, ayah);

  Future<TranslationPack> loadBundledPack(TranslationInfo info) {
    if (!info.bundled || info.assetPath == null) {
      throw StateError('Translation is not bundled: ${info.id}');
    }
    return _bundledPackFutures.putIfAbsent(
      info.id,
      () => _loadAssetPack(
        info.assetPath!,
        fallbackTranslationId: info.id,
        fallbackLanguageCode: info.languageCode,
        fallbackVersion: info.version,
        fallbackSource: info.source,
      ),
    );
  }

  Future<TranslationPack> loadSourcePack(String sourceId) async {
    if (sourceId == arabicOriginalSourceId) {
      throw StateError('Arabic original is not a translation pack.');
    }
    final info = translationById(sourceId);
    if (info == null) {
      throw StateError('Unknown translation source: $sourceId');
    }
    return loadInstalledPack(info);
  }

  Future<Map<String, String>> loadSourceVerses(String sourceId) async {
    if (sourceId == arabicOriginalSourceId) return const <String, String>{};
    return (await loadSourcePack(sourceId)).verses;
  }

  Future<TranslationPack> loadInstalledPack(TranslationInfo info) async {
    if (info.bundled) return loadBundledPack(info);
    return _downloadedPackFutures.putIfAbsent(info.id, () async {
      final file = await _downloadFile(info.id);
      if (!await file.exists()) {
        throw StateError('Translation is not installed: ${info.id}');
      }
      try {
        return decodeGzipPack(
          await file.readAsBytes(),
          fallbackTranslationId: info.id,
          fallbackLanguageCode: info.languageCode,
          fallbackVersion: info.version,
          fallbackSource: info.source,
        );
      } catch (_) {
        _downloadedPackFutures.remove(info.id);
        if (await file.exists()) await file.delete();
        rethrow;
      }
    });
  }

  Future<bool> isInstalled(String sourceId) async {
    if (sourceId == arabicOriginalSourceId) return true;
    final info = translationById(sourceId);
    if (info == null) return false;
    if (info.bundled) return true;
    final file = await _downloadFile(info.id);
    if (!await file.exists()) return false;
    try {
      decodeGzipPack(
        await file.readAsBytes(),
        fallbackTranslationId: info.id,
        fallbackLanguageCode: info.languageCode,
        fallbackVersion: info.version,
        fallbackSource: info.source,
      );
      return true;
    } catch (_) {
      if (await file.exists()) await file.delete();
      _downloadedPackFutures.remove(info.id);
      return false;
    }
  }

  Future<int> installedTranslationBytes(String sourceId) async {
    final info = translationById(sourceId);
    if (info == null || info.bundled) return 0;
    final file = await _downloadFile(sourceId);
    return await file.exists() ? file.length() : 0;
  }

  Future<void> deleteInstalledTranslation(String sourceId) async {
    if (sourceId == arabicOriginalSourceId) return;
    final info = translationById(sourceId);
    if (info == null || info.bundled) return;
    await cancelTranslationDownload(sourceId);
    final file = await _downloadFile(sourceId);
    for (final path in <String>[
      file.path,
      '${file.path}.part',
      '${file.path}.tmp',
      '${file.path}.bak',
    ]) {
      final candidate = File(path);
      if (await candidate.exists()) await candidate.delete();
    }
    _downloadedPackFutures.remove(sourceId);
  }

  /// Loads the last successful QuranEnc catalogue snapshot without network.
  ///
  /// This is also the startup recovery point for interrupted translation or
  /// catalogue writes. Old `.tmp`/`.part` files are disposable; a `.bak` is
  /// restored only when the committed file is missing.
  Future<void> loadCachedCatalog() async {
    await _recoverInterruptedWrites();
    final file = await _catalogCacheFile();
    if (!await file.exists()) return;
    try {
      final decoded = jsonDecode(await file.readAsString());
      _registerCatalogPayload(decoded);
    } catch (_) {
      if (await file.exists()) await file.delete();
    }
  }

  /// One tiny catalogue refresh per week; failures leave the cached/static
  /// catalogue untouched so reading never depends on connectivity.
  Future<void> refreshCatalogIfStale({String localization = 'en'}) async {
    final file = await _catalogCacheFile();
    if (await file.exists()) {
      final age = DateTime.now().difference(await file.lastModified());
      if (age >= Duration.zero && age < _catalogMaxAge) return;
    }
    try {
      await refreshQuranEncCatalog(localization: localization);
    } catch (_) {
      // Catalogue discovery is best-effort. Existing offline sources remain.
    }
  }

  Future<int> refreshQuranEncCatalog({String localization = 'en'}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..idleTimeout = const Duration(seconds: 20);
    try {
      final safeLocale = RegExp(r'^[A-Za-z]{2,3}$').hasMatch(localization)
          ? localization.toLowerCase()
          : 'en';
      final uri = Uri.https(
        _quranEncHost,
        '/api/v1/translations/list',
        <String, String>{'localization': safeLocale},
      );
      final payload = await _getJson(client, uri);
      final count = _registerCatalogPayload(payload);
      if (count == 0) {
        throw const FormatException('QuranEnc catalogue is empty.');
      }
      final file = await _catalogCacheFile();
      final part = File('${file.path}.part');
      if (await part.exists()) await part.delete();
      try {
        await part.writeAsString(jsonEncode(payload), flush: true);
        jsonDecode(await part.readAsString());
        await _commitPartFile(file, part);
      } catch (_) {
        if (await part.exists()) await part.delete();
        rethrow;
      }
      return count;
    } finally {
      client.close(force: true);
    }
  }

  int _registerCatalogPayload(dynamic payload) {
    final rows = _resultList(payload, context: 'translations/list');
    final discovered = <TranslationInfo>[];
    for (final raw in rows) {
      final key = '${raw['key'] ?? ''}'.trim();
      final language = '${raw['language_iso_code'] ?? ''}'.trim().toLowerCase();
      final title = '${raw['title'] ?? ''}'.trim();
      if (key.isEmpty || language.isEmpty || title.isEmpty) continue;
      final version = '${raw['version'] ?? 'latest'}'.trim();
      final description = '${raw['description'] ?? ''}'.trim();
      final lastUpdated = '${raw['last_update'] ?? ''}'.trim();
      discovered.add(
        TranslationInfo(
          id: key,
          code: 'QENC-${language.toUpperCase()}',
          languageCode: language,
          name: title,
          publisher: 'QuranEnc.com',
          source: 'QuranEnc.com',
          sourceKey: key,
          version: version.isEmpty ? 'latest' : version,
          bundled: false,
          available: true,
          downloadable: true,
          description: description.isEmpty ? null : description,
          lastUpdated: lastUpdated.isEmpty ? null : lastUpdated,
        ),
      );
    }
    registerDiscoveredTranslations(discovered);
    return discovered.length;
  }

  /// Downloads one translation. Parallel taps for the same source share the
  /// same future, preventing two writers from corrupting one .part file.
  Future<void> downloadTranslation(
    TranslationInfo info, {
    ValueChanged<double>? onProgress,
  }) {
    final active = _activeDownloads[info.id];
    if (active != null) return active;
    _cancelledDownloads.remove(info.id);
    final future = _downloadTranslationInternal(info, onProgress: onProgress);
    _activeDownloads[info.id] = future;
    return future.whenComplete(() {
      _activeDownloads.remove(info.id);
      _cancelledDownloads.remove(info.id);
    });
  }

  /// Stops network work for [sourceId] and discards only uncommitted temp data.
  /// An already-installed, validated offline pack is deliberately untouched.
  Future<void> cancelTranslationDownload(String sourceId) async {
    if (!_activeDownloads.containsKey(sourceId)) return;
    _cancelledDownloads.add(sourceId);
    _downloadClients.remove(sourceId)?.close(force: true);
    await _deleteStaleTemps(sourceId);
  }

  bool _isDownloadCancelled(String sourceId) =>
      _cancelledDownloads.contains(sourceId);

  void _throwIfDownloadCancelled(String sourceId) {
    if (_isDownloadCancelled(sourceId)) {
      throw const TranslationDownloadCancelledException();
    }
  }

  Future<void> _downloadTranslationInternal(
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
    await _deleteStaleTemps(info.id);
    _throwIfDownloadCancelled(info.id);
    if (info.provider == TranslationProvider.islamicNetwork) {
      await _downloadIslamicNetworkTranslation(info, onProgress: onProgress);
      return;
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 25)
      ..idleTimeout = const Duration(seconds: 30);
    _downloadClients[info.id] = client;
    try {
      onProgress?.call(.01);
      final catalogUri = Uri.https(
        _quranEncHost,
        '/api/v1/translations/list/${info.languageCode}/',
        const <String, String>{'localization': 'en'},
      );
      final catalogPayload = await _getJson(
        client,
        catalogUri,
        cancelled: () => _isDownloadCancelled(info.id),
      );
      _throwIfDownloadCancelled(info.id);
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

      final items = <Map<String, dynamic>>[];
      final seen = <String>{};
      // QuranEnc is a public service, not our personal load tester. Three
      // concurrent surahs is fast enough and avoids 429 cascades.
      const concurrency = 3;
      for (var start = 1; start <= 114; start += concurrency) {
        _throwIfDownloadCancelled(info.id);
        final end = math.min(start + concurrency - 1, 114);
        final chunks = await Future.wait([
          for (var surah = start; surah <= end; surah++)
            _fetchSurah(client, info, surah),
        ]);
        _throwIfDownloadCancelled(info.id);
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
              throw const FormatException(
                'QuranEnc returned an invalid verse.',
              );
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

      _throwIfDownloadCancelled(info.id);
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
      await _installValidatedPack(info, package);
      _throwIfDownloadCancelled(info.id);
      onProgress?.call(1);
    } finally {
      if (identical(_downloadClients[info.id], client)) {
        _downloadClients.remove(info.id);
      }
      client.close(force: true);
      if (_isDownloadCancelled(info.id)) {
        await _deleteStaleTemps(info.id);
      }
    }
  }

  Future<void> _downloadIslamicNetworkTranslation(
    TranslationInfo info, {
    ValueChanged<double>? onProgress,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 25)
      ..idleTimeout = const Duration(seconds: 30);
    _downloadClients[info.id] = client;
    try {
      onProgress?.call(.03);
      final payload = await _getJson(
        client,
        islamicNetworkTranslationPackageUri(info),
        cancelled: () => _isDownloadCancelled(info.id),
      );
      _throwIfDownloadCancelled(info.id);
      onProgress?.call(.82);
      if (payload is! Map || payload['data'] is! Map) {
        throw const FormatException(
          'Unexpected Islamic Network Quran response.',
        );
      }
      final data = Map<String, dynamic>.from(payload['data'] as Map);
      final surahs = data['surahs'];
      if (surahs is! List) {
        throw const FormatException('Islamic Network surah list is missing.');
      }

      final items = <Map<String, dynamic>>[];
      final seen = <String>{};
      for (final rawSurah in surahs) {
        _throwIfDownloadCancelled(info.id);
        if (rawSurah is! Map) continue;
        final surah = int.tryParse('${rawSurah['number']}');
        final ayahs = rawSurah['ayahs'];
        if (surah == null || surah < 1 || surah > 114 || ayahs is! List) {
          throw const FormatException(
            'Islamic Network returned an invalid surah.',
          );
        }
        for (final rawAyah in ayahs) {
          if (rawAyah is! Map) continue;
          final ayah = int.tryParse('${rawAyah['numberInSurah']}');
          final translation = rawAyah['text'];
          if (ayah == null ||
              ayah < 1 ||
              translation is! String ||
              translation.trim().isEmpty) {
            throw const FormatException(
              'Islamic Network returned an invalid verse.',
            );
          }
          final key = '$surah:$ayah';
          if (!seen.add(key)) {
            throw FormatException(
              'Islamic Network returned duplicate verse $key.',
            );
          }
          items.add(<String, dynamic>{
            'sura': surah,
            'aya': ayah,
            'translation': translation,
          });
        }
      }

      if (items.length < 6000) {
        throw FormatException(
          'Downloaded translation looks incomplete: ${items.length} verses.',
        );
      }
      _throwIfDownloadCancelled(info.id);
      onProgress?.call(.92);
      final edition = data['edition'];
      final package = <String, dynamic>{
        'schema_version': 1,
        'source': info.source,
        'source_key': info.sourceKey,
        'language_iso_code': info.languageCode,
        'version': info.version,
        'title': edition is Map ? edition['name'] ?? info.name : info.name,
        'description': info.publisher,
        'terms': const <String, dynamic>{
          'provider': 'Islamic Network / Al Quran Cloud',
          'attribution_required': true,
          'preserve_translation_identity': true,
        },
        'items': items,
      };
      await _installValidatedPack(info, package);
      _throwIfDownloadCancelled(info.id);
      onProgress?.call(1);
    } finally {
      if (identical(_downloadClients[info.id], client)) {
        _downloadClients.remove(info.id);
      }
      client.close(force: true);
      if (_isDownloadCancelled(info.id)) {
        await _deleteStaleTemps(info.id);
      }
    }
  }

  Future<void> _installValidatedPack(
    TranslationInfo info,
    Map<String, dynamic> package,
  ) async {
    _throwIfDownloadCancelled(info.id);
    final compressed = Uint8List.fromList(
      gzip.encode(utf8.encode(jsonEncode(package))),
    );
    _throwIfDownloadCancelled(info.id);
    decodeGzipPack(
      compressed,
      fallbackTranslationId: info.id,
      fallbackLanguageCode: info.languageCode,
      fallbackVersion: info.version,
      fallbackSource: info.source,
    );

    final file = await _downloadFile(info.id);
    final part = File('${file.path}.part');
    if (await part.exists()) await part.delete();
    try {
      _throwIfDownloadCancelled(info.id);
      await part.writeAsBytes(compressed, flush: true);
      _throwIfDownloadCancelled(info.id);
      // Verify bytes after filesystem write, not only the in-memory buffer.
      decodeGzipPack(
        await part.readAsBytes(),
        fallbackTranslationId: info.id,
        fallbackLanguageCode: info.languageCode,
        fallbackVersion: info.version,
        fallbackSource: info.source,
      );
      _throwIfDownloadCancelled(info.id);
      await _commitPartFile(file, part);
      _downloadedPackFutures.remove(info.id);
    } catch (_) {
      if (await part.exists()) await part.delete();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSurah(
    HttpClient client,
    TranslationInfo info,
    int surah,
  ) async {
    _throwIfDownloadCancelled(info.id);
    final uri = Uri.https(
      _quranEncHost,
      '/api/v1/translation/sura/${info.sourceKey}/$surah',
    );
    final payload = await _getJson(
      client,
      uri,
      cancelled: () => _isDownloadCancelled(info.id),
    );
    _throwIfDownloadCancelled(info.id);
    return _resultList(payload, context: 'sura $surah');
  }

  Future<dynamic> _getJson(
    HttpClient client,
    Uri uri, {
    bool Function()? cancelled,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 5; attempt++) {
      if (cancelled?.call() ?? false) {
        throw const TranslationDownloadCancelledException();
      }
      try {
        final request = await client.getUrl(uri);
        request.headers
          ..set(HttpHeaders.userAgentHeader, _userAgent)
          ..set(HttpHeaders.acceptHeader, 'application/json')
          ..set(HttpHeaders.acceptEncodingHeader, 'gzip');
        final response = await request.close();
        if (cancelled?.call() ?? false) {
          await response.drain<void>();
          throw const TranslationDownloadCancelledException();
        }
        final retryable = response.statusCode == HttpStatus.tooManyRequests ||
            response.statusCode >= 500;
        if (retryable && attempt < 4) {
          final retryAfter = int.tryParse(
            response.headers.value(HttpHeaders.retryAfterHeader) ?? '',
          );
          await response.drain<void>();
          await Future<void>.delayed(
            Duration(
              seconds: (retryAfter ?? math.min(2 << attempt, 12)).clamp(1, 15),
            ),
          );
          continue;
        }
        if (response.statusCode != HttpStatus.ok) {
          await response.drain<void>();
          throw HttpException(
            '${uri.host} returned HTTP ${response.statusCode}.',
            uri: uri,
          );
        }
        final bytes = await response.fold<List<int>>(
          <int>[],
          (buffer, data) => buffer..addAll(data),
        );
        if (cancelled?.call() ?? false) {
          throw const TranslationDownloadCancelledException();
        }
        return jsonDecode(utf8.decode(bytes));
      } on TranslationDownloadCancelledException {
        rethrow;
      } on SocketException catch (error) {
        if (cancelled?.call() ?? false) {
          throw const TranslationDownloadCancelledException();
        }
        lastError = error;
      } on HttpException catch (error) {
        if (cancelled?.call() ?? false) {
          throw const TranslationDownloadCancelledException();
        }
        lastError = error;
        if (!error.message.contains('HTTP 5') &&
            !error.message.contains('HTTP 429')) {
          rethrow;
        }
      } catch (_) {
        if (cancelled?.call() ?? false) {
          throw const TranslationDownloadCancelledException();
        }
        rethrow;
      }
      if (attempt < 4) {
        await Future<void>.delayed(
          Duration(seconds: math.min(2 << attempt, 12)),
        );
      }
    }
    throw HttpException(
      '${uri.host} temporarily failed after retries: ${lastError ?? 'unknown'}',
      uri: uri,
    );
  }

  List<Map<String, dynamic>> _resultList(
    dynamic payload, {
    required String context,
  }) {
    dynamic raw = payload;
    if (raw is Map) {
      for (final key in const [
        'result',
        'data',
        'translations',
        'items',
      ]) {
        final candidate = raw[key];
        if (candidate is List) {
          raw = candidate;
          break;
        }
        if (candidate is Map) {
          for (final nestedKey in const ['result', 'data', 'items']) {
            final nested = candidate[nestedKey];
            if (nested is List) {
              raw = nested;
              break;
            }
          }
          if (raw is List) break;
        }
      }
    }
    if (raw is! List) {
      throw FormatException('Unexpected QuranEnc response for $context.');
    }
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  Future<Directory> _translationDirectory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/translations');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> _downloadFile(String sourceId) async {
    final directory = await _translationDirectory();
    return File('${directory.path}/$sourceId.json.gz');
  }

  Future<File> _catalogCacheFile() async {
    final directory = await _translationDirectory();
    return File('${directory.path}/quranenc_catalog_v1.json');
  }

  Future<void> _deleteStaleTemps(String sourceId) async {
    final file = await _downloadFile(sourceId);
    for (final suffix in const <String>['.part', '.tmp']) {
      final temp = File('${file.path}$suffix');
      if (await temp.exists()) await temp.delete();
    }
  }

  Future<void> _recoverInterruptedWrites() async {
    final directory = await _translationDirectory();
    final entries = await directory.list(followLinks: false).toList();

    // Old builds used .tmp; current builds use .part. Neither is a committed
    // offline pack, so both are always safe to discard on a fresh launch.
    for (final entity in entries) {
      if (entity is! File) continue;
      if (entity.path.endsWith('.part') || entity.path.endsWith('.tmp')) {
        try {
          await entity.delete();
        } on FileSystemException {
          // Best-effort cleanup. A locked file can be retried next launch.
        }
      }
    }

    // If the process died between old -> .bak and .part -> committed, restore
    // the old committed file. If a committed target exists, the new write won
    // and the backup is now stale.
    final afterTempCleanup = await directory.list(followLinks: false).toList();
    for (final entity in afterTempCleanup) {
      if (entity is! File || !entity.path.endsWith('.bak')) continue;
      final target = File(
        entity.path.substring(0, entity.path.length - '.bak'.length),
      );
      try {
        if (await target.exists()) {
          await entity.delete();
        } else {
          await entity.rename(target.path);
        }
      } on FileSystemException {
        // Preserve the backup rather than risking data loss.
      }
    }
  }

  Future<void> _commitPartFile(File target, File part) async {
    final backup = File('${target.path}.bak');

    // Recover an earlier interrupted replacement before starting a new one.
    if (await backup.exists()) {
      if (await target.exists()) {
        await backup.delete();
      } else {
        await backup.rename(target.path);
      }
    }

    final hadCommittedFile = await target.exists();
    if (hadCommittedFile) {
      await target.rename(backup.path);
    }

    try {
      await part.rename(target.path);
    } catch (_) {
      // Never sacrifice the last known-good offline copy for a failed rename.
      if (!await target.exists() && await backup.exists()) {
        await backup.rename(target.path);
      }
      if (await part.exists()) await part.delete();
      rethrow;
    }

    // The new target is committed at this point. Backup cleanup is best effort:
    // failing to delete stale backup must not turn a successful install into a
    // fake download failure. Startup recovery will remove it on the next run.
    if (await backup.exists()) {
      try {
        await backup.delete();
      } on FileSystemException {
        // Keep it. _recoverInterruptedWrites() handles it safely next startup.
      }
    }
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
      throw FormatException(
        'Unsupported translation pack schema: $schemaVersion',
      );
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
      if (surah == null ||
          surah < 1 ||
          surah > 114 ||
          ayah == null ||
          ayah < 1) {
        throw FormatException(
          'Invalid verse identity: ${raw['sura']}:${raw['aya']}',
        );
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
      if (footnote is String && footnote.trim().isNotEmpty) {
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
      if (surah == null ||
          surah < 1 ||
          surah > 114 ||
          ayah == null ||
          ayah < 1) {
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
