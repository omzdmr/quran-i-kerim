import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home prayer duration copy uses generated localization only', () {
    final source = File(
      'lib/src/features/home/home_prayer_card.dart',
    ).readAsStringSync();

    expect(source, contains('GeneratedAppLocalizations.of(context)!'));
    expect(source, contains('l10n.homePrayerHourShort'));
    expect(source, contains('l10n.homePrayerMinuteShort'));
    expect(source, contains('generatedL10n.remaining'));
    expect(source, isNot(contains('home_prayer_strings.dart')));
    expect(source, isNot(contains("l10n.text('remaining')")));
    expect(
      File('lib/src/l10n/strings/home_prayer_strings.dart').existsSync(),
      isFalse,
    );
  });
}
