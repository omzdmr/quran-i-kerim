import 'dart:convert';

class DhikrDailyHistoryRecord {
  const DhikrDailyHistoryRecord({
    required this.dateKey,
    required this.counts,
    this.customLabels = const <String, String>{},
  });

  final String dateKey;
  final Map<String, int> counts;
  final Map<String, String> customLabels;

  int get total => counts.values.fold<int>(0, (sum, value) => sum + value);

  Map<String, Object?> toJson() => <String, Object?>{
        'date': dateKey,
        'counts': counts,
        if (customLabels.isNotEmpty) 'customLabels': customLabels,
      };

  static DhikrDailyHistoryRecord? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final date = raw['date'];
    final countsRaw = raw['counts'];
    if (date is! String || DateTime.tryParse(date) == null || countsRaw is! Map) {
      return null;
    }
    final counts = <String, int>{};
    for (final entry in countsRaw.entries) {
      if (entry.key is! String ||
          entry.value is! int ||
          (entry.value as int) <= 0 ||
          (entry.value as int) > 1000000) {
        return null;
      }
      counts[entry.key as String] = entry.value as int;
    }
    if (counts.isEmpty) return null;
    final labels = <String, String>{};
    final labelsRaw = raw['customLabels'];
    if (labelsRaw != null) {
      if (labelsRaw is! Map) return null;
      for (final entry in labelsRaw.entries) {
        if (entry.key is! String || entry.value is! String) return null;
        final label = (entry.value as String).trim();
        if (label.isEmpty || label.length > 80) return null;
        labels[entry.key as String] = label;
      }
    }
    return DhikrDailyHistoryRecord(
      dateKey: date,
      counts: Map<String, int>.unmodifiable(counts),
      customLabels: Map<String, String>.unmodifiable(labels),
    );
  }
}

class DhikrCounterDocument {
  const DhikrCounterDocument({
    required this.counts,
    required this.history,
  });

  final Map<String, int> counts;
  final List<DhikrDailyHistoryRecord> history;
}

class DhikrCounterDocumentCodec {
  const DhikrCounterDocumentCodec();

  static const maxHistoryRecords = 20000;

  DhikrCounterDocument decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const DhikrCounterDocument(counts: <String, int>{}, history: <DhikrDailyHistoryRecord>[]);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const DhikrCounterDocument(counts: <String, int>{}, history: <DhikrDailyHistoryRecord>[]);
      if (decoded['formatVersion'] == 2) {
        final counts = _decodeCounts(decoded['counts']);
        final historyRaw = decoded['history'];
        if (counts == null || historyRaw is! List || historyRaw.length > maxHistoryRecords) {
          return const DhikrCounterDocument(counts: <String, int>{}, history: <DhikrDailyHistoryRecord>[]);
        }
        final history = <DhikrDailyHistoryRecord>[];
        final dates = <String>{};
        for (final item in historyRaw) {
          final record = DhikrDailyHistoryRecord.tryParse(item);
          if (record == null || !dates.add(record.dateKey)) {
            return const DhikrCounterDocument(counts: <String, int>{}, history: <DhikrDailyHistoryRecord>[]);
          }
          history.add(record);
        }
        history.sort((a, b) => b.dateKey.compareTo(a.dateKey));
        return DhikrCounterDocument(
          counts: Map<String, int>.unmodifiable(counts),
          history: List<DhikrDailyHistoryRecord>.unmodifiable(history),
        );
      }

      final legacyCounts = _decodeCounts(decoded);
      return DhikrCounterDocument(
        counts: Map<String, int>.unmodifiable(legacyCounts ?? const <String, int>{}),
        history: const <DhikrDailyHistoryRecord>[],
      );
    } on FormatException {
      return const DhikrCounterDocument(counts: <String, int>{}, history: <DhikrDailyHistoryRecord>[]);
    }
  }

  String encode({
    required Map<String, int> counts,
    required List<DhikrDailyHistoryRecord> history,
  }) {
    final sanitizedCounts = <String, int>{
      for (final entry in counts.entries)
        if (entry.key.trim().isNotEmpty && entry.value >= 0)
          entry.key: entry.value,
    };
    final ordered = history.toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return jsonEncode(<String, Object?>{
      'formatVersion': 2,
      'counts': sanitizedCounts,
      'history': [
        for (final record in ordered) record.toJson(),
      ],
    });
  }

  List<DhikrDailyHistoryRecord> archiveDay({
    required List<DhikrDailyHistoryRecord> history,
    required String dateKey,
    required Map<String, int> counts,
    Map<String, String> customLabels = const <String, String>{},
  }) {
    final sanitized = <String, int>{
      for (final entry in counts.entries)
        if (entry.key.trim().isNotEmpty && entry.value > 0)
          entry.key: entry.value,
    };
    if (sanitized.isEmpty) return history;

    final byDate = <String, DhikrDailyHistoryRecord>{
      for (final record in history) record.dateKey: record,
    };
    byDate[dateKey] = DhikrDailyHistoryRecord(
      dateKey: dateKey,
      counts: Map<String, int>.unmodifiable(sanitized),
      customLabels: Map<String, String>.unmodifiable(<String, String>{
        for (final entry in customLabels.entries)
          if (sanitized.containsKey(entry.key) && entry.value.trim().isNotEmpty)
            entry.key: entry.value.trim(),
      }),
    );
    final result = byDate.values.toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return List<DhikrDailyHistoryRecord>.unmodifiable(
      result,
    );
  }

  Map<String, int>? _decodeCounts(Object? raw) {
    if (raw is! Map) return null;
    final result = <String, int>{};
    for (final entry in raw.entries) {
      if (entry.key is! String) return null;
      final value = entry.value;
      final parsed = value is int ? value : int.tryParse('$value');
      if (parsed == null || parsed < 0 || parsed > 1000000) return null;
      result[entry.key as String] = parsed;
    }
    return result;
  }
}
