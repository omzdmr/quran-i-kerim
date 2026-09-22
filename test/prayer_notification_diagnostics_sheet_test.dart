import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_self_test_store.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_notification_diagnostics_sheet.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Widget app() => const MaterialApp(
    locale: Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    home: Scaffold(body: PrayerNotificationDiagnosticsSheet(notificationsEnabled: true)),
  );

  testWidgets('diagnostics sheet resolves safely in widget-test environment', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(PrayerNotificationDiagnosticsSheet));
    expect(find.text(context.l10n.text('notificationDiagnosticsTitle')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('month-old received probe is not presented as current proof', (tester) async {
    await const PrayerNotificationSelfTestStore().save(
      PrayerNotificationProbeOutcome.received,
      now: DateTime.now().subtract(const Duration(days: 31)),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.textContaining('Old test'), findsOneWidget);
    expect(find.textContaining('Yes, it arrived'), findsNothing);
  });
}
