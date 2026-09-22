import 'package:flutter/material.dart';

import '../application/prayer_notification_schedule_health_refresher.dart';
import '../application/prayer_schedule_repair_receipt_store.dart';
import 'prayer_schedule_health_card.dart';
import 'prayer_schedule_repair_receipt_card.dart';

class PrayerScheduleHealthPanel extends StatelessWidget {
  const PrayerScheduleHealthPanel({super.key});

  static const _refresher = PrayerNotificationScheduleHealthRefresher();
  static const _receiptStore = PrayerScheduleRepairReceiptStore();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrayerScheduleHealthCard(
            onResync: () async {
              final refreshed = await _refresher.resync();
              // A successful explicit retry supersedes an older automatic
              // failure. Clearing the receipt also notifies the open panel so
              // contradictory "healthy" + "auto repair failed" cards cannot
              // remain on screen together.
              if (refreshed != null) await _receiptStore.clear();
            },
          ),
          const SizedBox(height: 8),
          const PrayerScheduleRepairReceiptCard(),
        ],
      );
}
