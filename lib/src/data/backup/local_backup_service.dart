import 'dart:convert';

import 'backup_document.dart';
import 'backup_import_plan.dart';
import 'backup_manifest.dart';
import 'backup_preview.dart';
import 'backup_restore_coordinator.dart';
import 'shared_preferences_backup_adapter.dart';

enum BackupRestoreMode { merge, replace }

class LocalBackupService {
  const LocalBackupService({
    this.adapter = const SharedPreferencesBackupAdapter(),
    this.previewParser = const BackupPreviewParser(),
    this.importPlanner = const BackupImportPlanner(),
    this.restoreCoordinator = const BackupRestoreCoordinator(),
  });

  final SharedPreferencesBackupAdapter adapter;
  final BackupPreviewParser previewParser;
  final BackupImportPlanner importPlanner;
  final BackupRestoreCoordinator restoreCoordinator;

  Future<BackupDocument> createDocument({DateTime? now}) async {
    final sections = await adapter.captureSections();
    return BackupDocument(version: BackupManifest.schemaVersion, createdAt: (now ?? DateTime.now()).toUtc(), data: BackupManifest.selectBackupData(sections));
  }

  Future<String> exportJson({DateTime? now}) async => (await createDocument(now: now)).encode();
  BackupPreview previewDecoded(Object? decoded) => previewParser.parse(decoded);

  BackupPreview previewJson(String encoded) {
    try { return previewParser.parse(jsonDecode(encoded)); } on FormatException { return previewParser.parse(null); }
  }

  Future<BackupImportPlan> planImportJson(String encoded) async {
    final decoded = jsonDecode(encoded);
    final incoming = _validatedSections(decoded);
    final current = await adapter.captureSections();
    return importPlanner.build(currentSections: current, incomingSections: incoming);
  }

  Future<void> restoreJson(String encoded, {BackupRestoreMode mode = BackupRestoreMode.replace}) async {
    await restoreDecoded(jsonDecode(encoded), mode: mode);
  }

  Future<void> restoreDecoded(Object? decoded, {BackupRestoreMode mode = BackupRestoreMode.replace}) async {
    Map<String, Object?>? normalizedData;
    int? normalizedVersion;
    await restoreCoordinator.restore(
      validate: () async {
        normalizedData = _validatedSections(decoded);
        normalizedVersion = previewParser.parse(decoded).version;
      },
      captureSnapshot: adapter.capture,
      applyRestore: () async {
        var dataToRestore = normalizedData!;
        if (mode == BackupRestoreMode.merge) {
          final current = await adapter.captureSections();
          dataToRestore = _mergeSections(current, normalizedData!);
        }
        await adapter.restoreSections(dataToRestore, schemaVersion: normalizedVersion!);
      },
      rollback: (snapshot) async {
        if (snapshot is! Map) throw const FormatException('Backup rollback snapshot is invalid.');
        await adapter.restore(Map<String, Object?>.from(snapshot));
      },
    );
  }

  Map<String, Object?> _validatedSections(Object? decoded) {
    final preview = previewParser.parse(decoded);
    if (!preview.canRestore || decoded is! Map || preview.version == null) throw const FormatException('Backup is not restorable.');
    final rawData = decoded['data'];
    if (rawData is! Map) throw const FormatException('Backup data is invalid.');
    final selected = <String, Object?>{};
    for (final entry in rawData.entries) {
      if (entry.key is! String) throw const FormatException('Backup section key is invalid.');
      final section = entry.key as String;
      if (BackupManifest.sectionsForVersion(preview.version!).contains(section)) selected[section] = entry.value;
    }
    return Map<String, Object?>.unmodifiable(selected);
  }

  Map<String, Object?> _mergeSections(Map<String, Object?> current, Map<String, Object?> incoming) {
    final merged = <String, Object?>{};
    for (final section in BackupManifest.includedSections) {
      final currentSection = current[section];
      final incomingSection = incoming[section];
      if (currentSection is Map || incomingSection is Map) {
        final currentMap = _stringMap(currentSection);
        final incomingMap = _stringMap(incomingSection);
        final keys = <String>{...currentMap.keys, ...incomingMap.keys};
        merged[section] = <String, Object?>{
          for (final key in keys)
            key: _mergePreferenceValue(section: section, key: key, current: currentMap[key], incoming: incomingMap[key], hasIncoming: incomingMap.containsKey(key)),
        };
      } else if (incoming.containsKey(section)) {
        merged[section] = incomingSection;
      } else if (current.containsKey(section)) {
        merged[section] = currentSection;
      }
    }
    return Map<String, Object?>.unmodifiable(merged);
  }

