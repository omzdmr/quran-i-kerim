import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/backup/backup_build_config.dart';
import '../../data/backup/backup_file_service.dart';
import '../../data/backup/backup_preview.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/app_settings.dart';
import '../learn/application/learn_progress_store.dart';
import '../plans/reading_plan_store.dart';
import '../prayer/application/prayer_notification_service.dart';
import 'google_drive_backup_section.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  final BackupFileService _service = BackupFileService();

  bool _busy = false;
  bool _loading = true;
  List<_BackupListEntry> _entries = const <_BackupListEntry>[];

  @override
  void initState() {
    super.initState();
    _refreshLocalBackups();
  }

  Future<void> _refreshLocalBackups() async {
    try {
      final files = await _service.listBackupFiles();
      final entries = <_BackupListEntry>[];
      for (final file in files) {
        BackupPreview? preview;
        try {
          preview = await _service.previewFile(file);
        } catch (_) {
          preview = null;
        }
        entries.add(_BackupListEntry(file: file, preview: preview));
      }
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showFailure();
    }
  }

  Future<void> _createAndExport() async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    try {
      final file = await _service.exportToFile();
      await _refreshLocalBackups();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('backupCreated'))),
      );
      await _share(file);
    } catch (_) {
      if (mounted) _showFailure();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(File file) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: 'application/json')],
        title: context.l10n.text('backupTitle'),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _refreshRestoredAppState() async {
    final settings = AppSettingsScope.of(context);
    await settings.reloadFromStorage();
    await PrayerNotificationService.refreshFromSaved();
    ReadingPlanStore.notifyExternalChange();
    LearnProgressStore.notifyExternalChange();
    if (!mounted) return;
    await _refreshLocalBackups();
  }

  Future<void> _pickAndPreviewBackup() async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
      );
      if (picked == null) return;
      final path = picked.path;
      if (path == null || path.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.text('backupImportPathUnavailable')),
          ),
        );
        return;
      }
      await _confirmAndRestore(File(path));
    } catch (_) {
      if (mounted) _showFailure();
    }
  }

  Future<void> _confirmAndRestore(File file) async {
    BackupPreview preview;
    try {
      preview = await _service.previewFile(file);
    } catch (_) {
      if (!mounted) return;
      await _showInvalidBackup();
      return;
    }

    if (!mounted) return;
    if (!preview.canRestore) {
      await _showInvalidBackup();
      return;
    }

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.text('backupRestoreConfirmTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.text('backupRestoreConfirmBody')),
            const SizedBox(height: 16),
            _PreviewSummary(preview: preview),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.text('backupRestore')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _service.restoreFile(file);
      await _refreshRestoredAppState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('backupRestored'))),
      );
    } catch (_) {
      if (mounted) _showFailure();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showInvalidBackup() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.text('backupTitle')),
      content: Text(context.l10n.text('backupInvalid')),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
        ),
      ],
    ),
  );

  void _showFailure() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.text('backupOperationFailed'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('backupTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text(
            l10n.text('backupSubtitle'),
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.privacy_tip_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.text('backupPrivacy'),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (BackupBuildConfig.googleDriveEnabled) ...[
            const SizedBox(height: 18),
            GoogleDriveBackupSection(onRestored: _refreshRestoredAppState),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : _createAndExport,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(l10n.text('backupCreateExport')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickAndPreviewBackup,
            icon: const Icon(Icons.file_open_outlined),
            label: Text(l10n.text('backupImport')),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.text('backupExternalHint'),
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            l10n.text('backupRecent'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.text('backupEmpty'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            for (final entry in _entries) ...[
              _BackupCard(
                entry: entry,
                busy: _busy,
                onShare: () async {
                  HapticFeedback.selectionClick();
                  try {
                    await _share(entry.file);
                  } catch (_) {
                    if (mounted) _showFailure();
                  }
                },
                onRestore: () => _confirmAndRestore(entry.file),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _BackupListEntry {
  const _BackupListEntry({required this.file, required this.preview});

  final File file;
  final BackupPreview? preview;
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({
    required this.entry,
    required this.busy,
    required this.onShare,
    required this.onRestore,
  });

  final _BackupListEntry entry;
  final bool busy;
  final VoidCallback onShare;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final preview = entry.preview;
    final valid = preview?.canRestore ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                valid ? Icons.inventory_2_outlined : Icons.warning_amber_rounded,
                color: valid ? scheme.primary : scheme.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  preview?.createdAt == null
                      ? _fileName(entry.file)
                      : _formatDateTime(context, preview!.createdAt!),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (preview != null) _PreviewSummary(preview: preview),
          if (preview == null)
            Text(
              l10n.text('backupInvalid'),
              style: TextStyle(color: scheme.error),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onShare,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(l10n.text('backupShare')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: busy || !valid ? null : onRestore,
                  icon: const Icon(Icons.restore_rounded),
                  label: Text(l10n.text('backupRestore')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({required this.preview});

  final BackupPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final version = preview.version?.toString() ?? '?';
    final versionText = l10n
        .text('backupVersionLabel')
        .replaceAll('{version}', version);
    final countText = l10n
        .text('backupRecordCount')
        .replaceAll('{count}', '${preview.totalRecords}');

    return Text(
      '$countText · $versionText',
      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
    );
  }
}

String _fileName(File file) => file.path.split(Platform.pathSeparator).last;

String _formatDateTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final material = MaterialLocalizations.of(context);
  final date = material.formatMediumDate(local);
  final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(local));
  return '$date · $time';
}
