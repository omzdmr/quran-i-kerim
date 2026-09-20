import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/plan_strings.dart';

void main() {
  test('plan strings keep the same non-empty key set in every locale', () {
    final expected = planStrings['tr']!.keys.toSet();
    expect(
      planStrings.keys,
      containsAll(<String>['tr', 'en', 'ar', 'az', 'ru', 'fr']),
    );

    for (final entry in planStrings.entries) {
      expect(entry.value.keys.toSet(), expected, reason: entry.key);
      for (final value in entry.value.values) {
        expect(value.trim(), isNotEmpty, reason: entry.key);
      }
    }
  });

  test('French plan strings preserve runtime placeholders', () {
    final french = planStrings['fr']!;
    expect(french['plansDayProgressV1'], contains('{day}'));
    expect(french['plansDayProgressV1'], contains('{total}'));
    expect(french['plansPagesV1'], contains('{start}'));
    expect(french['plansPagesV1'], contains('{end}'));
    expect(french['plansProgressV1'], contains('{done}'));
    expect(french['plansProgressV1'], contains('{total}'));
    expect(french['plansCompletedOnV1'], contains('{date}'));
    expect(french['plansScheduleBehindV1'], contains('{count}'));
    expect(french['plansScheduleAheadV1'], contains('{count}'));
    expect(french['plansScheduleDayV1'], contains('{day}'));
    expect(french['plansScheduleDayV1'], contains('{total}'));
    expect(french['plansScheduledEndV1'], contains('{date}'));
  });
}
