import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/translation_catalog.dart';
import '../../data/translation_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/app_settings.dart';

class QuranTranslationCatalogScreen extends StatefulWidget {
  const QuranTranslationCatalogScreen({super.key});

  @override
  State<QuranTranslationCatalogScreen> createState() =>
      _QuranTranslationCatalogScreenState();
}

class _QuranTranslationCatalogScreenState
    extends State<QuranTranslationCatalogScreen> {
  final _searchController = TextEditingController();
  final Set<String> _installed = <String>{};
  final Map<String, double> _progress = <String, double>{};
  String _query = '';
  bool _loadingInstalled = true;

  @override
  void initState() {
    super.initState();
    _refreshInstalled();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshInstalled() async {
    final installed = <String>{};
    for (final info in translationCatalog) {
      if (await TranslationRepository.instance.isInstalled(info.id)) {
        installed.add(info.id);
      }
    }
    if (!mounted) return;
    setState(() {
      _installed
        ..clear()
        ..addAll(installed);
      _loadingInstalled = false;
    });
  }

  String _languageName(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'tr' => l10n.turkish,
      'en' => l10n.english,
      'az' => l10n.azerbaijani,
      'ru' => l10n.russian,
      _ => code.toUpperCase(),
    };
  }

  bool _matches(BuildContext context, TranslationInfo item) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return item.name.toLowerCase().contains(query) ||
        item.publisher.toLowerCase().contains(query) ||
        item.code.toLowerCase().contains(query) ||
        _languageName(context, item.languageCode).toLowerCase().contains(query);
  }

  Future<void> _downloadAndSelect(TranslationInfo info) async {
    final l10n = context.l10n;
    final settings = AppSettingsScope.of(context);
    setState(() => _progress[info.id] = 0);
    try {
      await TranslationRepository.instance.downloadTranslation(
        info,
        onProgress: (value) {
          if (!mounted) return;
          setState(() => _progress[info.id] = value.clamp(0, 1));
        },
      );
      if (!mounted) return;
      await settings.setSelectedQuranSource(info.id);
      if (!mounted) return;
      setState(() {
        _progress.remove(info.id);
        _installed.add(info.id);
      });
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.text('translationInstalled'))),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _progress.remove(info.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.text('translationDownloadFailed')}: $error'),
        ),
      );
    }
  }

  Future<void> _deleteDownloaded(TranslationInfo info) async {
    final l10n = context.l10n;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.text('deleteDownloadConfirm')),
        content: Text(l10n.text('deleteDownloadBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.text('delete')),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    final settings = AppSettingsScope.of(context);
    await TranslationRepository.instance.deleteInstalledTranslation(info.id);
    if (settings.selectedQuranSourceId == info.id) {
      await settings.setSelectedQuranSource(bundledTurkishTranslationId);
    }
    if (!mounted) return;
    setState(() => _installed.remove(info.id));
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final settings = AppSettingsScope.of(context);
    final items = translationCatalog
        .where((item) => _matches(context, item))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quranLanguage)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: l10n.text('translationSearchHint'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: scheme.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _OriginalArabicTile(
            selected:
                settings.selectedQuranSourceId == arabicOriginalSourceId,
            onTap: () {
              HapticFeedback.selectionClick();
              settings.setSelectedQuranSource(arabicOriginalSourceId);
            },
          ),
          if (_loadingInstalled) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(),
          ],
          for (final item in items) ...[
            const SizedBox(height: 10),
            _TranslationTile(
              info: item,
              languageName: _languageName(context, item.languageCode),
              selected: settings.selectedQuranSourceId == item.id,
              installed: item.bundled || _installed.contains(item.id),
              progress: _progress[item.id],
              onDelete: !item.bundled && _installed.contains(item.id)
                  ? () => _deleteDownloaded(item)
                  : null,
              onTap: () {
                HapticFeedback.selectionClick();
                if (item.bundled || _installed.contains(item.id)) {
                  settings.setSelectedQuranSource(item.id);
                  return;
                }
                if (item.downloadable) {
                  _downloadAndSelect(item);
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.text('translationUnavailableYet')),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              l10n.moreTranslationsSoon,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _OriginalArabicTile extends StatelessWidget {
  const _OriginalArabicTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _LanguageBadge(code: 'AR', selected: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.arabicOriginal,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.arabicOriginalDescription,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.download_done_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TranslationTile extends StatelessWidget {
  const _TranslationTile({
    required this.info,
    required this.languageName,
    required this.selected,
    required this.installed,
    required this.progress,
    required this.onTap,
    required this.onDelete,
  });

  final TranslationInfo info;
  final String languageName;
  final bool selected;
  final bool installed;
  final double? progress;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final status = progress != null
        ? '${l10n.text('downloading')} ${(progress! * 100).round()}%'
        : installed
            ? l10n.installed
            : info.downloadable
                ? l10n.text('downloadReady')
                : l10n.text('translationUnavailableYet');

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: progress == null ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _LanguageBadge(
                code: info.languageCode.toUpperCase(),
                selected: selected,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            languageName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          info.code,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      info.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${info.source} · v${info.version} · $status',
                      textDirection: TextDirection.ltr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (progress != null)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(value: progress),
                )
              else if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: l10n.text('deleteDownload'),
                )
              else
                Icon(
                  installed
                      ? Icons.download_done_rounded
                      : info.downloadable
                          ? Icons.cloud_download_outlined
                          : Icons.schedule_rounded,
                  color: installed ? scheme.primary : scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({required this.code, required this.selected});

  final String code;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        code,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          color: selected ? scheme.onPrimary : scheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
