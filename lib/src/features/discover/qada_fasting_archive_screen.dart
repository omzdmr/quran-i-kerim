import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/strings/qada_fasting_archive_strings.dart';
import 'qada_fasting_ledger.dart';
import 'qada_fasting_portable_archive.dart';

class QadaFastingArchiveScreen extends StatefulWidget {
  const QadaFastingArchiveScreen({super.key});

  @override
  State<QadaFastingArchiveScreen> createState() =>
      _QadaFastingArchiveScreenState();
}

class _QadaFastingArchiveScreenState extends State<QadaFastingArchiveScreen> {
  static const _store = QadaFastingStore();
  static const _archive = QadaFastingPortableArchive();

  QadaFastingLedger _ledger = QadaFastingLedger();
  bool _loading = true;
  bool _includeNotes = false;
  String? _status;

  String _t(String key) => qadaFastingArchiveText(
        Localizations.localeOf(context).languageCode,
        key,
      );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ledger = await _store.load();
    if (!mounted) return;
    setState(() {
      _ledger = ledger;
      _loading = false;
    });
  }

  Future<void> _shareArchive() async {
    try {
      final directory = await getTemporaryDirectory();
      final source = _archive.export(
        _ledger,
        includePrivateNotes: _includeNotes,
      );
      final file = File('${directory.path}/qada-fasting-backup.qada.json');
      await file.writeAsString(source, flush: true);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path, mimeType: 'application/json')],
          title: _t('exportTitle'),
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _t('exportFailed'));
    }
  }

  Future<void> _pickAndPreview() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
      );
      if (picked == null || !mounted) return;
      final path = picked.path;
      if (path == null || path.trim().isEmpty) {
        setState(() => _status = _t('fileUnavailable'));
        return;
      }
      final source = await File(path).readAsString();
      if (!mounted) return;
      await _previewSource(source);
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _t('invalidArchive'));
    }
  }

  Future<void> _pasteAndPreview() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final source = data?.text?.trim();
    if (!mounted) return;
    if (source == null || source.isEmpty) {
      setState(() => _status = _t('clipboardEmpty'));
      return;
    }
    await _previewSource(source);
  }

  Future<void> _previewSource(String source) async {
    try {
      final preview = _archive.preview(source, current: _ledger);
      if (!mounted) return;
      await _showPreview(source, preview);
    } on FormatException {
      if (!mounted) return;
      setState(() => _status = _t('invalidArchive'));
    }
  }

  Future<void> _showPreview(String source, QadaArchivePreview preview) async {
    final action = await showDialog<QadaArchiveImportMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('previewTitle')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewRow(_t('incoming'), preview.incomingEntries),
              _PreviewRow(_t('newRecords'), preview.newEntries),
              _PreviewRow(_t('duplicates'), preview.duplicateEntries),
              _PreviewRow(
                _t('conflictingRecords'),
                preview.conflictingEntries,
                emphasize: preview.conflictingEntries > 0,
              ),
              _PreviewRow(_t('archiveBalance'), preview.remainingDays),
              const SizedBox(height: 12),
              if (preview.containsPrivateNotes)
                Semantics(
                  container: true,
                  child: Text(
                    _t('containsNotes'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (!preview.canMerge) ...[
                const SizedBox(height: 10),
                Semantics(
                  container: true,
                  liveRegion: true,
                  child: Text(
                    _t('mergeBlocked'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(_t('mergeExplanation')),
              const SizedBox(height: 8),
              Text(_t('replaceWarning')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_t('cancel')),
          ),
          FilledButton.tonal(
            onPressed: preview.canMerge
                ? () => Navigator.pop(
                    dialogContext,
                    QadaArchiveImportMode.merge,
                  )
                : null,
            child: Text(_t('merge')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              QadaArchiveImportMode.replace,
            ),
            child: Text(_t('replace')),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;
    if (action == QadaArchiveImportMode.replace) {
      final confirmed = await _confirmReplace();
      if (confirmed != true || !mounted) return;
    }
    try {
      final restored = _archive.import(
        source,
        current: _ledger,
        mode: action,
      );
      await _store.save(restored);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _ledger = restored;
        _status = _t('restoreComplete');
      });
    } on FormatException {
      setState(() => _status = _t('conflict'));
    }
  }

  Future<bool?> _confirmReplace() => showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(_t('replaceConfirmTitle')),
          content: Text(_t('replaceConfirmBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(_t('replace')),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_t('title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('localTitle'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text('${_t('records')}: ${_ledger.entries.length}'),
                      Text('${_t('remaining')}: ${_ledger.remainingDays}'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _includeNotes,
                  title: Text(_t('includeNotes')),
                  subtitle: Text(_t('includeNotesWarning')),
                  onChanged: (value) => setState(() => _includeNotes = value),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _ledger.entries.isEmpty ? null : _shareArchive,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(_t('export')),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickAndPreview,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: Text(_t('fileImport')),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _pasteAndPreview,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: Text(_t('pasteImport')),
                ),
                const SizedBox(height: 12),
                Text(
                  _t('pasteHelp'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 18),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _status!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow(this.label, this.value, {this.emphasize = false});
  final String label;
  final int value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: FontWeight.w800,
      color: emphasize ? Theme.of(context).colorScheme.error : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: emphasize ? style : null)),
          Text('$value', style: style),
        ],
      ),
    );
  }
}
