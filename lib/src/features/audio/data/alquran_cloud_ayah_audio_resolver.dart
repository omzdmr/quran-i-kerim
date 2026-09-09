import 'dart:convert';
import 'dart:io';

import '../domain/quran_audio_source.dart';

/// Resolves the provider-owned audio URL for one ayah/edition.
///
/// Al Quran Cloud recommends asking the API for an ayah's audio URL instead of
/// guessing CDN bitrate paths. This keeps every catalog edition usable even
/// when reciters expose different bitrate sets. The returned URI is still
/// handed to the local audio cache before playback by the next layer.
class AlQuranCloudAyahAudioResolver {
  AlQuranCloudAyahAudioResolver({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  static Uri requestUri({
    required QuranAudioSource source,
    required int surah,
    required int ayah,
  }) {
    if (surah < 1 || surah > 114) {
      throw RangeError.range(surah, 1, 114, 'surah');
    }
    if (ayah < 1) {
      throw RangeError.range(ayah, 1, null, 'ayah');
    }
    return Uri.https(
      'api.alquran.cloud',
      '/v1/ayah/$surah:$ayah/${source.identifier}',
    );
  }

  Future<Uri> resolve({
    required QuranAudioSource source,
    required int surah,
    required int ayah,
  }) async {
    final uri = requestUri(source: source, surah: surah, ayah: ayah);
    final request = await _httpClient.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Ayah audio request failed with ${response.statusCode}',
        uri: uri,
      );
    }
    return parseAudioUri(body);
  }

  static Uri parseAudioUri(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Ayah audio response must be an object.');
    }
    final data = decoded['data'];
    if (data is! Map) {
      throw const FormatException('Ayah audio response has no data object.');
    }

    final candidates = <Object?>[
      data['audio'],
      ...?data['audioSecondary'] is List
          ? data['audioSecondary'] as List<dynamic>
          : null,
    ];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      final uri = Uri.tryParse(value);
      if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
        return uri;
      }
    }
    throw const FormatException('Ayah audio response has no HTTPS audio URL.');
  }

  void close() => _httpClient.close(force: true);
}
