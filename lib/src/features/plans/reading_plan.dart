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

  /// The plan day corresponding to the current calendar date, clamped to the
  /// first and last plan day.
  final int calendarDayNumber;

  /// Number of days completed consecutively from day one.
  ///
  /// Persisted data is intentionally allowed to recover malformed day lists
  /// without crashing. Schedule math therefore does not count an isolated
  /// future day as progress past an earlier missing day.
  final int completedPrefixDays;

  /// Number of plan days that should have been completed before today began.
  final int expectedCompletedBeforeToday;

  /// Whole plan days currently overdue. Today itself is never overdue yet.
  final int behindByDays;

  /// Whole plan days completed beyond today's scheduled portion.
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
  });

  final ReadingPlanPreset preset;
  final DateTime startedAt;
  final Set<int> completedDays;

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
    final start = readingPlanDateOnly(startedAt);
    final today = readingPlanDateOnly(now);
    final elapsedDays = today.difference(start).inDays;
    final duration = preset.durationDays;
    final calendarDay = (elapsedDays + 1).clamp(1, duration).toInt();
    final expectedBeforeToday = elapsedDays.clamp(0, duration).toInt();
    final completed = completedPrefixDays;
    final behind = expectedBeforeToday > completed
        ? expectedBeforeToday - completed
        : 0;
    final ahead = completed > calendarDay ? completed - calendarDay : 0;

    return ReadingPlanScheduleStatus(
      calendarDayNumber: calendarDay,
      completedPrefixDays: completed,
      expectedCompletedBeforeToday: expectedBeforeToday,
      behindByDays: behind,
      aheadByDays: ahead,
      scheduledEndDate: start.add(Duration(days: duration - 1)),
    );
  }

  ActiveReadingPlan copyWith({Set<int>? completedDays}) => ActiveReadingPlan(
    preset: preset,
    startedAt: startedAt,
    completedDays: completedDays ?? this.completedDays,
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
