import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_preferences_store.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_city_catalog.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';

void main() {
  testWidgets('monthly prayer screen exposes localized calendar export action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MonthlyPrayerTimesScreen(
          city: prayerCities.first,
          settings: const PrayerSettingsSnapshot(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Horaires mensuels des prières'), findsOneWidget);
    expect(
      find.byTooltip(
        'Partager les horaires de prière de ce mois dans un fichier calendrier ICS.',
      ),
      findsOneWidget,
    );
  });
}
