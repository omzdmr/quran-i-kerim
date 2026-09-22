import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/backup/backup_build_config.dart';
import '../../data/backup/backup_cloud_connector.dart';
import '../../data/backup/backup_cloud_controller.dart';
import '../../data/backup/backup_cloud_coordinator.dart';
import '../../data/backup/backup_cloud_store.dart';
import '../../data/backup/backup_file_service.dart';
import '../../data/backup/google_drive_backup_auth.dart';
import '../../l10n/app_localizations.dart';
import 'backup_restore_dialog.dart';
import 'backup_restore_feedback.dart';

class GoogleDriveBackupSection extends StatefulWidget {
  const GoogleDriveBackupSection({
    required this.onRestored,
    this.connector,
    this.restoreSafetyService,
    this.enabledOverride,
    super.key,
  });

  final Future<void> Function() onRestored;
  final BackupCloudConnector? connector;
  final BackupFileService? restoreSafetyService;
  final bool? enabledOverride;

  @override
  State<GoogleDriveBackupSection> createState() => _GoogleDriveBackupSectionState();
}

class _GoogleDriveBackupSectionState extends State<GoogleDriveBackupSection> {
  late final BackupFileService _restoreSafetyService;
  late final BackupCloudController _controller;

  @override
  void initState() {
    super.initState();
    _restoreSafetyService = widget.restoreSafetyService ?? BackupFileService();
    _controller = BackupCloudController(
      connector: widget.connector ?? GoogleDriveBackupAuth(),
      coordinatorFactory: (store) => BackupCloudCoordinator(
        store: store,
        restoreFileService: _restoreSafetyService,
      ),
    )..addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    HapticFeedback.selectionClick();
    await _guard(() => _controller.connect());
  }

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();
    await _guard(_controller.refresh);
  }

  Future<void> _upload({required bool overwrite}) async {
    HapticFeedback.selectionClick();
    if (overwrite &&
        !await _confirm(
          titleKey: 'backupCloudUploadConfirmTitle',
          bodyKey: 'backupCloudUploadConfirmBody',
          actionKey: 'backupCloudUpload',
        )) {
      return;
    }
    await _guard(
      () => _controller.uploadLocal(allowOverwrite: overwrite),
      refreshOnFailure: true,
    );
  }

  Future<void> _replaceInvalid() async {
    HapticFeedback.selectionClick();
    if (!await _confirm(
      titleKey: 'backupCloudReplaceConfirmTitle',
      bodyKey: 'backupCloudReplaceConfirmBody',
      actionKey: 'backupCloudReplace',
    )) {
      return;
    }
    await _guard(
      () => _controller.uploadLocal(allowOverwrite: true),
      refreshOnFailure: true,
    );
  }

  Future<void> _restore() async {
    HapticFeedback.selectionClick();
    BackupCloudRestorePreparation? preparation;
    await _guard(() async {
      preparation = await _controller.prepareRemoteRestore();
    });
    if (!mounted || preparation == null) return;
    final reviewed = preparation!;

    final mode = await showDialog<BackupRestoreMode>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackupRestoreDialog(
        preview: reviewed.preview,
        plan: reviewed.plan,
      ),
    );
    if (!mounted || mode == null) return;

    BackupRestoreReceipt? receipt;
    await _guard(() async {
      receipt = await _controller.restoreRemote(
        preparation: reviewed,
        mode: mode,
      );
      if (receipt == null) return;
      await widget.onRestored();
    });
    if (receipt != null && mounted) {
      await BackupRestoreFeedback.show(
        context: context,
        service: _restoreSafetyService,
        receipt: receipt!,
        afterUndo: () async {
          await widget.onRestored();
          await _controller.refresh();
        },
      );
    }
  }

  Future<void> _signOut() async {
    HapticFeedback.selectionClick();
    await _guard(_controller.signOut);
  }

  Future<void> _guard(
    Future<void> Function() action, {
    bool refreshOnFailure = false,
  }) async {
    try {
      await action();
    } on BackupCloudConflictException {
      if (!mounted) return;
      final message =
          '${context.l10n.text('backupCloudDiverged')} ${context.l10n.text('backupCloudRefresh')}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            liveRegion: true,
            label: message,
            child: Text(message),
          ),
        ),
      );
    } catch (_) {
      if (refreshOnFailure && _controller.connected) {
        try {
          await _controller.refresh();
        } catch (_) {}
      }
      if (!mounted) return;
      final message = context.l10n.text('backupCloudFailed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            liveRegion: true,
            label: message,
            child: Text(message),
          ),
        ),
      );
    }
  }

  Future<bool> _confirm({
    required String titleKey,
    required String bodyKey,
    required String actionKey,
  }) async {
    final l10n = context.l10n;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.text(titleKey)),
            content: Text(l10n.text(bodyKey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.text(actionKey)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (!(widget.enabledOverride ?? BackupBuildConfig.googleDriveEnabled)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final state = _controller.state;
    final remote = _controller.inspection?.remote;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.cloud_outlined, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.text('backupCloudTitle'), style: const TextStyle(fontWeight: FontWeight.w900)),
              if (_controller.accountLabel != null)
                Text(l10n.text('backupCloudConnectedAs').replaceAll('{account}', _controller.accountLabel!), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            ])),
            if (_controller.connected)
              IconButton(tooltip: l10n.text('backupCloudSignOut'), onPressed: _controller.busy ? null : _signOut, icon: const Icon(Icons.logout_rounded)),
          ]),
          const SizedBox(height: 10),
          Text(l10n.text('backupCloudSubtitle'), style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4)),
          if (_controller.busy) ...[const SizedBox(height: 14), const LinearProgressIndicator()],
          const SizedBox(height: 14),
          if (!_controller.connected)
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _controller.busy ? null : _connect, icon: const Icon(Icons.account_circle_outlined), label: Text(l10n.text('backupCloudConnect'))))
          else ...[
            _CloudStatusLine(state: state),
            if (remote != null) ...[
              const SizedBox(height: 6),
              Text(l10n.text('backupCloudUpdatedAt').replaceAll('{date}', _formatDateTime(context, remote.updatedAt)), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            _CloudActions(state: state, busy: _controller.busy, onRefresh: _refresh, onUpload: () => _upload(overwrite: false), onOverwrite: () => _upload(overwrite: true), onRestore: _restore, onReplaceInvalid: _replaceInvalid),
          ],
        ],
      ),
    );
  }
}

