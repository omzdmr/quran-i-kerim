import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';

void main() {
  test('successive debt additions cannot create an undecodable balance', () {
    final ledger = QadaFastingLedger().addDebt(
      days: 3600,
      occurredOn: DateTime(2026, 1, 1),
      createdAt: DateTime.utc(2026, 9, 20),
      id: 'large-valid-debt',
    );

    expect(ledger.remainingDays, 3600);
    expect(
      () => ledger.addDebt(
        days: 51,
        occurredOn: DateTime(2026, 1, 2),
        createdAt: DateTime.utc(2026, 9, 21),
        id: 'would-overflow',
      ),
      throwsStateError,
    );

    final boundary = ledger.addDebt(
      days: 50,
      occurredOn: DateTime(2026, 1, 2),
      createdAt: DateTime.utc(2026, 9, 21),
      id: 'exact-boundary',
    );
    expect(boundary.remainingDays, QadaFastingLedger.maxBalanceDays);
    expect(
      QadaFastingLedger.decode(boundary.encode()).remainingDays,
      QadaFastingLedger.maxBalanceDays,
    );
  });

  test('completion frees capacity for a later debt correction', () {
    final full = QadaFastingLedger().addDebt(
      days: QadaFastingLedger.maxBalanceDays,
      occurredOn: DateTime(2026, 1, 1),
      createdAt: DateTime.utc(2026, 9, 20),
      id: 'full',
    );
    final reduced = full.complete(
      days: 10,
      occurredOn: DateTime(2026, 2, 1),
      createdAt: DateTime.utc(2026, 9, 21),
      id: 'completed-ten',
    );
    final restored = reduced.addDebt(
      days: 10,
      occurredOn: DateTime(2026, 2, 2),
      createdAt: DateTime.utc(2026, 9, 22),
      id: 'new-ten',
    );

    expect(restored.remainingDays, QadaFastingLedger.maxBalanceDays);
    expect(QadaFastingLedger.decode(restored.encode()).entries, hasLength(3));
  });
}
