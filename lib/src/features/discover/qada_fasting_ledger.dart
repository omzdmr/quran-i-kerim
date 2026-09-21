import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum QadaFastingEntryKind { debt, completion, correction }

class QadaFastingEntry {
  const QadaFastingEntry({required this.id, required this.kind, required this.days, required this.occurredOn, required this.createdAt, this.sourceRamadanYear, this.estimatedSource = false, this.note});
  final String id; final QadaFastingEntryKind kind; final int days; final DateTime occurredOn; final DateTime createdAt; final int? sourceRamadanYear; final bool estimatedSource; final String? note;
  int get balanceDelta => switch (kind) { QadaFastingEntryKind.debt => days, QadaFastingEntryKind.completion => -days, QadaFastingEntryKind.correction => days };
  Map<String, Object?> toJson() => <String, Object?>{'id': id, 'kind': kind.name, 'days': days, 'occurredOn': _dateOnly(occurredOn).toIso8601String(), 'createdAt': createdAt.toUtc().toIso8601String(), if (sourceRamadanYear != null) 'sourceRamadanYear': sourceRamadanYear, if (estimatedSource) 'estimatedSource': true, if (note != null && note!.trim().isNotEmpty) 'note': note!.trim()};
  static QadaFastingEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id']; final kindName = raw['kind']; final days = raw['days']; final occurredOnRaw = raw['occurredOn']; final createdAtRaw = raw['createdAt'];
    if (id is! String || id.trim().isEmpty || id.length > 128 || kindName is! String || days is! int || days == 0 || occurredOnRaw is! String || createdAtRaw is! String) return null;
    final kind = QadaFastingEntryKind.values.where((value) => value.name == kindName).firstOrNull; final occurredOn = DateTime.tryParse(occurredOnRaw); final createdAt = DateTime.tryParse(createdAtRaw);
    if (kind == null || occurredOn == null || createdAt == null || days.abs() > 3650 || (kind != QadaFastingEntryKind.correction && days < 1)) return null;
    final source = raw['sourceRamadanYear']; if (source != null && (source is! int || source < 1 || source > 9999)) return null;
    final note = raw['note']; if (note != null && note is! String) return null;
    return QadaFastingEntry(id: id, kind: kind, days: days, occurredOn: _dateOnly(occurredOn), createdAt: createdAt.toUtc(), sourceRamadanYear: source as int?, estimatedSource: raw['estimatedSource'] == true, note: note is String ? _cleanNote(note) : null);
  }
}

