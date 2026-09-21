enum QadaFastEntryKind { debt, completion, correction }

class QadaFastEntry {
  const QadaFastEntry({
    required this.id,
    required this.kind,
    required this.days,
    required this.recordedAt,
    this.sourceHijriYear,
    this.completedAt,
    this.note,
  }) : assert(days > 0);

  final String id;
  final QadaFastEntryKind kind;
  final int days;
  final DateTime recordedAt;
  final int? sourceHijriYear;
  final DateTime? completedAt;
  final String? note;

  int get balanceDelta => switch (kind) {
        QadaFastEntryKind.debt => days,
        QadaFastEntryKind.completion => -days,
        QadaFastEntryKind.correction => days,
      };

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.name,
        'days': days,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        if (sourceHijriYear != null) 'sourceHijriYear': sourceHijriYear,
        if (completedAt != null)
          'completedAt': completedAt!.toUtc().toIso8601String(),
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };

  static QadaFastEntry? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final kindName = json['kind'];
    final days = json['days'];
    final recorded = json['recordedAt'];
    if (id is! String || kindName is! String || days is! int || days <= 0 || recorded is! String) return null;
    final recordedAt = DateTime.tryParse(recorded);
    if (recordedAt == null) return null;
    final kind = QadaFastEntryKind.values.where((value) => value.name == kindName).firstOrNull;
    if (kind == null) return null;
    final completedRaw = json['completedAt'];
    return QadaFastEntry(
      id: id,
      kind: kind,
      days: days,
      recordedAt: recordedAt,
      sourceHijriYear: json['sourceHijriYear'] is int ? json['sourceHijriYear'] as int : null,
      completedAt: completedRaw is String ? DateTime.tryParse(completedRaw) : null,
      note: json['note'] is String ? json['note'] as String : null,
    );
  }
}

class QadaFastingLedger {
  const QadaFastingLedger(this.entries);

  final List<QadaFastEntry> entries;

  int get balance {
    final value = entries.fold<int>(0, (sum, entry) => sum + entry.balanceDelta);
    return value < 0 ? 0 : value;
  }

  int get totalRecordedDebt => entries
      .where((entry) => entry.kind == QadaFastEntryKind.debt)
      .fold<int>(0, (sum, entry) => sum + entry.days);

  int get totalCompleted => entries
      .where((entry) => entry.kind == QadaFastEntryKind.completion)
      .fold<int>(0, (sum, entry) => sum + entry.days);

  List<QadaFastEntry> get newestFirst => List.unmodifiable(
        [...entries]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt)),
      );
}
