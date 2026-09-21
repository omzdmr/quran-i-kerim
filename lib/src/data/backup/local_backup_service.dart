import 'dart:convert';

import 'backup_document.dart';
import 'backup_import_plan.dart';
import 'backup_manifest.dart';
import 'backup_preview.dart';
import 'backup_restore_coordinator.dart';
import 'shared_preferences_backup_adapter.dart';

enum BackupRestoreMode { merge, replace }

class LocalBackupService {
  const LocalBackupService({this.adapter = const SharedPreferencesBackupAdapter(), this.previewParser = const BackupPreviewParser(), this.importPlanner = const BackupImportPlanner(), this.restoreCoordinator = const BackupRestoreCoordinator()});
  final SharedPreferencesBackupAdapter adapter;
  final BackupPreviewParser previewParser;
  final BackupImportPlanner importPlanner;
  final BackupRestoreCoordinator restoreCoordinator;

  Future<BackupDocument> createDocument({DateTime? now}) async { final sections = await adapter.captureSections(); return BackupDocument(version: BackupManifest.schemaVersion, createdAt: (now ?? DateTime.now()).toUtc(), data: BackupManifest.selectBackupData(sections)); }
  Future<String> exportJson({DateTime? now}) async => (await createDocument(now: now)).encode();
  BackupPreview previewDecoded(Object? decoded) => previewParser.parse(decoded);
  BackupPreview previewJson(String encoded) { try { return previewParser.parse(jsonDecode(encoded)); } on FormatException { return previewParser.parse(null); } }
  Future<BackupImportPlan> planImportJson(String encoded) async { final decoded = jsonDecode(encoded); final incoming = _validatedSections(decoded); final current = await adapter.captureSections(); return importPlanner.build(currentSections: current, incomingSections: incoming); }
  Future<void> restoreJson(String encoded, {BackupRestoreMode mode = BackupRestoreMode.replace}) async => restoreDecoded(jsonDecode(encoded), mode: mode);

  Future<void> restoreDecoded(Object? decoded, {BackupRestoreMode mode = BackupRestoreMode.replace}) async {
    Map<String, Object?>? normalizedData; int? normalizedVersion;
    await restoreCoordinator.restore(
      validate: () async { normalizedData = _validatedSections(decoded); normalizedVersion = previewParser.parse(decoded).version; },
      captureSnapshot: adapter.capture,
      applyRestore: () async { var dataToRestore = normalizedData!; if (mode == BackupRestoreMode.merge) { final current = await adapter.captureSections(); dataToRestore = _mergeSections(current, normalizedData!); } await adapter.restoreSections(dataToRestore, schemaVersion: normalizedVersion!); },
      rollback: (snapshot) async { if (snapshot is! Map) throw const FormatException('Backup rollback snapshot is invalid.'); await adapter.restore(Map<String, Object?>.from(snapshot)); },
    );
  }

  Map<String, Object?> _validatedSections(Object? decoded) {
    final preview = previewParser.parse(decoded);
    if (!preview.canRestore || decoded is! Map || preview.version == null) throw const FormatException('Backup is not restorable.');
    final rawData = decoded['data']; if (rawData is! Map) throw const FormatException('Backup data is invalid.');
    final selected = <String, Object?>{};
    for (final entry in rawData.entries) {
      if (entry.key is! String) throw const FormatException('Backup section key is invalid.');
      final section = entry.key as String;
      if (!BackupManifest.sectionsForVersion(preview.version!).contains(section)) continue;
      if (section == 'fasting') _validateFastingSection(entry.value);
      selected[section] = entry.value;
    }
    return Map<String, Object?>.unmodifiable(selected);
  }

  void _validateFastingSection(Object? rawSection) {
    if (rawSection is! Map) throw const FormatException('Fasting backup section is invalid.');
    final encoded = rawSection['qada_fasting_ledger_v1'];
    if (encoded == null) return;
    if (encoded is! String || _qadaEvents(_decodeMap(encoded)) == null) throw const FormatException('Qada fasting ledger in backup is invalid.');
  }

  Map<String, Object?> _mergeSections(Map<String, Object?> current, Map<String, Object?> incoming) {
    final merged = <String, Object?>{};
    for (final section in BackupManifest.includedSections) {
      final currentSection = current[section]; final incomingSection = incoming[section];
      if (currentSection is Map || incomingSection is Map) {
        final currentMap = _stringMap(currentSection); final incomingMap = _stringMap(incomingSection); final keys = <String>{...currentMap.keys, ...incomingMap.keys};
        merged[section] = <String, Object?>{for (final key in keys) key: _mergePreferenceValue(section: section, key: key, current: currentMap[key], incoming: incomingMap[key], hasIncoming: incomingMap.containsKey(key))};
      } else if (incoming.containsKey(section)) { merged[section] = incomingSection; } else if (current.containsKey(section)) { merged[section] = currentSection; }
    }
    return Map<String, Object?>.unmodifiable(merged);
  }

  Map<String, Object?> _stringMap(Object? value) { if (value is! Map) return const <String, Object?>{}; return <String, Object?>{for (final entry in value.entries) if (entry.key is String) entry.key as String: entry.value}; }
  Object? _mergePreferenceValue({required String section, required String key, required Object? current, required Object? incoming, required bool hasIncoming}) {
    if (!hasIncoming) return current; if (current == null) return incoming;
    if (section == 'memorization' && const {'memorized_pages_v1', 'memorization_practice_days_v1', 'memorization_plan_missed_days_v1'}.contains(key)) return _mergeStringLists(current, incoming);
    if (section == 'memorization' && key == 'memorization_page_progress_v1') return _mergePageProgress(current, incoming);
    if (section == 'memorizationPractice' && key == 'memorization_practice_history_v1') return _mergeJsonEventLists(current, incoming);
    if (section == 'fasting' && key == 'qada_fasting_ledger_v1') return _mergeQadaLedger(current, incoming);
    return incoming;
  }

