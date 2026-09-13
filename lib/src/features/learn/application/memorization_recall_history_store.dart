import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum MemorizationRecallAssessment {
  independent,
  assisted,
  struggled,
}

class MemorizationRecallStat {
  const MemorizationRecallStat({
    required this.difficulty,
    required this.attempts,
    this.lastAttemptAt,
  });

  final int difficulty;
  final int attempts;
  final DateTime? lastAttemptAt;

  bool get isWeak => difficulty > 0;
}

class MemorizationRecallHistorySnapshot {
  const MemorizationRecallHistorySnapshot(this.stats);

  final Map<String, MemorizationRecallStat> stats;

  Set<String> get weakQuestionIds => stats.entries
      .where((entry) => entry.value.isWeak)
      .map((entry) => entry.key)
      .toSet();

  List<MapEntry<String, MemorizationRecallStat>> get weakStatsByPriority {
    final entries = stats.entries
        .where((entry) => entry.value.isWeak)
        .toList(growable: false)
      ..sort((a, b) {
        final difficulty = b.value.difficulty.compareTo(a.value.difficulty);
        if (difficulty != 0) return difficulty;

        final aDate = a.value.lastAttemptAt;
        final bDate = b.value.lastAttemptAt;
        if (aDate == null && bDate != null) return -1;
        if (aDate != null && bDate == null) return 1;
        if (aDate != null && bDate != null) {
          final oldestFirst = aDate.compareTo(bDate);
          if (oldestFirst != 0) return oldestFirst;
        }
        return a.key.compareTo(b.key);
      });
    return List<MapEntry<String, MemorizationRecallStat>>.unmodifiable(entries);
  }

  MemorizationRecallStat? statFor(String questionId) => stats[questionId];
}

class MemorizationRecallHistoryStore {
  const MemorizationRecallHistoryStore();

  static const _key = 'memorization_recall_history_v1';

  DateTime? _parseDateTime(Object? raw) {
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  Map<String, MemorizationRecallStat> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return <String, MemorizationRecallStat>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <String, MemorizationRecallStat>{};
      }

      final result = <String, MemorizationRecallStat>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (entry.key.isEmpty || value is! Map) continue;
        final difficulty = value['difficulty'];
        final attempts = value['attempts'];
        if (difficulty is! int || attempts is! int) continue;
        result[entry.key] = MemorizationRecallStat(
          difficulty: difficulty.clamp(0, 9),
          attempts: attempts < 0 ? 0 : attempts,
          lastAttemptAt: _parseDateTime(value['lastAttemptAt']),
        );
      }
      return result;
    } on FormatException {
      return <String, MemorizationRecallStat>{};
    }
  }

  String _encode(Map<String, MemorizationRecallStat> stats) {
    final keys = stats.keys.toList()..sort();
    final encoded = <String, Object?>{};
    for (final key in keys) {
      final stat = stats[key]!;
      encoded[key] = <String, Object?>{
        'difficulty': stat.difficulty,
        'attempts': stat.attempts,
        'lastAttemptAt': stat.lastAttemptAt?.toIso8601String(),
      };
    }
    return jsonEncode(encoded);
  }

  Future<MemorizationRecallHistorySnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = _decode(prefs.getString(_key));
    return MemorizationRecallHistorySnapshot(
      Map<String, MemorizationRecallStat>.unmodifiable(stats),
    );
  }

  Future<MemorizationRecallHistorySnapshot> recordResult(
    String questionId, {
    required bool known,
    DateTime? now,
  }) {
    return recordAssessment(
      questionId,
      assessment: known
          ? MemorizationRecallAssessment.independent
          : MemorizationRecallAssessment.struggled,
      now: now,
    );
  }

  Future<MemorizationRecallHistorySnapshot> recordAssessment(
    String questionId, {
    required MemorizationRecallAssessment assessment,
    DateTime? now,
  }) async {
    if (questionId.trim().isEmpty) return load();

    final current = await load();
    final stats = <String, MemorizationRecallStat>{...current.stats};
    final existing = stats[questionId] ??
        const MemorizationRecallStat(difficulty: 0, attempts: 0);
    final delta = switch (assessment) {
      MemorizationRecallAssessment.independent => -1,
      MemorizationRecallAssessment.assisted => 1,
      MemorizationRecallAssessment.struggled => 2,
    };
    final nextDifficulty = (existing.difficulty + delta).clamp(0, 9);
    stats[questionId] = MemorizationRecallStat(
      difficulty: nextDifficulty,
      attempts: existing.attempts + 1,
      lastAttemptAt: now ?? DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _encode(stats));
    return MemorizationRecallHistorySnapshot(
      Map<String, MemorizationRecallStat>.unmodifiable(stats),
    );
  }
}
