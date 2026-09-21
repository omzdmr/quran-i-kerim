import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/qada_fasting_ledger.dart';

class QadaFastingStore {
  const QadaFastingStore();

  static const _key = 'qada_fasting_ledger_v1';

  Future<QadaFastingLedger> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const QadaFastingLedger([]);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const QadaFastingLedger([]);
      final entries = <QadaFastEntry>[];
      for (final value in decoded) {
        if (value is Map) {
          final entry = QadaFastEntry.fromJson(Map<String, Object?>.from(value));
          if (entry != null) entries.add(entry);
        }
      }
      return QadaFastingLedger(List.unmodifiable(entries));
    } catch (_) {
      return const QadaFastingLedger([]);
    }
  }

  Future<QadaFastingLedger> save(QadaFastingLedger ledger) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ledger.entries.map((e) => e.toJson()).toList()));
    return ledger;
  }

  Future<QadaFastingLedger> append(QadaFastEntry entry) async {
    final current = await load();
    final withoutSameId = current.entries.where((item) => item.id != entry.id);
    return save(QadaFastingLedger(List.unmodifiable([...withoutSameId, entry])));
  }

  Future<QadaFastingLedger> remove(String id) async {
    final current = await load();
    return save(QadaFastingLedger(List.unmodifiable(current.entries.where((e) => e.id != id))));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
