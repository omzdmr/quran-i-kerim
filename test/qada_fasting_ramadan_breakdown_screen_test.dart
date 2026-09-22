import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ramadan_breakdown_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows separate Ramadan balances and persists explicit completion',
      (tester) async {
    final initial = QadaFastingLedger()
        .addDebt(
          days: 4,
          occurredOn: DateTime(2025, 3, 1),
          createdAt: DateTime.utc(2026, 9, 21, 1),
          sourceRamadanYear: 1446,
          id: 'debt-1446',
        )
        .addDebt(
          days: 3,
          occurredOn: DateTime(2026, 2, 18),
          createdAt: DateTime.utc(2026, 9, 21, 2),
          sourceRamadanYear: 1447,
          id: 'debt-1447',
        );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(QadaFastingStore.preferenceKey, initial.encode());

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: QadaFastingRamadanBreakdownScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ramadan 1447'), findsOneWidget);
    expect(find.text('Ramadan 1446'), findsOneWidget);
    expect(find.text('Remaining: 3'), findsOneWidget);
    expect(find.text('Remaining: 4'), findsOneWidget);

    final firstAction = find.text('Add completed fast for this Ramadan').first;
    await tester.tap(firstAction);
    await tester.pumpAndSettle();
    expect(find.textContaining('Attribute qada fast to Ramadan:'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final restored = QadaFastingLedger.decode(
      prefs.getString(QadaFastingStore.preferenceKey),
    );
    expect(restored.remainingDays, 6);
    expect(restored.attributedCompletionsByRamadan.values.fold<int>(0, (a, b) => a + b), 1);
  });

  testWidgets('announces Ramadan balance as one accessible card', (tester) async {
    final initial = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2026, 2, 18),
      createdAt: DateTime.utc(2026, 9, 21),
      sourceRamadanYear: 1447,
      id: 'debt',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(QadaFastingStore.preferenceKey, initial.encode());

    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: QadaFastingRamadanBreakdownScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        'Ramadan 1447, Remaining 2 days, Completed 0 days',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });
}
