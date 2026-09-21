import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_session.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_coverage_review_session_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(MemorizationReviewSession session) => MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GeneratedAppLocalizations.delegate,
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MemorizationCoverageReviewSessionScreen(session: session),
      );

  testWidgets('assessment advances to the next coverage page and persists review',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['1', '2'],
      'memorization_page_progress_v1':
          '{"1":{"memorizedAt":"2026-01-01T00:00:00.000"},'
          '"2":{"memorizedAt":"2026-01-01T00:00:00.000"}}',
    });
    const session = MemorizationReviewSession(
      pages: <int>[1, 2],
      totalAttentionPages: 2,
    );

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);
    expect(find.textContaining('1'), findsWidgets);

    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_circle_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('memorization_page_progress_v1')!;
    expect(raw, contains('"1"'));
    expect(raw, contains('lastReviewedAt'));
    expect(raw, contains('independent'));
  });

  testWidgets('leaving study without assessment does not mutate review state',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['3'],
      'memorization_page_progress_v1':
          '{"3":{"memorizedAt":"2026-01-01T00:00:00.000"}}',
    });
    const session = MemorizationReviewSession(
      pages: <int>[3],
      totalAttentionPages: 1,
    );

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final beforeAssessment = prefs.getString('memorization_page_progress_v1')!;
    expect(beforeAssessment, isNot(contains('lastReviewedAt')));
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
  });

  testWidgets('assisted outcome is stored before moving on', (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['4', '5'],
      'memorization_page_progress_v1':
          '{"4":{"memorizedAt":"2026-01-01T00:00:00.000"},'
          '"5":{"memorizedAt":"2026-01-01T00:00:00.000"}}',
    });
    const session = MemorizationReviewSession(
      pages: <int>[4, 5],
      totalAttentionPages: 2,
    );

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('2/2'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('memorization_page_progress_v1')!;
    expect(raw, contains('assisted'));
    expect(raw, contains('lastReviewedAt'));
  });

  testWidgets('skip advances without falsely recording a review', (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['9', '10'],
      'memorization_page_progress_v1':
          '{"9":{"memorizedAt":"2026-01-01T00:00:00.000"},'
          '"10":{"memorizedAt":"2026-01-01T00:00:00.000"}}',
    });
    const session = MemorizationReviewSession(
      pages: <int>[9, 10],
      totalAttentionPages: 2,
    );

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('memorization_page_progress_v1')!;
    expect(raw, isNot(contains('lastReviewedAt')));
  });
}
