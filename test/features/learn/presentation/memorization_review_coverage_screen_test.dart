import 'dart:ui' show SemanticsAction;

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

  testWidgets('shows attention pages first and can reveal all coverage', (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['2', '1', '3'],
      'memorization_page_progress_v1':
          '{"1":{"memorizedAt":"2026-08-01T00:00:00.000"},'
          '"2":{"memorizedAt":"2026-08-01T00:00:00.000",'
          '"lastReviewedAt":"2020-01-01T00:00:00.000",'
          '"selfAssessment":"assisted"},'
          '"3":{"memorizedAt":"2026-08-01T00:00:00.000",'
          '"lastReviewedAt":"2099-01-01T00:00:00.000",'
          '"selfAssessment":"independent"}}',
    });

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.new_releases_outlined), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsWidgets);

    await tester.tap(find.byType(ChoiceChip).last);
    await tester.pump();

    expect(find.textContaining('3'), findsWidgets);
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
