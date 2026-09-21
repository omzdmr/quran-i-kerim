import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/discover_screen.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Locale locale) => MaterialApp(
  locale: locale,
  supportedLocales: const <Locale>[
    Locale('tr'), Locale('en'), Locale('ar'), Locale('az'), Locale('ru'), Locale('fr'),
  ],
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: const Scaffold(body: DiscoverScreen()),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      QadaFastingStore.preferenceKey: QadaFastingLedger().encode(),
    });
  });

  testWidgets('French Discover opens the localized qada ledger', (tester) async {
    await tester.pumpWidget(_app(const Locale('fr')));
    await tester.pumpAndSettle();
    expect(find.text('Registre des jeûnes à rattraper'), findsOneWidget);

    await tester.tap(find.text('Registre des jeûnes à rattraper'));
    await tester.pumpAndSettle();

    expect(find.text('J’ai rattrapé un jeûne'), findsOneWidget);
    expect(find.text('Ajouter une dette'), findsOneWidget);
  });

  testWidgets('Arabic Discover keeps qada navigation RTL', (tester) async {
    await tester.pumpWidget(_app(const Locale('ar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('سجل صيام القضاء'));
    await tester.pumpAndSettle();

    expect(find.text('صمت يوم قضاء'), findsOneWidget);
    final directionality = tester.widget<Directionality>(find.byType(Directionality).first);
    expect(directionality.textDirection, TextDirection.rtl);
  });
}
