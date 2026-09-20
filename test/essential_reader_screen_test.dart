import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/reader/quran_reader_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Essential Reader moves search from first layer into the secondary menu',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'reader_experience_preset_v1': 'essential',
        'selected_quran_source': arabicOriginalSourceId,
        'quran_source_user_selected_v1': true,
      });
      final settings = AppSettings();
      await settings.load();

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
            home: Scaffold(body: QuranReaderScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byTooltip('Search Quran and translation'),
        findsNothing,
      );

      await tester.tap(find.byTooltip('Reading settings'));
      await tester.pumpAndSettle();

      expect(find.text('Search Quran and translation'), findsOneWidget);
      expect(find.text('Search Al-Baqarah, 2:255 or patience'), findsOneWidget);
    },
  );
}
