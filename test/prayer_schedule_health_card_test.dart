import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_schedule_health_store.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_schedule_health_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = PrayerNotificationScheduleHealthStore();
  final now = DateTime.utc(2026, 9, 22, 3);

  Widget app({Locale locale = const Locale('tr'), required Future<void> Function() onResync}) => MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('tr'), Locale('en'), Locale('fr'), Locale('ar'), Locale('az'), Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(body: PrayerScheduleHealthCard(now: now, onResync: onResync)),
      );

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('stale or missing evidence never claims notifications are healthy', (tester) async {
    var resyncs = 0;
    await tester.pumpWidget(app(onResync: () async => resyncs++));
    await tester.pumpAndSettle();
    expect(find.textContaining('eski veya doğrulanamıyor'), findsOneWidget);
    expect(find.text('Bildirimleri yeniden eşitle'), findsOneWidget);
    await tester.tap(find.text('Bildirimleri yeniden eşitle'));
    await tester.pumpAndSettle();
    expect(resyncs, 1);
  });

  testWidgets('legacy schedule is identified instead of silently trusted', (tester) async {
    await store.save(PrayerNotificationScheduleHealth(
      scheduledAt: DateTime.utc(2026, 9, 22, 2),
      nextPrayerId: 'dhuhr',
      nextScheduledAt: DateTime.utc(2026, 9, 22, 4, 30),
      timeZoneId: 'Asia/Shanghai',
      locationLabel: 'Shanghai',
      calculationMethodId: 'muslimWorldLeague',
      pendingCount: 42,
    ));
    await tester.pumpWidget(app(onResync: () async {}));
    await tester.pumpAndSettle();
    expect(find.textContaining('eski sürümden kaldı'), findsOneWidget);
    expect(find.textContaining('Öğle'), findsOneWidget);
    expect(find.textContaining('Shanghai'), findsOneWidget);
    expect(find.textContaining('Asia/Shanghai'), findsOneWidget);
    expect(find.textContaining('muslimWorldLeague'), findsOneWidget);
    expect(find.text('Bildirimleri yeniden eşitle'), findsOneWidget);
  });

  test('all product locales have complete stale/configuration copy', () {
    for (final code in const ['tr', 'en', 'fr', 'ar', 'az', 'ru']) {
      final copy = PrayerScheduleHealthCopy.forLocale(Locale(code));
      expect(copy.title, isNotEmpty, reason: code);
      expect(copy.needsResync, isNotEmpty, reason: code);
      expect(copy.configurationChanged, isNotEmpty, reason: code);
      expect(copy.legacySchedule, isNotEmpty, reason: code);
      expect(copy.updated, isNotEmpty, reason: code);
      expect(copy.resync, isNotEmpty, reason: code);
      for (final id in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        expect(copy.prayerName(id), isNot(id), reason: '$code/$id');
      }
    }
  });
}