  Object? _mergeStringLists(Object? current, Object? incoming) {
    final local = current is List && current.every((value) => value is String) ? current.cast<String>() : null; final remote = incoming is List && incoming.every((value) => value is String) ? incoming.cast<String>() : null;
    if (local == null) return remote ?? incoming; if (remote == null) return local;
    final values = <String>{...local, ...remote}.toList()..sort((a, b) { final aInt = int.tryParse(a); final bInt = int.tryParse(b); if (aInt != null && bInt != null) return aInt.compareTo(bInt); return a.compareTo(b); }); return values;
  }
  Map<dynamic, dynamic>? _decodeMap(String value) { try { final decoded = jsonDecode(value); return decoded is Map ? decoded : null; } on FormatException { return null; } }
  List<dynamic>? _decodeList(String value) { try { final decoded = jsonDecode(value); return decoded is List ? decoded : null; } on FormatException { return null; } }

  Object? _mergePageProgress(Object? current, Object? incoming) {
    if (current is! String) return incoming; if (incoming is! String) return current;
    final currentDecoded = _decodeMap(current); final incomingDecoded = _decodeMap(incoming); if (currentDecoded == null) return incomingDecoded == null ? current : incoming; if (incomingDecoded == null) return current;
    final merged = <String, Object?>{}; final keys = <String>{...currentDecoded.keys.whereType<String>(), ...incomingDecoded.keys.whereType<String>()};
    for (final key in keys) { final local = currentDecoded[key]; final remote = incomingDecoded[key]; if (local == null) merged[key] = remote; else if (remote == null) merged[key] = local; else merged[key] = _newerProgress(local, remote); }
    return jsonEncode(merged);
  }
  Object? _newerProgress(Object? local, Object? incoming) {
    if (local is! Map) return incoming; if (incoming is! Map) return local;
    DateTime? timestamp(Map value) => DateTime.tryParse(value['lastReviewedAt']?.toString() ?? '') ?? DateTime.tryParse(value['memorizedAt']?.toString() ?? '');
    final localTime = timestamp(local); final incomingTime = timestamp(incoming); if (localTime == null) return incomingTime == null ? local : incoming; if (incomingTime == null) return local; return incomingTime.isAfter(localTime) ? incoming : local;
  }
  bool _validPracticeEvent(Map event) { final id = event['id']; final page = event['page']; final context = event['context']; final occurredAt = event['occurredAt']; return id is String && id.trim().isNotEmpty && page is int && page > 0 && context is String && const {'soloReview', 'prayer', 'recitedToSomeone'}.contains(context) && occurredAt is String && DateTime.tryParse(occurredAt) != null; }
  Object? _mergeJsonEventLists(Object? current, Object? incoming) {
    if (current is! String) return incoming; if (incoming is! String) return current;
    final currentDecoded = _decodeList(current); final incomingDecoded = _decodeList(incoming); if (currentDecoded == null) return incomingDecoded == null ? current : incoming; if (incomingDecoded == null) return current;
    final byId = <String, Map>{}; void addEvents(List<dynamic> events) { for (final event in events) { if (event is! Map || !_validPracticeEvent(event)) continue; byId[event['id'] as String] = event; } }
    addEvents(currentDecoded); addEvents(incomingDecoded); final merged = byId.values.toList(growable: false)..sort((a, b) => (b['occurredAt'] as String).compareTo(a['occurredAt'] as String)); return jsonEncode(merged.take(4000).toList(growable: false));
  }

  Object? _mergeQadaLedger(Object? current, Object? incoming) {
    if (current is! String) return incoming; if (incoming is! String) return current;
    final localEvents = _qadaEvents(_decodeMap(current)); final remoteEvents = _qadaEvents(_decodeMap(incoming));
    if (localEvents == null) return remoteEvents == null ? current : incoming; if (remoteEvents == null) return current;
    final byId = <String, Map>{}; for (final event in localEvents) { byId[event['id'] as String] = event; } for (final event in remoteEvents) { byId.putIfAbsent(event['id'] as String, () => event); }
    final events = byId.values.toList(growable: false)..sort((a, b) => (a['createdAt'] as String).compareTo(b['createdAt'] as String));
    return jsonEncode(<String, Object?>{'formatVersion': 1, 'entries': events});
  }

  List<Map>? _qadaEvents(Map? document) {
    if (document == null || document['formatVersion'] != 1 || document['entries'] is! List) return null;
    final result = <Map>[]; final ids = <String>{};
    for (final raw in document['entries'] as List) {
      if (raw is! Map) return null;
      final id = raw['id']; final kind = raw['kind']; final days = raw['days']; final occurredOn = raw['occurredOn']; final createdAt = raw['createdAt']; final sourceYear = raw['sourceRamadanYear']; final note = raw['note'];
      if (id is! String || id.trim().isEmpty || !ids.add(id) || kind is! String || !const {'debt', 'completion', 'correction'}.contains(kind) || days is! int || days == 0 || days.abs() > 3650 || occurredOn is! String || DateTime.tryParse(occurredOn) == null || createdAt is! String || DateTime.tryParse(createdAt) == null || (sourceYear != null && (sourceYear is! int || sourceYear < 1 || sourceYear > 9999)) || (note != null && note is! String)) return null;
      result.add(raw);
    }
    return result;
  }
}
