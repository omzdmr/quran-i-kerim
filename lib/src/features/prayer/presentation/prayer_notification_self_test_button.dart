import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../application/prayer_notification_service.dart';

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
    final l10n = context.l10n;
    try {
      final result = await PrayerNotificationService.sendSelfTest();
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result == PrayerNotificationSelfTestResult.delivered
                  ? l10n.text('notificationDiagnosticsAllowed')
                  : l10n.text('notificationPermissionDenied'),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(l10n.text('notificationDiagnosticsFailed'))),
        );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.text('notificationDiagnosticsCheck');
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
