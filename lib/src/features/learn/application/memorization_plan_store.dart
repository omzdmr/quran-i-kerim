import 'package:shared_preferences/shared_preferences.dart';

import 'memorization_plan_engine.dart';

class MemorizationPlanSnapshot {
  const MemorizationPlanSnapshot({
    required this.pace,
    required this.startedAt,
    this.missedPlanDays = const <int>[],
  });

  final MemorizationPlanPace? pace;
  final DateTime? startedAt;
  final List<int> missedPlanDays;

  bool get hasPlan => pace != null && startedAt != null;
}

class MemorizationPlanStore {
  const MemorizationPlanStore();

  static const _paceKey = 'memorization_plan_pace_v1';
  static const _startedAtKey = 'memorization_plan_started_at_v1';
  static const _missedPlanDaysKey = 'memorization_plan_missed_days_v1';

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  MemorizationPlanPace? _parsePace(String? raw) {
    if (raw == null) return null;
    for (final pace in MemorizationPlanPace.values) {
      if (pace.name == raw) return pace;
    }
    return null;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? null : _dateOnly(parsed);
  }

  List<int> _parseMissedPlanDays(List<String>? raw) {
    if (raw == null) return const <int>[];
    final days = <int>{};
    for (final value in raw) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed >= 0) {
        days.add(parsed);
      }
    }
    final sorted = days.toList()..sort();
    return List<int>.unmodifiable(sorted);
  }

  List<int> _normalizeMissedPlanDays(Iterable<int> values) {
    final days = <int>{};
    for (final value in values) {
      if (value < 0) {
        throw ArgumentError.value(value, 'missedPlanDays', 'must be >= 0');
      }
      days.add(value);
    }
    return days.toList()..sort();
  }

  Future<MemorizationPlanSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    return MemorizationPlanSnapshot(
      pace: _parsePace(prefs.getString(_paceKey)),
      startedAt: _parseDate(prefs.getString(_startedAtKey)),
      missedPlanDays: _parseMissedPlanDays(
        prefs.getStringList(_missedPlanDaysKey),
      ),
    );
  }

  Future<MemorizationPlanSnapshot> save({
    required MemorizationPlanPace pace,
    required DateTime startedAt,
    Iterable<int> missedPlanDays = const <int>[],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedStart = _dateOnly(startedAt);
    final normalizedMissedDays = _normalizeMissedPlanDays(missedPlanDays);

    await Future.wait([
      prefs.setString(_paceKey, pace.name),
      prefs.setString(_startedAtKey, normalizedStart.toIso8601String()),
      prefs.setStringList(
        _missedPlanDaysKey,
        normalizedMissedDays.map((day) => '$day').toList(),
      ),
    ]);

    return MemorizationPlanSnapshot(
      pace: pace,
      startedAt: normalizedStart,
      missedPlanDays: List<int>.unmodifiable(normalizedMissedDays),
    );
  }

  Future<List<int>> saveMissedPlanDays(Iterable<int> planDayIndices) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeMissedPlanDays(planDayIndices);
    await prefs.setStringList(
      _missedPlanDaysKey,
      normalized.map((day) => '$day').toList(),
    );
    return List<int>.unmodifiable(normalized);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_paceKey),
      prefs.remove(_startedAtKey),
      prefs.remove(_missedPlanDaysKey),
    ]);
  }
}
