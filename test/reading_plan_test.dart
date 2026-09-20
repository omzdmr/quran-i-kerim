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

  test('off-device impact previews exact unfinished plan-day pages', () {
    final preset = ReadingPlanPreset.quran30;
    final day = readingPlanDay(preset, 2);
    final active = ActiveReadingPlan(
      preset: preset,
      startedAt: DateTime(2026, 9, 20),
      completedDays: const <int>{1},
    );
    final session = OffDevicePageReadingSession(
      readAt: DateTime(2026, 9, 20),
      startPage: day.startPage + 2,
      endPage: day.endPage - 1,
      inputKind: OffDeviceReadingInputKind.hizb,
      hizbNumber: 2,
    );

    final impact = previewOffDevicePlanImpact(active, session);

    expect(impact.firstDayNumber, 2);
    expect(impact.lastDayNumber, 2);
    expect(impact.touchedDayCount, 1);
    expect(impact.completedDayNumbers, isEmpty);
    expect(impact.remainingDayNumbers, <int>[2]);
    expect(impact.remainingPageCount, session.pageCount);
    expect(impact.segments.single.startPage, session.startPage);
    expect(impact.segments.single.endPage, session.endPage);
    expect(impact.segments.single.completed, isFalse);
  });

  test('off-device impact separates completed and remaining touched days', () {
    final preset = ReadingPlanPreset.quran30;
    final first = readingPlanDay(preset, 1);
    final third = readingPlanDay(preset, 3);
    final active = ActiveReadingPlan(
      preset: preset,
      startedAt: DateTime(2026, 9, 20),
      completedDays: const <int>{1, 3},
    );
    final session = OffDevicePageReadingSession(
      readAt: DateTime(2026, 9, 20),
      startPage: first.endPage,
      endPage: third.startPage,
    );

    final impact = previewOffDevicePlanImpact(active, session);

    expect(impact.firstDayNumber, 1);
    expect(impact.lastDayNumber, 3);
    expect(impact.touchedDayCount, 3);
    expect(impact.completedDayNumbers, <int>[1, 3]);
    expect(impact.remainingDayNumbers, <int>[2]);
    expect(impact.touchesCompletedDays, isTrue);
    expect(impact.touchesRemainingDays, isTrue);
    expect(impact.segments.first.startPage, first.endPage);
    expect(impact.segments.first.endPage, first.endPage);
    expect(impact.segments.last.startPage, third.startPage);
    expect(impact.segments.last.endPage, third.startPage);
    expect(
      impact.overlapPageCount,
      impact.completedPageCount + impact.remainingPageCount,
    );
  });

  test('off-device impact is read-only and does not advance active plan', () {
    final preset = ReadingPlanPreset.quran90;
    final day = readingPlanDay(preset, 4);
    final active = ActiveReadingPlan(
      preset: preset,
      startedAt: DateTime(2026, 9, 20),
      completedDays: const <int>{1, 2},
    );
    final before = active.completedDays.toSet();
    final session = OffDevicePageReadingSession(
      readAt: DateTime(2026, 9, 20),
      startPage: day.startPage,
      endPage: day.endPage,
      inputKind: OffDeviceReadingInputKind.ayahRange,
      startSurah: 2,
      startAyah: 1,
      endSurah: 2,
      endAyah: 5,
    );

    previewOffDevicePlanImpact(active, session);

    expect(active.completedDays, before);
    expect(active.nextDayNumber, 3);
  });

  test('full-Quran off-device impact touches every plan day', () {
    final preset = ReadingPlanPreset.quran365;
    final active = ActiveReadingPlan(
      preset: preset,
      startedAt: DateTime(2026, 9, 20),
      completedDays: const <int>{1, 2, 365},
    );
    final session = OffDevicePageReadingSession(
      readAt: DateTime(2026, 9, 20),
      startPage: 1,
      endPage: madinahMushafPageCount,
    );

    final impact = previewOffDevicePlanImpact(active, session);

    expect(impact.firstDayNumber, 1);
    expect(impact.lastDayNumber, 365);
    expect(impact.touchedDayCount, 365);
    expect(impact.completedDayCount, 3);
    expect(impact.remainingDayCount, 362);
    expect(impact.overlapPageCount, madinahMushafPageCount);
  });

}
