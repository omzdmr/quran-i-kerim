import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/quran_audio_source.dart';

/// Key-less, mobile-safe catalog backed by Al Quran Cloud / Islamic Network.
///
/// The upstream publishes audio editions through a public REST endpoint and
/// explicitly permits streaming/downloading under its published terms. We keep
/// a local copy of the edition manifest so app startup and browsing do not
/// depend on the network after the first successful refresh.
class AlQuranCloudAudioCatalogRepository {
  AlQuranCloudAudioCatalogRepository({
    HttpClient? httpClient,
    this.maxCacheAge = const Duration(days: 7),
  }) : _httpClient = httpClient ?? HttpClient();

  static final Uri catalogUri =
      Uri.parse('https://api.alquran.cloud/v1/edition/format/audio');
  static final Uri providerUri = Uri.parse('https://alquran.cloud/');
  static final Uri termsUri =
      Uri.parse('https://alquran.cloud/terms-and-conditions');

  static const String providerName = 'Al Quran Cloud / Islamic Network';
  static const String _cacheBodyKey = 'audio.catalog.alquran_cloud.body.v1';
  static const String _cacheTimeKey = 'audio.catalog.alquran_cloud.time.v1';

  final HttpClient _httpClient;
  final Duration maxCacheAge;

  Future<QuranAudioCatalog> load({bool forceRefresh = false}) async {
    final preferences = await SharedPreferences.getInstance();
    final cachedBody = preferences.getString(_cacheBodyKey);
    final cachedTimeMs = preferences.getInt(_cacheTimeKey);
    final cachedTime = cachedTimeMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(cachedTimeMs, isUtc: true);
    final cacheFresh = cachedBody != null &&
        cachedTime != null &&
        DateTime.now().toUtc().difference(cachedTime) <= maxCacheAge;

    if (!forceRefresh && cacheFresh) {
      return parseCatalog(cachedBody);
    }

    try {
      final request = await _httpClient.getUrl(catalogUri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Audio catalog request failed with ${response.statusCode}',
          uri: catalogUri,
        );
      }
      final parsed = parseCatalog(body);
      await preferences.setString(_cacheBodyKey, body);
      await preferences.setInt(
        _cacheTimeKey,
        DateTime.now().toUtc().millisecondsSinceEpoch,
      );
      return parsed;
    } catch (_) {
      if (cachedBody != null) {
        return parseCatalog(cachedBody);
      }
      rethrow;
    }
  }

  void close() => _httpClient.close(force: true);

  static QuranAudioCatalog parseCatalog(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Audio catalog root must be an object.');
    }
    final data = decoded['data'];
    if (data is! List) {
      throw const FormatException('Audio catalog data must be a list.');
    }

    final sources = <QuranAudioSource>[];
    for (final raw in data) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final format = _string(item['format']).toLowerCase();
      if (format != 'audio') continue;

      final identifier = _string(item['identifier']);
      final language = _string(item['language']);
      final name = _string(item['name']);
      final englishName = _string(item['englishName']);
      final type = _string(item['type']).toLowerCase();

      if (identifier.isEmpty || language.isEmpty) continue;
      if (_looksSynthetic(identifier, name, englishName, type)) continue;

      sources.add(
        QuranAudioSource(
          identifier: identifier,
          languageCode: language,
          name: name,
          englishName: englishName,
          kind: type.contains('translation')
              ? QuranAudioKind.translation
              : QuranAudioKind.quran,
          providerName: providerName,
          providerUri: providerUri,
          termsUri: termsUri,
        ),
      );
    }

    sources.sort((a, b) {
      final language = a.languageCode.compareTo(b.languageCode);
      if (language != 0) return language;
      final kind = a.kind.index.compareTo(b.kind.index);
      if (kind != 0) return kind;
      return a.displayName.compareTo(b.displayName);
    });
    return QuranAudioCatalog(List<QuranAudioSource>.unmodifiable(sources));
  }

  static bool _looksSynthetic(
    String identifier,
    String name,
    String englishName,
    String type,
  ) {
    final haystack = '$identifier $name $englishName $type'.toLowerCase();
    return haystack.contains('tts') ||
        haystack.contains('text-to-speech') ||
        haystack.contains('text to speech') ||
        haystack.contains('synthetic');
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';
}
