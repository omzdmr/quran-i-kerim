import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_portable_archive.dart';

void main() {
  const archive = QadaFastingPortableArchive();

  QadaFastingLedger ledger() => QadaFastingLedger().addDebt(
        days: 2,
        occurredOn: DateTime(2026, 3, 1),
        createdAt: DateTime.utc(2026, 9, 22),
        sourceRamadanYear: 1447,
        id: 'integrity-event',
      );

  test('fresh portable backup carries verifiable sha256 integrity metadata', () {
    final source = archive.export(
      ledger(),
      createdAt: DateTime.utc(2026, 9, 22),
    );
    final raw = jsonDecode(source) as Map<String, dynamic>;
    final integrity = raw['integrity'] as Map<String, dynamic>;

    expect(integrity['algorithm'], 'sha256');
    expect(integrity['ledgerSha256'], isA<String>());
    expect((integrity['ledgerSha256'] as String), hasLength(64));
    expect(archive.preview(source).remainingDays, 2);
  });

  test('tampered ledger payload is rejected before import', () {
    final raw = jsonDecode(archive.export(ledger())) as Map<String, dynamic>;
    final ledgerRaw = raw['ledger'] as Map<String, dynamic>;
    final entries = ledgerRaw['entries'] as List<dynamic>;
    final first = entries.first as Map<String, dynamic>;
    first['days'] = 9;
    final tampered = jsonEncode(raw);

    expect(() => archive.preview(tampered), throwsFormatException);
    expect(
      () => archive.import(
        tampered,
        current: QadaFastingLedger(),
      ),
      throwsFormatException,
    );
  });

  test('missing or unknown integrity metadata is rejected', () {
    final raw = jsonDecode(archive.export(ledger())) as Map<String, dynamic>;
    raw.remove('integrity');
    expect(() => archive.preview(jsonEncode(raw)), throwsFormatException);

    final unknown = jsonDecode(archive.export(ledger())) as Map<String, dynamic>;
    (unknown['integrity'] as Map<String, dynamic>)['algorithm'] = 'sha1';
    expect(() => archive.preview(jsonEncode(unknown)), throwsFormatException);
  });
}
