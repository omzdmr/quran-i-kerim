import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/quran/quran_area_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('saved entry does not overflow a narrow Quran header', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues(<String, Object>{
      'bookmarks': <String>['2:255'],
    });
    final settings = AppSettings();
    await settings.load();

    await tester.pumpWidget(
      AppSettingsScope(
        settings: settings,
        child: const MaterialApp(
          locale: Locale('fr'),
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

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Éléments enregistrés, 1'), findsOneWidget);
  });
}
