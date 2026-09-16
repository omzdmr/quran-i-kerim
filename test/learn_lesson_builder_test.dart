import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_pack.dart';
import 'package:quran_i_kerim/src/features/learn/application/learn_lesson_builder.dart';
import 'package:quran_i_kerim/src/features/learn/application/learn_lesson_catalog.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/lesson_visual_flow.dart';
import 'package:quran_i_kerim/src/l10n/strings/learn_strings.dart';

void main() {
  const verse5 = '  Provider translation stays exactly as supplied.  ';
  const footnote5 = ' Provider footnote is not paraphrased. ';

  TranslationPack pack({Map<String, String> footnotes = const <String, String>{}}) =>
      TranslationPack(
        translationId: 'turkish_rwwad',
        languageCode: 'tr',
        version: 'test-version',
        source: 'QuranEnc.com',
        verses: const <String, String>{
          '94:5': verse5,
          '94:6': 'Second provider translation.',
        },
        footnotes: footnotes,
      );

  test('builder preserves provider translation and footnote text verbatim', () {
    final steps = buildSourcedLearnLessonSteps(
      lesson: inshirahEaseLesson,
      pack: pack(footnotes: const <String, String>{'94:5': footnote5}),
      languageCode: 'tr',
      text: (key) => learnText('tr', key),
    );

    final meaning = steps.singleWhere((step) => step.id == 'meaning-5');
    final explanation = steps.singleWhere((step) => step.id == 'explanation-5');

    expect(meaning.body, verse5);
    expect(explanation.body, footnote5);
    expect(explanation.reference, contains('QuranEnc.com'));
    expect(explanation.reference, contains('vtest-version'));
  });

  test('builder omits explanation and hadith when no sourced content exists', () {
    final steps = buildSourcedLearnLessonSteps(
      lesson: inshirahEaseLesson,
      pack: pack(),
      languageCode: 'tr',
      text: (key) => learnText('tr', key),
    );

    expect(
      steps.where((step) => step.type == LearnLessonVisualStepType.explanation),
      isEmpty,
    );
    expect(
      steps.where((step) => step.type == LearnLessonVisualStepType.hadith),
      isEmpty,
    );
    expect(steps.map((step) => step.id), containsAll(<String>[
      'intro',
      'verse-5',
      'meaning-5',
      'verse-6',
      'meaning-6',
      'review',
      'quiz-surah',
      'summary',
      'completion',
    ]));
  });
}
