import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_review_history_screen.dart';
import 'package:quran_i_kerim/src/features/quran/quran_learn_overview.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('memorize tab exposes review history without replacing coverage',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['10'],
      'memorization_page_progress_v1':
          '{"10":{"memorizedAt":"2026-08-01T00:00:00.000"}}',
    });
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
        home: Scaffold(body: QuranLearnOverview()),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(QuranLearnOverview));
    final l10n = GeneratedAppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.quranLearnMemorize));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.history_toggle_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.insights_outlined), findsOneWidget);
    expect(find.text('Review history'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.insights_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(MemorizationReviewHistoryScreen), findsOneWidget);
  });
}
