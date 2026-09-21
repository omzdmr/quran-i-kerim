import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_practice_log_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(Locale locale) => MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GeneratedAppLocalizations.delegate,
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MemorizationPracticeLogScreen(),
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['1'],
      'memorization_page_progress_v1':
          '{"1":{"memorizedAt":"2026-09-01T00:00:00.000"}}',
    });
  });

  testWidgets('French practice logging copy is available offline', (tester) async {
    await tester.pumpWidget(app(const Locale('fr')));
    await tester.pumpAndSettle();
    expect(find.text('Enregistrer une révision'), findsOneWidget);
    expect(find.text('En prière'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
  });

  testWidgets('Arabic practice logging copy is available offline', (tester) async {
    await tester.pumpWidget(app(const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('تسجيل مراجعة'), findsOneWidget);
    expect(find.text('في الصلاة'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('تسجيل مراجعة'))), TextDirection.rtl);
  });
}
