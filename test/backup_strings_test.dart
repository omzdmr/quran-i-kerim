import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/backup_strings.dart';

void main() {
  test('backup strings keep the same key set in every supported language', () {
    const languages = <String>['tr', 'en', 'ar', 'az', 'ru', 'fr'];
    final expected = backupStrings['en']!.keys.toSet();

    for (final language in languages) {
      expect(
        backupStrings[language]!.keys.toSet(),
        expected,
        reason: 'backup localization keys differ for $language',
      );
      expect(
        backupStrings[language]!.values.every((value) => value.trim().isNotEmpty),
        isTrue,
        reason: 'backup localization contains an empty value for $language',
      );
    }
  });

  test('French backup strings preserve dynamic placeholders', () {
    final fr = backupStrings['fr']!;
    expect(fr['backupVersionLabel'], contains('{version}'));
    expect(fr['backupRecordCount'], contains('{count}'));
    expect(fr['backupCloudConnectedAs'], contains('{account}'));
    expect(fr['backupCloudUpdatedAt'], contains('{date}'));
  });
}
