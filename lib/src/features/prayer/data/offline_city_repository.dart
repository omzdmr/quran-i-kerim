import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../application/prayer_region_resolver.dart';
import '../domain/prayer_city_catalog.dart';
import '../domain/prayer_models.dart';

class OfflinePrayerCityRepository {
  OfflinePrayerCityRepository._();

  static final OfflinePrayerCityRepository instance =
      OfflinePrayerCityRepository._();

  static const _assetPath = 'assets/data/locations/cities5000.json.gz';
  Future<List<_OfflineCityEntry>>? _loadFuture;

  Future<List<PrayerCity>> search(String rawQuery, {int limit = 60}) async {
    final query = _normalize(rawQuery);
    if (query.length < 2) return const <PrayerCity>[];
    final entries = await (_loadFuture ??= _load());
    final results = <PrayerCity>[];
    for (final entry in entries) {
      if (!entry.searchText.contains(query)) continue;
      final region = resolvePrayerRegion(entry.latitude, entry.longitude);
      results.add(
        PrayerCity(
          id: 'geo:${entry.id}',
          label: entry.name,
          country: entry.country,
          group: entry.country,
          location: PrayerLocation(
            latitude: entry.latitude,
            longitude: entry.longitude,
            timeZoneId: entry.timeZone,
            label: entry.name,
          ),
          defaultMethod: region.method,
        ),
      );
      if (results.length >= limit) break;
    }
    return results;
  }

  Future<List<_OfflineCityEntry>> _load() async {
    final data = await rootBundle.load(_assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final rows = await compute(_decodeCityRows, bytes);
    return [
      for (final row in rows)
        _OfflineCityEntry(
          id: (row[0] as num).toInt(),
          name: row[1] as String,
          country: row[2] as String,
          latitude: (row[3] as num).toDouble(),
          longitude: (row[4] as num).toDouble(),
          timeZone: row[5] as String,
          searchText: row[6] as String,
        ),
    ];
  }

  String _normalize(String value) => value
      .trim()
      .replaceAll('İ', 'i')
      .replaceAll('I', 'i')
      .replaceAll('ı', 'i')
      .replaceAll('Ə', 'e')
      .replaceAll('ə', 'e')
      .toLowerCase();
}

List<List<Object?>> _decodeCityRows(Uint8List compressed) {
  final decodedBytes = gzip.decode(compressed);
  final raw = jsonDecode(utf8.decode(decodedBytes)) as List<dynamic>;
  return [
    for (final row in raw) (row as List<dynamic>).cast<Object?>(),
  ];
}

class _OfflineCityEntry {
  const _OfflineCityEntry({
    required this.id,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
    required this.searchText,
  });

  final int id;
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final String timeZone;
  final String searchText;
}
