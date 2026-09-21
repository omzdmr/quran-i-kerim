import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'backup_manifest.dart';

enum BackupPreviewIssue { invalidRoot, unsupportedVersion, invalidCreatedAt, invalidData, unsupportedIntegrity, checksumMismatch }

class BackupPreview {
  const BackupPreview({required this.version, required this.createdAt, required this.recordCounts, required this.issues, this.integrityVerified = false});
  final int? version; final DateTime? createdAt; final Map<String, int> recordCounts; final Set<BackupPreviewIssue> issues; final bool integrityVerified;
  bool get canRestore => issues.isEmpty;
  int get totalRecords => recordCounts.values.fold<int>(0, (total, count) => total + count);
}

class BackupPreviewParser {
  const BackupPreviewParser();
  static const int currentVersion = BackupManifest.schemaVersion;
  BackupPreview parse(Object? decoded) {
    if (decoded is! Map) return const BackupPreview(version: null, createdAt: null, recordCounts: <String, int>{}, issues: <BackupPreviewIssue>{BackupPreviewIssue.invalidRoot});
    final issues = <BackupPreviewIssue>{}; final version = decoded['version']; final parsedVersion = version is int ? version : null;
    if (parsedVersion == null || !BackupManifest.isVersionSupported(parsedVersion)) issues.add(BackupPreviewIssue.unsupportedVersion);
    final rawCreatedAt = decoded['createdAt']; final createdAt = rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt)?.toUtc() : null; if (createdAt == null) issues.add(BackupPreviewIssue.invalidCreatedAt);
    final data = decoded['data']; final counts = <String, int>{};
    if (data is Map) {
      for (final entry in data.entries) {
        if (entry.key is! String) { issues.add(BackupPreviewIssue.invalidData); continue; }
        final section = entry.key as String; final value = entry.value;
        if (value is List) counts[section] = value.length;
        else if (value is Map) { final count = _sectionRecordCount(section, value); if (count == null) { issues.add(BackupPreviewIssue.invalidData); counts[section] = 0; } else { counts[section] = count; } }
        else if (value == null) counts[section] = 0; else issues.add(BackupPreviewIssue.invalidData);
      }
    } else { issues.add(BackupPreviewIssue.invalidData); }
    var integrityVerified = false; final integrity = decoded['integrity'];
    if (integrity != null) {
      if (integrity is! Map || integrity['algorithm'] != 'sha256') issues.add(BackupPreviewIssue.unsupportedIntegrity);
      else if (data is Map) { final expected = integrity['dataSha256']; final actual = sha256.convert(utf8.encode(jsonEncode(data))).toString(); if (expected is! String || expected != actual) issues.add(BackupPreviewIssue.checksumMismatch); else integrityVerified = true; }
    }
    return BackupPreview(version: parsedVersion, createdAt: createdAt, recordCounts: Map<String, int>.unmodifiable(counts), issues: Set<BackupPreviewIssue>.unmodifiable(issues), integrityVerified: integrityVerified);
  }

  int? _sectionRecordCount(String section, Map value) {
    if (section != 'fasting') return value.length;
    final encoded = value['qada_fasting_ledger_v1']; if (encoded == null) return value.length; if (encoded is! String) return null;
    try {
      final ledger = jsonDecode(encoded); if (ledger is! Map || ledger['formatVersion'] != 1 || ledger['entries'] is! List) return null;
      final entries = ledger['entries'] as List; if (entries.length > 20000) return null;
      final ids = <String>{}; final debtByYear = <int, int>{}; final completionByYear = <int, int>{}; var balance = 0;
      for (final raw in entries) {
        if (raw is! Map) return null;
        final id = raw['id']; final kind = raw['kind']; final days = raw['days']; final occurredOn = raw['occurredOn']; final createdAt = raw['createdAt']; final sourceYear = raw['sourceRamadanYear']; final note = raw['note'];
        if (id is! String || id.trim().isEmpty || id.length > 128 || !ids.add(id) || kind is! String || !const {'debt', 'completion', 'correction'}.contains(kind) || days is! int || days == 0 || days.abs() > 3650 || occurredOn is! String || DateTime.tryParse(occurredOn) == null || createdAt is! String || DateTime.tryParse(createdAt) == null || (sourceYear != null && (sourceYear is! int || sourceYear < 1 || sourceYear > 9999)) || (note != null && (note is! String || note.length > 500))) return null;
        balance += kind == 'completion' ? -days : days;
        if (sourceYear is int && kind == 'debt') debtByYear[sourceYear] = (debtByYear[sourceYear] ?? 0) + days;
        if (sourceYear is int && kind == 'completion') completionByYear[sourceYear] = (completionByYear[sourceYear] ?? 0) + days;
      }
      if (balance < 0 || balance > 3650) return null;
      for (final item in completionByYear.entries) { if (item.value > (debtByYear[item.key] ?? 0)) return null; }
      return entries.length;
    } on FormatException { return null; }
  }
}
