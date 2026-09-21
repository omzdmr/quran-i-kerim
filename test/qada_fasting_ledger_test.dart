import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final created = DateTime.utc(2026, 9, 21, 6);

  test('ledger preserves debt, completion and explicit correction history', () {
    final ledger = QadaFastingLedger()
        .addDebt(
          days: 7,
          occurredOn: DateTime(2026, 3, 20),
          createdAt: created,
          sourceRamadanYear: 1447,
          id: 'debt-1',
        )
        .complete(
          occurredOn: DateTime(2026, 9, 20),
          createdAt: created.add(const Duration(minutes: 1)),
          id: 'done-1',
        )
        .correctBalance(
          targetDays: 4,
          occurredOn: DateTime(2026, 9, 21),
          createdAt: created.add(const Duration(minutes: 2)),
          note: 'Earlier paper record',
          id: 'fix-1',
        );

    expect(ledger.recordedDebtDays, 7);
    expect(ledger.completedDays, 1);
    expect(ledger.remainingDays, 4);
    expect(ledger.entries, hasLength(3));
    expect(ledger.entries.last.kind, QadaFastingEntryKind.correction);
    expect(ledger.entries.last.days, -2);
    expect(ledger.debtByRamadan[1447], 7);
  });

  test('unknown historical source remains explicitly estimated', () {
    final ledger = QadaFastingLedger().addDebt(
      days: 12,
      occurredOn: DateTime(2026, 1, 1),
      createdAt: created,
      id: 'estimated',
    );

    expect(ledger.entries.single.sourceRamadanYear, isNull);
    expect(ledger.entries.single.estimatedSource, isTrue);
    expect(ledger.remainingDays, 12);
  });

  test('completion cannot silently make the balance negative', () {
    final ledger = QadaFastingLedger().addDebt(
      days: 1,
      occurredOn: DateTime(2026, 1, 1),
      createdAt: created,
      id: 'debt',
    );

    expect(
      () => ledger.complete(
        days: 2,
        occurredOn: DateTime(2026, 9, 21),
        createdAt: created.add(const Duration(minutes: 1)),
      ),
      throwsStateError,
    );
  });

  test('round trip keeps optional private provenance without invention', () {
    final original = QadaFastingLedger().addDebt(
      days: 3,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: created,
      sourceRamadanYear: 1446,
      estimatedSource: true,
      note: 'Estimated from my own paper notes',
      id: 'debt',
    );

    final restored = QadaFastingLedger.decode(original.encode());

    expect(restored.remainingDays, 3);
    expect(restored.entries.single.sourceRamadanYear, 1446);
    expect(restored.entries.single.estimatedSource, isTrue);
    expect(restored.entries.single.note, 'Estimated from my own paper notes');
  });

  test('corrupt, duplicate and overdrawn events fail closed', () {
    final restored = QadaFastingLedger.decode(
      '{"formatVersion":1,"entries":['
      '{"id":"a","kind":"debt","days":2,"occurredOn":"2026-01-01","createdAt":"2026-01-01T00:00:00Z"},'
      '{"id":"a","kind":"debt","days":99,"occurredOn":"2026-01-01","createdAt":"2026-01-01T00:00:01Z"},'
      '{"id":"b","kind":"completion","days":3,"occurredOn":"2026-01-02","createdAt":"2026-01-02T00:00:00Z"}'
      ']}',
    );

    expect(restored.remainingDays, 2);
    expect(restored.entries, hasLength(1));
    expect(QadaFastingLedger.decode('{broken').entries, isEmpty);
  });

  test('store persists across process-style reload', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = QadaFastingStore();
    final ledger = QadaFastingLedger().addDebt(
      days: 5,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: created,
      sourceRamadanYear: 1447,
      id: 'persistent',
    );

    await store.save(ledger);
    final restored = await store.load();

    expect(restored.remainingDays, 5);
    expect(restored.debtByRamadan[1447], 5);
  });
}
