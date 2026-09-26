import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_practice_history_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_review_history_screen.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget app(Locale locale) => MaterialApp(
        locale: locale,
        localizationsDelegates: GeneratedAppLocalizations.localizationsDelegates,
        supportedLocales: GeneratedAppLocalizations.supportedLocales,
        home: const MemorizationReviewHistoryScreen(),
      );

  testWidgets('shows empty local-first history state', (tester) async {
    await tester.pumpWidget(app(const Locale('tr')));
    await tester.pumpAndSettle();

    expect(find.text('Tekrar geçmişi'), findsOneWidget);
    expect(find.textContaining('henüz tekrar kaydı yok'), findsOneWidget);
    expect(find.text('Son 30 gün 0'), findsOneWidget);
  });

  testWidgets('shows persisted review activity and filters it', (tester) async {
    const progressStore = MemorizationProgressStore();
    const historyStore = MemorizationPracticeHistoryStore();
    await progressStore.togglePage(1, now: DateTime(2026, 9, 1));
    await historyStore.record(
      page: 1,
      context: MemorizationPracticeContext.prayer,
      now: DateTime.now().subtract(const Duration(days: 1)),
    );
    await historyStore.record(
      page: 1,
      context: MemorizationPracticeContext.soloReview,
      now: DateTime.now(),
    );

    await tester.pumpWidget(app(const Locale('tr')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sayfa 1'), findsWidgets);
    expect(find.textContaining('Toplam tekrar: 2'), findsOneWidget);

    await tester.tap(find.text('Namazda'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Toplam tekrar: 1'), findsOneWidget);
  });

  testWidgets('French locale exposes localized history controls', (tester) async {
    await tester.pumpWidget(app(const Locale('fr')));
    await tester.pumpAndSettle();

    expect(find.text('Historique des révisions'), findsOneWidget);
    expect(find.text('30 derniers jours 0'), findsOneWidget);
    expect(find.text('Tout'), findsOneWidget);
  });
}