class _CloudStatusLine extends StatelessWidget {
  const _CloudStatusLine({required this.state});
  final BackupCloudState? state;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final key = switch (state) {
      BackupCloudState.remoteEmpty => 'backupCloudRemoteEmpty',
      BackupCloudState.upToDate => 'backupCloudUpToDate',
      BackupCloudState.diverged => 'backupCloudDiverged',
      BackupCloudState.invalidRemote => 'backupCloudInvalid',
      null => 'backupCloudChecking',
    };
    final icon = switch (state) {
      BackupCloudState.remoteEmpty => Icons.cloud_queue_rounded,
      BackupCloudState.upToDate => Icons.cloud_done_outlined,
      BackupCloudState.diverged => Icons.sync_problem_rounded,
      BackupCloudState.invalidRemote => Icons.warning_amber_rounded,
      null => Icons.sync_rounded,
    };
    return Row(children: [Icon(icon, size: 20, color: scheme.primary), const SizedBox(width: 8), Expanded(child: Text(context.l10n.text(key), style: const TextStyle(fontWeight: FontWeight.w700)))]);
  }
}

class _CloudActions extends StatelessWidget {
  const _CloudActions({required this.state, required this.busy, required this.onRefresh, required this.onUpload, required this.onOverwrite, required this.onRestore, required this.onReplaceInvalid});
  final BackupCloudState? state;
  final bool busy;
  final VoidCallback onRefresh, onUpload, onOverwrite, onRestore, onReplaceInvalid;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state == BackupCloudState.remoteEmpty) return SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : onUpload, icon: const Icon(Icons.cloud_upload_outlined), label: Text(l10n.text('backupCloudUpload'))));
    if (state == BackupCloudState.diverged) {
      return Column(children: [
        SizedBox(width: double.infinity, child: FilledButton.tonalIcon(onPressed: busy ? null : onOverwrite, icon: const Icon(Icons.cloud_upload_outlined), label: Text(l10n.text('backupCloudUpload')))),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: busy ? null : onRestore, icon: const Icon(Icons.cloud_download_outlined), label: Text(l10n.text('backupCloudRestore')))),
      ]);
    }
    if (state == BackupCloudState.invalidRemote) return SizedBox(width: double.infinity, child: FilledButton.tonalIcon(onPressed: busy ? null : onReplaceInvalid, icon: const Icon(Icons.cloud_upload_outlined), label: Text(l10n.text('backupCloudReplace'))));
    return SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: busy ? null : onRefresh, icon: const Icon(Icons.refresh_rounded), label: Text(l10n.text('backupCloudRefresh'))));
  }
}

String _formatDateTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final material = MaterialLocalizations.of(context);
  return '${material.formatMediumDate(local)} · ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}
