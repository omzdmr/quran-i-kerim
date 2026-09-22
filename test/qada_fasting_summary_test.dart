import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_summary.dart';

void main() {
  test('summary reconciles known, unknown and unattributed qada events', () {
    var ledger = QadaFastingLedger()
        .addDebt(
          days: 4,
          occurredOn: DateTime(2025, 3, 1),
          createdAt: DateTime.utc(2026, 9, 21, 1),
          sourceRamadanYear: 1446,
          id: 'known',
        )
        .addDebt(
          days: 3,
          occurredOn: DateTime(2024, 3, 1),
          createdAt: DateTime.utc(2026, 9, 21, 2),
          id: 'unknown',
        )
        .complete(
          occurredOn: DateTime(2026, 9, 20),
          createdAt: DateTime.utc(2026, 9, 21, 3),
          attributeWhenUnambiguous: false,
          id: 'unattributed-completion',
        );

    ledger = ledger.correctBalance(
      targetDays: 7,
      occurredOn: DateTime(2026, 9, 21),
      createdAt: DateTime.utc(2026, 9, 21, 4),
      id: 'correction',
    );

    final summary = QadaFastingBalanceSummary.fromLedger(ledger);
    expect(summary.knownRamadanRemainingDays, 4);
    expect(summary.unknownYearDebtDays, 3);
    expect(summary.unattributedCompletedDays, 1);
    expect(summary.correctionDeltaDays, 1);
    expect(summary.unallocatedBalanceDays, 3);
    expect(summary.totalRemainingDays, 7);
    expect(summary.reconciles, isTrue);
  });
}
