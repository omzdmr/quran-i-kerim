import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/presentation/memorization_practice_log_screen.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('practice logging remains usable at 200 percent text scale', (tester) async {
    SharedPreferences.setMockInitialValues({
      'memorized_pages_v1': <String>['1', '2'],
      'memorization_page_progress_v1':
          '{"1":{"memorizedAt":"2026-09-01T00:00:00.000"},'
          '"2":{"memorizedAt":"2026-09-02T00:00:00.000"}}',
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GeneratedAppLocalizations.delegate,
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
            ),
            child: const MemorizationPracticeLogScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('How did you review it?'), findsOneWidget);
    expect(find.text('Recited to someone'), findsOneWidget);
    expect(find.text('Save review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
