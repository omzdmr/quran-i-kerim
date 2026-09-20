import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_preferences_store.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('prayer notification profile defaults to full sound', () async {
    final settings = await PrayerPreferencesStore.load();

    expect(
      settings.notificationProfile,
      PrayerNotificationProfile.fullSound,
    );
    expect(settings.notificationProfile.playSound, isTrue);
    expect(settings.notificationProfile.enableVibration, isTrue);
    expect(
      settings.notificationProfile.channelId,
      'prayer_times_full_v1',
    );
  });

  test('discreet notification profile persists and uses its own channel', () async {
    const snapshot = PrayerSettingsSnapshot(
      notificationsEnabled: true,
      notificationPrayerIds: <String>{'fajr', 'isha'},
      notificationProfile: PrayerNotificationProfile.discreet,
    );

    await PrayerPreferencesStore.save(snapshot);
    final restored = await PrayerPreferencesStore.load();

    expect(restored.notificationsEnabled, isTrue);
    expect(restored.notificationPrayerIds, <String>{'fajr', 'isha'});
    expect(
      restored.notificationProfile,
      PrayerNotificationProfile.discreet,
    );
    expect(restored.notificationProfile.playSound, isFalse);
    expect(restored.notificationProfile.enableVibration, isTrue);
    expect(
      restored.notificationProfile.channelId,
      'prayer_times_discreet_v1',
    );
  });

  test('unknown stored notification profile safely falls back', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'prayer_notification_profile': 'future_profile',
    });

    final restored = await PrayerPreferencesStore.load();

    expect(
      restored.notificationProfile,
      PrayerNotificationProfile.fullSound,
    );
  });
}
