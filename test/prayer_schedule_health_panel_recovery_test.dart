import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_schedule_health_refresher.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_schedule_health_store.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_repair_receipt_store.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_schedule_health_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SuccessfulRefresher extends PrayerNotificationScheduleHealthRefresher {
  const _SuccessfulRefresher();
  @override
  Future<PrayerNotificationScheduleHealth?> resync({DateTime? now}) async => PrayerNotificationScheduleHealth(
    scheduledAt: now ?? DateTime.now(), nextPrayerId: 'dhuhr', nextScheduledAt: (now ?? DateTime.now()).add(const Duration(hours: 1)),
    timeZoneId: 'Asia/Shanghai', locationLabel: 'Shanghai', calculationMethodId: 'muslimWorldLeague', pendingCount: 8, configurationFingerprint: 'fresh',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('successful manual recovery removes obsolete automatic failure receipt', (tester) async {
    const receiptStore = PrayerScheduleRepairReceiptStore();
    await receiptStore.save(PrayerScheduleRepairReceipt(attemptedAt: DateTime.now(), outcome: PrayerScheduleRepairOutcome.failed, trigger: PrayerScheduleRepairTrigger.platformScheduleMissing, configurationFingerprint: 'same'));

    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: PrayerScheduleHealthPanel(refresher: _SuccessfulRefresher())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Automatic check'), findsOneWidget);
    expect(find.textContaining('could not finish'), findsOneWidget);

    await tester.tap(find.text('Resync notifications'));
    await tester.pumpAndSettle();

    expect(await receiptStore.load(), isNull);
    expect(find.text('Automatic check'), findsNothing);
  });
}
