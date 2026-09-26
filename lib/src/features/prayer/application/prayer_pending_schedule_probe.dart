import 'prayer_notification_service.dart';

/// Small seam around platform diagnostics so schedule-health logic can verify
/// the operating system still has pending reminders instead of trusting only
/// our last successful write.
abstract class PrayerPendingScheduleProbe {
  const PrayerPendingScheduleProbe();
  Future<int?> pendingCount();
}

class SystemPrayerPendingScheduleProbe implements PrayerPendingScheduleProbe {
  const SystemPrayerPendingScheduleProbe();

  @override
  Future<int?> pendingCount() async {
    try {
      final diagnostics = await PrayerNotificationService.diagnostics();
      return diagnostics.pendingCount;
    } catch (_) {
      // Unknown is different from zero. A transient platform diagnostics error
      // must not trigger destructive churn or falsely claim that reminders exist.
      return null;
    }
  }
}
