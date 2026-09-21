import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/quran/quran_learn_overview.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';

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
        home: Scaffold(body: QuranLearnOverview()),
      );

  Future<void> openMemorize(WidgetTester tester) async {
    final context = tester.element(find.byType(QuranLearnOverview));
    final l10n = GeneratedAppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.quranLearnMemorize));
    await tester.pumpAndSettle();
  }

  testWidgets('memorize tab surfaces review attention count', (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['1', '2', '3'],
      'memorization_page_progress_v1':
          '{"1":{"memorizedAt":"2026-01-01T00:00:00.000"},'
          '"2":{"memorizedAt":"2026-01-01T00:00:00.000",'
          '"lastReviewedAt":"2020-01-01T00:00:00.000"},'
          '"3":{"memorizedAt":"2026-01-01T00:00:00.000",'
          '"lastReviewedAt":"2099-01-01T00:00:00.000"}}',
    });

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openMemorize(tester);

    expect(find.textContaining('(2)'), findsOneWidget);
    expect(find.byIcon(Icons.history_toggle_off_rounded), findsOneWidget);
  });

  testWidgets('review count refreshes after returning from coverage', (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['7'],
      'memorization_page_progress_v1':
          '{"7":{"memorizedAt":"2026-01-01T00:00:00.000"}}',
    });

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openMemorize(tester);
    expect(find.textContaining('(1)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.history_toggle_off_rounded));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'memorization_page_progress_v1',
      '{"7":{"memorizedAt":"2026-01-01T00:00:00.000",'
      '"lastReviewedAt":"2099-01-01T00:00:00.000",'
      '"selfAssessment":"independent"}}',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.textContaining('(1)'), findsNothing);
    expect(find.byIcon(Icons.history_toggle_off_rounded), findsOneWidget);
  });
}
