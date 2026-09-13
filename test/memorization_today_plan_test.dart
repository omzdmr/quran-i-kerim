import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_engine.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_target_catalog.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_today_plan.dart';

void main() {
  test('returns null until a memorization pace has been started', () {
    final result = buildMemorizationTodayPlan(
      plan: const MemorizationPlanSnapshot(pace: null, startedAt: null),
      progress: const MemorizationProgressSnapshot(
        memorizedPages: <int>{},
        practiceDays: <String>{},
      ),
      target: MemorizationTargetId.fullQuran,
      weakRecallCount: 0,
      now: DateTime(2026, 9, 13),
    );

    expect(result, isNull);
  });

  test('healthy intensive plan schedules the first two available target pages', () {
    final now = DateTime(2026, 9, 13);
    final result = buildMemorizationTodayPlan(
      plan: MemorizationPlanSnapshot(
        pace: MemorizationPlanPace.intensive12Months,
        startedAt: now,
      ),
      progress: const MemorizationProgressSnapshot(
        memorizedPages: <int>{},
        practiceDays: <String>{},
      ),
      target: MemorizationTargetId.fullQuran,
      weakRecallCount: 0,
      now: now,
    );

    expect(result, isNotNull);
    expect(result!.baseNewPageCount, 2);
    expect(result.newPages, <int>[1, 2]);
    expect(result.pausesNewMemorization, isFalse);
  });

  test('two missed days in the trailing week turn today into recovery', () {
    final startedAt = DateTime(2026, 9, 10);
    final result = buildMemorizationTodayPlan(
      plan: MemorizationPlanSnapshot(
        pace: MemorizationPlanPace.intensive12Months,
        startedAt: startedAt,
        missedPlanDays: const <int>[0, 1],
      ),
      progress: const MemorizationProgressSnapshot(
        memorizedPages: <int>{},
        practiceDays: <String>{},
      ),
      target: MemorizationTargetId.fullQuran,
      weakRecallCount: 0,
      now: DateTime(2026, 9, 13),
    );

    expect(result, isNotNull);
    expect(result!.missedPlanDaysLast7, 2);
    expect(result.pausesNewMemorization, isTrue);
    expect(result.newPages, isEmpty);
  });

  test('selected target scopes both new work and review work', () {
    final now = DateTime(2026, 9, 13);
    final mulkPages = memorizationPagesForTarget(MemorizationTargetId.alMulk);
    final mulkPage = mulkPages.first;
    final outsidePage = mulkPage == 1 ? 2 : 1;
    final snapshot = MemorizationProgressSnapshot(
      memorizedPages: <int>{mulkPage, outsidePage},
      practiceDays: const <String>{},
      pageProgress: <int, MemorizationPageProgress>{
        mulkPage: MemorizationPageProgress(
          memorizedAt: now.subtract(const Duration(days: 2)),
        ),
        outsidePage: MemorizationPageProgress(
          memorizedAt: now.subtract(const Duration(days: 2)),
        ),
      },
    );

    final result = buildMemorizationTodayPlan(
      plan: MemorizationPlanSnapshot(
        pace: MemorizationPlanPace.intensive12Months,
        startedAt: now,
      ),
      progress: snapshot,
      target: MemorizationTargetId.alMulk,
      weakRecallCount: 0,
      now: now,
    );

    expect(result, isNotNull);
    expect(result!.reviewPages, contains(mulkPage));
    expect(result.reviewPages, isNot(contains(outsidePage)));
    expect(result.newPages.every(mulkPages.contains), isTrue);
    expect(result.newPages, isNot(contains(mulkPage)));
  });

  test('weak recall pressure can reduce the real scheduled new pages', () {
    final now = DateTime(2026, 9, 13);
    final result = buildMemorizationTodayPlan(
      plan: MemorizationPlanSnapshot(
        pace: MemorizationPlanPace.intensive12Months,
        startedAt: now,
      ),
      progress: const MemorizationProgressSnapshot(
        memorizedPages: <int>{},
        practiceDays: <String>{},
      ),
      target: MemorizationTargetId.fullQuran,
      weakRecallCount: 2,
      now: now,
    );

    expect(result, isNotNull);
    expect(result!.baseNewPageCount, 2);
    expect(result.newPageCount, 1);
    expect(result.isNewLoadReduced, isTrue);
  });

  test('study pages protect old and recent review before new memorization', () {
    final now = DateTime(2026, 9, 13);
    final result = buildMemorizationTodayPlan(
      plan: MemorizationPlanSnapshot(
        pace: MemorizationPlanPace.intensive12Months,
        startedAt: now,
      ),
      progress: MemorizationProgressSnapshot(
        memorizedPages: const <int>{1, 2},
        practiceDays: const <String>{},
        pageProgress: <int, MemorizationPageProgress>{
          1: MemorizationPageProgress(
            memorizedAt: now.subtract(const Duration(days: 40)),
          ),
          2: MemorizationPageProgress(
            memorizedAt: now.subtract(const Duration(days: 2)),
          ),
        },
      ),
      target: MemorizationTargetId.fullQuran,
      weakRecallCount: 0,
      now: now,
    );

    expect(result, isNotNull);
    expect(result!.queue.oldReviewPages, <int>[1]);
    expect(result.queue.recentReviewPages, <int>[2]);
    expect(result.newPages, <int>[3, 4]);
    expect(result.studyPages, <int>[1, 2, 3, 4]);
    expect(result.firstStudyPage, 1);
  });
}
