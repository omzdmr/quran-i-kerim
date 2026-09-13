import 'package:shared_preferences/shared_preferences.dart';

import 'memorization_plan_engine.dart';

class MemorizationPlanSnapshot {
  const MemorizationPlanSnapshot({
    required this.pace,
    required this.startedAt,
  });

  final MemorizationPlanPace? pace;
  final DateTime? startedAt;

  bool get hasPlan => pace != null && startedAt != null;
}

class MemorizationPlanStore {
  const MemorizationPlanStore();

  static const _paceKey = 'memorization_plan_pace_v1';
  static const _startedAtKey = 'memorization_plan_started_at_v1';

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

  Future<MemorizationPlanSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    return MemorizationPlanSnapshot(
      pace: _parsePace(prefs.getString(_paceKey)),
      startedAt: _parseDate(prefs.getString(_startedAtKey)),
    );
  }

  Future<MemorizationPlanSnapshot> save({
    required MemorizationPlanPace pace,
    required DateTime startedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedStart = _dateOnly(startedAt);

    await Future.wait([
      prefs.setString(_paceKey, pace.name),
      prefs.setString(_startedAtKey, normalizedStart.toIso8601String()),
    ]);

    return MemorizationPlanSnapshot(
      pace: pace,
      startedAt: normalizedStart,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_paceKey),
      prefs.remove(_startedAtKey),
    ]);
  }
}
