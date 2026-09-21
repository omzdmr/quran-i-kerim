import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum PrayerNotificationProbeOutcome { received, notReceived }

class PrayerNotificationProbeRecord {
  const PrayerNotificationProbeRecord({required this.outcome, required this.confirmedAt});
  final PrayerNotificationProbeOutcome outcome;
  final DateTime confirmedAt;
}

class PrayerNotificationSelfTestStore {
  const PrayerNotificationSelfTestStore();
  static const storageKey = 'prayer_notification_self_test_v1';

  Future<PrayerNotificationProbeRecord?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(storageKey);
    if (encoded == null) return null;
    try {
      final raw = jsonDecode(encoded);
      if (raw is! Map) return null;
      final outcome = raw['outcome'];
      final confirmedAt = raw['confirmedAt'];
      if (outcome is! String || confirmedAt is! String) return null;
      final parsed = DateTime.tryParse(confirmedAt);
      final parsedOutcome = PrayerNotificationProbeOutcome.values.where((value) => value.name == outcome).firstOrNull;
      if (parsed == null || parsedOutcome == null) return null;
      return PrayerNotificationProbeRecord(outcome: parsedOutcome, confirmedAt: parsed.toLocal());
    } on FormatException {
      return null;
    }
  }

  Future<void> save(PrayerNotificationProbeOutcome outcome, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(<String, Object>{
      'outcome': outcome.name,
      'confirmedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
    }));
  }
}