import 'dart:math';

import 'memorization_progress_store.dart';
import 'memorization_recall_quiz.dart';

/// Returns pages first marked as memorized during the current rolling review
/// window. The default window is the last seven local calendar days, including
/// today.
Set<int> weeklyMemorizedPages(
  MemorizationProgressSnapshot snapshot, {
  DateTime? now,
  int days = 7,
}) {
  if (days <= 0) return const <int>{};

  final effectiveNow = now ?? DateTime.now();
  final today = DateTime(
    effectiveNow.year,
    effectiveNow.month,
    effectiveNow.day,
  );
  final oldestDay = today.subtract(Duration(days: days - 1));

  return snapshot.memorizedPages.where((page) {
    final memorizedAt = snapshot.progressForPage(page)?.memorizedAt;
    if (memorizedAt == null) return false;
    final memorizedDay = DateTime(
      memorizedAt.year,
      memorizedAt.month,
      memorizedAt.day,
    );
    return !memorizedDay.isBefore(oldestDay) &&
        !memorizedDay.isAfter(today);
  }).toSet();
}

/// Builds a finite weekly consolidation session from recently memorized pages.
///
/// The prompt verse must start on a page memorized inside the review window,
/// while its answer may continue onto any page that is already memorized. Weak
/// verses are placed first when they are available, then the remaining
/// questions are shuffled to avoid a predictable order.
List<MemorizationRecallQuestion> buildWeeklyReviewQuestions(
  MemorizationProgressSnapshot snapshot, {
  DateTime? now,
  int days = 7,
  int maxQuestions = 7,
  Random? random,
  Set<String> preferredIds = const <String>{},
}) {
  if (maxQuestions <= 0) return const <MemorizationRecallQuestion>[];

  final recentPages = weeklyMemorizedPages(
    snapshot,
    now: now,
    days: days,
  );
  if (recentPages.isEmpty) return const <MemorizationRecallQuestion>[];

  final candidates = buildMemorizationRecallCandidates(snapshot.memorizedPages)
      .where((question) => recentPages.contains(question.page))
      .toList(growable: false);
  if (candidates.isEmpty) return const <MemorizationRecallQuestion>[];

  final generator = random ?? Random();
  final preferred = candidates
      .where((question) => preferredIds.contains(question.id))
      .toList();
  final remaining = candidates
      .where((question) => !preferredIds.contains(question.id))
      .toList();
  preferred.shuffle(generator);
  remaining.shuffle(generator);

  return List<MemorizationRecallQuestion>.unmodifiable(
    <MemorizationRecallQuestion>[...preferred, ...remaining]
        .take(maxQuestions),
  );
}
