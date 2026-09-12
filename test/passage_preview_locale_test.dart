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

  test('passage preview never falls back to bundled Turkish source', () {
    final source = File(
      'lib/src/features/reader/passage_preview_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('return bundledTurkishTranslationId;')));
    expect(source, contains('return settings.selectedQuranSourceId;'));
  });

  test('passage preview stays on centralized localization', () {
    final legacy = File(
      'lib/src/l10n/strings/passage_preview_strings.dart',
    );
    final source = File(
      'lib/src/features/reader/passage_preview_screen.dart',
    ).readAsStringSync();

    expect(legacy.existsSync(), isFalse);
    expect(source, contains('context.l10n.invalidPassage'));
    expect(source, contains('context.l10n.passageTitle'));
    expect(source, contains('context.l10n.passageReadFullSurah'));
    expect(source, contains('context.l10n.passageTextSource'));
    expect(source, contains('context.l10n.passageUnavailable'));
  });
}
