import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_session.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_coverage_review_session_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';

void main() {
  const expected = <String, String>{
    'tr': 'Şimdilik geç',
    'en': 'Skip for now',
    'ar': 'تخطَّ الآن',
    'az': 'Hələlik keç',
    'ru': 'Пока пропустить',
    'fr': 'Passer pour l’instant',
  };

  for (final entry in expected.entries) {
    testWidgets('review session defer action renders in ${entry.key}', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(entry.key),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            GeneratedAppLocalizations.delegate,
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MemorizationCoverageReviewSessionScreen(
            session: MemorizationReviewSession(
              pages: <int>[1],
              totalAttentionPages: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      if (entry.key == 'ar') {
        expect(Directionality.of(tester.element(find.text(entry.value))), TextDirection.rtl);
      }
    });
  }
}
