import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_practice_history_store.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_review_page_history_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const store = MemorizationPracticeHistoryStore();

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
        home: MemorizationReviewPageHistoryScreen(page: 12),
      );

  testWidgets('shows contexts and allows a mistaken event to be removed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await store.record(
      page: 12,
      context: MemorizationPracticeContext.prayer,
      now: DateTime(2026, 9, 21, 10),
    );
    await store.record(
      page: 12,
      context: MemorizationPracticeContext.soloReview,
      now: DateTime(2026, 9, 20, 10),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('In prayer'), findsOneWidget);
    expect(find.text('Solo review'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete review record?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    final history = await store.load();
    expect(history.eventsForPage(12).length, 1);
  });

  testWidgets('legacy page can still open study with no detailed events', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.textContaining('no detailed review events'), findsOneWidget);
    expect(find.text('Study this page'), findsOneWidget);
  });
}
