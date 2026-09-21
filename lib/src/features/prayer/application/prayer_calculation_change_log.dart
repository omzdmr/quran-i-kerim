import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-only record of the latest material input change that can alter prayer
/// times. It stores descriptive values only and never stores coordinates.
class PrayerCalculationChangeLog {
  PrayerCalculationChangeLog._();

  static const _key = 'prayer_calculation_latest_material_change_v1';

  static Future<PrayerCalculationMaterialChange?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return PrayerCalculationMaterialChange.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> record(PrayerCalculationMaterialChange change) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(change.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

enum PrayerCalculationChangeKind {
  place,
  timezone,
  calculationMethod,
  asrSchool,
  highLatitudeRule,
  manualOffset,
  timetableSource,
}

class PrayerCalculationMaterialChange {
  const PrayerCalculationMaterialChange({
    required this.kind,
    required this.changedAt,
    this.prayerId,
    this.previousValue,
    this.currentValue,
  });

  final PrayerCalculationChangeKind kind;
  final DateTime changedAt;
  final String? prayerId;
  final String? previousValue;
  final String? currentValue;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'changedAt': changedAt.toUtc().toIso8601String(),
    if (prayerId != null) 'prayerId': prayerId,
    if (previousValue != null) 'previousValue': previousValue,
    if (currentValue != null) 'currentValue': currentValue,
  };

  factory PrayerCalculationMaterialChange.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String?;
    final kind = PrayerCalculationChangeKind.values.firstWhere(
      (value) => value.name == kindName,
      orElse: () => PrayerCalculationChangeKind.calculationMethod,
    );
    return PrayerCalculationMaterialChange(
      kind: kind,
      changedAt: DateTime.parse(json['changedAt'] as String),
      prayerId: json['prayerId'] as String?,
      previousValue: json['previousValue'] as String?,
      currentValue: json['currentValue'] as String?,
    );
  }
}
