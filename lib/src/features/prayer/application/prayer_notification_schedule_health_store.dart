import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Durable, local-only evidence that prayer notifications were actually
/// scheduled. This deliberately records scheduling metadata, not worship
/// history, and is safe to inspect from diagnostics without a backend.
class PrayerNotificationScheduleHealth {
  const PrayerNotificationScheduleHealth({
    required this.scheduledAt,
    required this.nextPrayerId,
    required this.nextScheduledAt,
    required this.timeZoneId,
    required this.locationLabel,
    required this.calculationMethodId,
    required this.pendingCount,
    this.configurationFingerprint = '',
    this.schemaVersion = 2,
  });

  final DateTime scheduledAt;
  final String nextPrayerId;
  final DateTime nextScheduledAt;
  final String timeZoneId;
  final String locationLabel;
  final String calculationMethodId;
  final int pendingCount;

  /// Deterministic, non-secret identity of the inputs that produced the
  /// schedule. It intentionally contains no raw coordinates.
  final String configurationFingerprint;
  final int schemaVersion;

  bool isFreshAt(
    DateTime now, {
    Duration maxAge = const Duration(hours: 36),
    String? expectedConfigurationFingerprint,
  }) {
    final normalizedNow = now.toUtc();
    if (scheduledAt.toUtc().isAfter(normalizedNow.add(const Duration(minutes: 5)))) return false;
    if (normalizedNow.difference(scheduledAt.toUtc()) > maxAge) return false;
    if (!nextScheduledAt.toUtc().isAfter(normalizedNow)) return false;
    if (expectedConfigurationFingerprint != null &&
        expectedConfigurationFingerprint.isNotEmpty &&
        configurationFingerprint != expectedConfigurationFingerprint) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'nextPrayerId': nextPrayerId,
        'nextScheduledAt': nextScheduledAt.toUtc().toIso8601String(),
        'timeZoneId': timeZoneId,
        'locationLabel': locationLabel,
        'calculationMethodId': calculationMethodId,
        'pendingCount': pendingCount,
        'configurationFingerprint': configurationFingerprint,
      };

  static PrayerNotificationScheduleHealth? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final scheduledAt = DateTime.tryParse(raw['scheduledAt']?.toString() ?? '');
    final nextScheduledAt = DateTime.tryParse(raw['nextScheduledAt']?.toString() ?? '');
    final nextPrayerId = raw['nextPrayerId'];
    final timeZoneId = raw['timeZoneId'];
    final locationLabel = raw['locationLabel'];
    final calculationMethodId = raw['calculationMethodId'];
    final pendingCount = raw['pendingCount'];
    final schemaVersion = raw['schemaVersion'] is int ? raw['schemaVersion'] as int : 1;
    final fingerprint = raw['configurationFingerprint'] is String
        ? raw['configurationFingerprint'] as String
        : '';
    if (scheduledAt == null ||
        nextScheduledAt == null ||
        nextPrayerId is! String ||
        !const {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'}.contains(nextPrayerId) ||
        timeZoneId is! String ||
        timeZoneId.trim().isEmpty ||
        locationLabel is! String ||
        locationLabel.trim().isEmpty ||
        calculationMethodId is! String ||
        calculationMethodId.trim().isEmpty ||
        pendingCount is! int ||
        pendingCount < 1 ||
        pendingCount > 100 ||
        schemaVersion < 1 ||
        schemaVersion > 2) {
      return null;
    }
    return PrayerNotificationScheduleHealth(
      scheduledAt: scheduledAt.toUtc(),
      nextPrayerId: nextPrayerId,
      nextScheduledAt: nextScheduledAt.toUtc(),
      timeZoneId: timeZoneId,
      locationLabel: locationLabel,
      calculationMethodId: calculationMethodId,
      pendingCount: pendingCount,
      configurationFingerprint: fingerprint,
      schemaVersion: schemaVersion,
    );
  }
}

class PrayerNotificationScheduleHealthStore {
  const PrayerNotificationScheduleHealthStore();

  static const _key = 'prayer_notification_schedule_health_v1';

  Future<void> save(PrayerNotificationScheduleHealth health) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(health.toJson()));
  }

  Future<PrayerNotificationScheduleHealth?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key);
    if (encoded == null) return null;
    try {
      return PrayerNotificationScheduleHealth.tryParse(jsonDecode(encoded));
    } on FormatException {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
