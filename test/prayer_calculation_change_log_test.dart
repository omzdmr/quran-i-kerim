import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_calculation_change_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('records and restores latest material calculation change', () async {
    final changedAt = DateTime.utc(2026, 9, 21, 12, 15);
    await PrayerCalculationChangeLog.record(
      PrayerCalculationMaterialChange(
        kind: PrayerCalculationChangeKind.manualOffset,
        changedAt: changedAt,
        prayerId: 'fajr',
        previousValue: '0',
        currentValue: '-2',
      ),
    );

    final restored = await PrayerCalculationChangeLog.load();
    expect(restored, isNotNull);
    expect(restored!.kind, PrayerCalculationChangeKind.manualOffset);
    expect(restored.prayerId, 'fajr');
    expect(restored.previousValue, '0');
    expect(restored.currentValue, '-2');
    expect(restored.changedAt, changedAt);
  });

  test('new material change replaces the previous latest change', () async {
    await PrayerCalculationChangeLog.record(
      PrayerCalculationMaterialChange(
        kind: PrayerCalculationChangeKind.place,
        changedAt: DateTime.utc(2026, 9, 21, 10),
        previousValue: 'Ankara',
        currentValue: 'Istanbul',
      ),
    );
    await PrayerCalculationChangeLog.record(
      PrayerCalculationMaterialChange(
        kind: PrayerCalculationChangeKind.calculationMethod,
        changedAt: DateTime.utc(2026, 9, 21, 11),
        previousValue: 'turkiye',
        currentValue: 'muslimWorldLeague',
      ),
    );

    final restored = await PrayerCalculationChangeLog.load();
    expect(restored!.kind, PrayerCalculationChangeKind.calculationMethod);
    expect(restored.previousValue, 'turkiye');
    expect(restored.currentValue, 'muslimWorldLeague');
  });

  test('corrupt persisted payload fails closed instead of crashing', () async {
    SharedPreferences.setMockInitialValues({
      'prayer_calculation_latest_material_change_v1': '{broken-json',
    });

    expect(await PrayerCalculationChangeLog.load(), isNull);
  });

  test('clear removes stored change', () async {
    await PrayerCalculationChangeLog.record(
      PrayerCalculationMaterialChange(
        kind: PrayerCalculationChangeKind.timezone,
        changedAt: DateTime.utc(2026, 9, 21),
        previousValue: 'Europe/Istanbul',
        currentValue: 'Asia/Shanghai',
      ),
    );
    await PrayerCalculationChangeLog.clear();
    expect(await PrayerCalculationChangeLog.load(), isNull);
  });
}
