const int madinahMushafPageCount = 604;

enum ReadingPlanPreset {
  quran30,
  quran90,
  quran365;

  String get id => switch (this) {
    quran30 => 'quran30',
    quran90 => 'quran90',
    quran365 => 'quran365',
  };

  int get durationDays => switch (this) {
    quran30 => 30,
    quran90 => 90,
    quran365 => 365,
  };

  String get titleKey => switch (this) {
    quran30 => 'quran30',
    quran90 => 'quran90',
    quran365 => 'quranYear',
  };

  String get durationKey => switch (this) {
    quran30 => 'day30',
    quran90 => 'day90',
    quran365 => 'year1',
  };

  static ReadingPlanPreset? fromId(String? id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

class ReadingPlanDay {
  const ReadingPlanDay({
    required this.dayNumber,
    required this.startPage,
    required this.endPage,
  });

  final int dayNumber;
  final int startPage;
  final int endPage;

  int get pageCount => endPage - startPage + 1;
}

ReadingPlanDay readingPlanDay(ReadingPlanPreset preset, int dayNumber) {
  final duration = preset.durationDays;
  if (dayNumber < 1 || dayNumber > duration) {
    throw RangeError.range(dayNumber, 1, duration, 'dayNumber');
  }

  final startPage = ((dayNumber - 1) * madinahMushafPageCount ~/ duration) + 1;
  final endPage = dayNumber * madinahMushafPageCount ~/ duration;
  return ReadingPlanDay(
    dayNumber: dayNumber,
    startPage: startPage,
    endPage: endPage,
  );
}

class ReadingPlanScheduleStatus {
  const ReadingPlanScheduleStatus({
    required this.calendarDayNumber,
    required this.completedPrefixDays,
    required this.expectedCompletedBeforeToday,
    required this.behindByDays,
    required this.aheadByDays,
    required this.scheduledEndDate,
  });

  final int calendarDayNumber;
  final int completedPrefixDays;
  final int expectedCompletedBeforeToday;
  final int behindByDays;
  final int aheadByDays;
  final DateTime scheduledEndDate;

  bool get isBehind => behindByDays > 0;
  bool get isAhead => aheadByDays > 0;
  bool get isOnTrack => !isBehind && !isAhead;
}

/// A contiguous catch-up slice from the first unfinished plan day through the
/// current scheduled day. This does not mutate the user's plan or silently
/// mark missed work complete; it only gives the UI a deterministic recovery
/// target that can be opened in Reader and explicitly completed by the user.
class ReadingPlanCatchUpTarget {
  const ReadingPlanCatchUpTarget({
    required this.firstDayNumber,
    required this.lastDayNumber,
    required this.startPage,
    required this.endPage,
  });

  final int firstDayNumber;
  final int lastDayNumber;
  final int startPage;
  final int endPage;

  int get dayCount => lastDayNumber - firstDayNumber + 1;
  int get pageCount => endPage - startPage + 1;
  bool get spansMultipleDays => dayCount > 1;
}

class ActiveReadingPlan {
  const ActiveReadingPlan({
    required this.preset,
    required this.startedAt,
    this.completedDays = const <int>{},
    this.offDeviceCredits = const <OffDevicePlanCreditEvent>[],
    this.pausedAt,
    this.pausedDays = 0,
  });

  final ReadingPlanPreset preset;
  final DateTime startedAt;
  final Set<int> completedDays;

  /// Explicit user-confirmed credits created from off-device reading records.
  /// These are snapshots of the confirmed action, not live links to mutable
  /// reading logs.
  final List<OffDevicePlanCreditEvent> offDeviceCredits;

  /// Date on which the current pause began. Null means the schedule is active.
  final DateTime? pausedAt;

  /// Full calendar days accumulated by earlier completed pauses.
  final int pausedDays;

  bool get isPaused => pausedAt != null;

  int? get nextDayNumber {
    for (var day = 1; day <= preset.durationDays; day++) {
      if (!completedDays.contains(day)) return day;
    }
    return null;
  }

  ReadingPlanDay? get nextDay {
    final day = nextDayNumber;
    return day == null ? null : readingPlanDay(preset, day);
  }

  int get completedPrefixDays {
    var completed = 0;
    for (var day = 1; day <= preset.durationDays; day++) {
      if (!completedDays.contains(day)) break;
      completed = day;
    }
    return completed;
  }

  double get progress => completedPrefixDays / preset.durationDays;

  /// Returns the work needed to catch the contiguous plan schedule up through
  /// today. When the user is on-track or ahead this is simply the next day.
  /// While paused the frozen schedule day is respected, so pausing never grows
  /// the recovery target in the background.
  ReadingPlanCatchUpTarget? catchUpTarget(DateTime now) {
    final first = nextDayNumber;
    if (first == null) return null;
    final status = scheduleStatus(now);
    final last = status.calendarDayNumber < first
        ? first
        : status.calendarDayNumber.clamp(first, preset.durationDays).toInt();
    final firstSlice = readingPlanDay(preset, first);
    final lastSlice = readingPlanDay(preset, last);
    return ReadingPlanCatchUpTarget(
      firstDayNumber: first,
      lastDayNumber: last,
      startPage: firstSlice.startPage,
      endPage: lastSlice.endPage,
    );
  }

  ReadingPlanScheduleStatus scheduleStatus(DateTime now) {
    final originalStart = readingPlanDateOnly(startedAt);
    final scheduleStart = originalStart.add(Duration(days: pausedDays));
    final today = readingPlanDateOnly(now);
    final pauseDate = pausedAt == null ? null : readingPlanDateOnly(pausedAt!);
    final effectiveToday = pauseDate != null && !today.isBefore(pauseDate)
        ? pauseDate
        : today;
    final elapsedDays = effectiveToday.difference(scheduleStart).inDays;
    final duration = preset.durationDays;
    final calendarDay = (elapsedDays + 1).clamp(1, duration).toInt();
    final expectedBeforeToday = elapsedDays.clamp(0, duration).toInt();
    final completed = completedPrefixDays;
    final behind = expectedBeforeToday > completed
        ? expectedBeforeToday - completed
        : 0;
    final ahead = completed > calendarDay ? completed - calendarDay : 0;
    final livePauseDays = pauseDate == null
        ? 0
        : today.difference(pauseDate).inDays > 0
        ? today.difference(pauseDate).inDays
        : 0;

    return ReadingPlanScheduleStatus(
      calendarDayNumber: calendarDay,
      completedPrefixDays: completed,
      expectedCompletedBeforeToday: expectedBeforeToday,
      behindByDays: behind,
      aheadByDays: ahead,
      scheduledEndDate: scheduleStart.add(
        Duration(days: duration - 1 + livePauseDays),
      ),
    );
  }

  ActiveReadingPlan pause(DateTime now) {
    if (isPaused) return this;
    return ActiveReadingPlan(
      preset: preset,
      startedAt: startedAt,
      completedDays: completedDays,
      offDeviceCredits: offDeviceCredits,
      pausedAt: readingPlanDateOnly(now),
      pausedDays: pausedDays,
    );
  }

  ActiveReadingPlan resume(DateTime now) {
    final pauseDate = pausedAt;
    if (pauseDate == null) return this;
    final resumeDate = readingPlanDateOnly(now);
    final pausedFor = resumeDate
        .difference(readingPlanDateOnly(pauseDate))
        .inDays;
    return ActiveReadingPlan(
      preset: preset,
      startedAt: startedAt,
      completedDays: completedDays,
      offDeviceCredits: offDeviceCredits,
      pausedDays: pausedDays + (pausedFor > 0 ? pausedFor : 0),
    );
  }

  ActiveReadingPlan copyWith({
    Set<int>? completedDays,
    List<OffDevicePlanCreditEvent>? offDeviceCredits,
  }) => ActiveReadingPlan(
    preset: preset,
    startedAt: startedAt,
    completedDays: completedDays ?? this.completedDays,
    offDeviceCredits: offDeviceCredits ?? this.offDeviceCredits,
    pausedAt: pausedAt,
    pausedDays: pausedDays,
  );
}

enum OffDeviceReadingInputKind {
  page,
  juz,
  hizb,
  ayahRange;

  String get id => switch (this) {
    page => 'page',
    juz => 'juz',
    hizb => 'hizb',
    ayahRange => 'ayahRange',
  };

  static OffDeviceReadingInputKind fromId(String? id) => switch (id) {
    'juz' => OffDeviceReadingInputKind.juz,
    'hizb' => OffDeviceReadingInputKind.hizb,
    'ayahRange' => OffDeviceReadingInputKind.ayahRange,
    _ => OffDeviceReadingInputKind.page,
  };
}

class OffDevicePageReadingSession {
  const OffDevicePageReadingSession({
    required this.readAt,
    required this.startPage,
    required this.endPage,
    this.inputKind = OffDeviceReadingInputKind.page,
    this.juzNumber,
    this.hizbNumber,
    this.startSurah,
    this.startAyah,
    this.endSurah,
    this.endAyah,
    this.note,
  });

  final DateTime readAt;
  final int startPage;
  final int endPage;
  final OffDeviceReadingInputKind inputKind;
  final int? juzNumber;
  final int? hizbNumber;
  final int? startSurah;
  final int? startAyah;
  final int? endSurah;
  final int? endAyah;
  final String? note;

  int get pageCount => endPage - startPage + 1;

  bool get hasCanonicalAyahRange =>
      startSurah != null &&
      startAyah != null &&
      endSurah != null &&
      endAyah != null;

  String? get canonicalStartKey =>
      hasCanonicalAyahRange ? '$startSurah:$startAyah' : null;

  String? get canonicalEndKey =>
      hasCanonicalAyahRange ? '$endSurah:$endAyah' : null;
}

class OffDevicePlanCreditEvent {
  const OffDevicePlanCreditEvent({
    required this.creditedAt,
    required this.sourceReadAt,
    required this.sourceInputKind,
    required this.sourceStartPage,
    required this.sourceEndPage,
    required this.dayNumbers,
    this.sourceCanonicalStartKey,
    this.sourceCanonicalEndKey,
  });

  final DateTime creditedAt;
  final DateTime sourceReadAt;
  final OffDeviceReadingInputKind sourceInputKind;
  final int sourceStartPage;
  final int sourceEndPage;
  final List<int> dayNumbers;
  final String? sourceCanonicalStartKey;
  final String? sourceCanonicalEndKey;
}

class OffDevicePlanCreditPreview {
  const OffDevicePlanCreditPreview({
    required this.impact,
    required this.creditableDayNumbers,
    required this.partialRemainingDayNumbers,
  });

  final OffDevicePlanImpact impact;
  final List<int> creditableDayNumbers;
  final List<int> partialRemainingDayNumbers;

  bool get canCredit => creditableDayNumbers.isNotEmpty;
  int get creditableDayCount => creditableDayNumbers.length;
  int get partialRemainingDayCount => partialRemainingDayNumbers.length;
}

class OffDevicePlanImpactSegment {
  const OffDevicePlanImpactSegment({
    required this.dayNumber,
    required this.startPage,
    required this.endPage,
    required this.completed,
  });

  final int dayNumber;
  final int startPage;
  final int endPage;
  final bool completed;

  int get pageCount => endPage - startPage + 1;
}

class OffDevicePlanImpact {
  const OffDevicePlanImpact({required this.segments});

  final List<OffDevicePlanImpactSegment> segments;

  int get firstDayNumber => segments.first.dayNumber;
  int get lastDayNumber => segments.last.dayNumber;
  int get touchedDayCount => segments.length;

  List<int> get completedDayNumbers => List<int>.unmodifiable(
    segments.where((item) => item.completed).map((item) => item.dayNumber),
  );

  List<int> get remainingDayNumbers => List<int>.unmodifiable(
    segments.where((item) => !item.completed).map((item) => item.dayNumber),
  );

  int get completedDayCount => segments.where((item) => item.completed).length;
  int get remainingDayCount => segments.where((item) => !item.completed).length;

  int get completedPageCount => segments
      .where((item) => item.completed)
      .fold(0, (sum, item) => sum + item.pageCount);

  int get remainingPageCount => segments
      .where((item) => !item.completed)
      .fold(0, (sum, item) => sum + item.pageCount);

  int get overlapPageCount =>
      segments.fold(0, (sum, item) => sum + item.pageCount);

  bool get touchesCompletedDays => completedDayCount > 0;
  bool get touchesRemainingDays => remainingDayCount > 0;
}

/// Read-only projection of an off-device reading onto the active plan.
///
/// This function never mutates [active] and never credits progress. It only
/// intersects the session's already-normalized Mushaf page coverage with each
/// plan day so the UI can explain what an explicit future credit action would
/// touch.
OffDevicePlanImpact previewOffDevicePlanImpact(
  ActiveReadingPlan active,
  OffDevicePageReadingSession session,
) {
  final segments = <OffDevicePlanImpactSegment>[];

  for (
    var dayNumber = 1;
    dayNumber <= active.preset.durationDays;
    dayNumber++
  ) {
    final day = readingPlanDay(active.preset, dayNumber);
    final overlapStart = day.startPage > session.startPage
        ? day.startPage
        : session.startPage;
    final overlapEnd = day.endPage < session.endPage
        ? day.endPage
        : session.endPage;
    if (overlapStart > overlapEnd) continue;

    segments.add(
      OffDevicePlanImpactSegment(
        dayNumber: dayNumber,
        startPage: overlapStart,
        endPage: overlapEnd,
        completed: active.completedDays.contains(dayNumber),
      ),
    );
  }

  if (segments.isEmpty) {
    throw StateError('Off-device reading does not intersect the active plan.');
  }

  return OffDevicePlanImpact(
    segments: List<OffDevicePlanImpactSegment>.unmodifiable(segments),
  );
}

enum KhatmCompletionSource {
  readingPlan,
  manualOffDevice;

  String get id => switch (this) {
    readingPlan => 'readingPlan',
    manualOffDevice => 'manualOffDevice',
  };

  static KhatmCompletionSource fromId(String? id) => switch (id) {
    'manualOffDevice' => KhatmCompletionSource.manualOffDevice,
    _ => KhatmCompletionSource.readingPlan,
  };
}

class CompletedReadingPlan {
  const CompletedReadingPlan({
    required this.completedAt,
    this.preset,
    this.startedAt,
    this.source = KhatmCompletionSource.readingPlan,
    this.note,
    this.offDeviceCredits = const <OffDevicePlanCreditEvent>[],
  });

  final ReadingPlanPreset? preset;
  final DateTime? startedAt;
  final DateTime completedAt;
  final KhatmCompletionSource source;
  final String? note;

  /// Immutable snapshots of explicit off-device credits that contributed to a
  /// completed app reading plan. These never depend on the original mutable
  /// off-device reading records remaining in storage.
  final List<OffDevicePlanCreditEvent> offDeviceCredits;

  bool get isManualOffDevice => source == KhatmCompletionSource.manualOffDevice;
  bool get hasOffDeviceCredits => offDeviceCredits.isNotEmpty;

  Set<int> get offDeviceCreditedDayNumbers => Set<int>.unmodifiable(<int>{
    for (final event in offDeviceCredits) ...event.dayNumbers,
  });

  int get offDeviceCreditedDayCount => offDeviceCreditedDayNumbers.length;

  int get appCompletedDayCount {
    final total = preset?.durationDays;
    if (total == null) return 0;
    final appDays = total - offDeviceCreditedDayCount;
    return appDays > 0 ? appDays : 0;
  }

  CompletedReadingPlan copyWith({
    DateTime? startedAt,
    bool clearStartedAt = false,
    DateTime? completedAt,
    String? note,
    bool clearNote = false,
    List<OffDevicePlanCreditEvent>? offDeviceCredits,
  }) {
    return CompletedReadingPlan(
      preset: preset,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      completedAt: completedAt ?? this.completedAt,
      source: source,
      note: clearNote ? null : (note ?? this.note),
      offDeviceCredits: offDeviceCredits ?? this.offDeviceCredits,
    );
  }
}

DateTime readingPlanDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
