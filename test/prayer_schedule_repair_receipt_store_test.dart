import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_repair_receipt_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('round-trips repaired receipt including trigger', () async {
    const store = PrayerScheduleRepairReceiptStore();
    final attemptedAt = DateTime.utc(2026, 9, 22, 3, 30);
    await store.save(PrayerScheduleRepairReceipt(attemptedAt: attemptedAt, outcome: PrayerScheduleRepairOutcome.repaired, trigger: PrayerScheduleRepairTrigger.platformScheduleMissing, configurationFingerprint: 'safe-fingerprint'));
    final restored = await store.load();
    expect(restored, isNotNull);
    expect(restored!.attemptedAt, attemptedAt);
    expect(restored.outcome, PrayerScheduleRepairOutcome.repaired);
    expect(restored.trigger, PrayerScheduleRepairTrigger.platformScheduleMissing);
    expect(restored.configurationFingerprint, 'safe-fingerprint');
  });

  test('receipt written before trigger field remains readable', () {
    final restored = PrayerScheduleRepairReceipt.tryParse(<String, Object?>{
      'attemptedAt': '2026-09-22T03:30:00.000Z',
      'outcome': 'repaired',
      'configurationFingerprint': 'legacy',
    });
    expect(restored?.outcome, PrayerScheduleRepairOutcome.repaired);
    expect(restored?.trigger, PrayerScheduleRepairTrigger.unknown);
  });

  test('unknown future trigger degrades to unknown without losing receipt', () {
    final restored = PrayerScheduleRepairReceipt.tryParse(<String, Object?>{
      'attemptedAt': '2026-09-22T03:30:00.000Z',
      'outcome': 'repaired',
      'trigger': 'newFutureReason',
    });
    expect(restored?.outcome, PrayerScheduleRepairOutcome.repaired);
    expect(restored?.trigger, PrayerScheduleRepairTrigger.unknown);
  });

  test('malformed receipt is ignored instead of becoming trusted evidence', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'prayer_schedule_repair_receipt_v1': '{"attemptedAt":"not-a-date","outcome":"repaired"}'});
    expect(await const PrayerScheduleRepairReceiptStore().load(), isNull);
  });

  test('unknown future outcome is ignored safely', () {
    final parsed = PrayerScheduleRepairReceipt.tryParse(<String, Object?>{'attemptedAt': '2026-09-22T03:30:00.000Z', 'outcome': 'futureOutcome'});
    expect(parsed, isNull);
  });
}
