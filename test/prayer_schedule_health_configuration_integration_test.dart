import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_schedule_health_refresher.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_saved_location_resolver.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedResolver extends PrayerSavedLocationResolver {
  const _FixedResolver();

  @override
  Future<PrayerResolvedLocation?> resolve() async => const PrayerResolvedLocation(
        label: 'Shanghai',
        location: PrayerLocation(
          latitude: 31.2304,
          longitude: 121.4737,
          timeZoneId: 'Asia/Shanghai',
        ),
        defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
      );
}

void main() {
  const refresher = PrayerNotificationScheduleHealthRefresher(resolver: _FixedResolver());

  test('disabled notifications have no current schedule identity', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'prayer_notifications_enabled': false,
    });
    expect(await refresher.currentConfigurationFingerprint(), isNull);
  });

  test('enabled saved settings produce a current schedule identity', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'prayer_notifications_enabled': true,
      'prayer_notification_ids': <String>['fajr', 'dhuhr'],
      'prayer_notification_profile': 'fullSound',
    });
    final value = await refresher.currentConfigurationFingerprint();
    expect(value, isNotNull);
    expect(value, startsWith('v2-'));
  });

  test('changing saved delivery profile changes current schedule identity', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'prayer_notifications_enabled': true,
      'prayer_notification_ids': <String>['fajr', 'dhuhr'],
      'prayer_notification_profile': 'fullSound',
    });
    final before = await refresher.currentConfigurationFingerprint();

    SharedPreferences.setMockInitialValues(<String, Object>{
      'prayer_notifications_enabled': true,
      'prayer_notification_ids': <String>['fajr', 'dhuhr'],
      'prayer_notification_profile': 'discreet',
    });
    final after = await refresher.currentConfigurationFingerprint();
    expect(after, isNot(before));
  });
}
