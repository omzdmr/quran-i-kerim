import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_strength.dart';

void main() {
  final memorizedAt = DateTime(2026, 1, 1, 9);

  test('page without a memorized timestamp stays new', () {
    expect(
      deriveMemorizationStrength(
        progress: const MemorizationPageProgress(),
        now: DateTime(2026, 1, 10),
      ),
      MemorizationStrength.newItem,
    );
  });

  test('fresh page without recall evidence stays learning', () {
    expect(
      deriveMemorizationStrength(
        progress: MemorizationPageProgress(memorizedAt: memorizedAt),
        now: DateTime(2026, 1, 2),
      ),
      MemorizationStrength.learning,
    );
  });

  test('fragile self assessment keeps page in learning', () {
    expect(
      deriveMemorizationStrength(
        progress: MemorizationPageProgress(
          memorizedAt: memorizedAt,
          lastReviewedAt: DateTime(2026, 2, 10),
          selfAssessment: MemorizationSelfAssessment.assisted,
        ),
        now: DateTime(2026, 2, 11),
      ),
      MemorizationStrength.learning,
    );
  });

  test('independent recall inside seven days stays recent review', () {
    expect(
      deriveMemorizationStrength(
        progress: MemorizationPageProgress(
          memorizedAt: memorizedAt,
          lastReviewedAt: DateTime(2026, 1, 4),
          selfAssessment: MemorizationSelfAssessment.independent,
        ),
        now: DateTime(2026, 1, 6),
      ),
      MemorizationStrength.recentReview,
    );
  });

  test('page between day seven and day thirty stays old review', () {
    expect(
      deriveMemorizationStrength(
        progress: MemorizationPageProgress(
          memorizedAt: memorizedAt,
          lastReviewedAt: DateTime(2026, 1, 15),
          selfAssessment: MemorizationSelfAssessment.independent,
        ),
        now: DateTime(2026, 1, 20),
      ),
      MemorizationStrength.oldReview,
    );
  });

  test('day thirty independent evidence can make page solid', () {
    expect(
      deriveMemorizationStrength(
        progress: MemorizationPageProgress(
          memorizedAt: memorizedAt,
          lastReviewedAt: DateTime(2026, 2, 2),
          selfAssessment: MemorizationSelfAssessment.independent,
        ),
        now: DateTime(2026, 2, 10),
      ),
      MemorizationStrength.solid,
    );
  });

  test('real world practice can keep an independently recalled page fresh', () {
    expect(
      deriveMemorizationStrength(
        progress: MemorizationPageProgress(
          memorizedAt: memorizedAt,
          lastReviewedAt: DateTime(2026, 2, 2),
          selfAssessment: MemorizationSelfAssessment.independent,
        ),
        latestPracticeAt: DateTime(2026, 3, 5),
        now: DateTime(2026, 3, 20),
      ),
      MemorizationStrength.solid,
    );
  });

  test('stale evidence returns a page to old review', () {
    expect(
      deriveMemorizationStrength(
        progress: MemorizationPageProgress(
          memorizedAt: memorizedAt,
          lastReviewedAt: DateTime(2026, 2, 2),
          selfAssessment: MemorizationSelfAssessment.independent,
        ),
        now: DateTime(2026, 3, 20),
      ),
      MemorizationStrength.oldReview,
    );
  });
}
