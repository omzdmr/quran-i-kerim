import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/prayer_notification_diagnostics_strings.dart';

void main() {
  test('notification diagnostic strings have parity in every locale', () {
    final expected =
        prayerNotificationDiagnosticsStrings['tr']!.keys.toSet();

    expect(
      prayerNotificationDiagnosticsStrings.keys,
      containsAll(<String>['tr', 'en', 'ar', 'az', 'ru', 'fr']),
    );

    for (final entry in prayerNotificationDiagnosticsStrings.entries) {
      expect(entry.value.keys.toSet(), expected, reason: entry.key);
      for (final value in entry.value.values) {
        expect(value.trim(), isNotEmpty, reason: entry.key);
      }
    }
  });
}
