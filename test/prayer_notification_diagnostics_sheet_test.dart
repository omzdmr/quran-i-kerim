import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_notification_diagnostics_sheet.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('diagnostics sheet resolves safely in widget-test environment',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: PrayerNotificationDiagnosticsSheet(
            notificationsEnabled: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PrayerNotificationDiagnosticsSheet));
    final l10n = context.l10n;
    expect(find.text(l10n.text('notificationDiagnosticsTitle')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
