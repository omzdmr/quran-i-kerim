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

  double get progress => completedDays.length / preset.durationDays;

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
