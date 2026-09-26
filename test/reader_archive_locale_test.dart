import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/reader_archive_screen.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const supported = <Locale>[
    Locale('tr'),
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
    Locale('az'),
    Locale('ru'),
  ];
  const delegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  final cases = <String, Map<String, String>>{
    'tr': <String, String>{'title': 'Kaydedilenler', 'all': 'Tümü (1)'},
    'en': <String, String>{'title': 'Saved activity', 'all': 'All (1)'},
    'fr': <String, String>{'title': 'Éléments enregistrés', 'all': 'Tout (1)'},
    'ar': <String, String>{'title': 'المحفوظات', 'all': 'الكل (1)'},
    'az': <String, String>{'title': 'Yadda saxlanılanlar', 'all': 'Hamısı (1)'},
    'ru': <String, String>{'title': 'Сохранённое', 'all': 'Все (1)'},
  };

  for (final entry in cases.entries) {
    testWidgets('archive chrome supports ${entry.key}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'bookmarks': <String>['2:255'],
      });
      final settings = AppSettings();
      await settings.load();

      await tester.pumpWidget(
        AppSettingsScope(
          settings: settings,
          child: MaterialApp(
            locale: Locale(entry.key),
            supportedLocales: supported,
            localizationsDelegates: delegates,
            home: const ReaderArchiveScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(entry.value['title']!), findsOneWidget);
      expect(find.text(entry.value['all']!), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