  Map<String, Object?> _stringMap(Object? value) {
    if (value is! Map) return const <String, Object?>{};
    return <String, Object?>{for (final entry in value.entries) if (entry.key is String) entry.key as String: entry.value};
  }

  Object? _mergePreferenceValue({required String section, required String key, required Object? current, required Object? incoming, required bool hasIncoming}) {
    if (!hasIncoming) return current;
    if (current == null) return incoming;
    if (section == 'memorization' && const {'memorized_pages_v1', 'memorization_practice_days_v1', 'memorization_plan_missed_days_v1'}.contains(key)) {
      return _mergeStringLists(current, incoming);
    }
    if (section == 'memorization' && key == 'memorization_page_progress_v1') return _mergePageProgress(current, incoming);
    if (section == 'memorizationPractice' && key == 'memorization_practice_history_v1') return _mergeJsonEventLists(current, incoming);
    return incoming;
  }

  Object? _mergeStringLists(Object? current, Object? incoming) {
    if (current is! List || incoming is! List) return current;
    if (current.any((value) => value is! String) || incoming.any((value) => value is! String)) return current;
    final values = <String>{...current.cast<String>(), ...incoming.cast<String>()}.toList()
      ..sort((a, b) {
        final aInt = int.tryParse(a);
        final bInt = int.tryParse(b);
        if (aInt != null && bInt != null) return aInt.compareTo(bInt);
        return a.compareTo(b);
      });
    return values;
  }

  Object? _mergePageProgress(Object? current, Object? incoming) {
    if (current is! String || incoming is! String) return current;
    try {
      final currentDecoded = jsonDecode(current);
      final incomingDecoded = jsonDecode(incoming);
      if (currentDecoded is! Map || incomingDecoded is! Map) return current;
      final merged = <String, Object?>{};
      final keys = <String>{...currentDecoded.keys.whereType<String>(), ...incomingDecoded.keys.whereType<String>()};
      for (final key in keys) {
        final local = currentDecoded[key];
        final remote = incomingDecoded[key];
        if (local == null) {
          merged[key] = remote;
        } else if (remote == null) {
          merged[key] = local;
        } else {
          merged[key] = _newerProgress(local, remote);
        }
      }
      return jsonEncode(merged);
    } on FormatException { return current; }
  }

  Object? _newerProgress(Object? local, Object? incoming) {
    if (local is! Map || incoming is! Map) return local;
    DateTime? timestamp(Map value) {
      final reviewed = value['lastReviewedAt'];
      final memorized = value['memorizedAt'];
      return DateTime.tryParse(reviewed?.toString() ?? '') ?? DateTime.tryParse(memorized?.toString() ?? '');
    }
    final localTime = timestamp(local);
    final incomingTime = timestamp(incoming);
    if (localTime == null && incomingTime != null) return incoming;
    if (incomingTime == null) return local;
    if (localTime == null) return incoming;
    return incomingTime.isAfter(localTime) ? incoming : local;
  }

  Object? _mergeJsonEventLists(Object? current, Object? incoming) {
    if (current is! String || incoming is! String) return current;
    try {
      final currentDecoded = jsonDecode(current);
      final incomingDecoded = jsonDecode(incoming);
      if (currentDecoded is! List || incomingDecoded is! List) return current;
      final byId = <String, Object?>{};
      void addEvents(List<dynamic> events) {
        for (final event in events) {
          if (event is! Map || event['id'] is! String) continue;
          byId[event['id'] as String] = event;
        }
      }
      addEvents(currentDecoded);
      addEvents(incomingDecoded);
      final merged = byId.values.toList(growable: false)
        ..sort((a, b) {
          final aDate = a is Map ? a['occurredAt']?.toString() ?? '' : '';
          final bDate = b is Map ? b['occurredAt']?.toString() ?? '' : '';
          return bDate.compareTo(aDate);
        });
      return jsonEncode(merged.take(4000).toList(growable: false));
    } on FormatException { return current; }
  }
}
