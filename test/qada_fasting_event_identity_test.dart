import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';

void main() {
  test('generated ids remain unique when two events share the same timestamp', () {
    final timestamp = DateTime.utc(2026, 9, 21, 10);
    final ledger = QadaFastingLedger()
        .addDebt(days: 2, occurredOn: DateTime(2026, 3, 1), createdAt: timestamp)
        .complete(occurredOn: DateTime(2026, 9, 21), createdAt: timestamp);
    expect(ledger.entries.map((entry) => entry.id).toSet(), hasLength(2));
    expect(ledger.entries.last.id, endsWith('-2'));
    final restored = QadaFastingLedger.decode(ledger.encode());
    expect(restored.entries, hasLength(2));
    expect(restored.remainingDays, 1);
  });

  test('oversized imported event arrays fail closed', () {
    final event = <String, Object?>{'id': 'template', 'kind': 'debt', 'days': 1, 'occurredOn': '2026-03-01T00:00:00.000', 'createdAt': '2026-09-21T10:00:00.000Z'};
    final entries = List<Object?>.generate(QadaFastingLedger.maxEntries + 1, (index) => <String, Object?>{...event, 'id': 'event-$index'}, growable: false);
    final restored = QadaFastingLedger.decode(jsonEncode(<String, Object?>{'formatVersion': QadaFastingLedger.formatVersion, 'entries': entries}));
    expect(restored.entries, isEmpty);
  });

  test('oversized imported ids and notes are bounded', () {
    final oversizedId = List<String>.filled(129, 'x').join();
    final oversizedNote = List<String>.filled(800, 'n').join();
    final invalidId = QadaFastingLedger.decode(jsonEncode(<String, Object?>{
      'formatVersion': 1,
      'entries': <Object?>[<String, Object?>{'id': oversizedId, 'kind': 'debt', 'days': 1, 'occurredOn': '2026-03-01', 'createdAt': '2026-09-21T10:00:00Z'}],
    }));
    expect(invalidId.entries, isEmpty);

    final longNote = QadaFastingLedger.decode(jsonEncode(<String, Object?>{
      'formatVersion': 1,
      'entries': <Object?>[<String, Object?>{'id': 'valid', 'kind': 'debt', 'days': 1, 'occurredOn': '2026-03-01', 'createdAt': '2026-09-21T10:00:00Z', 'note': oversizedNote}],
    }));
    expect(longNote.entries.single.note, hasLength(500));
  });
}
