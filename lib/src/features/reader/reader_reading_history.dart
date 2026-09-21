import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/surah_catalog.dart';

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
    if (surah is! num ||
        ayah is! num ||
        sourceId is! String ||
        updatedAt is! num) {
      return null;
    }
    final safeSurah = surah.toInt();
    final safeAyah = ayah.toInt();
    final normalizedSourceId = sourceId.trim();
    if (safeSurah < 1 ||
        safeSurah > surahCatalog.length ||
        safeAyah < 1 ||
        safeAyah > surahCatalog[safeSurah - 1].verseCount ||
        normalizedSourceId.isEmpty) {
      return null;
    }
    return ReaderHistoryEntry(
      surah: safeSurah,
      ayah: safeAyah,
      sourceId: normalizedSourceId,
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
      final entries = decoded
          .map(ReaderHistoryEntry.fromJson)
          .whereType<ReaderHistoryEntry>()
          .toList(growable: true)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return List<ReaderHistoryEntry>.unmodifiable(entries);
    } catch (_) {
      return const <ReaderHistoryEntry>[];
    }
  }

  Future<void> record({
    required int surah,
    required int ayah,
    required String sourceId,
  }) async {
    final safeSourceId = sourceId.trim();
    if (safeSourceId.isEmpty) return;
    final safeSurah = surah.clamp(1, surahCatalog.length).toInt();
    final safeAyah = ayah.clamp(1, surahCatalog[safeSurah - 1].verseCount).toInt();
    final items = (await load()).toList(growable: true);
    items.removeWhere(
      (entry) => entry.surah == safeSurah && entry.ayah == safeAyah,
    );
    items.insert(
      0,
      ReaderHistoryEntry(
        surah: safeSurah,
        ayah: safeAyah,
        sourceId: safeSourceId,
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

List<ReaderHistoryEntry> selectRecentReadingContexts(
  Iterable<ReaderHistoryEntry> entries, {
  required int currentSurah,
  required int currentAyah,
  required String currentSourceId,
  int limit = 3,
}) {
  if (limit <= 0) return const <ReaderHistoryEntry>[];

  final selected = <ReaderHistoryEntry>[];
  final seenContexts = <String>{'$currentSurah:$currentSourceId'};
  for (final entry in entries) {
    if (entry.surah == currentSurah && entry.ayah == currentAyah) continue;
    if (!seenContexts.add('${entry.surah}:${entry.sourceId}')) continue;
    selected.add(entry);
    if (selected.length == limit) break;
  }
  return List<ReaderHistoryEntry>.unmodifiable(selected);
}
