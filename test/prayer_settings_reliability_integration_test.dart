import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_city_catalog.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_notification_diagnostics_sheet.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_settings_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('prayer settings opens the shared reliability diagnostics surface', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: PrayerSettingsScreen(
        city: prayerCities.first,
        initial: const PrayerSettingsSnapshot(notificationsEnabled: true, notificationPrayerIds: {'fajr'}),
      ),
    ));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PrayerSettingsScreen));
    final label = context.l10n.text('notificationDiagnosticsCheck');
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();

    expect(find.byType(PrayerNotificationDiagnosticsSheet), findsOneWidget);
    expect(find.text(context.l10n.text('notificationDiagnosticsTitle')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
