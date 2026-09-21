import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/reader/reader_archive_screen.dart';
import 'package:quran_i_kerim/src/navigation/app_navigation.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppNavigation.instance.consumeReaderRequest();
    AppNavigation.instance.consumeTabRequest();
  });

  Future<AppSettings> settingsWithSavedActivity() async {
    final rwwad = translationCatalog.firstWhere((source) => source.code == 'RWD');
    SharedPreferences.setMockInitialValues(<String, Object>{
      'quran_source_user_selected_v1': true,
      'selected_quran_source': arabicOriginalSourceId,
      'bookmarks': <String>['36:1'],
      'verse_notes': jsonEncode(<String, String>{'2:255': 'Personal note'}),
      'verse_note_sources': jsonEncode(<String, String>{'2:255': 'RWD'}),
      'verse_highlights': jsonEncode(<String, String>{'18:10': 'yellow'}),
      'reader_history_v1': jsonEncode(<Map<String, Object>>[
        <String, Object>{
          'surah': 36,
          'ayah': 1,
          'sourceId': 'french_rashid',
          'updatedAt': 300,
        },
      ]),
      'archive_times': jsonEncode(<String, String>{
        'bookmark|36:1': '100',
        'highlight|18:10': '150',
        'note|2:255': '200',
      }),
    });
    final settings = AppSettings();
    await settings.load();
    expect(rwwad.id, isNotEmpty);
    return settings;
  }

  Future<void> pumpArchive(
    WidgetTester tester,
    AppSettings settings, {
    Locale locale = const Locale('en'),
  }) => tester.pumpWidget(
    AppSettingsScope(
      settings: settings,
      child: MaterialApp(locale: locale, home: const ReaderArchiveScreen()),
    ),
  );

  testWidgets('shows saved artifacts and note display-source provenance', (
    tester,
  ) async {
    final settings = await settingsWithSavedActivity();
    await pumpArchive(tester, settings);
    await tester.pumpAndSettle();

    expect(find.text('Saved activity'), findsOneWidget);
    expect(find.text('Personal note'), findsOneWidget);
    expect(find.textContaining('Display source:'), findsWidgets);
    expect(find.text('Saved verse'), findsOneWidget);
    expect(find.text('Highlighted verse'), findsOneWidget);
  });

  testWidgets('filters saved artifacts without losing persisted state', (
    tester,
  ) async {
    final settings = await settingsWithSavedActivity();
    await pumpArchive(tester, settings);
    await tester.pumpAndSettle();

    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('Notes (1)'), findsOneWidget);
    await tester.tap(find.text('Notes (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Personal note'), findsOneWidget);
    expect(find.text('Saved verse'), findsNothing);
    expect(find.text('Highlighted verse'), findsNothing);
  });

  testWidgets('opening a note requests its original display source', (
    tester,
  ) async {
    final settings = await settingsWithSavedActivity();
    final rwwad = translationCatalog.firstWhere((source) => source.code == 'RWD');
    await pumpArchive(tester, settings);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Personal note'));
    await tester.pump();

    final target = AppNavigation.instance.readerRequest.value;
    expect(target, isNotNull);
    expect(target!.surah, 2);
    expect(target.ayah, 255);
    expect(target.sourceId, rwwad.id);
    expect(AppNavigation.instance.tabRequest.value, AppNavigation.quranTabIndex);
  });

  testWidgets('legacy bookmark recovers its newest historical display source', (
    tester,
  ) async {
    final settings = await settingsWithSavedActivity();
    await pumpArchive(tester, settings);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saved verse'));
    await tester.pump();

    final target = AppNavigation.instance.readerRequest.value;
    expect(target, isNotNull);
    expect(target!.surah, 36);
    expect(target.ayah, 1);
    expect(target.sourceId, 'french_rashid');
  });

  testWidgets('French archive labels are available end to end', (tester) async {
    final settings = await settingsWithSavedActivity();
    await pumpArchive(tester, settings, locale: const Locale('fr'));
    await tester.pumpAndSettle();

    expect(find.text('Éléments enregistrés'), findsOneWidget);
    expect(find.text('Tout (3)'), findsOneWidget);
    expect(find.text('Notes (1)'), findsOneWidget);
    expect(find.text('Surlignages (1)'), findsOneWidget);
  });
}