class QadaFastingLedger {
  QadaFastingLedger([Iterable<QadaFastingEntry> entries = const []]) : entries = List<QadaFastingEntry>.unmodifiable(entries.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  static const int formatVersion = 1; static const int maxEntries = 20000; static const int maxBalanceDays = 3650;
  final List<QadaFastingEntry> entries;
  int get remainingDays => entries.fold<int>(0, (sum, entry) => sum + entry.balanceDelta);
  int get recordedDebtDays => entries.where((entry) => entry.kind == QadaFastingEntryKind.debt).fold<int>(0, (sum, entry) => sum + entry.days);
  int get completedDays => entries.where((entry) => entry.kind == QadaFastingEntryKind.completion).fold<int>(0, (sum, entry) => sum + entry.days);
  Map<int?, int> get debtByRamadan { final result = <int?, int>{}; for (final entry in entries) { if (entry.kind == QadaFastingEntryKind.debt) result[entry.sourceRamadanYear] = (result[entry.sourceRamadanYear] ?? 0) + entry.days; } return Map<int?, int>.unmodifiable(result); }
  Map<int, int> get attributedCompletionsByRamadan { final result = <int, int>{}; for (final entry in entries) { if (entry.kind == QadaFastingEntryKind.completion && entry.sourceRamadanYear != null) { final year = entry.sourceRamadanYear!; result[year] = (result[year] ?? 0) + entry.days; } } return Map<int, int>.unmodifiable(result); }
  int remainingForRamadan(int year) => (debtByRamadan[year] ?? 0) - (attributedCompletionsByRamadan[year] ?? 0);
  Iterable<int> get openRamadanYears sync* { final years = debtByRamadan.keys.whereType<int>().toList()..sort((a, b) => b.compareTo(a)); for (final year in years) { if (remainingForRamadan(year) > 0) yield year; } }
  int? get unambiguousCompletionRamadanYear { final years = openRamadanYears.toList(growable: false); if (years.length != 1) return null; final year = years.single; return remainingForRamadan(year) == remainingDays ? year : null; }
  DateTime? get earliestOccurredOn => entries.isEmpty ? null : entries.map((entry) => entry.occurredOn).reduce((a, b) => a.isBefore(b) ? a : b);
  DateTime? get latestOccurredOn => entries.isEmpty ? null : entries.map((entry) => entry.occurredOn).reduce((a, b) => a.isAfter(b) ? a : b);
  List<QadaFastingEntry> entriesOn(DateTime day) { final target = _dateOnly(day); return List<QadaFastingEntry>.unmodifiable(entries.where((entry) => _dateOnly(entry.occurredOn) == target)); }
  List<DateTime> get recordedDates { final dates = <int, DateTime>{}; for (final entry in entries) { final date = _dateOnly(entry.occurredOn); dates[date.year * 10000 + date.month * 100 + date.day] = date; } final result = dates.values.toList()..sort((a, b) => a.compareTo(b)); return List<DateTime>.unmodifiable(result); }
  DateTime? previousRecordedDate(DateTime day) { final target = _dateOnly(day); for (final date in recordedDates.reversed) { if (date.isBefore(target)) return date; } return null; }
  DateTime? nextRecordedDate(DateTime day) { final target = _dateOnly(day); for (final date in recordedDates) { if (date.isAfter(target)) return date; } return null; }

  QadaFastingLedger addDebt({required int days, required DateTime occurredOn, required DateTime createdAt, int? sourceRamadanYear, bool estimatedSource = false, String? note, String? id}) {
    if (days < 1 || days > maxBalanceDays) throw ArgumentError.value(days, 'days', 'Must be between 1 and $maxBalanceDays');
    if (remainingDays + days > maxBalanceDays) throw StateError('Debt would exceed the safe qada balance limit');
    _validateYear(sourceRamadanYear); _ensureCapacity();
    return _append(QadaFastingEntry(id: id ?? _newEntryId(createdAt), kind: QadaFastingEntryKind.debt, days: days, occurredOn: _dateOnly(occurredOn), createdAt: createdAt.toUtc(), sourceRamadanYear: sourceRamadanYear, estimatedSource: estimatedSource || sourceRamadanYear == null, note: _cleanNote(note)));
  }
  QadaFastingLedger complete({int days = 1, required DateTime occurredOn, required DateTime createdAt, int? sourceRamadanYear, bool attributeWhenUnambiguous = true, String? note, String? id}) {
    if (days < 1 || days > remainingDays) throw StateError('Completion exceeds remaining qada balance'); _validateYear(sourceRamadanYear); _ensureCapacity();
    final resolvedYear = sourceRamadanYear ?? (attributeWhenUnambiguous ? unambiguousCompletionRamadanYear : null); if (resolvedYear != null && days > remainingForRamadan(resolvedYear)) throw StateError('Completion exceeds remaining qada balance for Ramadan $resolvedYear');
    return _append(QadaFastingEntry(id: id ?? _newEntryId(createdAt), kind: QadaFastingEntryKind.completion, days: days, occurredOn: _dateOnly(occurredOn), createdAt: createdAt.toUtc(), sourceRamadanYear: resolvedYear, note: _cleanNote(note)));
  }
  QadaFastingLedger correctBalance({required int targetDays, required DateTime occurredOn, required DateTime createdAt, String? note, String? id}) {
    if (targetDays < 0 || targetDays > maxBalanceDays) throw ArgumentError.value(targetDays, 'targetDays'); final delta = targetDays - remainingDays; if (delta == 0) return this; _ensureCapacity();
    return _append(QadaFastingEntry(id: id ?? _newEntryId(createdAt), kind: QadaFastingEntryKind.correction, days: delta, occurredOn: _dateOnly(occurredOn), createdAt: createdAt.toUtc(), note: _cleanNote(note)));
  }
  void _ensureCapacity() { if (entries.length >= maxEntries) throw StateError('Qada fasting ledger has reached its safe local event limit'); }
  String _newEntryId(DateTime value) { final base = _entryId(value); final used = entries.map((entry) => entry.id).toSet(); if (!used.contains(base)) return base; var suffix = 2; while (used.contains('$base-$suffix')) { suffix++; } return '$base-$suffix'; }
  QadaFastingLedger _append(QadaFastingEntry entry) => QadaFastingLedger(<QadaFastingEntry>[...entries, entry]);
  String encode() => jsonEncode(<String, Object?>{'formatVersion': formatVersion, 'entries': entries.map((entry) => entry.toJson()).toList(growable: false)});

  static QadaFastingLedger decode(String? source) {
    if (source == null || source.trim().isEmpty) return QadaFastingLedger();
    try {
      final raw = jsonDecode(source); if (raw is! Map || raw['formatVersion'] != formatVersion || raw['entries'] is! List) return QadaFastingLedger();
      final rawEntries = raw['entries'] as List; if (rawEntries.length > maxEntries) return QadaFastingLedger();
      final parsed = rawEntries.map(QadaFastingEntry.fromJson).whereType<QadaFastingEntry>().toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final ids = <String>{}; final candidates = <QadaFastingEntry>[for (final entry in parsed) if (ids.add(entry.id)) entry];
      if (_isCoherentEventSet(candidates)) return QadaFastingLedger(candidates); return QadaFastingLedger(_salvageSequentially(candidates));
    } catch (_) { return QadaFastingLedger(); }
  }
  static bool _isCoherentEventSet(List<QadaFastingEntry> entries) {
    final balance = entries.fold<int>(0, (sum, entry) => sum + entry.balanceDelta); if (balance < 0 || balance > maxBalanceDays) return false;
    final debtByYear = <int, int>{}; final completionByYear = <int, int>{};
    for (final entry in entries) { final year = entry.sourceRamadanYear; if (year == null) continue; if (entry.kind == QadaFastingEntryKind.debt) debtByYear[year] = (debtByYear[year] ?? 0) + entry.days; if (entry.kind == QadaFastingEntryKind.completion) completionByYear[year] = (completionByYear[year] ?? 0) + entry.days; }
    for (final item in completionByYear.entries) { if (item.value > (debtByYear[item.key] ?? 0)) return false; } return true;
  }
  static List<QadaFastingEntry> _salvageSequentially(List<QadaFastingEntry> candidates) {
    final accepted = <QadaFastingEntry>[]; var balance = 0; final debtByYear = <int, int>{}; final completionByYear = <int, int>{};
    for (final entry in candidates) { final next = balance + entry.balanceDelta; if (next < 0 || next > maxBalanceDays) continue; final year = entry.sourceRamadanYear; if (year != null && entry.kind == QadaFastingEntryKind.debt) debtByYear[year] = (debtByYear[year] ?? 0) + entry.days; if (year != null && entry.kind == QadaFastingEntryKind.completion) { final nextCompletion = (completionByYear[year] ?? 0) + entry.days; if (nextCompletion > (debtByYear[year] ?? 0)) continue; completionByYear[year] = nextCompletion; } balance = next; accepted.add(entry); }
    return accepted;
  }
}

class QadaFastingStore {
  const QadaFastingStore(); static const String preferenceKey = 'qada_fasting_ledger_v1';
  Future<QadaFastingLedger> load() async { final prefs = await SharedPreferences.getInstance(); return QadaFastingLedger.decode(prefs.getString(preferenceKey)); }
  Future<void> save(QadaFastingLedger ledger) async { final prefs = await SharedPreferences.getInstance(); await prefs.setString(preferenceKey, ledger.encode()); }
}

void _validateYear(int? year) { if (year != null && (year < 1 || year > 9999)) throw ArgumentError.value(year, 'sourceRamadanYear'); }
DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
String _entryId(DateTime value) => 'qada-${value.toUtc().microsecondsSinceEpoch.toRadixString(36)}';
String? _cleanNote(String? value) { final cleaned = value?.trim(); if (cleaned == null || cleaned.isEmpty) return null; return cleaned.length <= 500 ? cleaned : cleaned.substring(0, 500); }
