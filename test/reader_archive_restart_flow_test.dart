import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/reader/reader_archive_screen.dart';
import 'package:quran_i_kerim/src/navigation/app_navigation.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'note -> meal change -> app restart -> saved item reopens canonical ayah with note source',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'quran_source_user_selected_v1': true,
        'selected_quran_source': arabicOriginalSourceId,
        'last_surah': 18,
        'last_ayah': 10,
        'verse_notes': jsonEncode(<String, String>{
          '2:255': 'Remember this context',
        }),
        'verse_note_sources': jsonEncode(<String, String>{'2:255': 'RWD-EN'}),
        'archive_times': jsonEncode(<String, String>{'note|2:255': '100'}),
      });

      final restartedSettings = AppSettings();
      await restartedSettings.load();
      expect(restartedSettings.selectedQuranSourceId, arabicOriginalSourceId);
      expect(restartedSettings.lastSurah, 18);
      expect(restartedSettings.lastAyah, 10);

      AppNavigation.instance.consumeReaderRequest();
      AppNavigation.instance.consumeTabRequest();

      await tester.pumpWidget(
        AppSettingsScope(
          settings: restartedSettings,
          child: MaterialApp(
            locale: const Locale('en'),
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReaderArchiveScreen(),
                  ),
                ),
                child: const Text('open archive'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open archive'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remember this context'));
      await tester.pumpAndSettle();

      final target = AppNavigation.instance.readerRequest.value;
      expect(target, isNotNull);
      expect(target!.surah, 2);
      expect(target.ayah, 255);
      expect(target.sourceId, englishTranslationId);
      expect(AppNavigation.instance.tabRequest.value, AppNavigation.quranTabIndex);
      expect(find.text('open archive'), findsOneWidget);
    },
  );
}
