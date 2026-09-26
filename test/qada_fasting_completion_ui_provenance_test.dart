import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('simple completed-fast UI preserves unambiguous Ramadan in storage', (tester) async {
    final seeded = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21, 7),
      sourceRamadanYear: 1447,
      id: 'seed-debt',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      QadaFastingStore.preferenceKey: seeded.encode(),
    });

    await tester.pumpWidget(
      const MaterialApp(locale: Locale('en'), home: QadaFastingScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Remaining: 2 days'), findsOneWidget);
    await tester.tap(find.text('I completed a fast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Remaining: 1 days'), findsOneWidget);
    // The existing history card already renders sourceRamadanYear, so the
    // automatic safe attribution is visible without adding another dialog.
    expect(find.textContaining('Ramadan 1447'), findsWidgets);

    final persisted = await const QadaFastingStore().load();
    expect(persisted.entries, hasLength(2));
    expect(persisted.entries.last.kind, QadaFastingEntryKind.completion);
    expect(persisted.entries.last.sourceRamadanYear, 1447);
    expect(persisted.remainingForRamadan(1447), 1);
  });

  testWidgets('multi-year UI completion stays unassigned instead of guessing', (tester) async {
    final seeded = QadaFastingLedger()
        .addDebt(
          days: 1,
          occurredOn: DateTime(2025, 3, 1),
          createdAt: DateTime.utc(2026, 9, 21, 7),
          sourceRamadanYear: 1446,
          id: 'old',
        )
        .addDebt(
          days: 1,
          occurredOn: DateTime(2026, 3, 1),
          createdAt: DateTime.utc(2026, 9, 21, 7, 1),
          sourceRamadanYear: 1447,
          id: 'new',
        );
    SharedPreferences.setMockInitialValues(<String, Object>{
      QadaFastingStore.preferenceKey: seeded.encode(),
    });

    await tester.pumpWidget(
      const MaterialApp(locale: Locale('en'), home: QadaFastingScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('I completed a fast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final persisted = await const QadaFastingStore().load();
    expect(persisted.remainingDays, 1);
    expect(persisted.entries.last.kind, QadaFastingEntryKind.completion);
    expect(persisted.entries.last.sourceRamadanYear, isNull);
  });
}
