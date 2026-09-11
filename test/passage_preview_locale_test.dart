import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('passage preview resolves surah names from app locale', () {
    final source = File(
      'lib/src/features/reader/passage_preview_screen.dart',
    ).readAsStringSync();

    expect(source, contains('localizedSurahName('));
    expect(source, contains('context.l10n.locale.languageCode'));
    expect(
      source,
      isNot(contains('Localizations.localeOf(context).languageCode')),
    );
  });
}
