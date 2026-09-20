import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_plan.dart';

class ReadingPlanSnapshot {
  const ReadingPlanSnapshot({
    this.active,
    this.savedPresetIds = const <String>{},
    this.completed = const <CompletedReadingPlan>[],
    this.yearlyKhatmTarget,
    this.redistributionTargetEndDate,
  });

  final ActiveReadingPlan? active;
  final Set<String> savedPresetIds;
  final List<CompletedReadingPlan> completed;

  /// Optional user-owned yearly khatm target. This is deliberately a private,
  /// local preference rather than a streak or social score.
  final int? yearlyKhatmTarget;

  int completedInYear(int year) =>
      completed.where((item) => item.completedAt.year == year).length;

  int remainingForYear(int year) {
    final target = yearlyKhatmTarget;
    if (target == null) return 0;
    final remaining = target - completedInYear(year);
    return remaining > 0 ? remaining : 0;
  }

  /// User-selected end date for missed-day redistribution.
  ///
  /// This is intentionally plan state, not derived schedule state: choosing a
  /// recovery window must survive process death/restore without silently
  /// marking any reading day complete.
  final DateTime? redistributionTargetEndDate;
}

class ReadingPlanStore {
  const ReadingPlanStore();

  static const preferenceKey = 'reading_plan_state_v1';

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void notifyExternalChange() {
    changes.value += 1;
  }

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
      yearlyKhatmTarget: current.yearlyKhatmTarget,
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
      yearlyKhatmTarget: current.yearlyKhatmTarget,
      redistributionTargetEndDate: current.redistributionTargetEndDate,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> setYearlyKhatmTarget(int? target) async {
    if (target != null && (target < 1 || target > 99)) {
      throw RangeError.range(target, 1, 99, 'target');
    }
    final current = await load();
    if (current.yearlyKhatmTarget == target) return current;
    final next = ReadingPlanSnapshot(
      active: current.active,
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      yearlyKhatmTarget: target,
      redistributionTargetEndDate: current.redistributionTargetEndDate,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> pauseActive({DateTime? now}) async {
    final current = await load();
    final active = current.active;
    if (active == null || active.isPaused) return current;
    final next = ReadingPlanSnapshot(
      active: active.pause(now ?? DateTime.now()),
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      yearlyKhatmTarget: current.yearlyKhatmTarget,
      redistributionTargetEndDate: current.redistributionTargetEndDate,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> resumeActive({DateTime? now}) async {
    final current = await load();
    final active = current.active;
    if (active == null || !active.isPaused) return current;
    final next = ReadingPlanSnapshot(
      active: active.resume(now ?? DateTime.now()),
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      yearlyKhatmTarget: current.yearlyKhatmTarget,
      redistributionTargetEndDate: current.redistributionTargetEndDate,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> setRedistributionTargetEndDate(
    DateTime targetEndDate, {
    DateTime? now,
  }) async {
    final current = await load();
    final active = current.active;
    if (active == null) return current;
    final today = readingPlanDateOnly(now ?? DateTime.now());
    final target = readingPlanDateOnly(targetEndDate);
    if (target.isBefore(today)) {
      throw ArgumentError.value(targetEndDate, 'targetEndDate', 'Must not be before today.');
    }
    final next = ReadingPlanSnapshot(
      active: active,
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      yearlyKhatmTarget: current.yearlyKhatmTarget,
      redistributionTargetEndDate: target,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> clearRedistributionTargetEndDate() async {
    final current = await load();
    if (current.redistributionTargetEndDate == null) return current;
    final next = ReadingPlanSnapshot(
      active: current.active,
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      yearlyKhatmTarget: current.yearlyKhatmTarget,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> completeNextDay({DateTime? now}) async {
    final current = await load();
    final active = current.active;
    if (active == null || active.isPaused) return current;
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
        yearlyKhatmTarget: current.yearlyKhatmTarget,
      );
      await _save(next);
      return next;
    }

    final next = ReadingPlanSnapshot(
      active: active.copyWith(completedDays: completedDays),
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      yearlyKhatmTarget: current.yearlyKhatmTarget,
      redistributionTargetEndDate: current.redistributionTargetEndDate,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> completeThroughDay(
    int dayNumber, {
    DateTime? now,
  }) async {
    final current = await load();
    final active = current.active;
    if (active == null || active.isPaused) return current;

    final firstUnfinished = active.nextDayNumber;
    if (firstUnfinished == null) return current;
    if (dayNumber < firstUnfinished || dayNumber > active.preset.durationDays) {
      throw RangeError.range(
        dayNumber,
        firstUnfinished,
        active.preset.durationDays,
        'dayNumber',
      );
    }

    final completedDays = active.completedDays.toSet();
    for (var day = firstUnfinished; day <= dayNumber; day++) {
      completedDays.add(day);
    }

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
        yearlyKhatmTarget: current.yearlyKhatmTarget,
      );
      await _save(next);
      return next;
    }

    final next = ReadingPlanSnapshot(
      active: active.copyWith(completedDays: completedDays),
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      yearlyKhatmTarget: current.yearlyKhatmTarget,
      redistributionTargetEndDate: current.redistributionTargetEndDate,
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
      yearlyKhatmTarget: current.yearlyKhatmTarget,
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
        final normalizedStart = readingPlanDateOnly(startedAt);
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
        final rawPausedDays = rawActive['pausedDays'];
        final parsedPausedDays = rawPausedDays is int
            ? rawPausedDays
            : int.tryParse('${rawPausedDays ?? ''}');
        final pausedDays = parsedPausedDays != null && parsedPausedDays >= 0
            ? parsedPausedDays
            : 0;
        DateTime? pausedAt;
        final rawPausedAt = rawActive['pausedAt'];
        if (rawPausedAt != null) {
          final parsed = DateTime.tryParse(rawPausedAt.toString());
          if (parsed != null) {
            final normalized = readingPlanDateOnly(parsed);
            if (!normalized.isBefore(normalizedStart)) pausedAt = normalized;
          }
        }
        active = ActiveReadingPlan(
          preset: preset,
          startedAt: normalizedStart,
          completedDays: completedDays,
          pausedAt: pausedAt,
          pausedDays: pausedDays,
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

    DateTime? redistributionTargetEndDate;
    if (active != null) {
      final parsed = DateTime.tryParse(json['redistributionTargetEndDate']?.toString() ?? '');
      if (parsed != null) redistributionTargetEndDate = readingPlanDateOnly(parsed);
    }

    final rawYearlyKhatmTarget = json['yearlyKhatmTarget'];
    final parsedYearlyKhatmTarget = rawYearlyKhatmTarget is int
        ? rawYearlyKhatmTarget
        : int.tryParse('${rawYearlyKhatmTarget ?? ''}');
    final yearlyKhatmTarget = parsedYearlyKhatmTarget != null &&
            parsedYearlyKhatmTarget >= 1 &&
            parsedYearlyKhatmTarget <= 99
        ? parsedYearlyKhatmTarget
        : null;

    return ReadingPlanSnapshot(
      active: active,
      savedPresetIds: saved,
      completed: completed.take(20).toList(growable: false),
      yearlyKhatmTarget: yearlyKhatmTarget,
      redistributionTargetEndDate: redistributionTargetEndDate,
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
              'pausedAt': active.pausedAt == null ? null : _date(active.pausedAt!),
              'pausedDays': active.pausedDays,
            },
      'yearlyKhatmTarget': snapshot.yearlyKhatmTarget,
      'redistributionTargetEndDate': snapshot.redistributionTargetEndDate == null
          ? null
          : _date(snapshot.redistributionTargetEndDate!),
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
    notifyExternalChange();
  }

  String _date(DateTime value) {
    final date = readingPlanDateOnly(value);
    final month = '${date.month}'.padLeft(2, '0');
    final day = '${date.day}'.padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
