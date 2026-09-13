import 'dart:math';

import 'package:quran/quran.dart' as quran;

import 'memorization_page_catalog.dart';
import 'memorization_progress_store.dart';
import 'memorization_recall_quiz.dart';

/// Returns juz numbers whose page set is fully marked as memorized.
///
/// Page membership follows the app's existing Mushaf page catalog so this stays
/// consistent with the memorization map and its 604-page model.
List<int> completedMemorizedJuz(MemorizationProgressSnapshot snapshot) {
  final completed = <int>[];
  for (var juz = 1; juz <= 30; juz++) {
    final pages = memorizationPagesForJuz(juz);
    if (pages.isEmpty) continue;
    final allMemorized = pages.every(
      (page) => snapshot.memorizedPages.contains(page.page),
    );
    if (allMemorized) completed.add(juz);
  }
  return List<int>.unmodifiable(completed);
}

/// Builds a finite completion exam for one fully memorized juz.
///
/// Both the prompt and its continuation are required to belong to the selected
/// juz. Weak verses are placed first, then the remaining questions are shuffled
/// so repeated sessions do not become a predictable sequence.
List<MemorizationRecallQuestion> buildJuzReviewQuestions(
  MemorizationProgressSnapshot snapshot,
  int juz, {
  int maxQuestions = 10,
  Random? random,
  Set<String> preferredIds = const <String>{},
}) {
  if (juz < 1 || juz > 30 || maxQuestions <= 0) {
    return const <MemorizationRecallQuestion>[];
  }
  if (!completedMemorizedJuz(snapshot).contains(juz)) {
    return const <MemorizationRecallQuestion>[];
  }

  final candidates = buildMemorizationRecallCandidates(snapshot.memorizedPages)
      .where((question) {
        final promptJuz = quran.getJuzNumber(question.surah, question.ayah);
        final answerJuz =
            quran.getJuzNumber(question.surah, question.answerAyah);
        return promptJuz == juz && answerJuz == juz;
      })
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
