import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_archive_screen.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_portable_archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const archive = QadaFastingPortableArchive();

  testWidgets('conflicting backup is visible and merge is disabled', (
    tester,
  ) async {
    final local = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21),
      sourceRamadanYear: 1447,
      id: 'same-id',
    );
    final incoming = QadaFastingLedger().addDebt(
      days: 3,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21),
      sourceRamadanYear: 1447,
      id: 'same-id',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      QadaFastingStore.preferenceKey: local.encode(),
    });
    await Clipboard.setData(ClipboardData(text: archive.export(incoming)));

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        home: QadaFastingArchiveScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Panodan yedek içe aktar'));
    await tester.pumpAndSettle();

    expect(find.text('Çakışan kayıt'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(
      find.text(
        'Aynı kimliğe sahip farklı kayıtlar var. Veri kaybını önlemek için Birleştir kapatıldı.',
      ),
      findsOneWidget,
    );
    final mergeButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Birleştir'),
    );
    expect(mergeButton.onPressed, isNull);
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Değiştir'),
      ).onPressed,
      isNotNull,
    );
  });
}
