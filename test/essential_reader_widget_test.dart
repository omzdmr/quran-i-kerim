import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/app.dart';
import 'package:quran_i_kerim/src/features/settings/settings_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:quran_i_kerim/src/navigation/app_navigation.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings exposes a reversible Essential Reader preset', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    SharedPreferences.setMockInitialValues(<String, Object>{});
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
          home: SettingsScreen(),
        ),
      ),
    );

    expect(find.text('Essential / Large-text Reader'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Essential / Large-text Reader'),
      findsOneWidget,
    );
    await tester.tap(find.text('Essential / Large-text Reader'));
    await tester.pumpAndSettle();

    expect(settings.essentialReaderEnabled, isTrue);
    expect(settings.readerContentTextSize, 32);

    await tester.tap(find.text('Essential / Large-text Reader'));
    await tester.pumpAndSettle();
    expect(settings.essentialReaderEnabled, isFalse);
  });

  testWidgets('standard experience leaves the platform text scale untouched', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final settings = AppSettings();
    await settings.load();

    await tester.pumpWidget(QuranModernApp(settings: settings));
    await tester.pump();

    final mediaQueries = tester.widgetList<MediaQuery>(find.byType(MediaQuery));
    expect(
      mediaQueries.any(
        (widget) => widget.data.textScaler.scale(16) / 16 >= 1.16,
      ),
      isFalse,
    );
  });

  testWidgets('Essential mode never shrinks a larger platform text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reader_experience_preset_v1': 'essential',
    });
    final settings = AppSettings();
    await settings.load();

    await tester.pumpWidget(QuranModernApp(settings: settings));
    await tester.pump();

    final mediaQueries = tester.widgetList<MediaQuery>(find.byType(MediaQuery));
    expect(
      mediaQueries.any(
        (widget) => widget.data.textScaler.scale(16) / 16 >= 2,
      ),
      isTrue,
    );
  });

  testWidgets('app enforces the preset minimum interface scale', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reader_experience_preset_v1': 'essential',
    });
    final settings = AppSettings();
    await settings.load();

    await tester.pumpWidget(QuranModernApp(settings: settings));
    await tester.pump();

    final mediaQueries = tester.widgetList<MediaQuery>(find.byType(MediaQuery));
    expect(
      mediaQueries.any(
        (widget) => widget.data.textScaler.scale(16) / 16 >= 1.16,
      ),
      isTrue,
    );
  });
  testWidgets('settings search opens Reader focus controls', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final settings = AppSettings();
    await settings.load();
    AppNavigation.instance.consumeTabRequest();
    addTearDown(AppNavigation.instance.consumeTabRequest);

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
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'focus reading');
    await tester.pumpAndSettle();

    expect(find.text('Focus reading'), findsOneWidget);
    await tester.tap(find.text('Focus reading'));
    await tester.pump();

    expect(
      AppNavigation.instance.tabRequest.value,
      AppNavigation.quranTabIndex,
    );
  });

}
