import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/home/home_quick_actions.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<AppSettings> loadSettings() async {
    final settings = AppSettings();
    await settings.load();
    return settings;
  }

  Widget harness(
    AppSettings settings, {
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) {
    return AppSettingsScope(
      settings: settings,
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: const SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: HomeQuickActionsSection(),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('quick actions remain usable with large text', (tester) async {
    final settings = await loadSettings();

    await tester.pumpWidget(harness(settings, textScale: 1.7));
    await tester.pumpAndSettle();

    expect(find.text('Quick actions'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit quick actions'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(HomeQuickAction.values.length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick actions follow RTL direction in Arabic', (tester) async {
    final settings = await loadSettings();

    await tester.pumpWidget(
      harness(settings, locale: const Locale('ar'), textScale: 1.2),
    );
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(HomeQuickActionsSection));
    expect(Directionality.of(element), TextDirection.rtl);
    expect(find.text('إجراءات سريعة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
