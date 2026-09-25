import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/dhikr_counter_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dhikr_v2_selected': 'custom_1',
      'dhikr_v2_counts': '{"custom_1":5}',
      'dhikr_v2_targets': '{"custom_1":10}',
      'dhikr_v2_custom': '[{"id":"custom_1","label":"Morning"}]',
      'dhikr_v2_daily_counts': '{"custom_1":2}',
      'dhikr_v2_daily_date': DateTime.now().toIso8601String().substring(0, 10),
    });
  });

  Widget app() => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DhikrCounterScreen(),
      );

  testWidgets('custom dhikr can be renamed and retargeted without losing count', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Morning'), findsWidgets);
    await tester.tap(find.byTooltip('Edit dhikr'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'Evening');
    await tester.enterText(fields.at(1), '25');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Evening'), findsWidgets);
    expect(find.textContaining('Target 25'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('dhikr_v2_custom'), contains('Evening'));
    expect(prefs.getString('dhikr_v2_targets'), contains('"custom_1":25'));
    final countDocument = prefs.getString('dhikr_v2_counts')!;
    expect(countDocument, contains('"custom_1":5'));
  });
}
