import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_hub_screen.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(Locale locale) => MaterialApp(
        locale: locale,
        supportedLocales: const <Locale>[
          Locale('tr'), Locale('en'), Locale('fr'),
          Locale('ar'), Locale('az'), Locale('ru'),
        ],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const QadaFastingHubScreen(),
      );

  testWidgets('hub summarizes durable local qada history', (tester) async {
    final ledger = QadaFastingLedger()
        .addDebt(
          days: 5,
          occurredOn: DateTime(2026, 3, 1),
          createdAt: DateTime.utc(2026, 9, 20),
          sourceRamadanYear: 1447,
          id: 'debt',
        )
        .complete(
          days: 2,
          occurredOn: DateTime(2026, 9, 21),
          createdAt: DateTime.utc(2026, 9, 21),
          sourceRamadanYear: 1447,
          id: 'done',
        );
    SharedPreferences.setMockInitialValues(<String, Object>{
      QadaFastingStore.preferenceKey: ledger.encode(),
    });

    await tester.pumpWidget(app(const Locale('tr')));
    await tester.pumpAndSettle();

    expect(find.text('Kaza orucu'), findsOneWidget);
    expect(find.text('Kalan gün'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Kayıt'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Kaza defteri'), findsOneWidget);
    expect(find.text('Yedekle ve geri yükle'), findsOneWidget);
  });

  testWidgets('hub exposes Arabic RTL labels without falling back to English', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(app(const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.text('صيام القضاء'), findsOneWidget);
    expect(find.text('سجل القضاء'), findsOneWidget);
    expect(find.text('النسخ الاحتياطي والاستعادة'), findsOneWidget);
    expect(find.text('Backup and restore'), findsNothing);
    expect(
      tester.widget<Directionality>(find.byType(Directionality).first).textDirection,
      TextDirection.rtl,
    );
  });

  testWidgets('hub survives 200 percent text scale', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: app(const Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Qada ledger'), findsOneWidget);
    expect(find.text('Backup and restore'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
