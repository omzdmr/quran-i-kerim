import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_schedule_health_store.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_city_catalog.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_notification_diagnostics_sheet.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_settings_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  MaterialApp app(Widget home) => MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    home: home,
  );

  testWidgets('prayer settings opens the shared reliability diagnostics surface', (tester) async {
    await tester.pumpWidget(app(PrayerSettingsScreen(
      city: prayerCities.first,
      initial: const PrayerSettingsSnapshot(notificationsEnabled: true, notificationPrayerIds: {'fajr'}),
    )));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(PrayerSettingsScreen));
    await tester.tap(find.text(context.l10n.text('notificationDiagnosticsCheck')));
    await tester.pumpAndSettle();
    expect(find.byType(PrayerNotificationDiagnosticsSheet), findsOneWidget);
    expect(find.text(context.l10n.text('notificationDiagnosticsTitle')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving disabled reminders clears stale schedule health evidence', (tester) async {
    const healthStore = PrayerNotificationScheduleHealthStore();
    await healthStore.save(PrayerNotificationScheduleHealth(
      scheduledAt: DateTime.utc(2026, 9, 22, 2), nextPrayerId: 'dhuhr', nextScheduledAt: DateTime.utc(2026, 9, 22, 4),
      timeZoneId: 'Europe/Istanbul', locationLabel: 'Istanbul', calculationMethodId: 'turkiye', pendingCount: 8, configurationFingerprint: 'old',
    ));

    await tester.pumpWidget(app(Builder(builder: (context) => Center(child: ElevatedButton(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PrayerSettingsScreen(city: prayerCities.first, initial: const PrayerSettingsSnapshot(notificationsEnabled: false)))),
      child: const Text('open'),
    )))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final settingsContext = tester.element(find.byType(PrayerSettingsScreen));
    await tester.tap(find.text(settingsContext.l10n.save));
    await tester.pumpAndSettle();

    expect(await healthStore.load(), isNull);
    expect(find.text('open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
