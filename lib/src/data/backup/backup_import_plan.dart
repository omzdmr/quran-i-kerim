class BackupImportPlan {
  const BackupImportPlan({
    required this.incomingRecords,
    required this.localRecords,
    required this.conflictingRecords,
    required this.incomingOnlyRecords,
    required this.localOnlyRecords,
  });

  final int incomingRecords;
  final int localRecords;
  final int conflictingRecords;
  final int incomingOnlyRecords;
  final int localOnlyRecords;

  bool get hasConflicts => conflictingRecords > 0;
}

class BackupImportPlanner {
  const BackupImportPlanner();

  BackupImportPlan build({
    required Map<String, Object?> currentSections,
    required Map<String, Object?> incomingSections,
  }) {
    var incomingRecords = 0;
    var localRecords = 0;
    var conflictingRecords = 0;
    var incomingOnlyRecords = 0;
    var localOnlyRecords = 0;

    final sectionNames = <String>{
      ...currentSections.keys,
      ...incomingSections.keys,
    };

    for (final section in sectionNames) {
      final current = _records(currentSections[section]);
      final incoming = _records(incomingSections[section]);
      localRecords += current.length;
      incomingRecords += incoming.length;

      final keys = <String>{...current.keys, ...incoming.keys};
      for (final key in keys) {
        final hasCurrent = current.containsKey(key);
        final hasIncoming = incoming.containsKey(key);
        if (hasCurrent && hasIncoming) {
          if (!_equivalent(current[key], incoming[key])) {
            conflictingRecords++;
          }
        } else if (hasIncoming) {
          incomingOnlyRecords++;
        } else {
          localOnlyRecords++;
        }
      }
    }

    return BackupImportPlan(
      incomingRecords: incomingRecords,
      localRecords: localRecords,
      conflictingRecords: conflictingRecords,
      incomingOnlyRecords: incomingOnlyRecords,
      localOnlyRecords: localOnlyRecords,
    );
  }

  Map<String, Object?> _records(Object? section) {
    if (section is Map) {
      return <String, Object?>{
        for (final entry in section.entries)
          if (entry.key is String) entry.key as String: entry.value,
      };
    }
    if (section is List) {
      return <String, Object?>{
        for (var index = 0; index < section.length; index++)
          '#$index': section[index],
      };
    }
    return const <String, Object?>{};
  }

  bool _equivalent(Object? a, Object? b) {
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_equivalent(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final entry in a.entries) {
        if (!b.containsKey(entry.key) || !_equivalent(entry.value, b[entry.key])) {
          return false;
        }
      }
      return true;
    }
    return a == b;
  }
}
