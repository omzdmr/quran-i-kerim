import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/quran/quran_area_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:quran_i_kerim/src/navigation/app_navigation.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saved item opened from Progress returns to Read at canonical ayah', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'bookmarks': <String>['36:1'],
    });
    final settings = AppSettings();
    await settings.load();
    AppNavigation.instance.consumeReaderRequest();
    AppNavigation.instance.consumeTabRequest();
    AppNavigation.instance.reportQuranSection(0);

    await tester.pumpWidget(
      AppSettingsScope(
        settings: settings,
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            GeneratedAppLocalizations.delegate,
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: QuranAreaScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Progress'));
    await tester.pump();
    expect(AppNavigation.instance.quranSectionIndex.value, 2);

    await tester.tap(find.byTooltip('Saved activity, 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved verse'));
    await tester.pumpAndSettle();

    final target = AppNavigation.instance.readerRequest.value;
    expect(target, isNotNull);
    expect(target!.surah, 36);
    expect(target.ayah, 1);
    expect(AppNavigation.instance.quranSectionIndex.value, 0);
    expect(AppNavigation.instance.tabRequest.value, AppNavigation.quranTabIndex);
  });
}
