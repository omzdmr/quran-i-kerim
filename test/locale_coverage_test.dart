import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/locale_coverage.dart';

void main() {
  test('coverage follows the full-app locale metadata set', () {
    final coverage = buildLocaleCoverage(<String, Map<String, String>>{
      'tr': <String, String>{'title': 'Başlık', 'body': 'Metin'},
      'en': <String, String>{'title': 'Title', 'body': 'Body'},
      'ar': <String, String>{'title': 'العنوان', 'body': 'النص'},
      'az': <String, String>{'title': 'Başlıq', 'body': 'Mətn'},
      'ru': <String, String>{'title': 'Заголовок', 'body': 'Текст'},
      'fr': <String, String>{'title': 'Titre', 'body': 'Texte'},
    });

    expect(
      coverage.map((entry) => entry.languageCode).toList(),
      <String>['tr', 'en', 'ar', 'az', 'ru', 'fr'],
    );
    expect(coverage.every((entry) => entry.hasFullKeyCoverage), isTrue);
  });

  test('missing and blank translations reduce coverage without counting extras', () {
    final coverage = buildLocaleCoverage(<String, Map<String, String>>{
      'en': <String, String>{'title': 'Title', 'body': 'Body'},
      'fr': <String, String>{
        'title': 'Titre',
        'body': '   ',
        'unexpected': 'Ne compte pas',
      },
    });

    final french = coverage.singleWhere((entry) => entry.languageCode == 'fr');
    expect(french.translatedKeys, 1);
    expect(french.totalKeys, 2);
    expect(french.ratio, 0.5);
    expect(french.hasFullKeyCoverage, isFalse);
    expect(french.releaseReady, isFalse);
  });

  test('French stays blocked from release-ready until human review is complete', () {
    final coverage = buildLocaleCoverage(<String, Map<String, String>>{
      'en': <String, String>{'title': 'Title'},
      'fr': <String, String>{'title': 'Titre'},
    });

    final french = coverage.singleWhere((entry) => entry.languageCode == 'fr');
    expect(french.hasFullKeyCoverage, isTrue);
    expect(french.humanReviewRequired, isTrue);
    expect(french.releaseReady, isFalse);
  });

  test('missing reference locale is rejected explicitly', () {
    expect(
      () => buildLocaleCoverage(
        <String, Map<String, String>>{'fr': <String, String>{'title': 'Titre'}},
      ),
      throwsArgumentError,
    );
  });
}
