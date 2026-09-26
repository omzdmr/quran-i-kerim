import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';

void main() {
  final created = DateTime.utc(2026, 9, 21, 8);

  test('simple completion keeps the only unambiguous Ramadan provenance', () {
    final ledger = QadaFastingLedger()
        .addDebt(
          days: 3,
          occurredOn: DateTime(2026, 3, 1),
          createdAt: created,
          sourceRamadanYear: 1447,
          id: 'debt',
        )
        .complete(
          occurredOn: DateTime(2026, 9, 21),
          createdAt: created.add(const Duration(minutes: 1)),
          id: 'done',
        );

    expect(ledger.entries.last.sourceRamadanYear, 1447);
    expect(ledger.remainingForRamadan(1447), 2);
    expect(ledger.remainingDays, 2);
  });

  test('multi-Ramadan balance is not guessed by simple completion flow', () {
    final ledger = QadaFastingLedger()
        .addDebt(
          days: 2,
          occurredOn: DateTime(2025, 3, 1),
          createdAt: created,
          sourceRamadanYear: 1446,
          id: 'old',
        )
        .addDebt(
          days: 2,
          occurredOn: DateTime(2026, 3, 1),
          createdAt: created.add(const Duration(minutes: 1)),
          sourceRamadanYear: 1447,
          id: 'new',
        )
        .complete(
          occurredOn: DateTime(2026, 9, 21),
          createdAt: created.add(const Duration(minutes: 2)),
          id: 'done',
        );

    expect(ledger.entries.last.sourceRamadanYear, isNull);
    expect(ledger.remainingForRamadan(1446), 2);
    expect(ledger.remainingForRamadan(1447), 2);
    expect(ledger.remainingDays, 3);
  });

  test('unknown opening debt prevents false Ramadan attribution', () {
    final ledger = QadaFastingLedger()
        .addDebt(
          days: 1,
          occurredOn: DateTime(2020, 1, 1),
          createdAt: created,
          id: 'unknown',
        )
        .addDebt(
          days: 2,
          occurredOn: DateTime(2026, 3, 1),
          createdAt: created.add(const Duration(minutes: 1)),
          sourceRamadanYear: 1447,
          id: 'known',
        );

    expect(ledger.unambiguousCompletionRamadanYear, isNull);
    final completed = ledger.complete(
      occurredOn: DateTime(2026, 9, 21),
      createdAt: created.add(const Duration(minutes: 2)),
      id: 'done',
    );
    expect(completed.entries.last.sourceRamadanYear, isNull);
  });

  test('correction outside a known Ramadan prevents false attribution', () {
    final ledger = QadaFastingLedger()
        .addDebt(
          days: 2,
          occurredOn: DateTime(2026, 3, 1),
          createdAt: created,
          sourceRamadanYear: 1447,
          id: 'known',
        )
        .correctBalance(
          targetDays: 4,
          occurredOn: DateTime(2026, 9, 1),
          createdAt: created.add(const Duration(minutes: 1)),
          id: 'correction',
        );

    expect(ledger.remainingForRamadan(1447), 2);
    expect(ledger.remainingDays, 4);
    expect(ledger.unambiguousCompletionRamadanYear, isNull);
  });

  test('caller can explicitly keep completion unassigned', () {
    final ledger = QadaFastingLedger()
        .addDebt(
          days: 2,
          occurredOn: DateTime(2026, 3, 1),
          createdAt: created,
          sourceRamadanYear: 1447,
          id: 'known',
        )
        .complete(
          occurredOn: DateTime(2026, 9, 21),
          createdAt: created.add(const Duration(minutes: 1)),
          attributeWhenUnambiguous: false,
          id: 'done',
        );

    expect(ledger.entries.last.sourceRamadanYear, isNull);
    expect(ledger.remainingForRamadan(1447), 2);
    expect(ledger.remainingDays, 1);
  });
}
