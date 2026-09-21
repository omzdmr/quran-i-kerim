import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/quran/quran_learn_overview.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('memorize tab exposes review coverage entry', (tester) async {
    SharedPreferences.setMockInitialValues({});
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
    expect(find.text(l10n.memorizeTodayReview), findsWidgets);
  });
}
