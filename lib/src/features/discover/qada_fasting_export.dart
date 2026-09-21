import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'qada_fasting_ledger.dart';

class QadaFastingCsvExporter {
  const QadaFastingCsvExporter();

  String build(
    QadaFastingLedger ledger, {
    bool includePrivateNotes = false,
  }) {
    final columns = <String>[
      'occurred_on',
      'entry_type',
      'days',
      'balance_delta',
      'source_ramadan_hijri',
      'estimated_source',
      if (includePrivateNotes) 'private_note',
    ];
    final rows = <List<String>>[
      columns,
      for (final entry in ledger.entries)
        <String>[
          _isoDate(entry.occurredOn),
          entry.kind.name,
          '${entry.days}',
          '${entry.balanceDelta}',
          entry.sourceRamadanYear?.toString() ?? '',
          entry.estimatedSource ? 'true' : 'false',
          if (includePrivateNotes) _safeUserText(entry.note ?? ''),
        ],
    ];
    return rows
        .map((row) => row.map(_csvCell).join(','))
        .join('\r\n');
  }

  String _safeUserText(String value) {
    final trimmedLeft = value.trimLeft();
    if (trimmedLeft.startsWith('=') ||
        trimmedLeft.startsWith('+') ||
        trimmedLeft.startsWith('-') ||
        trimmedLeft.startsWith('@')) {
      return "'$value";
    }
    return value;
  }

  String _csvCell(String value) {
    if (!value.contains(',') &&
        !value.contains('"') &&
        !value.contains('\n') &&
        !value.contains('\r')) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }
}

class QadaFastingExportFileService {
  const QadaFastingExportFileService({
    this.exporter = const QadaFastingCsvExporter(),
    this.directoryProvider,
  });

  final QadaFastingCsvExporter exporter;
  final Future<Directory> Function()? directoryProvider;

  Future<File> createFile(
    QadaFastingLedger ledger, {
    bool includePrivateNotes = false,
    DateTime? now,
  }) async {
    final directory = await (directoryProvider ?? getTemporaryDirectory)();
    final createdOn = now ?? DateTime.now();
    final file = File(
      '${directory.path}/qada-fasting-ledger-${_isoDate(createdOn)}.csv',
    );
    final csv = exporter.build(
      ledger,
      includePrivateNotes: includePrivateNotes,
    );
    return file.writeAsString('\ufeff$csv', flush: true);
  }
}

String _isoDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
