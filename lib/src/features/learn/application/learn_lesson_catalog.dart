class LearnLessonDefinition {
  const LearnLessonDefinition({
    required this.id,
    required this.surah,
    required this.ayahs,
    required this.titleKey,
    required this.subtitleKey,
    required this.introBodyKey,
    required this.summaryBodyKey,
    required this.quizDistractorSurahs,
  });

  final String id;
  final int surah;
  final List<int> ayahs;
  final String titleKey;
  final String subtitleKey;
  final String introBodyKey;
  final String summaryBodyKey;
  final List<int> quizDistractorSurahs;

  int get firstAyah => ayahs.first;
}

const LearnLessonDefinition inshirahEaseLesson = LearnLessonDefinition(
  id: 'inshirah-94-5-6-v1',
  surah: 94,
  ayahs: <int>[5, 6],
  titleKey: 'learnLessonEaseTitleV1',
  subtitleKey: 'learnLessonEaseSubtitleV1',
  introBodyKey: 'learnLessonEaseIntroBodyV1',
  summaryBodyKey: 'learnLessonEaseSummaryBodyV1',
  quizDistractorSurahs: <int>[93, 95],
);

const List<LearnLessonDefinition> curatedLearnLessons = <LearnLessonDefinition>[
  inshirahEaseLesson,
];
