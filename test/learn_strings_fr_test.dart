import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/learn_strings.dart';
import 'package:quran_i_kerim/src/l10n/strings/learn_strings_fr.dart';

void main() {
  test('French Learn lesson strings match the canonical key set', () {
    expect(learnStringsFr.keys.toSet(), learnStrings['en']!.keys.toSet());
    expect(learnStringsFr.values.every((value) => value.trim().isNotEmpty), isTrue);
  });

  test('French Learn dynamic verse label preserves its placeholder', () {
    expect(learnStringsFr['learnLessonVerseTitleV1'], contains('{ayah}'));
  });

  test('French Learn copy keeps Quran lesson terminology explicit', () {
    expect(learnStringsFr['learnLessonCompletionBodyV1'], contains('Coran'));
    expect(learnStringsFr['learnLessonMeaningTitleV1'], contains('Traduction'));
  });
}
