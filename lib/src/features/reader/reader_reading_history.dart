import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReaderHistoryEntry {
  const ReaderHistoryEntry({
    required this.surah,
    required this.ayah,
    required this.sourceId,
    required this.updatedAt,
  });

  final int surah;
  final int ayah;
  final String sourceId;
  final int updatedAt;

  Map<String, Object> toJson() => <String, Object>{
    'surah': surah,
    'ayah': ayah,
    'sourceId': sourceId,
    'updatedAt': updatedAt,
  };

  static ReaderHistoryEntry? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final surah = value['surah'];
    final ayah = value['ayah'];
    final sourceId = value['sourceId'];
    final updatedAt = value['updatedAt'];
    if (surah is! num || ayah is! num || sourceId is! String || updatedAt is! num) {
      return null;
    }
    if (surah < 1 || surah > 114 || ayah < 1) return null;
    return ReaderHistoryEntry(
      surah: surah.toInt(),
      ayah: ayah.toInt(),
      sourceId: sourceId,
      updatedAt: updatedAt.toInt(),
    );
  }
}

class ReaderReadingHistoryRepository {
  ReaderReadingHistoryRepository._();

  static final ReaderReadingHistoryRepository instance =
      ReaderReadingHistoryRepository._();

  static const String storageKey = 'reader_history_v1';
  static const int maxEntries = 50;
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<List<ReaderHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const <ReaderHistoryEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <ReaderHistoryEntry>[];
      return decoded
          .map(ReaderHistoryEntry.fromJson)
          .whereType<ReaderHistoryEntry>()
          .toList(growable: false);
    } catch (_) {
      return const <ReaderHistoryEntry>[];
    }
  }

  Future<void> record({
    required int surah,
    required int ayah,
    required String sourceId,
  }) async {
    final safeSurah = surah.clamp(1, 114).toInt();
    final safeAyah = ayah < 1 ? 1 : ayah;
    final items = (await load()).toList(growable: true);
    items.removeWhere(
      (entry) => entry.surah == safeSurah && entry.ayah == safeAyah,
    );
    items.insert(
      0,
      ReaderHistoryEntry(
        surah: safeSurah,
        ayah: safeAyah,
        sourceId: sourceId,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (items.length > maxEntries) {
      items.removeRange(maxEntries, items.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(items.map((entry) => entry.toJson()).toList(growable: false)),
    );
    changes.value++;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    changes.value++;
  }
}
