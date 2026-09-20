import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';

void main() {
  for (final preset in ReadingPlanPreset.values) {
    test('${preset.id} covers all 604 pages exactly once in order', () {
      final pages = <int>[];
      for (var day = 1; day <= preset.durationDays; day++) {
        final item = readingPlanDay(preset, day);
        expect(item.startPage, lessThanOrEqualTo(item.endPage));
        pages.addAll(<int>[
          for (var page = item.startPage; page <= item.endPage; page++) page,
        ]);
      }

      expect(pages, <int>[for (var page = 1; page <= 604; page++) page]);
    });
  }

  test('active plan advances to the first incomplete day', () {
    final active = ActiveReadingPlan(
      preset: ReadingPlanPreset.quran30,
      startedAt: DateTime(2026, 9, 16),
      completedDays: const <int>{1, 2, 4},
    );

    expect(active.nextDayNumber, 3);
    expect(active.nextDay?.startPage, readingPlanDay(ReadingPlanPreset.quran30, 3).startPage);
  });

  test('day lookup rejects values outside the preset duration', () {
    expect(() => readingPlanDay(ReadingPlanPreset.quran30, 0), throwsRangeError);
    expect(() => readingPlanDay(ReadingPlanPreset.quran30, 31), throwsRangeError);
  });
}
