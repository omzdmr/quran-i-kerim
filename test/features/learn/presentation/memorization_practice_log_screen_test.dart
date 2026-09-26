import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_practice_log_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app() => const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          GeneratedAppLocalizations.delegate,
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MemorizationPracticeLogScreen(),
      );

  testWidgets('requires a memorized page before practice can be logged', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Mark at least one page as memorized first.'), findsOneWidget);
    expect(find.text('Save review'), findsNothing);
  });

  testWidgets('logs prayer practice and refreshes review freshness', (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['7'],
      'memorization_page_progress_v1':
          '{"7":{"memorizedAt":"2026-08-01T00:00:00.000"}}',
    });
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('In prayer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save review'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final progress = prefs.getString('memorization_page_progress_v1')!;
    expect(progress, contains('lastReviewedAt'));

    final history = jsonDecode(prefs.getString('memorization_practice_history_v1')!) as List;
    expect(history.length, 1);
    expect((history.single as Map)['page'], 7);
    expect((history.single as Map)['context'], 'prayer');
  });
}
