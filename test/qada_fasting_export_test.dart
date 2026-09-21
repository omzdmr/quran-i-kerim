import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_export.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';

void main() {
  const exporter = QadaFastingCsvExporter();
  final created = DateTime.utc(2026, 9, 21, 7);

  QadaFastingLedger buildLedger() => QadaFastingLedger()
      .addDebt(
        days: 3,
        occurredOn: DateTime(2025, 3, 2),
        createdAt: created,
        sourceRamadanYear: 1446,
        estimatedSource: true,
        note: 'private, opening balance',
        id: 'debt',
      )
      .complete(
        occurredOn: DateTime(2026, 9, 21),
        createdAt: created.add(const Duration(minutes: 1)),
        note: '=sensitive formula',
        id: 'done',
      );

  test('default export omits private note column and values', () {
    final csv = exporter.build(buildLedger());

    expect(csv, startsWith(
      'occurred_on,entry_type,days,balance_delta,'
      'source_ramadan_hijri,estimated_source',
    ));
    expect(csv, isNot(contains('private_note')));
    expect(csv, isNot(contains('opening balance')));
    expect(csv, isNot(contains('sensitive formula')));
    expect(csv, contains('2025-03-02,debt,3,3,1446,true'));
    expect(csv, contains('2026-09-21,completion,1,-1,,false'));
  });

  test('opt-in private notes are escaped and spreadsheet-safe', () {
    final csv = exporter.build(
      buildLedger(),
      includePrivateNotes: true,
    );

    expect(csv, contains('private_note'));
    expect(csv, contains('"private, opening balance"'));
    expect(csv, contains("'=sensitive formula"));
    expect(csv.split('\r\n'), hasLength(3));
  });

  test('file service writes a dated UTF-8 file without private notes', () async {
    final directory = await Directory.systemTemp.createTemp('qada-export-test');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });
    final service = QadaFastingExportFileService(
      directoryProvider: () async => directory,
    );

    final file = await service.createFile(
      buildLedger(),
      now: DateTime(2026, 9, 21),
    );
    final content = await file.readAsString();

    expect(file.path, endsWith('qada-fasting-ledger-2026-09-21.csv'));
    expect(content, startsWith('\ufeffoccurred_on'));
    expect(content, isNot(contains('opening balance')));
    expect(content, isNot(contains('sensitive formula')));
  });

  test('empty ledger still exports a stable machine-readable header', () {
    final csv = exporter.build(QadaFastingLedger());

    expect(csv.split('\r\n'), hasLength(1));
    expect(csv, contains('occurred_on'));
  });
}
