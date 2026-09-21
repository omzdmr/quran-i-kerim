import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_archive_screen.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(
    WidgetTester tester, {
    Locale locale = const Locale('tr'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: const [
          Locale('tr'),
          Locale('en'),
          Locale('fr'),
          Locale('ar'),
          Locale('az'),
          Locale('ru'),
        ],
        home: const QadaFastingArchiveScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows local ledger summary and keeps private notes opt-in', (
    tester,
  ) async {
    final ledger = QadaFastingLedger().addDebt(
      days: 3,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 22),
      sourceRamadanYear: 1447,
      note: 'sensitive',
      id: 'qada-test',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      QadaFastingStore.preferenceKey: ledger.encode(),
    });

    await pumpScreen(tester);

    expect(find.text('Kaza defteri yedeği'), findsOneWidget);
    expect(find.text('Kayıt: 1'), findsOneWidget);
    expect(find.text('Kalan gün: 3'), findsOneWidget);
    final notesSwitch = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(notesSwitch.value, isFalse);
    expect(find.text('Taşınabilir yedek oluştur'), findsOneWidget);
    expect(find.text('Panodan yedek içe aktar'), findsOneWidget);
  });

  testWidgets('empty ledger disables export but leaves restore available', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await pumpScreen(tester, locale: const Locale('en'));

    final export = tester.widget<FilledButton>(find.byType(FilledButton).first);
    expect(export.onPressed, isNull);
    final restore = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(restore.onPressed, isNotNull);
  });

  testWidgets('large text keeps backup and restore actions reachable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: const MaterialApp(home: QadaFastingArchiveScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QadaFastingArchiveScreen), findsOneWidget);
    expect(find.byIcon(Icons.content_paste_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
