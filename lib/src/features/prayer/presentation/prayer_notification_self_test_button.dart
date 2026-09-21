import 'package:flutter/material.dart';

import '../application/prayer_notification_service.dart';
import 'prayer_notification_self_test_strings.dart';

/// User-triggered end-to-end notification probe. It deliberately sends no
/// prayer-completion/history event and can therefore be used repeatedly while
/// troubleshooting device notification settings.
class PrayerNotificationSelfTestButton extends StatefulWidget {
  const PrayerNotificationSelfTestButton({super.key});

  @override
  State<PrayerNotificationSelfTestButton> createState() =>
      _PrayerNotificationSelfTestButtonState();
}

class _PrayerNotificationSelfTestButtonState
    extends State<PrayerNotificationSelfTestButton> {
  bool _sending = false;

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final copy = prayerNotificationSelfTestStrings(context);
    try {
      final result = await PrayerNotificationService.sendSelfTest();
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result == PrayerNotificationSelfTestResult.delivered
                  ? copy.sent
                  : copy.denied,
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(copy.failed)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = prayerNotificationSelfTestStrings(context).send;
    return Semantics(
      button: true,
      label: label,
      child: OutlinedButton.icon(
        onPressed: _sending ? null : _send,
        icon: _sending
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.notifications_active_outlined),
        label: Text(label),
      ),
    );
  }
}
