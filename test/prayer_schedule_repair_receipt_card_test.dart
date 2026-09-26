import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_repair_receipt_store.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_schedule_repair_receipt_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> seed(PrayerScheduleRepairOutcome outcome, DateTime at, {PrayerScheduleRepairTrigger trigger = PrayerScheduleRepairTrigger.unknown}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await const PrayerScheduleRepairReceiptStore().save(PrayerScheduleRepairReceipt(attemptedAt: at, outcome: outcome, trigger: trigger));
  }

  testWidgets('explains a recent automatic repair and its reason in Turkish', (tester) async {
    final now = DateTime.utc(2026, 9, 22, 4);
    await seed(PrayerScheduleRepairOutcome.repaired, now.subtract(const Duration(minutes: 5)), trigger: PrayerScheduleRepairTrigger.configurationChanged);
    await tester.pumpWidget(MaterialApp(locale: const Locale('tr'), home: Scaffold(body: PrayerScheduleRepairReceiptCard(now: now))));
    await tester.pumpAndSettle();
    expect(find.text('Otomatik kontrol'), findsOneWidget);
    expect(find.textContaining('otomatik olarak yenilendi'), findsOneWidget);
    expect(find.textContaining('Konum, dil veya namaz ayarları'), findsOneWidget);
  });

  testWidgets('does not present week-old repair as current diagnostics', (tester) async {
    final now = DateTime.utc(2026, 9, 22, 4);
    await seed(PrayerScheduleRepairOutcome.repaired, now.subtract(const Duration(days: 8)));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PrayerScheduleRepairReceiptCard(now: now))));
    await tester.pumpAndSettle();
    expect(find.text('Automatic check'), findsNothing);
  });

  testWidgets('failed repair gives a recovery path without claiming success', (tester) async {
    final now = DateTime.utc(2026, 9, 22, 4);
    await seed(PrayerScheduleRepairOutcome.failed, now);
    await tester.pumpWidget(MaterialApp(locale: const Locale('en'), home: Scaffold(body: PrayerScheduleRepairReceiptCard(now: now))));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not finish'), findsOneWidget);
    expect(find.textContaining('current'), findsNothing);
  });

  testWidgets('updates while diagnostics is open when lifecycle repair writes a new receipt', (tester) async {
    final now = DateTime.utc(2026, 9, 22, 4);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PrayerScheduleRepairReceiptCard(now: now))));
    await tester.pumpAndSettle();
    expect(find.text('Automatic check'), findsNothing);

    await const PrayerScheduleRepairReceiptStore().save(PrayerScheduleRepairReceipt(
      attemptedAt: now,
      outcome: PrayerScheduleRepairOutcome.repaired,
      trigger: PrayerScheduleRepairTrigger.platformScheduleMissing,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Automatic check'), findsOneWidget);
    expect(find.textContaining('missing from the device'), findsOneWidget);
  });
}
