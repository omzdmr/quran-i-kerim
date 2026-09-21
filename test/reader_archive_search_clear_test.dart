import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/reader/reader_archive_screen.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('clear search resets both field text and visible saved items', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'quran_source_user_selected_v1': true,
      'selected_quran_source': arabicOriginalSourceId,
      'bookmarks': <String>['36:1', '2:255'],
    });
    final settings = AppSettings();
    await settings.load();

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

    await tester.enterText(find.byType(TextField), '36:1');
    await tester.pump();
    expect(find.textContaining('36:1'), findsOneWidget);
    expect(find.textContaining('2:255'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
    expect(find.textContaining('36:1'), findsOneWidget);
    expect(find.textContaining('2:255'), findsOneWidget);
  });
}
