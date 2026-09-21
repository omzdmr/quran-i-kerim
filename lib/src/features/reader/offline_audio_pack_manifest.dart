import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum OfflineAudioPackReadiness {
  notInstalled,
  incomplete,
  ready,
  needsRepair,
}

class OfflineAudioPackManifest {
  const OfflineAudioPackManifest({
    required this.storageKey,
    required this.surah,
    required this.verseCount,
    required this.ayahBytes,
    required this.ayahSha256,
    required this.completedAt,
  });

  static const int formatVersion = 1;

  final String storageKey;
  final int surah;
  final int verseCount;
  final Map<int, int> ayahBytes;
  final Map<int, String> ayahSha256;
  final DateTime completedAt;

  int get totalBytes => ayahBytes.values.fold(0, (sum, value) => sum + value);

  bool matches({
    required String expectedStorageKey,
    required int expectedSurah,
    required int expectedVerseCount,
    required Map<int, int> actualAyahBytes,
    required Map<int, String> actualAyahSha256,
    required bool hasPartialFiles,
  }) {
    if (hasPartialFiles ||
        storageKey != expectedStorageKey ||
        surah != expectedSurah ||
        verseCount != expectedVerseCount ||
        ayahBytes.length != expectedVerseCount ||
        ayahSha256.length != expectedVerseCount ||
        actualAyahBytes.length != expectedVerseCount ||
        actualAyahSha256.length != expectedVerseCount) {
      return false;
    }
    for (var ayah = 1; ayah <= expectedVerseCount; ayah++) {
      final expectedBytes = ayahBytes[ayah];
      if (expectedBytes == null ||
          expectedBytes <= 0 ||
          actualAyahBytes[ayah] != expectedBytes ||
          actualAyahSha256[ayah] != ayahSha256[ayah]) {
        return false;
      }
    }
    return true;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'formatVersion': formatVersion,
    'storageKey': storageKey,
    'surah': surah,
    'verseCount': verseCount,
    'completedAt': completedAt.toUtc().toIso8601String(),
    'ayahBytes': <String, int>{
      for (final entry in ayahBytes.entries) '${entry.key}': entry.value,
    },
    'ayahSha256': <String, String>{
      for (final entry in ayahSha256.entries) '${entry.key}': entry.value,
    },
  };

  String encode() => jsonEncode(toJson());

  static OfflineAudioPackManifest? decode(String source) {
    try {
      final value = jsonDecode(source);
      if (value is! Map<String, dynamic> ||
          value['formatVersion'] != formatVersion ||
          value['storageKey'] is! String ||
          value['surah'] is! int ||
          value['verseCount'] is! int ||
          value['ayahBytes'] is! Map ||
          value['ayahSha256'] is! Map ||
          value['completedAt'] is! String) {
        return null;
      }
      final storageKey = value['storageKey'] as String;
      final surah = value['surah'] as int;
      final verseCount = value['verseCount'] as int;
      if (storageKey.isEmpty ||
          surah < 1 ||
          surah > 114 ||
          verseCount <= 0) {
        return null;
      }
      final rawBytes = value['ayahBytes'] as Map;
      final bytes = <int, int>{};
      for (final entry in rawBytes.entries) {
        final ayah = int.tryParse('${entry.key}');
        final size = entry.value;
        if (ayah == null || size is! int || size <= 0) return null;
        bytes[ayah] = size;
      }
      final rawHashes = value['ayahSha256'] as Map;
      final hashes = <int, String>{};
      for (final entry in rawHashes.entries) {
        final ayah = int.tryParse('${entry.key}');
        final hash = entry.value;
        if (ayah == null ||
            hash is! String ||
            !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
          return null;
        }
        hashes[ayah] = hash;
      }
      final completedAt = DateTime.tryParse(value['completedAt'] as String);
      if (completedAt == null) return null;
      return OfflineAudioPackManifest(
        storageKey: storageKey,
        surah: surah,
        verseCount: verseCount,
        ayahBytes: Map<int, int>.unmodifiable(bytes),
        ayahSha256: Map<int, String>.unmodifiable(hashes),
        completedAt: completedAt,
      );
    } catch (_) {
      return null;
    }
  }
}

class OfflineAudioPackIntent {
  const OfflineAudioPackIntent({
    required this.storageKey,
    required this.surah,
    required this.verseCount,
  });

  final String storageKey;
  final int surah;
  final int verseCount;

  String get id => '$storageKey|$surah';

  String encode() => jsonEncode(<String, Object?>{
    'storageKey': storageKey,
    'surah': surah,
    'verseCount': verseCount,
  });

  static OfflineAudioPackIntent? decode(String source) {
    try {
      final value = jsonDecode(source);
      if (value is! Map<String, dynamic> ||
          value['storageKey'] is! String ||
          value['surah'] is! int ||
          value['verseCount'] is! int) {
        return null;
      }
      final storageKey = value['storageKey'] as String;
      final surah = value['surah'] as int;
      final verseCount = value['verseCount'] as int;
      if (storageKey.isEmpty ||
          surah < 1 ||
          surah > 114 ||
          verseCount <= 0) {
        return null;
      }
      return OfflineAudioPackIntent(
        storageKey: storageKey,
        surah: surah,
        verseCount: verseCount,
      );
    } catch (_) {
      return null;
    }
  }
}

class OfflineAudioPackIntentStore {
  const OfflineAudioPackIntentStore();

  static const String preferenceKey = 'offline_audio_pack_intents_v1';

  Future<List<OfflineAudioPackIntent>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final byId = <String, OfflineAudioPackIntent>{};
    for (final encoded
        in prefs.getStringList(preferenceKey) ?? const <String>[]) {
      final intent = OfflineAudioPackIntent.decode(encoded);
      if (intent != null) byId[intent.id] = intent;
    }
    final values = byId.values.toList()
      ..sort((a, b) {
        final source = a.storageKey.compareTo(b.storageKey);
        return source != 0 ? source : a.surah.compareTo(b.surah);
      });
    return List<OfflineAudioPackIntent>.unmodifiable(values);
  }

  Future<void> upsert(OfflineAudioPackIntent intent) async {
    final prefs = await SharedPreferences.getInstance();
    final values = <String, OfflineAudioPackIntent>{
      for (final existing in await load()) existing.id: existing,
      intent.id: intent,
    };
    await prefs.setStringList(
      preferenceKey,
      values.values.map((value) => value.encode()).toList(growable: false),
    );
  }

  Future<void> remove(String storageKey, int surah) async {
    final prefs = await SharedPreferences.getInstance();
    final id = '$storageKey|$surah';
    final values = (await load()).where((value) => value.id != id).toList();
    await prefs.setStringList(
      preferenceKey,
      values.map((value) => value.encode()).toList(growable: false),
    );
  }

  Future<void> removeSource(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final values = (await load())
        .where((value) => value.storageKey != storageKey)
        .toList();
    await prefs.setStringList(
      preferenceKey,
      values.map((value) => value.encode()).toList(growable: false),
    );
  }
}
