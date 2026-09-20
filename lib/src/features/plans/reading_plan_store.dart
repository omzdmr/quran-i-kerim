import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/quran_partition_metadata.dart';
import 'reading_plan.dart';

class _CanonicalOffDeviceCoverage {
  const _CanonicalOffDeviceCoverage({
    required this.startPage,
    required this.endPage,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
  });

  final int startPage;
  final int endPage;
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;
}

class ReadingPlanSnapshot {
  const ReadingPlanSnapshot({
    this.active,
    this.savedPresetIds = const <String>{},
    this.completed = const <CompletedReadingPlan>[],
    this.offDevicePageSessions = const <OffDevicePageReadingSession>[],
    this.yearlyKhatmTarget,
    this.redistributionTargetEndDate,
  });

  final ActiveReadingPlan? active;
  final Set<String> savedPresetIds;
  final List<CompletedReadingPlan> completed;
  final List<OffDevicePageReadingSession> offDevicePageSessions;

  /// Optional user-owned yearly khatm target. This is deliberately a private,
  /// local preference rather than a streak or social score.
  final int? yearlyKhatmTarget;

  int completedInYear(int year) =>
      completed.where((item) => item.completedAt.year == year).length;

  int completedInYearBySource(int year, KhatmCompletionSource source) =>
      completed
          .where(
            (item) => item.completedAt.year == year && item.source == source,
          )
          .length;

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
      offDevicePageSessions: current.offDevicePageSessions,
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
      offDevicePageSessions: current.offDevicePageSessions,
      yearlyKhatmTarget: current.yearlyKhatmTarget,
      redistributionTargetEndDate: current.redistributionTargetEndDate,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> removeCompletedAt(int index) async {
    final current = await load();
    if (index < 0 || index >= current.completed.length) {
      throw RangeError.index(index, current.completed, 'index');
    }
    final completed = current.completed.toList(growable: true)..removeAt(index);
    final next = ReadingPlanSnapshot(
      active: current.active,
      savedPresetIds: current.savedPresetIds,
      completed: List<CompletedReadingPlan>.unmodifiable(completed),
      offDevicePageSessions: current.offDevicePageSessions,
      yearlyKhatmTarget: current.yearlyKhatmTarget,
      redistributionTargetEndDate: current.redistributionTargetEndDate,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> addManualCompletedKhatm({
    DateTime? startedAt,
    required DateTime completedAt,
    String? note,
    DateTime? now,
  }) async {
    final current = await load();
    final today = readingPlanDateOnly(now ?? DateTime.now());
    final end = readingPlanDateOnly(completedAt);
    final start = startedAt == null ? null : readingPlanDateOnly(startedAt);
    _validateManualKhatmDates(start: start, end: end, today: today);

    final history = <CompletedReadingPlan>[
      CompletedReadingPlan(
        startedAt: start,
        completedAt: end,
        source: KhatmCompletionSource.manualOffDevice,
        note: _normalizeNote(note),
      ),
      ...current.completed,
    ];
    final next = ReadingPlanSnapshot(
      active: current.active,
      savedPresetIds: current.savedPresetIds,
      completed: List<CompletedReadingPlan>.unmodifiable(history),
      offDevicePageSessions: current.offDevicePageSessions,
      yearlyKhatmTarget: current.yearlyKhatmTarget,
      redistributionTargetEndDate: current.redistributionTargetEndDate,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> updateManualCompletedKhatmAt(
    int index, {
    DateTime? startedAt,
    required DateTime completedAt,
    String? note,
    DateTime? now,
  }) async {
    final current = await load();
    if (index < 0 || index >= current.completed.length) {
      throw RangeError.index(index, current.completed, 'index');
    }
    final existing = current.completed[index];
    if (!existing.isManualOffDevice) {
      throw StateError('Only manual/off-device khatm records can be edited.');
    }

    final today = readingPlanDateOnly(now ?? DateTime.now());
    final end = readingPlanDateOnly(completedAt);
    final start = startedAt == null ? null : readingPlanDateOnly(startedAt);
    _validateManualKhatmDates(start: start, end: end, today: today);

    final completed = current.completed.toList(growable: true);
    completed[index] = CompletedReadingPlan(
      startedAt: start,
      completedAt: end,
      source: KhatmCompletionSource.manualOffDevice,
      note: _normalizeNote(note),
    );
    final next = ReadingPlanSnapshot(
      active: current.active,
      savedPresetIds: current.savedPresetIds,
      completed: List<CompletedReadingPlan>.unmodifiable(completed),
      offDevicePageSessions: current.offDevicePageSessions,
      yearlyKhatmTarget: current.yearlyKhatmTarget,
      redistributionTargetEndDate: current.redistributionTargetEndDate,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> addOffDevicePageSession({
    required int startPage,
    required int endPage,
    required DateTime readAt,
    String? note,
    DateTime? now,
  }) async {
    final coverage = _coverageForPages(startPage, endPage);
    return _addOffDeviceSession(
      inputKind: OffDeviceReadingInputKind.page,
      coverage: coverage,
      readAt: readAt,
      note: note,
      now: now,
    );
  }

  Future<ReadingPlanSnapshot> addOffDeviceJuzSession({
    required int juzNumber,
    required DateTime readAt,
    String? note,
    DateTime? now,
  }) async {
    final coverage = _coverageForJuz(juzNumber);
    return _addOffDeviceSession(
      inputKind: OffDeviceReadingInputKind.juz,
      coverage: coverage,
      juzNumber: juzNumber,
      readAt: readAt,
      note: note,
      now: now,
    );
  }

  Future<ReadingPlanSnapshot> addOffDeviceHizbSession({
    required int hizbNumber,
    required DateTime readAt,
    String? note,
    DateTime? now,
  }) async {
    final coverage = _coverageForHizb(hizbNumber);
    return _addOffDeviceSession(
      inputKind: OffDeviceReadingInputKind.hizb,
      coverage: coverage,
      hizbNumber: hizbNumber,
      readAt: readAt,
      note: note,
      now: now,
    );
  }

  Future<ReadingPlanSnapshot> addOffDeviceAyahRangeSession({
    required int startSurah,
    required int startAyah,
    required int endSurah,
    required int endAyah,
    required DateTime readAt,
    String? note,
    DateTime? now,
  }) async {
    final coverage = _coverageForAyahRange(
      startSurah: startSurah,
      startAyah: startAyah,
      endSurah: endSurah,
      endAyah: endAyah,
    );
    return _addOffDeviceSession(
      inputKind: OffDeviceReadingInputKind.ayahRange,
      coverage: coverage,
      readAt: readAt,
      note: note,
      now: now,
    );
  }

  Future<ReadingPlanSnapshot> updateOffDevicePageSessionAt(
    int index, {
    required int startPage,
    required int endPage,
    required DateTime readAt,
    String? note,
    DateTime? now,
  }) {
    return _replaceOffDeviceSessionAt(
      index,
      inputKind: OffDeviceReadingInputKind.page,
      coverage: _coverageForPages(startPage, endPage),
      readAt: readAt,
      note: note,
      now: now,
    );
  }

  Future<ReadingPlanSnapshot> updateOffDeviceJuzSessionAt(
    int index, {
    required int juzNumber,
    required DateTime readAt,
    String? note,
    DateTime? now,
  }) {
    return _replaceOffDeviceSessionAt(
      index,
      inputKind: OffDeviceReadingInputKind.juz,
      coverage: _coverageForJuz(juzNumber),
      juzNumber: juzNumber,
      readAt: readAt,
      note: note,
      now: now,
    );
  }

  Future<ReadingPlanSnapshot> updateOffDeviceHizbSessionAt(
    int index, {
    required int hizbNumber,
    required DateTime readAt,
    String? note,
    DateTime? now,
  }) {
    return _replaceOffDeviceSessionAt(
      index,
      inputKind: OffDeviceReadingInputKind.hizb,
      coverage: _coverageForHizb(hizbNumber),
      hizbNumber: hizbNumber,
      readAt: readAt,
      note: note,
      now: now,
    );
  }

  Future<ReadingPlanSnapshot> updateOffDeviceAyahRangeSessionAt(
    int index, {
    required int startSurah,
    required int startAyah,
    required int endSurah,
    required int endAyah,
    required DateTime readAt,
    String? note,
    DateTime? now,
  }) {
    return _replaceOffDeviceSessionAt(
      index,
      inputKind: OffDeviceReadingInputKind.ayahRange,
      coverage: _coverageForAyahRange(
        startSurah: startSurah,
        startAyah: startAyah,
        endSurah: endSurah,
        endAyah: endAyah,
      ),
      readAt: readAt,
      note: note,
      now: now,
    );
  }

  Future<ReadingPlanSnapshot> _addOffDeviceSession({
    required OffDeviceReadingInputKind inputKind,
    required _CanonicalOffDeviceCoverage coverage,
    required DateTime readAt,
    String? note,
    int? juzNumber,
    int? hizbNumber,
    DateTime? now,
  }) async {
    final current = await load();
    final date = readingPlanDateOnly(readAt);
    final today = readingPlanDateOnly(now ?? DateTime.now());
    _validateOffDeviceReadDate(readAt: date, today: today);

    final sessions = <OffDevicePageReadingSession>[
      _sessionFromCoverage(
        inputKind: inputKind,
        coverage: coverage,
        readAt: date,
        note: _normalizeNote(note),
        juzNumber: juzNumber,
        hizbNumber: hizbNumber,
      ),
      ...current.offDevicePageSessions,
    ];
    final next = ReadingPlanSnapshot(
      active: current.active,
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      offDevicePageSessions: List<OffDevicePageReadingSession>.unmodifiable(
        sessions,
      ),
      yearlyKhatmTarget: current.yearlyKhatmTarget,
      redistributionTargetEndDate: current.redistributionTargetEndDate,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> _replaceOffDeviceSessionAt(
    int index, {
    required OffDeviceReadingInputKind inputKind,
    required _CanonicalOffDeviceCoverage coverage,
    required DateTime readAt,
    String? note,
    int? juzNumber,
    int? hizbNumber,
    DateTime? now,
  }) async {
    final current = await load();
    if (index < 0 || index >= current.offDevicePageSessions.length) {
      throw RangeError.index(index, current.offDevicePageSessions, 'index');
    }
    final date = readingPlanDateOnly(readAt);
    final today = readingPlanDateOnly(now ?? DateTime.now());
    _validateOffDeviceReadDate(readAt: date, today: today);

    final sessions = current.offDevicePageSessions.toList(growable: true);
    sessions[index] = _sessionFromCoverage(
      inputKind: inputKind,
      coverage: coverage,
      readAt: date,
      note: _normalizeNote(note),
      juzNumber: juzNumber,
      hizbNumber: hizbNumber,
    );
    final next = ReadingPlanSnapshot(
      active: current.active,
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      offDevicePageSessions: List<OffDevicePageReadingSession>.unmodifiable(
        sessions,
      ),
      yearlyKhatmTarget: current.yearlyKhatmTarget,
      redistributionTargetEndDate: current.redistributionTargetEndDate,
    );
    await _save(next);
    return next;
  }

  Future<ReadingPlanSnapshot> removeOffDevicePageSessionAt(int index) async {
    final current = await load();
    if (index < 0 || index >= current.offDevicePageSessions.length) {
      throw RangeError.index(index, current.offDevicePageSessions, 'index');
    }
    final sessions = current.offDevicePageSessions.toList(growable: true)
      ..removeAt(index);
    final next = ReadingPlanSnapshot(
      active: current.active,
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      offDevicePageSessions: List<OffDevicePageReadingSession>.unmodifiable(
        sessions,
      ),
      yearlyKhatmTarget: current.yearlyKhatmTarget,
      redistributionTargetEndDate: current.redistributionTargetEndDate,
    );
    await _save(next);
    return next;
  }

  OffDevicePlanCreditPreview previewOffDevicePlanCredit(
    ActiveReadingPlan active,
    OffDevicePageReadingSession session,
  ) {
    final impact = previewOffDevicePlanImpact(active, session);
    final creditable = <int>[];
    final partial = <int>[];

    for (final dayNumber in impact.remainingDayNumbers) {
      final day = readingPlanDay(active.preset, dayNumber);
      final dayCoverage = _coverageForPages(day.startPage, day.endPage);
      final coversCanonicalDay =
          session.hasCanonicalAyahRange &&
          _compareQuranReference(
                session.startSurah!,
                session.startAyah!,
                dayCoverage.startSurah,
                dayCoverage.startAyah,
              ) <=
              0 &&
          _compareQuranReference(
                session.endSurah!,
                session.endAyah!,
                dayCoverage.endSurah,
                dayCoverage.endAyah,
              ) >=
              0;

      if (coversCanonicalDay) {
        creditable.add(dayNumber);
      } else {
        partial.add(dayNumber);
      }
    }

    return OffDevicePlanCreditPreview(
      impact: impact,
      creditableDayNumbers: List<int>.unmodifiable(creditable),
      partialRemainingDayNumbers: List<int>.unmodifiable(partial),
    );
  }

  Future<ReadingPlanSnapshot> creditOffDeviceSessionToActivePlan(
    OffDevicePageReadingSession session, {
    DateTime? now,
  }) async {
    final current = await load();
    final active = current.active;
    if (active == null) {
      throw StateError('An active reading plan is required.');
    }
    if (active.isPaused) {
      throw StateError('A paused reading plan cannot be credited.');
    }
    if (!current.offDevicePageSessions.any(
      (item) => _sameOffDeviceSession(item, session),
    )) {
      throw StateError('The off-device reading record no longer exists.');
    }

    final preview = previewOffDevicePlanCredit(active, session);
    if (!preview.canCredit) {
      throw StateError('No fully covered unfinished plan day can be credited.');
    }

    final creditedAt = readingPlanDateOnly(now ?? DateTime.now());
    final completedDays = active.completedDays.toSet()
      ..addAll(preview.creditableDayNumbers);
    final credits = <OffDevicePlanCreditEvent>[
      ...active.offDeviceCredits,
      OffDevicePlanCreditEvent(
        creditedAt: creditedAt,
        sourceReadAt: session.readAt,
        sourceInputKind: session.inputKind,
        sourceStartPage: session.startPage,
        sourceEndPage: session.endPage,
        sourceCanonicalStartKey: session.canonicalStartKey,
        sourceCanonicalEndKey: session.canonicalEndKey,
        dayNumbers: List<int>.unmodifiable(preview.creditableDayNumbers),
      ),
    ];

    if (completedDays.length >= active.preset.durationDays) {
      final history = <CompletedReadingPlan>[
        CompletedReadingPlan(
          preset: active.preset,
          startedAt: active.startedAt,
          completedAt: creditedAt,
          offDeviceCredits: List<OffDevicePlanCreditEvent>.unmodifiable(
            credits,
          ),
        ),
        ...current.completed,
      ];
      final next = ReadingPlanSnapshot(
        savedPresetIds: current.savedPresetIds,
        completed: List<CompletedReadingPlan>.unmodifiable(history),
        offDevicePageSessions: current.offDevicePageSessions,
        yearlyKhatmTarget: current.yearlyKhatmTarget,
      );
      await _save(next);
      return next;
    }

    final next = ReadingPlanSnapshot(
      active: active.copyWith(
        completedDays: completedDays,
        offDeviceCredits: List<OffDevicePlanCreditEvent>.unmodifiable(credits),
      ),
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      offDevicePageSessions: current.offDevicePageSessions,
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
      offDevicePageSessions: current.offDevicePageSessions,
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
      offDevicePageSessions: current.offDevicePageSessions,
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
      offDevicePageSessions: current.offDevicePageSessions,
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
      throw ArgumentError.value(
        targetEndDate,
        'targetEndDate',
        'Must not be before today.',
      );
    }
    final next = ReadingPlanSnapshot(
      active: active,
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      offDevicePageSessions: current.offDevicePageSessions,
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
      offDevicePageSessions: current.offDevicePageSessions,
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
          offDeviceCredits: active.offDeviceCredits,
        ),
        ...current.completed,
      ];
      final next = ReadingPlanSnapshot(
        savedPresetIds: current.savedPresetIds,
        completed: List<CompletedReadingPlan>.unmodifiable(history),
        offDevicePageSessions: current.offDevicePageSessions,
        yearlyKhatmTarget: current.yearlyKhatmTarget,
      );
      await _save(next);
      return next;
    }

    final next = ReadingPlanSnapshot(
      active: active.copyWith(completedDays: completedDays),
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      offDevicePageSessions: current.offDevicePageSessions,
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
          offDeviceCredits: active.offDeviceCredits,
        ),
        ...current.completed,
      ];
      final next = ReadingPlanSnapshot(
        savedPresetIds: current.savedPresetIds,
        completed: List<CompletedReadingPlan>.unmodifiable(history),
        offDevicePageSessions: current.offDevicePageSessions,
        yearlyKhatmTarget: current.yearlyKhatmTarget,
      );
      await _save(next);
      return next;
    }

    final next = ReadingPlanSnapshot(
      active: active.copyWith(completedDays: completedDays),
      savedPresetIds: current.savedPresetIds,
      completed: current.completed,
      offDevicePageSessions: current.offDevicePageSessions,
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
      offDevicePageSessions: current.offDevicePageSessions,
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
      final startedAt = DateTime.tryParse(
        rawActive['startedAt']?.toString() ?? '',
      );
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
        final offDeviceCredits = _decodeOffDeviceCreditEvents(
          rawActive['offDeviceCredits'],
          preset,
        );

        active = ActiveReadingPlan(
          preset: preset,
          startedAt: normalizedStart,
          completedDays: completedDays,
          offDeviceCredits: List<OffDevicePlanCreditEvent>.unmodifiable(
            offDeviceCredits,
          ),
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
        final source = KhatmCompletionSource.fromId(item['source']?.toString());
        final preset = ReadingPlanPreset.fromId(item['preset']?.toString());
        final parsedStart = DateTime.tryParse(
          item['startedAt']?.toString() ?? '',
        );
        final parsedCompleted = DateTime.tryParse(
          item['completedAt']?.toString() ?? '',
        );
        if (parsedCompleted == null) continue;

        final startedAt = parsedStart == null
            ? null
            : readingPlanDateOnly(parsedStart);
        final completedAt = readingPlanDateOnly(parsedCompleted);
        if (startedAt != null && startedAt.isAfter(completedAt)) continue;
        if (source == KhatmCompletionSource.readingPlan &&
            (preset == null || startedAt == null)) {
          continue;
        }

        final completedCredits =
            source == KhatmCompletionSource.readingPlan && preset != null
            ? _decodeOffDeviceCreditEvents(item['offDeviceCredits'], preset)
            : const <OffDevicePlanCreditEvent>[];

        completed.add(
          CompletedReadingPlan(
            preset: source == KhatmCompletionSource.readingPlan ? preset : null,
            startedAt: startedAt,
            completedAt: completedAt,
            source: source,
            note: _decodeNote(item['note']?.toString()),
            offDeviceCredits: completedCredits,
          ),
        );
      }
    }

    final offDevicePageSessions = <OffDevicePageReadingSession>[];
    final rawSessions = json['offDevicePageSessions'];
    if (rawSessions is List) {
      for (final item in rawSessions) {
        if (item is! Map) continue;
        final readAt = DateTime.tryParse(item['readAt']?.toString() ?? '');
        if (readAt == null) continue;

        final inputKind = OffDeviceReadingInputKind.fromId(
          item['inputKind']?.toString(),
        );
        try {
          final _CanonicalOffDeviceCoverage coverage;
          int? juzNumber;
          int? hizbNumber;
          switch (inputKind) {
            case OffDeviceReadingInputKind.page:
              final startPage = _intValue(item['startPage']);
              final endPage = _intValue(item['endPage']);
              if (startPage == null || endPage == null) continue;
              coverage = _coverageForPages(startPage, endPage);
              break;
            case OffDeviceReadingInputKind.juz:
              juzNumber = _intValue(item['juzNumber']);
              if (juzNumber == null) continue;
              coverage = _coverageForJuz(juzNumber);
              break;
            case OffDeviceReadingInputKind.hizb:
              hizbNumber = _intValue(item['hizbNumber']);
              if (hizbNumber == null) continue;
              coverage = _coverageForHizb(hizbNumber);
              break;
            case OffDeviceReadingInputKind.ayahRange:
              final startSurah = _intValue(item['startSurah']);
              final startAyah = _intValue(item['startAyah']);
              final endSurah = _intValue(item['endSurah']);
              final endAyah = _intValue(item['endAyah']);
              if (startSurah == null ||
                  startAyah == null ||
                  endSurah == null ||
                  endAyah == null) {
                continue;
              }
              coverage = _coverageForAyahRange(
                startSurah: startSurah,
                startAyah: startAyah,
                endSurah: endSurah,
                endAyah: endAyah,
              );
              break;
          }

          offDevicePageSessions.add(
            _sessionFromCoverage(
              inputKind: inputKind,
              coverage: coverage,
              readAt: readingPlanDateOnly(readAt),
              note: _decodeNote(item['note']?.toString()),
              juzNumber: juzNumber,
              hizbNumber: hizbNumber,
            ),
          );
        } catch (_) {
          continue;
        }
      }
    }

    DateTime? redistributionTargetEndDate;
    if (active != null) {
      final parsed = DateTime.tryParse(
        json['redistributionTargetEndDate']?.toString() ?? '',
      );
      if (parsed != null)
        redistributionTargetEndDate = readingPlanDateOnly(parsed);
    }

    final rawYearlyKhatmTarget = json['yearlyKhatmTarget'];
    final parsedYearlyKhatmTarget = rawYearlyKhatmTarget is int
        ? rawYearlyKhatmTarget
        : int.tryParse('${rawYearlyKhatmTarget ?? ''}');
    final yearlyKhatmTarget =
        parsedYearlyKhatmTarget != null &&
            parsedYearlyKhatmTarget >= 1 &&
            parsedYearlyKhatmTarget <= 99
        ? parsedYearlyKhatmTarget
        : null;

    return ReadingPlanSnapshot(
      active: active,
      savedPresetIds: saved,
      completed: List<CompletedReadingPlan>.unmodifiable(completed),
      offDevicePageSessions: List<OffDevicePageReadingSession>.unmodifiable(
        offDevicePageSessions,
      ),
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
              'pausedAt': active.pausedAt == null
                  ? null
                  : _date(active.pausedAt!),
              'pausedDays': active.pausedDays,
              'offDeviceCredits': _encodeOffDeviceCreditEvents(
                active.offDeviceCredits,
              ),
            },
      'offDevicePageSessions': <Object?>[
        for (final item in snapshot.offDevicePageSessions)
          <String, Object?>{
            'readAt': _date(item.readAt),
            'inputKind': item.inputKind.id,
            'juzNumber': item.juzNumber,
            'hizbNumber': item.hizbNumber,
            'startPage': item.startPage,
            'endPage': item.endPage,
            'startSurah': item.startSurah,
            'startAyah': item.startAyah,
            'endSurah': item.endSurah,
            'endAyah': item.endAyah,
            'note': item.note,
          },
      ],
      'yearlyKhatmTarget': snapshot.yearlyKhatmTarget,
      'redistributionTargetEndDate':
          snapshot.redistributionTargetEndDate == null
          ? null
          : _date(snapshot.redistributionTargetEndDate!),
      'saved': snapshot.savedPresetIds.toList()..sort(),
      'completed': <Object?>[
        for (final item in snapshot.completed)
          <String, Object?>{
            'source': item.source.id,
            'preset': item.preset?.id,
            'startedAt': item.startedAt == null ? null : _date(item.startedAt!),
            'completedAt': _date(item.completedAt),
            'note': item.note,
            'offDeviceCredits': _encodeOffDeviceCreditEvents(
              item.offDeviceCredits,
            ),
          },
      ],
    };
    await prefs.setString(preferenceKey, jsonEncode(json));
    notifyExternalChange();
  }

  List<OffDevicePlanCreditEvent> _decodeOffDeviceCreditEvents(
    Object? rawCredits,
    ReadingPlanPreset preset,
  ) {
    if (rawCredits is! List) return const <OffDevicePlanCreditEvent>[];
    final decoded = <OffDevicePlanCreditEvent>[];
    for (final item in rawCredits) {
      if (item is! Map) continue;
      final creditedAt = DateTime.tryParse(
        item['creditedAt']?.toString() ?? '',
      );
      final sourceReadAt = DateTime.tryParse(
        item['sourceReadAt']?.toString() ?? '',
      );
      final sourceStartPage = _intValue(item['sourceStartPage']);
      final sourceEndPage = _intValue(item['sourceEndPage']);
      final rawCreditDays = item['dayNumbers'];
      if (creditedAt == null ||
          sourceReadAt == null ||
          sourceStartPage == null ||
          sourceEndPage == null ||
          sourceStartPage < 1 ||
          sourceEndPage > madinahMushafPageCount ||
          sourceStartPage > sourceEndPage ||
          rawCreditDays is! List) {
        continue;
      }
      final creditDays = <int>{};
      for (final rawDay in rawCreditDays) {
        final day = _intValue(rawDay);
        if (day != null && day >= 1 && day <= preset.durationDays) {
          creditDays.add(day);
        }
      }
      if (creditDays.isEmpty) continue;
      final orderedDays = creditDays.toList()..sort();
      decoded.add(
        OffDevicePlanCreditEvent(
          creditedAt: readingPlanDateOnly(creditedAt),
          sourceReadAt: readingPlanDateOnly(sourceReadAt),
          sourceInputKind: OffDeviceReadingInputKind.fromId(
            item['sourceInputKind']?.toString(),
          ),
          sourceStartPage: sourceStartPage,
          sourceEndPage: sourceEndPage,
          sourceCanonicalStartKey:
              item['sourceCanonicalStartKey']?.toString(),
          sourceCanonicalEndKey:
              item['sourceCanonicalEndKey']?.toString(),
          dayNumbers: List<int>.unmodifiable(orderedDays),
        ),
      );
    }
    return List<OffDevicePlanCreditEvent>.unmodifiable(decoded);
  }

  List<Object?> _encodeOffDeviceCreditEvents(
    List<OffDevicePlanCreditEvent> credits,
  ) {
    return <Object?>[
      for (final credit in credits)
        <String, Object?>{
          'creditedAt': _date(credit.creditedAt),
          'sourceReadAt': _date(credit.sourceReadAt),
          'sourceInputKind': credit.sourceInputKind.id,
          'sourceStartPage': credit.sourceStartPage,
          'sourceEndPage': credit.sourceEndPage,
          'sourceCanonicalStartKey': credit.sourceCanonicalStartKey,
          'sourceCanonicalEndKey': credit.sourceCanonicalEndKey,
          'dayNumbers': credit.dayNumbers,
        },
    ];
  }

  OffDevicePageReadingSession _sessionFromCoverage({
    required OffDeviceReadingInputKind inputKind,
    required _CanonicalOffDeviceCoverage coverage,
    required DateTime readAt,
    String? note,
    int? juzNumber,
    int? hizbNumber,
  }) {
    return OffDevicePageReadingSession(
      readAt: readAt,
      startPage: coverage.startPage,
      endPage: coverage.endPage,
      inputKind: inputKind,
      juzNumber: juzNumber,
      hizbNumber: hizbNumber,
      startSurah: coverage.startSurah,
      startAyah: coverage.startAyah,
      endSurah: coverage.endSurah,
      endAyah: coverage.endAyah,
      note: note,
    );
  }

  _CanonicalOffDeviceCoverage _coverageForPages(int startPage, int endPage) {
    _validateOffDevicePageRange(startPage: startPage, endPage: endPage);
    final startData = quran.getPageData(startPage);
    final endData = quran.getPageData(endPage);
    if (startData.isEmpty || endData.isEmpty) {
      throw StateError('Quran page metadata is unavailable.');
    }
    final first = Map<Object?, Object?>.from(startData.first as Map);
    final last = Map<Object?, Object?>.from(endData.last as Map);
    final startSurah = _intValue(first['surah']);
    final startAyah = _intValue(first['start']);
    final endSurah = _intValue(last['surah']);
    final endAyah = _intValue(last['end']);
    if (startSurah == null ||
        startAyah == null ||
        endSurah == null ||
        endAyah == null) {
      throw StateError('Quran page metadata is malformed.');
    }
    return _CanonicalOffDeviceCoverage(
      startPage: startPage,
      endPage: endPage,
      startSurah: startSurah,
      startAyah: startAyah,
      endSurah: endSurah,
      endAyah: endAyah,
    );
  }

  _CanonicalOffDeviceCoverage _coverageForJuz(int juzNumber) {
    if (juzNumber < 1 || juzNumber > 30) {
      throw RangeError.range(juzNumber, 1, 30, 'juzNumber');
    }
    final data = quran.getSurahAndVersesFromJuz(juzNumber);
    if (data.isEmpty) throw StateError('Quran juz metadata is unavailable.');
    final surahs = data.keys.toList()..sort();
    final startSurah = surahs.first;
    final endSurah = surahs.last;
    final startVerses = data[startSurah];
    final endVerses = data[endSurah];
    if (startVerses == null ||
        startVerses.isEmpty ||
        endVerses == null ||
        endVerses.isEmpty) {
      throw StateError('Quran juz metadata is malformed.');
    }
    final startAyah = startVerses.first;
    final endAyah = endVerses.last;
    return _CanonicalOffDeviceCoverage(
      startPage: quran.getPageNumber(startSurah, startAyah),
      endPage: quran.getPageNumber(endSurah, endAyah),
      startSurah: startSurah,
      startAyah: startAyah,
      endSurah: endSurah,
      endAyah: endAyah,
    );
  }

  _CanonicalOffDeviceCoverage _coverageForHizb(int hizbNumber) {
    if (hizbNumber < 1 || hizbNumber > quranHizbCount) {
      throw RangeError.range(hizbNumber, 1, quranHizbCount, 'hizbNumber');
    }

    final start = tanzilHizbStartReferences[hizbNumber - 1];
    late final int endSurah;
    late final int endAyah;
    if (hizbNumber == quranHizbCount) {
      endSurah = 114;
      endAyah = quran.getVerseCount(endSurah);
    } else {
      final next = tanzilHizbStartReferences[hizbNumber];
      if (next.ayah > 1) {
        endSurah = next.surah;
        endAyah = next.ayah - 1;
      } else {
        endSurah = next.surah - 1;
        endAyah = quran.getVerseCount(endSurah);
      }
    }

    return _CanonicalOffDeviceCoverage(
      startPage: quran.getPageNumber(start.surah, start.ayah),
      endPage: quran.getPageNumber(endSurah, endAyah),
      startSurah: start.surah,
      startAyah: start.ayah,
      endSurah: endSurah,
      endAyah: endAyah,
    );
  }

  _CanonicalOffDeviceCoverage _coverageForAyahRange({
    required int startSurah,
    required int startAyah,
    required int endSurah,
    required int endAyah,
  }) {
    _validateAyahReference(startSurah, startAyah, 'start');
    _validateAyahReference(endSurah, endAyah, 'end');
    if (startSurah > endSurah ||
        (startSurah == endSurah && startAyah > endAyah)) {
      throw ArgumentError('Start ayah must not be after end ayah.');
    }
    return _CanonicalOffDeviceCoverage(
      startPage: quran.getPageNumber(startSurah, startAyah),
      endPage: quran.getPageNumber(endSurah, endAyah),
      startSurah: startSurah,
      startAyah: startAyah,
      endSurah: endSurah,
      endAyah: endAyah,
    );
  }

  int _compareQuranReference(
    int leftSurah,
    int leftAyah,
    int rightSurah,
    int rightAyah,
  ) {
    if (leftSurah != rightSurah) return leftSurah.compareTo(rightSurah);
    return leftAyah.compareTo(rightAyah);
  }

  bool _sameOffDeviceSession(
    OffDevicePageReadingSession left,
    OffDevicePageReadingSession right,
  ) {
    return left.readAt == right.readAt &&
        left.inputKind == right.inputKind &&
        left.startPage == right.startPage &&
        left.endPage == right.endPage &&
        left.juzNumber == right.juzNumber &&
        left.hizbNumber == right.hizbNumber &&
        left.canonicalStartKey == right.canonicalStartKey &&
        left.canonicalEndKey == right.canonicalEndKey &&
        left.note == right.note;
  }

  void _validateAyahReference(int surah, int ayah, String field) {
    if (surah < 1 || surah > 114) {
      throw RangeError.range(surah, 1, 114, '${field}Surah');
    }
    final verseCount = quran.getVerseCount(surah);
    if (ayah < 1 || ayah > verseCount) {
      throw RangeError.range(ayah, 1, verseCount, '${field}Ayah');
    }
  }

  int? _intValue(Object? value) =>
      value is int ? value : int.tryParse('${value ?? ''}');

  void _validateOffDeviceReadDate({
    required DateTime readAt,
    required DateTime today,
  }) {
    if (readAt.isAfter(today)) {
      throw ArgumentError.value(readAt, 'readAt', 'Must not be in the future.');
    }
  }

  void _validateOffDevicePageRange({
    required int startPage,
    required int endPage,
  }) {
    if (startPage < 1 || startPage > madinahMushafPageCount) {
      throw RangeError.range(startPage, 1, madinahMushafPageCount, 'startPage');
    }
    if (endPage < 1 || endPage > madinahMushafPageCount) {
      throw RangeError.range(endPage, 1, madinahMushafPageCount, 'endPage');
    }
    if (startPage > endPage) {
      throw ArgumentError.value(
        endPage,
        'endPage',
        'Must not be before startPage.',
      );
    }
  }

  void _validateManualKhatmDates({
    required DateTime? start,
    required DateTime end,
    required DateTime today,
  }) {
    if (end.isAfter(today)) {
      throw ArgumentError.value(
        end,
        'completedAt',
        'Must not be in the future.',
      );
    }
    if (start != null && start.isAfter(end)) {
      throw ArgumentError.value(
        start,
        'startedAt',
        'Must not be after the completion date.',
      );
    }
  }

  String? _decodeNote(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed.length <= 300) return trimmed;
    return trimmed.substring(0, 300);
  }

  String? _normalizeNote(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed.length > 300) {
      throw ArgumentError.value(
        value,
        'note',
        'Must be at most 300 characters.',
      );
    }
    return trimmed;
  }

  String _date(DateTime value) {
    final date = readingPlanDateOnly(value);
    final month = '${date.month}'.padLeft(2, '0');
    final day = '${date.day}'.padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
