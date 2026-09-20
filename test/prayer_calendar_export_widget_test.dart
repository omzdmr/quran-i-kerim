import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_preferences_store.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_city_catalog.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';

void main() {
  testWidgets('export explains its scope and can be cancelled without sharing', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate],
      home: MonthlyPrayerTimesScreen(city: prayerCities.first,
        settings: const PrayerSettingsSnapshot()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Share calendar file'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('sunrise is excluded'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
