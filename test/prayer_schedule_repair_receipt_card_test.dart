import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_modern/src/features/prayer/application/prayer_schedule_repair_receipt_store.dart';
import 'package:quran_modern/src/features/prayer/presentation/prayer_schedule_repair_receipt_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> seed(PrayerScheduleRepairOutcome outcome, DateTime at) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await const PrayerScheduleRepairReceiptStore().save(
      PrayerScheduleRepairReceipt(attemptedAt: at, outcome: outcome),
    );
  }

  testWidgets('explains a recent automatic repair in Turkish', (tester) async {
    final now = DateTime.utc(2026, 9, 22, 4);
    await seed(PrayerScheduleRepairOutcome.repaired, now.subtract(const Duration(minutes: 5)));

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      home: Scaffold(body: PrayerScheduleRepairReceiptCard(now: now)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Otomatik kontrol'), findsOneWidget);
    expect(find.textContaining('otomatik olarak yenilendi'), findsOneWidget);
  });

  testWidgets('does not present week-old repair as current diagnostics', (tester) async {
    final now = DateTime.utc(2026, 9, 22, 4);
    await seed(PrayerScheduleRepairOutcome.repaired, now.subtract(const Duration(days: 8)));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PrayerScheduleRepairReceiptCard(now: now)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Automatic check'), findsNothing);
  });

  testWidgets('failed repair gives a recovery path without claiming success', (tester) async {
    final now = DateTime.utc(2026, 9, 22, 4);
    await seed(PrayerScheduleRepairOutcome.failed, now);

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      home: Scaffold(body: PrayerScheduleRepairReceiptCard(now: now)),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('could not finish'), findsOneWidget);
    expect(find.textContaining('current'), findsNothing);
  });
}
