import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';

void main() {
  test('completed fast can be explicitly attributed across multiple Ramadans', () {
    var ledger = QadaFastingLedger()
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

    expect(ledger.remainingDays, 7);
    expect(ledger.openRamadanYears, [1447, 1446]);
    expect(ledger.unambiguousCompletionRamadanYear, isNull);

    ledger = ledger.complete(
      days: 2,
      occurredOn: DateTime(2026, 9, 21),
      createdAt: DateTime.utc(2026, 9, 21, 3),
      sourceRamadanYear: 1446,
      attributeWhenUnambiguous: false,
      id: 'completion-1446',
    );

    expect(ledger.remainingForRamadan(1446), 2);
    expect(ledger.remainingForRamadan(1447), 3);
    expect(ledger.remainingDays, 5);
    expect(ledger.attributedCompletionsByRamadan[1446], 2);
  });

  test('per-Ramadan attribution survives local serialization', () {
    final ledger = QadaFastingLedger()
        .addDebt(
          days: 5,
          occurredOn: DateTime(2026, 2, 18),
          createdAt: DateTime.utc(2026, 9, 21, 1),
          sourceRamadanYear: 1447,
          id: 'debt',
        )
        .complete(
          days: 2,
          occurredOn: DateTime(2026, 9, 21),
          createdAt: DateTime.utc(2026, 9, 21, 2),
          sourceRamadanYear: 1447,
          attributeWhenUnambiguous: false,
          id: 'completion',
        );

    final restored = QadaFastingLedger.decode(ledger.encode());
    expect(restored.remainingForRamadan(1447), 3);
    expect(restored.attributedCompletionsByRamadan[1447], 2);
    expect(restored.entries.last.sourceRamadanYear, 1447);
  });

  test('allocation cannot exceed selected Ramadan balance', () {
    final ledger = QadaFastingLedger().addDebt(
      days: 1,
      occurredOn: DateTime(2026, 2, 18),
      createdAt: DateTime.utc(2026, 9, 21, 1),
      sourceRamadanYear: 1447,
      id: 'debt',
    );

    expect(
      () => ledger.complete(
        days: 2,
        occurredOn: DateTime(2026, 9, 21),
        createdAt: DateTime.utc(2026, 9, 21, 2),
        sourceRamadanYear: 1447,
        attributeWhenUnambiguous: false,
      ),
      throwsStateError,
    );
  });
}
