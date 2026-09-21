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
      'archive_times': jsonEncode(<String, String>{
        'bookmark|36:1': '100',
        'note|2:255': '200',
      }),
    });
    final settings = AppSettings();
    await settings.load();
    expect(rwwad.id, isNotEmpty);
    return settings;
  }

  testWidgets('shows saved artifacts and note display-source provenance', (
    tester,
  ) async {
    final settings = await settingsWithSavedActivity();

    await tester.pumpWidget(
      AppSettingsScope(
        settings: settings,
        child: const MaterialApp(
          locale: Locale('en'),
          home: ReaderArchiveScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved activity'), findsOneWidget);
    expect(find.text('Personal note'), findsOneWidget);
    expect(find.textContaining('Display source:'), findsOneWidget);
    expect(find.text('Saved verse'), findsOneWidget);
  });

  testWidgets('opening a note requests its original display source', (
    tester,
  ) async {
    final settings = await settingsWithSavedActivity();
    final rwwad = translationCatalog.firstWhere((source) => source.code == 'RWD');

    await tester.pumpWidget(
      AppSettingsScope(
        settings: settings,
        child: const MaterialApp(
          locale: Locale('en'),
          home: ReaderArchiveScreen(),
        ),
      ),
    );
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

  testWidgets('legacy bookmark keeps current display source', (tester) async {
    final settings = await settingsWithSavedActivity();

    await tester.pumpWidget(
      AppSettingsScope(
        settings: settings,
        child: const MaterialApp(
          locale: Locale('en'),
          home: ReaderArchiveScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saved verse'));
    await tester.pump();

    final target = AppNavigation.instance.readerRequest.value;
    expect(target, isNotNull);
    expect(target!.surah, 36);
    expect(target.ayah, 1);
    expect(target.sourceId, arabicOriginalSourceId);
  });
}
