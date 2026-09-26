import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Locale locale, {double textScale = 1}) => MaterialApp(
  locale: locale,
  supportedLocales: const <Locale>[
    Locale('tr'), Locale('en'), Locale('ar'), Locale('az'), Locale('ru'), Locale('fr'),
  ],
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: const QadaFastingScreen(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final ledger = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21),
      sourceRamadanYear: 1447,
      id: 'seed',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      QadaFastingStore.preferenceKey: ledger.encode(),
    });
  });

  testWidgets('French qada surface is localized and keeps semantic balance', (tester) async {
    await tester.pumpWidget(_app(const Locale('fr')));
    await tester.pumpAndSettle();
    expect(find.text('Registre des jeûnes à rattraper'), findsOneWidget);
    expect(find.text('J’ai rattrapé un jeûne'), findsOneWidget);
    expect(find.bySemanticsLabel('Restant: 2 jours'), findsOneWidget);
  });

  testWidgets('Arabic qada surface resolves RTL direction', (tester) async {
    await tester.pumpWidget(_app(const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('سجل صيام القضاء'), findsOneWidget);
    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
    expect(find.text('صمت يوم قضاء'), findsOneWidget);
  });

  testWidgets('large text keeps primary qada actions reachable by scrolling', (tester) async {
    await tester.pumpWidget(_app(const Locale('en'), textScale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Add debt'), findsOneWidget);
    expect(find.text('I completed a fast'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('History'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('History'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
