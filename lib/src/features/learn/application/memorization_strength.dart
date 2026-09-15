import 'memorization_progress_store.dart';

enum MemorizationStrength {
  newItem,
  learning,
  recentReview,
  oldReview,
  solid,
}

DateTime _memorizationDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime? _latestEvidence({
  required DateTime memorizedAt,
  required DateTime now,
  DateTime? lastReviewedAt,
  DateTime? latestPracticeAt,
}) {
  DateTime? latest;
  for (final value in <DateTime?>[lastReviewedAt, latestPracticeAt]) {
    if (value == null || value.isBefore(memorizedAt) || value.isAfter(now)) {
      continue;
    }
    if (latest == null || value.isAfter(latest)) latest = value;
  }
  return latest;
}

/// Derives a conservative presentation state for one memorized page.
///
/// The state intentionally does not treat a single `memorized` flag as proof
/// that a page is solid. Fragile self-assessments keep the page in learning,
/// the first seven days stay in recent review, and `solid` requires both an
/// independent assessment and evidence at/after the day-30 checkpoint. A later
/// real-world practice event can keep an already independently recalled page
/// fresh, but cannot promote an assisted/struggled page by itself.
MemorizationStrength deriveMemorizationStrength({
  required MemorizationPageProgress progress,
  DateTime? latestPracticeAt,
  DateTime? now,
}) {
  final memorizedAt = progress.memorizedAt;
  if (memorizedAt == null) return MemorizationStrength.newItem;

  final effectiveNow = now ?? DateTime.now();
  final assessment = progress.selfAssessment;
  if (assessment == MemorizationSelfAssessment.struggled ||
      assessment == MemorizationSelfAssessment.assisted) {
    return MemorizationStrength.learning;
  }

  if (assessment == null && progress.lastReviewedAt == null) {
    return MemorizationStrength.learning;
  }

  final ageDays = _memorizationDay(effectiveNow)
      .difference(_memorizationDay(memorizedAt))
      .inDays;
  if (ageDays < 7) return MemorizationStrength.recentReview;
  if (ageDays < 30) return MemorizationStrength.oldReview;

  if (assessment == MemorizationSelfAssessment.independent) {
    final evidence = _latestEvidence(
      memorizedAt: memorizedAt,
      now: effectiveNow,
      lastReviewedAt: progress.lastReviewedAt,
      latestPracticeAt: latestPracticeAt,
    );
    final day30 = _memorizationDay(memorizedAt).add(const Duration(days: 30));
    if (evidence != null &&
        !_memorizationDay(evidence).isBefore(day30) &&
        _memorizationDay(effectiveNow)
                .difference(_memorizationDay(evidence))
                .inDays <=
            30) {
      return MemorizationStrength.solid;
    }
  }

  return MemorizationStrength.oldReview;
}
