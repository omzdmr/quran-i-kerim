import 'package:flutter/material.dart';

import '../application/prayer_notification_schedule_health_refresher.dart';
import '../application/prayer_schedule_repair_receipt_store.dart';
import 'prayer_schedule_health_card.dart';
import 'prayer_schedule_repair_receipt_card.dart';

class PrayerScheduleHealthPanel extends StatelessWidget {
  const PrayerScheduleHealthPanel({
    this.refresher = const PrayerNotificationScheduleHealthRefresher(),
    this.receiptStore = const PrayerScheduleRepairReceiptStore(),
    super.key,
  });

  final PrayerNotificationScheduleHealthRefresher refresher;
  final PrayerScheduleRepairReceiptStore receiptStore;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrayerScheduleHealthCard(
            onResync: () async {
              final refreshed = await refresher.resync();
              // A successful explicit retry supersedes an older automatic
              // failure. Clearing the receipt also notifies the open panel so
              // contradictory "healthy" + "auto repair failed" cards cannot
              // remain on screen together.
              if (refreshed != null) await receiptStore.clear();
            },
          ),
          const SizedBox(height: 8),
          const PrayerScheduleRepairReceiptCard(),
        ],
      );
}
