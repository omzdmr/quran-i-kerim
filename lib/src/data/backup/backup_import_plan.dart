import 'dart:convert';

class BackupSectionImpact {
  const BackupSectionImpact({required this.section, required this.incomingRecords, required this.localRecords, required this.conflictingRecords, required this.incomingOnlyRecords, required this.localOnlyRecords});
  final String section;
  final int incomingRecords;
  final int localRecords;
  final int conflictingRecords;
  final int incomingOnlyRecords;
  final int localOnlyRecords;
  bool get hasChanges => conflictingRecords > 0 || incomingOnlyRecords > 0 || localOnlyRecords > 0;
}

class BackupImportPlan {
  const BackupImportPlan({required this.incomingRecords, required this.localRecords, required this.conflictingRecords, required this.incomingOnlyRecords, required this.localOnlyRecords, this.sectionImpacts = const <BackupSectionImpact>[]});
  final int incomingRecords;
  final int localRecords;
  final int conflictingRecords;
  final int incomingOnlyRecords;
  final int localOnlyRecords;
  final List<BackupSectionImpact> sectionImpacts;
  bool get hasConflicts => conflictingRecords > 0;
  List<BackupSectionImpact> get changedSections => sectionImpacts.where((impact) => impact.hasChanges).toList(growable: false);
}

class BackupImportPlanner {
  const BackupImportPlanner();

  BackupImportPlan build({required Map<String, Object?> currentSections, required Map<String, Object?> incomingSections, Set<String>? managedSections}) {
    var incomingRecords = 0;
    var localRecords = 0;
    var conflictingRecords = 0;
    var incomingOnlyRecords = 0;
    var localOnlyRecords = 0;
    final impacts = <BackupSectionImpact>[];
    final sectionNames = (managedSections ?? <String>{...currentSections.keys, ...incomingSections.keys}).toList()..sort();

    for (final section in sectionNames) {
      final current = _records(section, currentSections[section]);
      final incoming = _records(section, incomingSections[section]);
      var sectionConflicts = 0;
      var sectionIncomingOnly = 0;
      var sectionLocalOnly = 0;
      localRecords += current.length;
      incomingRecords += incoming.length;
      final keys = <String>{...current.keys, ...incoming.keys};
      for (final key in keys) {
        final hasCurrent = current.containsKey(key);
        final hasIncoming = incoming.containsKey(key);
        if (hasCurrent && hasIncoming) {
          if (!_equivalent(current[key], incoming[key])) {
            conflictingRecords++;
            sectionConflicts++;
          }
        } else if (hasIncoming) {
          incomingOnlyRecords++;
          sectionIncomingOnly++;
        } else {
          localOnlyRecords++;
          sectionLocalOnly++;
        }
      }
      impacts.add(BackupSectionImpact(section: section, incomingRecords: incoming.length, localRecords: current.length, conflictingRecords: sectionConflicts, incomingOnlyRecords: sectionIncomingOnly, localOnlyRecords: sectionLocalOnly));
    }

    return BackupImportPlan(incomingRecords: incomingRecords, localRecords: localRecords, conflictingRecords: conflictingRecords, incomingOnlyRecords: incomingOnlyRecords, localOnlyRecords: localOnlyRecords, sectionImpacts: List<BackupSectionImpact>.unmodifiable(impacts));
  }

  Map<String, Object?> _records(String section, Object? value) {
    if (section == 'bookmarks' && value is Map) {
      final bookmarks = _stringListRecords(value['bookmarks']);
      if (bookmarks != null) return bookmarks;
    }
    if (section == 'fasting' && value is Map) {
      final expanded = _qadaRecords(value['qada_fasting_ledger_v1']);
      if (expanded != null) {
        return <String, Object?>{
          for (final entry in value.entries)
            if (entry.key is String && entry.key != 'qada_fasting_ledger_v1') 'pref:${entry.key}': entry.value,
          for (final entry in expanded.entries) 'qada:${entry.key}': entry.value,
        };
      }
    }
    if (value is Map) return <String, Object?>{for (final entry in value.entries) if (entry.key is String) entry.key as String: entry.value};
    if (value is List) return <String, Object?>{for (var index = 0; index < value.length; index++) '#$index': value[index]};
    return const <String, Object?>{};
  }

  Map<String, Object?>? _stringListRecords(Object? value) {
    if (value is! List || !value.every((item) => item is String)) return null;
    final records = <String, Object?>{};
    for (final item in value.cast<String>()) {
      if (item.trim().isEmpty || records.containsKey(item)) return null;
      records[item] = true;
    }
    return records;
  }

  Map<String, Object?>? _qadaRecords(Object? encoded) {
    if (encoded is! String) return null;
    try {
      final document = jsonDecode(encoded);
      if (document is! Map || document['formatVersion'] != 1 || document['entries'] is! List) return null;
      final records = <String, Object?>{};
      for (final event in document['entries'] as List) {
        if (event is! Map || event['id'] is! String || (event['id'] as String).trim().isEmpty) return null;
        final id = event['id'] as String;
        if (records.containsKey(id)) return null;
        records[id] = event;
      }
      return records;
    } on FormatException {
      return null;
    }
  }

  bool _equivalent(Object? a, Object? b) {
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) { if (!_equivalent(a[i], b[i])) return false; }
      return true;
    }
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final entry in a.entries) { if (!b.containsKey(entry.key) || !_equivalent(entry.value, b[entry.key])) return false; }
      return true;
    }
    return a == b;
  }
}
