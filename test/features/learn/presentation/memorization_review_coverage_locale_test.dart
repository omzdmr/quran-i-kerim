import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_review_coverage_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('coverage screen renders on narrow phone in ${locale.languageCode}',
        (tester) async {
      tester.view.physicalSize = const Size(640, 1280);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        'memorized_pages_v1': <String>['1', '2'],
        'memorization_page_progress_v1':
            '{"1":{"memorizedAt":"2026-08-01T00:00:00.000"},'
            '"2":{"memorizedAt":"2026-08-02T00:00:00.000",'
            '"lastReviewedAt":"2020-01-01T00:00:00.000"}}',
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            GeneratedAppLocalizations.delegate,
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MemorizationReviewCoverageScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ChoiceChip), findsNWidgets(2));
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  }
}
