import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-only receipt for automatic prayer schedule repair.
///
/// This is diagnostic state, not worship history. Keeping the last outcome lets
/// the diagnostics UI explain that a stale/missing platform schedule was
/// repaired after resume instead of silently changing state behind the user.
class PrayerScheduleRepairReceipt {
  const PrayerScheduleRepairReceipt({
    required this.attemptedAt,
    required this.outcome,
    this.configurationFingerprint = '',
  });

  final DateTime attemptedAt;
  final PrayerScheduleRepairOutcome outcome;
  final String configurationFingerprint;

  Map<String, Object?> toJson() => <String, Object?>{
        'attemptedAt': attemptedAt.toUtc().toIso8601String(),
        'outcome': outcome.name,
        'configurationFingerprint': configurationFingerprint,
      };

  static PrayerScheduleRepairReceipt? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final attemptedAt = DateTime.tryParse(raw['attemptedAt']?.toString() ?? '');
    final outcomeName = raw['outcome'];
    if (attemptedAt == null || outcomeName is! String) return null;
    PrayerScheduleRepairOutcome? outcome;
    for (final candidate in PrayerScheduleRepairOutcome.values) {
      if (candidate.name == outcomeName) {
        outcome = candidate;
        break;
      }
    }
    if (outcome == null) return null;
    final fingerprint = raw['configurationFingerprint'];
    return PrayerScheduleRepairReceipt(
      attemptedAt: attemptedAt.toUtc(),
      outcome: outcome,
      configurationFingerprint: fingerprint is String ? fingerprint : '',
    );
  }
}

enum PrayerScheduleRepairOutcome {
  notApplicable,
  alreadyFresh,
  repaired,
  failed,
}

class PrayerScheduleRepairReceiptStore {
  const PrayerScheduleRepairReceiptStore();

  static const _key = 'prayer_schedule_repair_receipt_v1';

  Future<void> save(PrayerScheduleRepairReceipt receipt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(receipt.toJson()));
  }

  Future<PrayerScheduleRepairReceipt?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key);
    if (encoded == null) return null;
    try {
      return PrayerScheduleRepairReceipt.tryParse(jsonDecode(encoded));
    } on FormatException {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
