import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const guardedFiles = <String>[
    'lib/src/features/home/home_screen.dart',
    'lib/src/features/home/home_prayer_card.dart',
    'lib/src/features/reader/passage_preview_screen.dart',
    'lib/src/features/reader/reader_note_sheet.dart',
    'lib/src/features/reader/reader_media_session.dart',
    'lib/src/features/reader/reader_mixed_verse_list.dart',
    'lib/src/features/prayer/application/prayer_notification_service.dart',
  ];

  const allowedLiteralsByFile = <String, Set<String>>{
    'lib/src/features/reader/passage_preview_screen.dart': {
      'Tanzil.net · CC BY 3.0',
    },
    'lib/src/features/reader/reader_note_sheet.dart': {
      r'$reference · $sourceCode',
    },
  };

  final directTextLiteral = RegExp(
    r'''\bText\(\s*(['"])(?!\$)([^'"\n]+)\1''',
    multiLine: true,
  );
  final directTooltipLiteral = RegExp(
    r'''\btooltip\s*:\s*(['"])(?!\$)([^'"\n]+)\1''',
    multiLine: true,
  );

  test('migrated localization surfaces do not regain direct UI literals', () {
    for (final path in guardedFiles) {
      final source = File(path).readAsStringSync();
      final allowed = allowedLiteralsByFile[path] ?? const <String>{};
      final findings = <String>{};

      for (final pattern in [directTextLiteral, directTooltipLiteral]) {
        for (final match in pattern.allMatches(source)) {
          final value = match.group(2)!.trim();
          if (value.isNotEmpty && !allowed.contains(value)) {
            findings.add(value);
          }
        }
      }

      expect(
        findings,
        isEmpty,
        reason:
            '$path contains direct user-visible literals. Add copy to '
            'AppLocalizations/feature strings instead. Only non-localizable '
            'technical/source labels belong in the per-file whitelist.',
      );
    }
  });
}
