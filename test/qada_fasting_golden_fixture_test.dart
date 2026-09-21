import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';

void main() {
  test('v1 golden qada fixture remains readable and round-trippable', () async {
    final source = await File('test/fixtures/qada_fasting_ledger_v1.json').readAsString();
    final ledger = QadaFastingLedger.decode(source);

    expect(ledger.entries.map((entry) => entry.id), <String>[
      'golden-debt-1446',
      'golden-done-1446',
      'golden-debt-1447',
    ]);
    expect(ledger.recordedDebtDays, 5);
    expect(ledger.completedDays, 1);
    expect(ledger.remainingDays, 4);
    expect(ledger.remainingForRamadan(1446), 2);
    expect(ledger.remainingForRamadan(1447), 2);
    expect(ledger.entries.first.estimatedSource, isTrue);
    expect(ledger.entries.first.note, 'Imported from my paper record');

    final secondPass = QadaFastingLedger.decode(ledger.encode());
    expect(secondPass.entries.map((entry) => entry.id), ledger.entries.map((entry) => entry.id));
    expect(secondPass.remainingDays, ledger.remainingDays);
    expect(secondPass.entries.first.note, ledger.entries.first.note);
  });
}
