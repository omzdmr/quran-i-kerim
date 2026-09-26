import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/reader/reader_archive_screen.dart';
import 'package:quran_i_kerim/src/navigation/app_navigation.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('corrupt saved reference is shown safely but cannot navigate', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'quran_source_user_selected_v1': true,
      'selected_quran_source': arabicOriginalSourceId,
      'bookmarks': <String>['bad-reference', '2:255'],
    });
    final settings = AppSettings();
    await settings.load();
    AppNavigation.instance.consumeReaderRequest();

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

    expect(find.textContaining('bad-reference'), findsOneWidget);
    expect(find.textContaining('2:255'), findsOneWidget);
    await tester.tap(find.textContaining('bad-reference'));
    await tester.pump();
    expect(AppNavigation.instance.readerRequest.value, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search has an explicit no-results state and can recover', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'quran_source_user_selected_v1': true,
      'selected_quran_source': arabicOriginalSourceId,
      'bookmarks': <String>['36:1'],
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

    await tester.enterText(find.byType(TextField), 'definitely-not-a-surah');
    await tester.pump();
    expect(find.text('No saved item matches your search.'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.textContaining('36:1'), findsOneWidget);
    expect(find.text('No saved item matches your search.'), findsNothing);
  });
}
