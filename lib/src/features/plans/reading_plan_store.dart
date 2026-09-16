import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'reading_plan.dart';

class ReadingPlanSnapshot {
  const ReadingPlanSnapshot({
    this.active,
    this.savedPresetIds = const <String>{},
    this.completed = const <CompletedReadingPlan>[],
  });

  final ActiveReadingPlan? active;
  final Set<String> savedPresetIds;
  final List<CompletedReadingPlan> completed;
}

class ReadingPlanStore {
  const ReadingPlanStore();

  static const preferenceKey = 'reading_plan_state_v1';

  Future<ReadingPlanSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(preferenceKey);
    if (raw == null || raw.trim().isEmpty) return const ReadingPlanSnapshot();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const ReadingPlanSnapshot();
      return _decodeSnapshot(decoded);
    } catch (_) {
      return const ReadingPlanSnapshot();
    }
  }

  Future<ReadingPlanSnapshot> start(
    ReadingPlanPreset preset, {
    DateTime? now,
  }) async {
    final current = await load();
    final next = ReadingPlanSnapshot(
      active: ActiveReadingPlan(
        preset: preset,
        startedAt: readingPlanDateOnly(now ?? DateTime.now()),
      ),
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> toggleSaved(ReadingPlanPreset preset) async {
    final current = await load();
    final saved = current.savedPresetIds.toSet();
    if (!saved.add(preset.id)) saved.remove(preset.id);
    final next = ReadingPlanSnapshot(
      active: current.active,
      savedPresetIds: saved,
      completed: current.completed,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> completeNextDay({DateTime? now}) async {
    final current = await load();
    final active = current.active;
    if (active == null) return current;
    final day = active.nextDayNumber;
    if (day == null) return current;

    final completedDays = active.completedDays.toSet()..add(day);
    if (completedDays.length >= active.preset.durationDays) {
      final history = <CompletedReadingPlan>[
        CompletedReadingPlan(
          preset: active.preset,
          startedAt: active.startedAt,
          completedAt: readingPlanDateOnly(now ?? DateTime.now()),
        ),
        ...current.completed,
      ];
      final next = ReadingPlanSnapshot(
        savedPresetIds: current.savedPresetIds,
        completed: history.take(20).toList(growable: false),
      );
      await _save(next);
      return next;
    }

    final next = ReadingPlanSnapshot(
      active: active.copyWith(completedDays: completedDays),
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> stopActive() async {
    final current = await load();
    if (current.active == null) return current;
    final next = ReadingPlanSnapshot(
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
    );
    await _save(next);
    return next;
  }

  ReadingPlanSnapshot _decodeSnapshot(Map<String, dynamic> json) {
    ActiveReadingPlan? active;
    final rawActive = json['active'];
    if (rawActive is Map) {
      final preset = ReadingPlanPreset.fromId(rawActive['preset']?.toString());
      final startedAt = DateTime.tryParse(rawActive['startedAt']?.toString() ?? '');
      if (preset != null && startedAt != null) {
        final completedDays = <int>{};
        final rawDays = rawActive['completedDays'];
        if (rawDays is List) {
          for (final item in rawDays) {
            final day = item is int ? item : int.tryParse('$item');
            if (day != null && day >= 1 && day <= preset.durationDays) {
              completedDays.add(day);
            }
          }
        }
        active = ActiveReadingPlan(
          preset: preset,
          startedAt: readingPlanDateOnly(startedAt),
          completedDays: completedDays,
        );
      }
    }

    final saved = <String>{};
    final rawSaved = json['saved'];
    if (rawSaved is List) {
      for (final item in rawSaved) {
        final preset = ReadingPlanPreset.fromId(item?.toString());
        if (preset != null) saved.add(preset.id);
      }
    }

    final completed = <CompletedReadingPlan>[];
    final rawCompleted = json['completed'];
    if (rawCompleted is List) {
      for (final item in rawCompleted) {
        if (item is! Map) continue;
        final preset = ReadingPlanPreset.fromId(item['preset']?.toString());
        final startedAt = DateTime.tryParse(item['startedAt']?.toString() ?? '');
        final completedAt = DateTime.tryParse(item['completedAt']?.toString() ?? '');
        if (preset == null || startedAt == null || completedAt == null) continue;
        completed.add(
          CompletedReadingPlan(
            preset: preset,
            startedAt: readingPlanDateOnly(startedAt),
            completedAt: readingPlanDateOnly(completedAt),
          ),
        );
      }
    }

    return ReadingPlanSnapshot(
      active: active,
      savedPresetIds: saved,
      completed: completed.take(20).toList(growable: false),
    );
  }

  Future<void> _save(ReadingPlanSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final active = snapshot.active;
    final json = <String, Object?>{
      'active': active == null
          ? null
          : <String, Object?>{
              'preset': active.preset.id,
              'startedAt': _date(active.startedAt),
              'completedDays': active.completedDays.toList()..sort(),
            },
      'saved': snapshot.savedPresetIds.toList()..sort(),
      'completed': <Object?>[
        for (final item in snapshot.completed)
          <String, Object?>{
            'preset': item.preset.id,
            'startedAt': _date(item.startedAt),
            'completedAt': _date(item.completedAt),
          },
      ],
    };
    await prefs.setString(preferenceKey, jsonEncode(json));
  }

  String _date(DateTime value) {
    final date = readingPlanDateOnly(value);
    final month = '${date.month}'.padLeft(2, '0');
    final day = '${date.day}'.padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
