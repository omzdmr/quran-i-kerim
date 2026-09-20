import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('passage preview resolves surah names from app locale', () {
    final source = File(
      'lib/src/features/reader/passage_preview_screen.dart',
    ).readAsStringSync();

    expect(source, contains('GeneratedAppLocalizations.of(context)!.localeName'));
    expect(
      source,
      isNot(contains('Localizations.localeOf(context).languageCode')),
    );
  });

  test('passage preview never falls back to bundled Turkish source', () {
    final source = File(
      'lib/src/features/reader/passage_preview_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('return bundledTurkishTranslationId;')));
    expect(source, contains('return settings.selectedQuranSourceId;'));
  });

  test('passage preview stays on generated ARB localization', () {
    final legacy = File(
      'lib/src/l10n/strings/passage_preview_strings.dart',
    );
    final source = File(
      'lib/src/features/reader/passage_preview_screen.dart',
    ).readAsStringSync();

    expect(legacy.existsSync(), isFalse);
    expect(source, contains('GeneratedAppLocalizations.of(context)!'));
    expect(source, contains('l10n.invalidPassage'));
    expect(source, contains('l10n.passageTitle'));
    expect(source, contains('l10n.passageReadFullSurah'));
    expect(source, contains('l10n.passageTextSource'));
    expect(source, contains('l10n.passageUnavailable'));
    expect(source, isNot(contains('context.l10n.')));
  });
}
