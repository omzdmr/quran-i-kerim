import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/dhikr_history_screen.dart';
import 'package:quran_i_kerim/src/features/discover/dhikr_history_store.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';

void main() {
  testWidgets('history shows archived breakdown and accessible daily total', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DhikrHistoryScreen(
          records: <DhikrDailyHistoryRecord>[
            DhikrDailyHistoryRecord(
              dateKey: '2026-09-25',
              counts: <String, int>{'subhanallah': 33, 'custom_1': 7},
              customLabels: <String, String>{'custom_1': 'Kendi zikrim'},
            ),
          ],
        ),
      ),
    );

    expect(find.text('Zikir geçmişi'), findsOneWidget);
    expect(find.text('Sübhanallah'), findsOneWidget);
    expect(find.text('Kendi zikrim'), findsOneWidget);
    expect(find.text('Günlük toplam: 40'), findsOneWidget);
    expect(
      find.bySemanticsLabel('2026-09-25, Günlük toplam 40'),
      findsOneWidget,
    );
  });

  testWidgets('empty history explains that no archived day exists', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DhikrHistoryScreen(records: <DhikrDailyHistoryRecord>[]),
      ),
    );

    expect(find.text('There are no saved dhikr days yet.'), findsOneWidget);
  });
}
