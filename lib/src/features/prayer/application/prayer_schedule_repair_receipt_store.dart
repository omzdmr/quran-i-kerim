import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PrayerScheduleRepairReceipt {
  const PrayerScheduleRepairReceipt({required this.attemptedAt, required this.outcome, this.trigger = PrayerScheduleRepairTrigger.unknown, this.configurationFingerprint = ''});
  final DateTime attemptedAt;
  final PrayerScheduleRepairOutcome outcome;
  final PrayerScheduleRepairTrigger trigger;
  final String configurationFingerprint;
  Map<String, Object?> toJson() => <String, Object?>{'attemptedAt': attemptedAt.toUtc().toIso8601String(), 'outcome': outcome.name, 'trigger': trigger.name, 'configurationFingerprint': configurationFingerprint};

  static PrayerScheduleRepairReceipt? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final attemptedAt = DateTime.tryParse(raw['attemptedAt']?.toString() ?? '');
    final outcome = _enumByName(PrayerScheduleRepairOutcome.values, raw['outcome']);
    if (attemptedAt == null || outcome == null) return null;
    final trigger = _enumByName(PrayerScheduleRepairTrigger.values, raw['trigger']) ?? PrayerScheduleRepairTrigger.unknown;
    final fingerprint = raw['configurationFingerprint'];
    return PrayerScheduleRepairReceipt(attemptedAt: attemptedAt.toUtc(), outcome: outcome, trigger: trigger, configurationFingerprint: fingerprint is String ? fingerprint : '');
  }

  static T? _enumByName<T extends Enum>(Iterable<T> values, Object? raw) {
    if (raw is! String) return null;
    for (final value in values) { if (value.name == raw) return value; }
    return null;
  }
}

enum PrayerScheduleRepairOutcome { notApplicable, alreadyFresh, repaired, failed }
enum PrayerScheduleRepairTrigger { unknown, noSchedulableConfiguration, configurationChanged, staleEvidence, platformScheduleMissing, verifiedFresh }

class PrayerScheduleRepairReceiptStore {
  const PrayerScheduleRepairReceiptStore();
  static const _key = 'prayer_schedule_repair_receipt_v1';
  static final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);

  /// In-process signal only. Persistence remains SharedPreferences so app
  /// restart behavior stays local-first and deterministic.
  Stream<void> get changes => _changes.stream;

  Future<void> save(PrayerScheduleRepairReceipt receipt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(receipt.toJson()));
    _changes.add(null);
  }

  Future<PrayerScheduleRepairReceipt?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key);
    if (encoded == null) return null;
    try { return PrayerScheduleRepairReceipt.tryParse(jsonDecode(encoded)); } on FormatException { return null; }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _changes.add(null);
  }
}
