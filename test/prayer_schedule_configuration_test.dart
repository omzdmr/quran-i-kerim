import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_preferences_store.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_saved_location_resolver.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_configuration.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';

void main() {
  const shanghai = PrayerResolvedLocation(
    label: 'Shanghai',
    location: PrayerLocation(latitude: 31.2304, longitude: 121.4737, timeZoneId: 'Asia/Shanghai'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  );

  String fingerprint({
    PrayerResolvedLocation resolved = shanghai,
    PrayerAsrMethod asr = PrayerAsrMethod.standard,
    PrayerNotificationProfile profile = PrayerNotificationProfile.fullSound,
    PrayerMinuteAdjustments adjustments = const PrayerMinuteAdjustments(),
  }) => PrayerScheduleConfiguration.fingerprint(
        resolved: resolved,
        settings: PrayerSettingsSnapshot(
          notificationsEnabled: true,
          asrMethod: asr,
          notificationProfile: profile,
          adjustments: adjustments,
        ),
      );

  test('same prayer inputs produce a stable fingerprint', () {
    expect(fingerprint(), fingerprint());
    expect(fingerprint(), startsWith('v2-'));
  });

  test('travel location and timezone changes invalidate schedule identity', () {
    const tokyo = PrayerResolvedLocation(
      label: 'Tokyo',
      location: PrayerLocation(latitude: 35.6762, longitude: 139.6503, timeZoneId: 'Asia/Tokyo'),
      defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
    );
    expect(fingerprint(resolved: tokyo), isNot(fingerprint()));
  });

  test('calculation-affecting preferences invalidate schedule identity', () {
    expect(fingerprint(asr: PrayerAsrMethod.hanafi), isNot(fingerprint()));
    expect(
      fingerprint(adjustments: const PrayerMinuteAdjustments(fajr: 2)),
      isNot(fingerprint()),
    );
  });

  test('notification profile also invalidates delivery identity', () {
    expect(fingerprint(profile: PrayerNotificationProfile.discreet), isNot(fingerprint()));
  });
}
