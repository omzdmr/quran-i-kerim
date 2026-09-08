import 'package:shared_preferences/shared_preferences.dart';

import '../domain/prayer_models.dart';

class PrayerSettingsSnapshot {
  const PrayerSettingsSnapshot({
    this.methodOverride,
    this.asrMethod = PrayerAsrMethod.standard,
    this.highLatitudeMethod = PrayerHighLatitudeMethod.recommended,
    this.adjustments = const PrayerMinuteAdjustments(),
  });

  final PrayerCalculationMethod? methodOverride;
  final PrayerAsrMethod asrMethod;
  final PrayerHighLatitudeMethod highLatitudeMethod;
  final PrayerMinuteAdjustments adjustments;

  PrayerPreferences preferencesFor(PrayerCalculationMethod cityDefault) {
    return PrayerPreferences(
      calculationMethod: methodOverride ?? cityDefault,
      asrMethod: asrMethod,
      highLatitudeMethod: highLatitudeMethod,
      adjustments: adjustments,
    );
  }
}

class PrayerPreferencesStore {
  PrayerPreferencesStore._();

  static const cityKey = 'prayer_city_id';
  static const _methodKey = 'prayer_method_override';
  static const _asrKey = 'prayer_asr_method';
  static const _highLatitudeKey = 'prayer_high_latitude_method';
  static const _fajrAdjustmentKey = 'prayer_adjustment_fajr';
  static const _sunriseAdjustmentKey = 'prayer_adjustment_sunrise';
  static const _dhuhrAdjustmentKey = 'prayer_adjustment_dhuhr';
  static const _asrAdjustmentKey = 'prayer_adjustment_asr';
  static const _maghribAdjustmentKey = 'prayer_adjustment_maghrib';
  static const _ishaAdjustmentKey = 'prayer_adjustment_isha';

  static Future<PrayerSettingsSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PrayerSettingsSnapshot(
      methodOverride: _enumByName(
        PrayerCalculationMethod.values,
        prefs.getString(_methodKey),
      ),
      asrMethod: _enumByName(
            PrayerAsrMethod.values,
            prefs.getString(_asrKey),
          ) ??
          PrayerAsrMethod.standard,
      highLatitudeMethod: _enumByName(
            PrayerHighLatitudeMethod.values,
            prefs.getString(_highLatitudeKey),
          ) ??
          PrayerHighLatitudeMethod.recommended,
      adjustments: PrayerMinuteAdjustments(
        fajr: prefs.getInt(_fajrAdjustmentKey) ?? 0,
        sunrise: prefs.getInt(_sunriseAdjustmentKey) ?? 0,
        dhuhr: prefs.getInt(_dhuhrAdjustmentKey) ?? 0,
        asr: prefs.getInt(_asrAdjustmentKey) ?? 0,
        maghrib: prefs.getInt(_maghribAdjustmentKey) ?? 0,
        isha: prefs.getInt(_ishaAdjustmentKey) ?? 0,
      ),
    );
  }

  static Future<String?> loadCityId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(cityKey);
  }

  static Future<void> saveCityId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cityKey, id);
  }

  static Future<void> save(PrayerSettingsSnapshot value) async {
    final prefs = await SharedPreferences.getInstance();
    final method = value.methodOverride;
    if (method == null) {
      await prefs.remove(_methodKey);
    } else {
      await prefs.setString(_methodKey, method.name);
    }
    await prefs.setString(_asrKey, value.asrMethod.name);
    await prefs.setString(_highLatitudeKey, value.highLatitudeMethod.name);
    await prefs.setInt(_fajrAdjustmentKey, value.adjustments.fajr);
    await prefs.setInt(_sunriseAdjustmentKey, value.adjustments.sunrise);
    await prefs.setInt(_dhuhrAdjustmentKey, value.adjustments.dhuhr);
    await prefs.setInt(_asrAdjustmentKey, value.adjustments.asr);
    await prefs.setInt(_maghribAdjustmentKey, value.adjustments.maghrib);
    await prefs.setInt(_ishaAdjustmentKey, value.adjustments.isha);
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
