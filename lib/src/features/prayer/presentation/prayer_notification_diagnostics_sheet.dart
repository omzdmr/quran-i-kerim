import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../application/prayer_notification_self_test_store.dart';
import '../application/prayer_notification_service.dart';
import 'prayer_notification_self_test_button.dart';
import 'prayer_notification_self_test_strings.dart';
import 'prayer_schedule_health_panel.dart';

Future<void> showPrayerNotificationDiagnosticsSheet({required BuildContext context, required bool notificationsEnabled}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => PrayerNotificationDiagnosticsSheet(notificationsEnabled: notificationsEnabled),
);

class PrayerNotificationDiagnosticsSheet extends StatefulWidget {
  const PrayerNotificationDiagnosticsSheet({required this.notificationsEnabled, super.key});
  final bool notificationsEnabled;

  @override
  State<PrayerNotificationDiagnosticsSheet> createState() => _PrayerNotificationDiagnosticsSheetState();
}

class _PrayerNotificationDiagnosticsSheetState extends State<PrayerNotificationDiagnosticsSheet> {
  static const _probeStore = PrayerNotificationSelfTestStore();
  PrayerNotificationDiagnostics? _diagnostics;
  PrayerNotificationProbeRecord? _probeRecord;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _diagnostics = null;
    });
    try {
      final diagnosticsFuture = PrayerNotificationService.diagnostics();
      final probeFuture = _probeStore.load();
      final diagnostics = await diagnosticsFuture;
      final probe = await probeFuture;
      if (!mounted) return;
      setState(() {
        _diagnostics = diagnostics;
        _probeRecord = probe;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selfTestCopy = prayerNotificationSelfTestStrings(context);
    final diagnostics = _diagnostics;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.text('notificationDiagnosticsTitle'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(l10n.text('notificationDiagnosticsFailed')),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: Text(l10n.text('notificationDiagnosticsCheck'))),
              ] else if (diagnostics == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                _DiagnosticRow(icon: Icons.notifications_outlined, label: l10n.text('notificationDiagnosticsAppSetting'), value: widget.notificationsEnabled ? l10n.text('notificationDiagnosticsOn') : l10n.text('notificationDiagnosticsOff')),
                _DiagnosticRow(icon: Icons.security_rounded, label: l10n.text('notificationDiagnosticsPermission'), value: diagnostics.systemPermissionGranted == null ? l10n.text('notificationDiagnosticsUnknown') : diagnostics.systemPermissionGranted! ? l10n.text('notificationDiagnosticsAllowed') : l10n.text('notificationDiagnosticsBlocked')),
                _DiagnosticRow(icon: Icons.schedule_rounded, label: l10n.text('notificationDiagnosticsPending'), value: '${diagnostics.pendingCount}'),
                _DiagnosticRow(icon: Icons.alarm_on_rounded, label: l10n.text('notificationDiagnosticsExactAlarm'), value: diagnostics.exactAlarmAvailable == null ? l10n.text('notificationDiagnosticsNotApplicable') : diagnostics.exactAlarmAvailable! ? l10n.text('notificationDiagnosticsAvailable') : l10n.text('notificationDiagnosticsUnavailable')),
                if (_probeRecord != null)
                  _DiagnosticRow(
                    icon: _probeRecord!.outcome == PrayerNotificationProbeOutcome.received ? Icons.verified_outlined : Icons.report_problem_outlined,
                    label: selfTestCopy.lastVerified,
                    value: '${_probeRecord!.outcome == PrayerNotificationProbeOutcome.received ? selfTestCopy.received : selfTestCopy.notReceived} · ${MaterialLocalizations.of(context).formatCompactDate(_probeRecord!.confirmedAt)}',
                  ),
                if (diagnostics.systemPermissionGranted == false) ...[
                  const SizedBox(height: 8),
                  Text(l10n.text('notificationDiagnosticsPermissionHint'), style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 14),
                PrayerNotificationSelfTestButton(onConfirmed: _load),
                if (widget.notificationsEnabled) ...[
                  const SizedBox(height: 14),
                  const PrayerScheduleHealthPanel(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label: $value',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            const SizedBox(width: 12),
            Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800))),
          ]),
        ),
      );
}
