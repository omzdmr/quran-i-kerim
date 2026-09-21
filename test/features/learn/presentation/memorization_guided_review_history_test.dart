import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_session.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_coverage_review_session_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('completed guided review writes reversible practice-history event',
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

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          GeneratedAppLocalizations.delegate,
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MemorizationCoverageReviewSessionScreen(session: session),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check_circle_outline_rounded));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getString('memorization_practice_history_v1');
    expect(history, isNotNull);
    expect(history, contains('"page":1'));
    expect(history, contains('"context":"soloReview"'));
  });
}
