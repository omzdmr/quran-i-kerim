import 'package:shared_preferences/shared_preferences.dart';

import '../domain/prayer_models.dart';

const defaultPrayerNotificationIds = <String>{
  'fajr',
  'dhuhr',
  'asr',
  'maghrib',
  'isha',
};

class PrayerSettingsSnapshot {
  const PrayerSettingsSnapshot({
    this.methodOverride,
    this.asrMethod = PrayerAsrMethod.standard,
    this.highLatitudeMethod = PrayerHighLatitudeMethod.recommended,
    this.adjustments = const PrayerMinuteAdjustments(),
    this.notificationsEnabled = false,
    this.notificationPrayerIds = defaultPrayerNotificationIds,
    this.hijriOffsetDays = 0,
  });

  final PrayerCalculationMethod? methodOverride;
  final PrayerAsrMethod asrMethod;
  final PrayerHighLatitudeMethod highLatitudeMethod;
  final PrayerMinuteAdjustments adjustments;
  final bool notificationsEnabled;
  final Set<String> notificationPrayerIds;
  final int hijriOffsetDays;

  PrayerPreferences preferencesFor(PrayerCalculationMethod cityDefault) {
    return PrayerPreferences(
      calculationMethod: methodOverride ?? cityDefault,
      asrMethod: asrMethod,
      highLatitudeMethod: highLatitudeMethod,
      adjustments: adjustments,
    );
  }
}

class PrayerDeviceLocationSnapshot {
  const PrayerDeviceLocationSnapshot({
    required this.location,
    required this.defaultMethod,
    required this.regionCode,
  });

  final PrayerLocation location;
  final PrayerCalculationMethod defaultMethod;
  final String regionCode;
}

class PrayerManualLocationSnapshot {
  const PrayerManualLocationSnapshot({
    required this.sourceId,
    required this.label,
    required this.country,
    required this.location,
    required this.defaultMethod,
    required this.regionCode,
  });

  final String sourceId;
  final String label;
  final String country;
  final PrayerLocation location;
  final PrayerCalculationMethod defaultMethod;
  final String regionCode;
}

class PrayerPreferencesStore {
  PrayerPreferencesStore._();

  static const deviceLocationId = '__device_location__';
  static const manualLocationId = '__manual_location__';
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
  static const _notificationsEnabledKey = 'prayer_notifications_enabled';
  static const _notificationPrayerIdsKey = 'prayer_notification_ids';
  static const _hijriOffsetKey = 'prayer_hijri_offset';
  static const _deviceLatitudeKey = 'prayer_device_latitude';
  static const _deviceLongitudeKey = 'prayer_device_longitude';
  static const _deviceTimezoneKey = 'prayer_device_timezone';
  static const _deviceMethodKey = 'prayer_device_method';
  static const _deviceRegionKey = 'prayer_device_region';
  static const _manualSourceIdKey = 'prayer_manual_source_id';
  static const _manualLabelKey = 'prayer_manual_label';
  static const _manualCountryKey = 'prayer_manual_country';
  static const _manualLatitudeKey = 'prayer_manual_latitude';
  static const _manualLongitudeKey = 'prayer_manual_longitude';
  static const _manualTimezoneKey = 'prayer_manual_timezone';
  static const _manualMethodKey = 'prayer_manual_method';
  static const _manualRegionKey = 'prayer_manual_region';

  static Future<PrayerSettingsSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedNotificationIds = prefs.getStringList(
      _notificationPrayerIdsKey,
    );
    return PrayerSettingsSnapshot(
      methodOverride: _enumByName(
        PrayerCalculationMethod.values,
        prefs.getString(_methodKey),
      ),
      asrMethod:
          _enumByName(PrayerAsrMethod.values, prefs.getString(_asrKey)) ??
          PrayerAsrMethod.standard,
      highLatitudeMethod:
          _enumByName(
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
      notificationsEnabled: prefs.getBool(_notificationsEnabledKey) ?? false,
      notificationPrayerIds: storedNotificationIds == null
          ? defaultPrayerNotificationIds
          : storedNotificationIds.toSet(),
      hijriOffsetDays: (prefs.getInt(_hijriOffsetKey) ?? 0).clamp(-2, 2),
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

  static Future<void> saveDeviceLocation(
    PrayerDeviceLocationSnapshot value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_deviceLatitudeKey, value.location.latitude);
    await prefs.setDouble(_deviceLongitudeKey, value.location.longitude);
    await prefs.setString(_deviceTimezoneKey, value.location.timeZoneId);
    await prefs.setString(_deviceMethodKey, value.defaultMethod.name);
    await prefs.setString(_deviceRegionKey, value.regionCode);
    await prefs.setString(cityKey, deviceLocationId);
  }

  static Future<PrayerDeviceLocationSnapshot?> loadDeviceLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_deviceLatitudeKey);
    final longitude = prefs.getDouble(_deviceLongitudeKey);
    final timezone = prefs.getString(_deviceTimezoneKey);
    final method = _enumByName(
      PrayerCalculationMethod.values,
      prefs.getString(_deviceMethodKey),
    );
    if (latitude == null ||
        longitude == null ||
        timezone == null ||
        method == null) {
      return null;
    }
    return PrayerDeviceLocationSnapshot(
      location: PrayerLocation(
        latitude: latitude,
        longitude: longitude,
        timeZoneId: timezone,
        label: 'GPS',
      ),
      defaultMethod: method,
      regionCode: prefs.getString(_deviceRegionKey) ?? 'world',
    );
  }

  static Future<void> saveManualLocation(
    PrayerManualLocationSnapshot value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_manualSourceIdKey, value.sourceId);
    await prefs.setString(_manualLabelKey, value.label);
    await prefs.setString(_manualCountryKey, value.country);
    await prefs.setDouble(_manualLatitudeKey, value.location.latitude);
    await prefs.setDouble(_manualLongitudeKey, value.location.longitude);
    await prefs.setString(_manualTimezoneKey, value.location.timeZoneId);
    await prefs.setString(_manualMethodKey, value.defaultMethod.name);
    await prefs.setString(_manualRegionKey, value.regionCode);
    await prefs.setString(cityKey, manualLocationId);
  }

  static Future<PrayerManualLocationSnapshot?> loadManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final sourceId = prefs.getString(_manualSourceIdKey);
    final label = prefs.getString(_manualLabelKey);
    final country = prefs.getString(_manualCountryKey);
    final latitude = prefs.getDouble(_manualLatitudeKey);
    final longitude = prefs.getDouble(_manualLongitudeKey);
    final timezone = prefs.getString(_manualTimezoneKey);
    final method = _enumByName(
      PrayerCalculationMethod.values,
      prefs.getString(_manualMethodKey),
    );
    if (sourceId == null ||
        label == null ||
        country == null ||
        latitude == null ||
        longitude == null ||
        timezone == null ||
        method == null) {
      return null;
    }
    return PrayerManualLocationSnapshot(
      sourceId: sourceId,
      label: label,
      country: country,
      location: PrayerLocation(
        latitude: latitude,
        longitude: longitude,
        timeZoneId: timezone,
        label: label,
      ),
      defaultMethod: method,
      regionCode: prefs.getString(_manualRegionKey) ?? 'world',
    );
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
    await prefs.setBool(_notificationsEnabledKey, value.notificationsEnabled);
    await prefs.setStringList(
      _notificationPrayerIdsKey,
      value.notificationPrayerIds.toList()..sort(),
    );
    await prefs.setInt(_hijriOffsetKey, value.hijriOffsetDays.clamp(-2, 2));
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
