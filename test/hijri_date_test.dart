import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/hijri_date.dart';

void main() {
  test('converts known Ramadan 1445 boundary locally', () {
    final hijri = PrayerHijriDate.fromGregorian(DateTime(2024, 3, 11));
    expect(hijri.year, 1445);
    expect(hijri.month, 9);
    expect(hijri.day, 1);
  });

  test('applies user Hijri day offset', () {
    final hijri = PrayerHijriDate.fromGregorian(
      DateTime(2024, 3, 11),
      offsetDays: 1,
    );
    expect(hijri.year, 1445);
    expect(hijri.month, 9);
    expect(hijri.day, 2);
  });
}
