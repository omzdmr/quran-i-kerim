import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/quran/quran_area_screen.dart';
import 'package:quran_i_kerim/src/features/reader/reader_archive_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpArea(WidgetTester tester, AppSettings settings) async {
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
  }

  testWidgets('Quran area exposes saved activity without adding a fourth section', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final settings = AppSettings();
    await settings.load();
    await pumpArea(tester, settings);

    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.byTooltip('Saved activity'), findsOneWidget);

    await tester.tap(find.byTooltip('Saved activity'));
    await tester.pumpAndSettle();

    expect(find.byType(ReaderArchiveScreen), findsOneWidget);
    expect(find.text('Saved activity'), findsOneWidget);
  });

  testWidgets('archive entry shows combined bookmark, note and highlight count', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'bookmarks': <String>['2:255', '36:1'],
      'verse_notes': jsonEncode(<String, String>{'18:10': 'note'}),
      'verse_highlights': jsonEncode(<String, String>{'94:5': 'yellow'}),
    });
    final settings = AppSettings();
    await settings.load();
    await pumpArea(tester, settings);

    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('4')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Saved activity, 4'), findsOneWidget);
  });
}
