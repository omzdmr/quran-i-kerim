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
    required this.quizCorrectOptionIndex,
  }) : assert(quizCorrectOptionIndex >= 0),
       assert(quizCorrectOptionIndex <= quizDistractorSurahs.length);

  final String id;
  final int surah;
  final List<int> ayahs;
  final String titleKey;
  final String subtitleKey;
  final String introBodyKey;
  final String summaryBodyKey;
  final List<int> quizDistractorSurahs;
  final int quizCorrectOptionIndex;

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
  quizCorrectOptionIndex: 1,
);

const LearnLessonDefinition asrLesson = LearnLessonDefinition(
  id: 'asr-103-1-3-v1',
  surah: 103,
  ayahs: <int>[1, 2, 3],
  titleKey: 'learnLessonAsrTitleV1',
  subtitleKey: 'learnLessonAsrSubtitleV1',
  introBodyKey: 'learnLessonAsrIntroBodyV1',
  summaryBodyKey: 'learnLessonAsrSummaryBodyV1',
  quizDistractorSurahs: <int>[102, 104],
  quizCorrectOptionIndex: 2,
);

const LearnLessonDefinition ikhlasLesson = LearnLessonDefinition(
  id: 'ikhlas-112-1-4-v1',
  surah: 112,
  ayahs: <int>[1, 2, 3, 4],
  titleKey: 'learnLessonIkhlasTitleV1',
  subtitleKey: 'learnLessonIkhlasSubtitleV1',
  introBodyKey: 'learnLessonIkhlasIntroBodyV1',
  summaryBodyKey: 'learnLessonIkhlasSummaryBodyV1',
  quizDistractorSurahs: <int>[111, 113],
  quizCorrectOptionIndex: 0,
);

const List<LearnLessonDefinition> curatedLearnLessons = <LearnLessonDefinition>[
  inshirahEaseLesson,
  asrLesson,
  ikhlasLesson,
];
