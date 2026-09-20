import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/app.dart';
import 'package:quran_i_kerim/src/features/settings/settings_screen.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings exposes a reversible Essential Reader preset', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final settings = AppSettings();
    await settings.load();

    await tester.pumpWidget(
      AppSettingsScope(
        settings: settings,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('Essential / Large-text Reader'), findsOneWidget);
    await tester.tap(find.text('Essential / Large-text Reader'));
    await tester.pumpAndSettle();

    expect(settings.essentialReaderEnabled, isTrue);
    expect(settings.readerContentTextSize, 32);

    await tester.tap(find.text('Essential / Large-text Reader'));
    await tester.pumpAndSettle();
    expect(settings.essentialReaderEnabled, isFalse);
  });

  testWidgets('app enforces the preset minimum interface scale', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reader_experience_preset_v1': 'essential',
    });
    final settings = AppSettings();
    await settings.load();

    await tester.pumpWidget(QuranModernApp(settings: settings));
    await tester.pump();

    final context = tester.element(find.byType(MediaQuery).last);
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    expect(scale, greaterThanOrEqualTo(1.16));
  });
}
