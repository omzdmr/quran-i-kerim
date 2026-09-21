import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_practice_log_screen.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_review_history_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('history screen logs a prayer review and refreshes summary', (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['8'],
      'memorization_page_progress_v1':
          '{"8":{"memorizedAt":"2026-09-01T00:00:00.000"}}',
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
        home: MemorizationReviewHistoryScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Total reviews 0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(MemorizationPracticeLogScreen), findsOneWidget);
    await tester.tap(find.text('In prayer'));
    await tester.tap(find.text('Save review'));
    await tester.pumpAndSettle();

    expect(find.byType(MemorizationReviewHistoryScreen), findsOneWidget);
    expect(find.text('Total reviews 1'), findsOneWidget);
    expect(find.textContaining('In prayer'), findsWidgets);
  });
}
