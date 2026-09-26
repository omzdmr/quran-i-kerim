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

  testWidgets('French Discover opens qada hub then localized ledger', (tester) async {
    await tester.pumpWidget(_app(const Locale('fr')));
    await tester.pumpAndSettle();
    expect(find.text('Registre des jeûnes à rattraper'), findsOneWidget);

    await tester.tap(find.text('Registre des jeûnes à rattraper'));
    await tester.pumpAndSettle();
    expect(find.text('Jeûnes à rattraper'), findsOneWidget);
    expect(find.text('Registre'), findsOneWidget);

    await tester.tap(find.text('Registre'));
    await tester.pumpAndSettle();
    expect(find.text('J’ai rattrapé un jeûne'), findsOneWidget);
    expect(find.text('Ajouter une dette'), findsOneWidget);
  });

  testWidgets('French qada hub opens portable backup flow', (tester) async {
    final ledger = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 22),
      sourceRamadanYear: 1447,
      id: 'discover-backup',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      QadaFastingStore.preferenceKey: ledger.encode(),
    });

    await tester.pumpWidget(_app(const Locale('fr')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registre des jeûnes à rattraper'));
    await tester.pumpAndSettle();

    expect(find.text('Jours restants'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Sauvegarde et restauration'), findsOneWidget);
    await tester.tap(find.text('Sauvegarde et restauration'));
    await tester.pumpAndSettle();

    expect(find.text('Sauvegarde des jeûnes à rattraper'), findsOneWidget);
    expect(find.text('Entrées: 1'), findsOneWidget);
    expect(find.text('Jours restants: 2'), findsOneWidget);
    expect(find.text('Créer une sauvegarde portable'), findsOneWidget);
  });

  testWidgets('Arabic qada hub and ledger keep RTL navigation', (tester) async {
    await tester.pumpWidget(_app(const Locale('ar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('سجل صيام القضاء'));
    await tester.pumpAndSettle();

    expect(find.text('صيام القضاء'), findsOneWidget);
    expect(find.text('سجل القضاء'), findsOneWidget);
    final hubDirectionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(hubDirectionality.textDirection, TextDirection.rtl);

    await tester.tap(find.text('سجل القضاء'));
    await tester.pumpAndSettle();
    expect(find.text('صمت يوم قضاء'), findsOneWidget);
  });
}
