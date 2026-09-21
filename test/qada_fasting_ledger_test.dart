import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/qada_fasting_ledger.dart';

void main() {
  test('ledger preserves per-Ramadan debt and completion history', () {
    final ledger = QadaFastingLedger([
      QadaFastEntry(id: 'a', kind: QadaFastEntryKind.debt, days: 6, recordedAt: DateTime.utc(2025, 4), sourceHijriYear: 1446),
      QadaFastEntry(id: 'b', kind: QadaFastEntryKind.debt, days: 4, recordedAt: DateTime.utc(2026, 4), sourceHijriYear: 1447),
      QadaFastEntry(id: 'c', kind: QadaFastEntryKind.completion, days: 3, recordedAt: DateTime.utc(2026, 7), completedAt: DateTime.utc(2026, 7)),
    ]);
    expect(ledger.totalRecordedDebt, 10);
    expect(ledger.totalCompleted, 3);
    expect(ledger.balance, 7);
    expect(ledger.newestFirst.first.id, 'c');
  });

  test('json roundtrip keeps private optional metadata', () {
    final original = QadaFastEntry(id: 'x', kind: QadaFastEntryKind.debt, days: 2, recordedAt: DateTime.utc(2026, 3, 1), sourceHijriYear: 1447, note: 'özel not');
    final restored = QadaFastEntry.fromJson(original.toJson());
    expect(restored?.id, 'x');
    expect(restored?.sourceHijriYear, 1447);
    expect(restored?.note, 'özel not');
  });

  test('invalid persisted entry is rejected', () {
    expect(QadaFastEntry.fromJson({'id': 'bad', 'kind': 'debt', 'days': 0, 'recordedAt': 'nope'}), isNull);
  });
}
