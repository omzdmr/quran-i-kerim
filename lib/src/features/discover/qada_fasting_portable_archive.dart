import 'dart:convert';

import 'qada_fasting_ledger.dart';

enum QadaArchiveImportMode { merge, replace }

class QadaArchivePreview {
  const QadaArchivePreview({
    required this.ledger,
    required this.incomingEntries,
    required this.newEntries,
    required this.duplicateEntries,
    required this.conflictingEntries,
    required this.remainingDays,
    required this.containsPrivateNotes,
  });

  final QadaFastingLedger ledger;
  final int incomingEntries;
  final int newEntries;
  final int duplicateEntries;
  final int conflictingEntries;
  final int remainingDays;
  final bool containsPrivateNotes;

  bool get canMerge => conflictingEntries == 0;
}

class QadaFastingPortableArchive {
  const QadaFastingPortableArchive();

  static const int formatVersion = 1;
  static const String format = 'quran-i-kerim.qada-fasting-ledger';

  String export(
    QadaFastingLedger ledger, {
    bool includePrivateNotes = false,
    DateTime? createdAt,
  }) {
    final exportedAt = (createdAt ?? DateTime.now()).toUtc();
    return jsonEncode(<String, Object?>{
      'format': format,
      'formatVersion': formatVersion,
      'createdAt': exportedAt.toIso8601String(),
      'privacy': <String, Object?>{
        'privateNotesIncluded': includePrivateNotes,
      },
      'ledger': <String, Object?>{
        'formatVersion': QadaFastingLedger.formatVersion,
        'entries': <Object?>[
          for (final entry in ledger.entries)
            <String, Object?>{
              ...entry.toJson(),
              if (!includePrivateNotes) 'note': null,
            },
        ],
      },
    });
  }

  QadaArchivePreview preview(
    String source, {
    QadaFastingLedger? current,
  }) {
    final decoded = _decodeArchive(source);
    final currentLedger = current ?? QadaFastingLedger();
    final currentById = <String, QadaFastingEntry>{
      for (final entry in currentLedger.entries) entry.id: entry,
    };
    var duplicateCount = 0;
    var conflictCount = 0;
    for (final entry in decoded.entries) {
      final existing = currentById[entry.id];
      if (existing == null) continue;
      if (_sameEntry(existing, entry)) {
        duplicateCount++;
      } else {
        conflictCount++;
      }
    }
    return QadaArchivePreview(
      ledger: decoded,
      incomingEntries: decoded.entries.length,
      newEntries: decoded.entries.length - duplicateCount - conflictCount,
      duplicateEntries: duplicateCount,
      conflictingEntries: conflictCount,
      remainingDays: decoded.remainingDays,
      containsPrivateNotes: decoded.entries.any(
        (entry) => entry.note != null && entry.note!.isNotEmpty,
      ),
    );
  }

  QadaFastingLedger import(
    String source, {
    required QadaFastingLedger current,
    QadaArchiveImportMode mode = QadaArchiveImportMode.merge,
  }) {
    final incoming = _decodeArchive(source);
    if (mode == QadaArchiveImportMode.replace) return incoming;

    final byId = <String, QadaFastingEntry>{
      for (final entry in current.entries) entry.id: entry,
    };
    for (final entry in incoming.entries) {
      final existing = byId[entry.id];
      if (existing == null) {
        byId[entry.id] = entry;
        continue;
      }
      if (!_sameEntry(existing, entry)) {
        throw const FormatException(
          'Archive contains a record id that conflicts with local history.',
        );
      }
    }

    final merged = byId.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final encoded = jsonEncode(<String, Object?>{
      'formatVersion': QadaFastingLedger.formatVersion,
      'entries': merged.map((entry) => entry.toJson()).toList(growable: false),
    });
    final ledger = QadaFastingLedger.decode(encoded);
    if (ledger.entries.length != merged.length) {
      throw const FormatException(
        'Merged archive would create an incoherent qada history.',
      );
    }
    return ledger;
  }

  QadaFastingLedger _decodeArchive(String source) {
    Object? raw;
    try {
      raw = jsonDecode(source);
    } catch (_) {
      throw const FormatException('Archive is not valid JSON.');
    }
    if (raw is! Map ||
        raw['format'] != format ||
        raw['formatVersion'] != formatVersion) {
      throw const FormatException('Unsupported qada archive format.');
    }
    final ledgerRaw = raw['ledger'];
    if (ledgerRaw is! Map) {
      throw const FormatException('Archive does not contain a qada ledger.');
    }
    final entries = ledgerRaw['entries'];
    if (ledgerRaw['formatVersion'] != QadaFastingLedger.formatVersion ||
        entries is! List ||
        entries.length > QadaFastingLedger.maxEntries) {
      throw const FormatException('Unsupported qada ledger payload.');
    }
    final parsed = <QadaFastingEntry>[];
    final ids = <String>{};
    for (final rawEntry in entries) {
      final entry = QadaFastingEntry.fromJson(rawEntry);
      if (entry == null || !ids.add(entry.id)) {
        throw const FormatException('Archive contains an invalid qada record.');
      }
      parsed.add(entry);
    }
    final canonical = jsonEncode(<String, Object?>{
      'formatVersion': QadaFastingLedger.formatVersion,
      'entries': parsed.map((entry) => entry.toJson()).toList(growable: false),
    });
    final ledger = QadaFastingLedger.decode(canonical);
    if (ledger.entries.length != parsed.length) {
      throw const FormatException('Archive contains incoherent qada history.');
    }
    return ledger;
  }

  bool _sameEntry(QadaFastingEntry a, QadaFastingEntry b) =>
      jsonEncode(a.toJson()) == jsonEncode(b.toJson());
}
