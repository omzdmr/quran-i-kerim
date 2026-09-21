import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_review_coverage_screen.dart';
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
        home: MemorizationReviewCoverageScreen(),
      );

  testWidgets('shows memorized pages ordered by review attention', (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['2', '1'],
      'memorization_page_progress_v1':
          '{"1":{"memorizedAt":"2026-08-01T00:00:00.000"},'
          '"2":{"memorizedAt":"2026-08-01T00:00:00.000",'
          '"lastReviewedAt":"2020-01-01T00:00:00.000",'
          '"selfAssessment":"assisted"}}',
    });

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.textContaining('1'), findsWidgets);
    expect(find.textContaining('2'), findsWidgets);
    expect(find.byIcon(Icons.new_releases_outlined), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('has tappable semantics for review page rows', (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['5'],
      'memorization_page_progress_v1':
          '{"5":{"memorizedAt":"2026-08-01T00:00:00.000"}}',
    });

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final semantics = tester.getSemantics(find.byType(ListTile));
    expect(semantics.hasAction(SemanticsAction.tap), isTrue);
    expect(semantics.label, contains('5'));
  });
}
