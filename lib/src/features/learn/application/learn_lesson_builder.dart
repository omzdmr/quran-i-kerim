import 'package:quran/quran.dart' as quran;

import '../../../data/sourced_explanation.dart';
import '../../../data/surah_localization.dart';
import '../../../data/translation_catalog.dart';
import '../../../data/translation_pack.dart';
import '../presentation/lesson_visual_flow.dart';
import 'learn_lesson_catalog.dart';

List<LearnLessonVisualStep> buildSourcedLearnLessonSteps({
  required LearnLessonDefinition lesson,
  required TranslationPack pack,
  required String languageCode,
  required String Function(String key) text,
}) {
  final info = translationById(pack.translationId);
  final publisher = info?.publisher.trim();
  final sourceLabel = <String>[
    if (publisher != null && publisher.isNotEmpty) publisher,
    pack.source,
    'v${pack.version}',
  ].join(' · ');

  final steps = <LearnLessonVisualStep>[
    LearnLessonVisualStep(
      id: 'intro',
      type: LearnLessonVisualStepType.introduction,
      title: text(lesson.titleKey),
      body: text(lesson.introBodyKey),
      eyebrow: text('learnLessonSourceBadgeV1'),
      reference: '${lesson.surah}:${lesson.ayahs.first}-${lesson.ayahs.last}',
    ),
  ];

  for (final ayah in lesson.ayahs) {
    final translation = pack.verse(lesson.surah, ayah);
    if (translation == null || translation.trim().isEmpty) {
      throw StateError(
        'Translation ${pack.translationId} is missing ${lesson.surah}:$ayah.',
      );
    }

    final verseTitle = text('learnLessonVerseTitleV1').replaceAll(
      '{ayah}',
      '$ayah',
    );
    steps.add(
      LearnLessonVisualStep(
        id: 'verse-$ayah',
        type: LearnLessonVisualStepType.verse,
        title: verseTitle,
        arabicText: quran.getVerse(lesson.surah, ayah),
        reference: '${lesson.surah}:$ayah',
      ),
    );
    steps.add(
      LearnLessonVisualStep(
        id: 'meaning-$ayah',
        type: LearnLessonVisualStepType.meaning,
        title: text('learnLessonMeaningTitleV1'),
        body: translation,
        reference: '$sourceLabel · ${lesson.surah}:$ayah',
      ),
    );

    final explanation = sourcedTranslationFootnote(
      pack: pack,
      surah: lesson.surah,
      ayah: ayah,
    );
    if (explanation != null) {
      steps.add(
        LearnLessonVisualStep(
          id: 'explanation-$ayah',
          type: LearnLessonVisualStepType.explanation,
          title: text('learnLessonExplanationTitleV1'),
          body: explanation.text,
          reference:
              '$sourceLabel · ${explanation.reference}',
        ),
      );
    }
  }

  steps.add(
    LearnLessonVisualStep(
      id: 'review',
      type: LearnLessonVisualStepType.review,
      title: text('learnLessonReviewTitleV1'),
      body: text('learnLessonReviewBodyV1'),
      reference: sourceLabel,
    ),
  );

  final quizSurahs = <int>[
    lesson.surah,
    ...lesson.quizDistractorSurahs,
  ];
  steps.add(
    LearnLessonVisualStep(
      id: 'quiz-surah',
      type: LearnLessonVisualStepType.quiz,
      title: text('learnLessonQuizSurahV1'),
      quizOptions: [
        for (final surah in quizSurahs)
          localizedSurahName(surah, languageCode),
      ],
      correctQuizIndex: 0,
    ),
  );

  steps.addAll(<LearnLessonVisualStep>[
    LearnLessonVisualStep(
      id: 'summary',
      type: LearnLessonVisualStepType.summary,
      title: text('learnLessonSummaryTitleV1'),
      body: text(lesson.summaryBodyKey),
      reference: sourceLabel,
    ),
    LearnLessonVisualStep(
      id: 'completion',
      type: LearnLessonVisualStepType.completion,
      title: text('learnLessonCompletionTitleV1'),
      body: text('learnLessonCompletionBodyV1'),
    ),
  ]);

  return List<LearnLessonVisualStep>.unmodifiable(steps);
}
