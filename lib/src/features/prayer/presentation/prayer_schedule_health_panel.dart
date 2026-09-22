import 'package:flutter/material.dart';

import '../application/prayer_notification_schedule_health_refresher.dart';
import 'prayer_schedule_health_card.dart';
import 'prayer_schedule_repair_receipt_card.dart';

/// Connected diagnostics panel used by prayer settings/diagnostics. Keeping the
/// platform reschedule behind one callback also makes the visual component easy
/// to exercise in widget tests.
class PrayerScheduleHealthPanel extends StatelessWidget {
  const PrayerScheduleHealthPanel({super.key});

  static const _refresher = PrayerNotificationScheduleHealthRefresher();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrayerScheduleHealthCard(
            onResync: () async {
              await _refresher.resync();
            },
          ),
          const SizedBox(height: 8),
          const PrayerScheduleRepairReceiptCard(),
        ],
      );
}
