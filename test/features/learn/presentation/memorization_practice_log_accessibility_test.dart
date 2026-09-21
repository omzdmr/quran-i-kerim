import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_practice_log_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('practice context choices expose selected state to assistive tech', (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['1'],
      'memorization_page_progress_v1':
          '{"1":{"memorizedAt":"2026-09-01T00:00:00.000"}}',
    });
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          GeneratedAppLocalizations.delegate,
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MemorizationPracticeLogScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text('Solo review')),
      matchesSemantics(label: 'Solo review', hint: 'My own review session', isButton: true, isSelected: true, hasTapAction: true),
    );

    await tester.tap(find.text('In prayer'));
    await tester.pump();
    expect(
      tester.getSemantics(find.text('In prayer')),
      matchesSemantics(label: 'In prayer', hint: 'I recited this memorization in prayer', isButton: true, isSelected: true, hasTapAction: true),
    );
  });
}
