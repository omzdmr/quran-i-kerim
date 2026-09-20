import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;

import '../domain/prayer_city_catalog.dart';
import '../domain/prayer_models.dart';
import 'prayer_region_resolver.dart';

class PrayerOnlineLocationService {
  PrayerOnlineLocationService._();

  static final Map<String, List<PrayerCity>> _cache =
      <String, List<PrayerCity>>{};
  static DateTime? _lastRequestAt;

  static Future<List<PrayerCity>> search({
    required String query,
    required String languageCode,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const <PrayerCity>[];
    final cacheKey = '${languageCode.toLowerCase()}:${trimmed.toLowerCase()}';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final last = _lastRequestAt;
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      const minimumGap = Duration(milliseconds: 1100);
      if (elapsed < minimumGap) {
        await Future<void>.delayed(minimumGap - elapsed);
      }
    }
    _lastRequestAt = DateTime.now();

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '8',
      'q': trimmed,
    });
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 10)
      ..userAgent = 'Quran-i-Kerim/0.5 (manual city lookup; omzdmr)';

    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptLanguageHeader, languageCode);
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Nominatim ${response.statusCode}');
      }
      final body = await utf8.decoder.bind(response).join();
      final raw = jsonDecode(body) as List<dynamic>;
      final results = <PrayerCity>[];
      for (final item in raw) {
        final map = item as Map<String, dynamic>;
        final lat = double.tryParse('${map['lat'] ?? ''}');
        final lon = double.tryParse('${map['lon'] ?? ''}');
        if (lat == null || lon == null) continue;
        final displayName = '${map['display_name'] ?? ''}'.trim();
        if (displayName.isEmpty) continue;
        final address = map['address'] is Map<String, dynamic>
            ? map['address'] as Map<String, dynamic>
            : const <String, dynamic>{};
        final label = _firstNonEmpty([
          address['city'],
          address['town'],
          address['village'],
          address['municipality'],
          address['county'],
          displayName.split(',').first,
        ]);
        final country = '${address['country'] ?? ''}'.trim();
        final timeZone = tzmap.latLngToTimezoneString(lat, lon);
        if (timeZone.isEmpty) continue;
        final region = resolvePrayerRegion(lat, lon);
        results.add(
          PrayerCity(
            id: 'osm:${map['place_id'] ?? '${lat}_$lon'}',
            label: label,
            country: country,
            group: country.isEmpty ? 'Online' : country,
            location: PrayerLocation(
              latitude: lat,
              longitude: lon,
              timeZoneId: timeZone,
              label: label,
            ),
            defaultMethod: region.method,
          ),
        );
      }
      final frozen = List<PrayerCity>.unmodifiable(results);
      _cache[cacheKey] = frozen;
      return frozen;
    } finally {
      client.close(force: true);
    }
  }

  static String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = '${value ?? ''}'.trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
