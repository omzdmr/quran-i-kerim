import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/reader/reader_archive_screen.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettings> _settings() async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'quran_source_user_selected_v1': true,
    'selected_quran_source': arabicOriginalSourceId,
    'bookmarks': <String>['2:255'],
    'verse_notes': jsonEncode(<String, String>{'36:1': 'ملاحظة خاصة'}),
    'verse_note_sources': jsonEncode(<String, String>{'36:1': 'AR'}),
    'archive_times': jsonEncode(<String, String>{
      'bookmark|2:255': '100',
      'note|36:1': '200',
    }),
  });
  final settings = AppSettings();
  await settings.load();
  return settings;
}

void main() {
  testWidgets('archive remains usable with large system text', (tester) async {
    final settings = await _settings();
    await tester.pumpWidget(
      AppSettingsScope(
        settings: settings,
        child: MaterialApp(
          locale: const Locale('en'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2.0),
            ),
            child: child!,
          ),
          home: const ReaderArchiveScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Saved activity'), findsOneWidget);
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('Arabic archive uses RTL direction and exposes tappable semantics', (
    tester,
  ) async {
    final settings = await _settings();
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    await tester.pumpWidget(
      AppSettingsScope(
        settings: settings,
        child: const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ReaderArchiveScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('المحفوظات'), findsOneWidget);
    expect(find.text('ملاحظة خاصة'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('آية محفوظة')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
