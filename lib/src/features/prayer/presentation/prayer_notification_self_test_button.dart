import 'package:flutter/material.dart';

import '../application/prayer_notification_service.dart';
import 'prayer_notification_self_test_strings.dart';

/// User-triggered notification probe. API acceptance alone is not presented as
/// proof of delivery: after sending, the user confirms whether the device
/// actually surfaced the alert/sound.
class PrayerNotificationSelfTestButton extends StatefulWidget {
  const PrayerNotificationSelfTestButton({super.key});

  @override
  State<PrayerNotificationSelfTestButton> createState() => _PrayerNotificationSelfTestButtonState();
}

class _PrayerNotificationSelfTestButtonState extends State<PrayerNotificationSelfTestButton> {
  bool _sending = false;
  bool _awaitingConfirmation = false;

  Future<void> _send() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _awaitingConfirmation = false;
    });
    final messenger = ScaffoldMessenger.of(context);
    final copy = prayerNotificationSelfTestStrings(context);
    try {
      final result = await PrayerNotificationService.sendSelfTest();
      if (!mounted) return;
      if (result == PrayerNotificationSelfTestResult.delivered) {
        setState(() => _awaitingConfirmation = true);
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(copy.sent)));
      } else {
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(copy.denied)));
      }
    } catch (_) {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(copy.failed)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _confirm(bool received) {
    final copy = prayerNotificationSelfTestStrings(context);
    setState(() => _awaitingConfirmation = false);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(received ? copy.receivedAck : copy.notReceivedHelp),
        duration: received ? const Duration(seconds: 3) : const Duration(seconds: 6),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final copy = prayerNotificationSelfTestStrings(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: copy.send,
          child: OutlinedButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.notifications_active_outlined),
            label: Text(copy.send),
          ),
        ),
        if (_awaitingConfirmation) ...[
          const SizedBox(height: 10),
          Semantics(container: true, liveRegion: true, child: Text(copy.confirmPrompt)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonalIcon(onPressed: () => _confirm(true), icon: const Icon(Icons.check_rounded), label: Text(copy.received)),
            OutlinedButton.icon(onPressed: () => _confirm(false), icon: const Icon(Icons.close_rounded), label: Text(copy.notReceived)),
          ]),
        ],
      ],
    );
  }
}