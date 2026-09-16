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

class ActiveReadingPlan {
  const ActiveReadingPlan({
    required this.preset,
    required this.startedAt,
    this.completedDays = const <int>{},
    this.pausedAt,
    this.pausedDays = 0,
  });

  final ReadingPlanPreset preset;
  final DateTime startedAt;
  final Set<int> completedDays;

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
      pausedAt: readingPlanDateOnly(now),
      pausedDays: pausedDays,
    );
  }

  ActiveReadingPlan resume(DateTime now) {
    final pauseDate = pausedAt;
    if (pauseDate == null) return this;
    final resumeDate = readingPlanDateOnly(now);
    final pausedFor = resumeDate.difference(readingPlanDateOnly(pauseDate)).inDays;
    return ActiveReadingPlan(
      preset: preset,
      startedAt: startedAt,
      completedDays: completedDays,
      pausedDays: pausedDays + (pausedFor > 0 ? pausedFor : 0),
    );
  }

  ActiveReadingPlan copyWith({Set<int>? completedDays}) => ActiveReadingPlan(
    preset: preset,
    startedAt: startedAt,
    completedDays: completedDays ?? this.completedDays,
    pausedAt: pausedAt,
    pausedDays: pausedDays,
  );
}

class CompletedReadingPlan {
  const CompletedReadingPlan({
    required this.preset,
    required this.startedAt,
    required this.completedAt,
  });

  final ReadingPlanPreset preset;
  final DateTime startedAt;
  final DateTime completedAt;
}

DateTime readingPlanDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
