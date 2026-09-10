import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/quran_audio_catalog.dart';
import '../../data/translation_catalog.dart';
import '../../data/translation_repository.dart';
import '../../settings/app_settings.dart';

class QuranTranslationCatalogScreen extends StatefulWidget {
  const QuranTranslationCatalogScreen({super.key});

  @override
  State<QuranTranslationCatalogScreen> createState() =>
      _QuranTranslationCatalogScreenState();
}

class _QuranTranslationCatalogScreenState
    extends State<QuranTranslationCatalogScreen> {
  final Set<String> _installed = <String>{};
  bool _loadingInstalled = true;

  @override
  void initState() {
    super.initState();
    _refreshInstalled();
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

  Future<void> _selectAndClose(String sourceId) async {
    final settings = AppSettingsScope.of(context);
    await settings.setSelectedQuranSource(sourceId);
    if (!mounted) return;
    HapticFeedback.selectionClick();
    Navigator.pop(context, sourceId);
  }

  Future<void> _openDiscovery() async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const _TranslationDiscoveryScreen(),
      ),
    );
    if (!mounted) return;
    await _refreshInstalled();
    if (picked != null && mounted) {
      await _selectAndClose(picked);
    }
  }

  Future<void> _deleteDownloaded(TranslationInfo info) async {
    final copy = _TranslationUiCopy.of(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(copy.deleteTitle),
        content: Text(copy.deleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(copy.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(copy.delete),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await TranslationRepository.instance.deleteInstalledTranslation(info.id);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    await _refreshInstalled();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _TranslationUiCopy.of(context);
    final scheme = Theme.of(context).colorScheme;
    final settings = AppSettingsScope.of(context);
    final selectedId = settings.selectedQuranSourceId;
    final selectedInfo = translationById(selectedId);

    final installedSources = <_InstalledSource>[];
    if (selectedId != arabicOriginalSourceId) {
      installedSources.add(
        _InstalledSource.arabic(
          title: copy.arabicOriginal,
          subtitle: 'Tanzil.net · ${copy.offline}',
        ),
      );
    }
    for (final info in translationCatalog) {
      if (!_installed.contains(info.id) || info.id == selectedId) continue;
      installedSources.add(_InstalledSource.translation(info));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(copy.managerTitle),
        actions: [
          IconButton(
            onPressed: _openDiscovery,
            icon: const Icon(Icons.search_rounded),
            tooltip: copy.searchTranslations,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          _CurrentSourceCard(
            code: selectedId == arabicOriginalSourceId
                ? 'AR'
                : selectedInfo?.code ?? '—',
            title: selectedId == arabicOriginalSourceId
                ? copy.arabicOriginal
                : selectedInfo?.name ?? selectedId,
            subtitle: selectedId == arabicOriginalSourceId
                ? 'Tanzil.net · ${copy.offline}'
                : '${selectedInfo?.publisher ?? ''} · ${selectedInfo?.source ?? ''}',
            hasAudio: hasQuranAudioForSource(selectedId),
            currentLabel: copy.current,
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: Text(
                  copy.myTranslations,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: _openDiscovery,
                icon: const Icon(Icons.add_rounded),
                tooltip: copy.moreTranslations,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingInstalled)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: LinearProgressIndicator(),
            )
          else if (installedSources.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                copy.onlyCurrentInstalled,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            for (final source in installedSources)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InstalledSourceRow(
                  source: source,
                  onTap: () => _selectAndClose(source.sourceId),
                  onDelete:
                      source.info != null &&
                          !source.info!.bundled &&
                          _installed.contains(source.info!.id)
                      ? () => _deleteDownloaded(source.info!)
                      : null,
                ),
              ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _openDiscovery,
              icon: const Icon(Icons.add_rounded),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(copy.moreTranslations),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            copy.managerHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TranslationDiscoveryScreen extends StatefulWidget {
  const _TranslationDiscoveryScreen();

  @override
  State<_TranslationDiscoveryScreen> createState() =>
      _TranslationDiscoveryScreenState();
}

class _TranslationDiscoveryScreenState
    extends State<_TranslationDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _installed = <String>{};
  final Map<String, double> _progress = <String, double>{};
  _TranslationFilter _filter = _TranslationFilter.recommended;
  String _query = '';
  bool _loadingInstalled = true;

  @override
  void initState() {
    super.initState();
    _refreshInstalled();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCatalog());
  }

  @override
  void dispose() {
    for (final sourceId in _progress.keys.toList(growable: false)) {
      unawaited(
        TranslationRepository.instance.cancelTranslationDownload(sourceId),
      );
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshCatalog() async {
    final language = Localizations.localeOf(context).languageCode;
    await TranslationRepository.instance.refreshCatalogIfStale(
      localization: language,
    );
    if (!mounted) return;
    await _refreshInstalled();
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

  String _normalize(String value) =>
      value.trim().replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

  bool _matches(BuildContext context, TranslationInfo item) {
    final query = _normalize(_query);
    if (query.isEmpty) return true;
    final copy = _TranslationUiCopy.of(context);
    final haystack = <String>[
      item.name,
      item.publisher,
      item.code,
      item.languageCode,
      item.source,
      copy.languageName(item.languageCode),
      copy.nativeLanguageName(item.languageCode),
    ].map(_normalize).join(' ');
    return haystack.contains(query);
  }

  TranslationInfo _audioDiscoveryItem(
    BuildContext context,
    QuranAudioInfo audio,
  ) {
    final linked = translationById(audio.sourceId);
    if (linked != null) return linked;
    final copy = _TranslationUiCopy.of(context);
    return TranslationInfo(
      id: audio.sourceId,
      code: audio.code,
      languageCode: audio.languageCode,
      name: audio.sourceId == arabicOriginalSourceId
          ? copy.arabicOriginal
          : audio.title,
      publisher: audio.title,
      source: audio.attribution,
      sourceKey: audio.id,
      version: 'audio',
      bundled: true,
      available: true,
      downloadable: false,
      hasAudio: true,
    );
  }

  List<TranslationInfo> _visibleItems(BuildContext context) {
    final uiLanguage = Localizations.localeOf(context).languageCode;
    final all = translationCatalog
        .where((item) => item.available && _matches(context, item))
        .toList(growable: false);

    Iterable<TranslationInfo> filtered;
    switch (_filter) {
      case _TranslationFilter.recommended:
        final sameLanguage = all
            .where((item) => item.languageCode == uiLanguage)
            .toList(growable: false);
        filtered = sameLanguage.isEmpty ? all : sameLanguage;
        break;
      case _TranslationFilter.all:
        filtered = all;
        break;
      case _TranslationFilter.audio:
        final seenSources = <String>{};
        filtered = quranAudioCatalog
            .where((audio) => seenSources.add(audio.sourceId))
            .map((audio) => _audioDiscoveryItem(context, audio))
            .where((item) => _matches(context, item));
        break;
    }

    final copy = _TranslationUiCopy.of(context);
    final result = filtered.toList(growable: false)
      ..sort((a, b) {
        if (a.languageCode == uiLanguage && b.languageCode != uiLanguage) {
          return -1;
        }
        if (b.languageCode == uiLanguage && a.languageCode != uiLanguage) {
          return 1;
        }
        final languageCompare = copy
            .languageName(a.languageCode)
            .compareTo(copy.languageName(b.languageCode));
        if (languageCompare != 0) return languageCompare;
        return a.name.compareTo(b.name);
      });
    return result;
  }

  Future<void> _cancelDownload(TranslationInfo info) async {
    HapticFeedback.selectionClick();
    await TranslationRepository.instance.cancelTranslationDownload(info.id);
    if (!mounted) return;
    setState(() => _progress.remove(info.id));
  }

  Future<void> _pick(TranslationInfo info) async {
    final copy = _TranslationUiCopy.of(context);
    if (_installed.contains(info.id) || info.bundled) {
      HapticFeedback.selectionClick();
      Navigator.pop(context, info.id);
      return;
    }
    if (!info.downloadable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.notReady)));
      return;
    }

    setState(() => _progress[info.id] = 0.0);
    try {
      await TranslationRepository.instance.downloadTranslation(
        info,
        onProgress: (value) {
          if (!mounted) return;
          setState(() => _progress[info.id] = value.clamp(0.0, 1.0).toDouble());
        },
      );
      if (!mounted) return;
      setState(() {
        _progress.remove(info.id);
        _installed.add(info.id);
      });
      HapticFeedback.lightImpact();
      Navigator.pop(context, info.id);
    } on TranslationDownloadCancelledException {
      if (!mounted) return;
      setState(() => _progress.remove(info.id));
    } catch (_) {
      if (!mounted) return;
      setState(() => _progress.remove(info.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.downloadFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = _TranslationUiCopy.of(context);
    final scheme = Theme.of(context).colorScheme;
    final items = _visibleItems(context);
    final grouped = <String, List<TranslationInfo>>{};
    for (final item in items) {
      grouped
          .putIfAbsent(item.languageCode, () => <TranslationInfo>[])
          .add(item);
    }

    return Scaffold(
      appBar: AppBar(title: Text(copy.moreTranslations)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: copy.searchHint,
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
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                _FilterChip(
                  label: copy.recommended,
                  selected: _filter == _TranslationFilter.recommended,
                  onTap: () =>
                      setState(() => _filter = _TranslationFilter.recommended),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: copy.all,
                  selected: _filter == _TranslationFilter.all,
                  onTap: () => setState(() => _filter = _TranslationFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  icon: Icons.volume_up_outlined,
                  label: copy.audioAvailable,
                  selected: _filter == _TranslationFilter.audio,
                  onTap: () =>
                      setState(() => _filter = _TranslationFilter.audio),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (_loadingInstalled)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Text(
                        _filter == _TranslationFilter.audio
                            ? copy.noAudio
                            : copy.noResults,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
                    children: [
                      for (final entry in grouped.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 14, 4, 9),
                          child: Row(
                            children: [
                              const Icon(Icons.language_rounded, size: 22),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  copy.languageName(entry.key),
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('${entry.value.length}'),
                              ),
                            ],
                          ),
                        ),
                        for (final item in entry.value)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _DiscoveryTranslationRow(
                              info: item,
                              installed:
                                  item.bundled || _installed.contains(item.id),
                              progress: _progress[item.id],
                              onTap: () => _pick(item),
                              onCancel: _progress.containsKey(item.id)
                                  ? () => _cancelDownload(item)
                                  : null,
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

enum _TranslationFilter { recommended, all, audio }

class _CurrentSourceCard extends StatelessWidget {
  const _CurrentSourceCard({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.hasAudio,
    required this.currentLabel,
  });

  final String code;
  final String title;
  final String subtitle;
  final bool hasAudio;
  final String currentLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          _SourceBadge(code: code, selected: true),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentLabel,
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (hasAudio) ...[
            const SizedBox(width: 8),
            const Icon(Icons.volume_up_outlined),
          ],
          const SizedBox(width: 8),
          Icon(Icons.check_circle_rounded, color: scheme.primary),
        ],
      ),
    );
  }
}

class _InstalledSource {
  const _InstalledSource({
    required this.sourceId,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.hasAudio,
    this.info,
  });

  factory _InstalledSource.arabic({
    required String title,
    required String subtitle,
  }) => _InstalledSource(
    sourceId: arabicOriginalSourceId,
    code: 'AR',
    title: title,
    subtitle: subtitle,
    hasAudio: hasQuranAudioForSource(arabicOriginalSourceId),
  );

  factory _InstalledSource.translation(TranslationInfo info) =>
      _InstalledSource(
        sourceId: info.id,
        code: info.code,
        title: info.name,
        subtitle: '${info.publisher} · ${info.source}',
        hasAudio: hasQuranAudioForSource(info.id),
        info: info,
      );

  final String sourceId;
  final String code;
  final String title;
  final String subtitle;
  final bool hasAudio;
  final TranslationInfo? info;
}

class _InstalledSourceRow extends StatelessWidget {
  const _InstalledSourceRow({
    required this.source,
    required this.onTap,
    required this.onDelete,
  });

  final _InstalledSource source;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final copy = _TranslationUiCopy.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              _SourceBadge(code: source.code),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      source.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (source.hasAudio)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.volume_up_outlined, size: 21),
                ),
              if (onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') onDelete!();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded),
                          const SizedBox(width: 10),
                          Text(copy.delete),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Icon(Icons.cloud_done_outlined, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoveryTranslationRow extends StatelessWidget {
  const _DiscoveryTranslationRow({
    required this.info,
    required this.installed,
    required this.progress,
    required this.onTap,
    required this.onCancel,
  });

  final TranslationInfo info;
  final bool installed;
  final double? progress;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final copy = _TranslationUiCopy.of(context);
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: progress == null ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _SourceBadge(code: info.code),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      info.publisher,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${info.source} · v${info.version}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (info.hasAudio)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.volume_up_outlined, size: 21),
                ),
              if (progress != null)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: onCancel,
                    tooltip: copy.cancel,
                    icon: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(value: progress),
                        ),
                        const Icon(Icons.close_rounded, size: 17),
                      ],
                    ),
                  ),
                )
              else if (installed)
                Icon(Icons.cloud_done_outlined, color: scheme.primary)
              else if (info.downloadable)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_download_outlined),
                    const SizedBox(height: 2),
                    Text(
                      copy.download,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              else
                Icon(Icons.schedule_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.code, this.selected = false});

  final String code;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 66,
      height: 58,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: selected ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        code,
        maxLines: 2,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          color: selected ? scheme.onPrimary : scheme.onSurface,
          fontSize: code.length > 7 ? 11 : 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.onSurface : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: selected ? scheme.surface : scheme.onSurface,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? scheme.surface : scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TranslationUiCopy {
  const _TranslationUiCopy(this.languageCode);

  factory _TranslationUiCopy.of(BuildContext context) =>
      _TranslationUiCopy(Localizations.localeOf(context).languageCode);

  final String languageCode;

  String get managerTitle => _pick(
    tr: 'Kuran Çevirileri',
    en: 'Quran Translations',
    ar: 'ترجمات القرآن',
    az: 'Quran tərcümələri',
    ru: 'Переводы Корана',
  );
  String get current => _pick(
    tr: 'Şu an okunan',
    en: 'Currently reading',
    ar: 'الترجمة الحالية',
    az: 'Hazırda oxunan',
    ru: 'Текущий перевод',
  );
  String get myTranslations => _pick(
    tr: 'Benim Çevirilerim',
    en: 'My Translations',
    ar: 'ترجماتي',
    az: 'Mənim tərcümələrim',
    ru: 'Мои переводы',
  );
  String get moreTranslations => _pick(
    tr: 'Daha Fazla Çeviri',
    en: 'More Translations',
    ar: 'المزيد من الترجمات',
    az: 'Daha çox tərcümə',
    ru: 'Больше переводов',
  );
  String get searchTranslations => _pick(
    tr: 'Çeviri ara',
    en: 'Search translations',
    ar: 'البحث في الترجمات',
    az: 'Tərcümə axtar',
    ru: 'Поиск переводов',
  );
  String get searchHint => _pick(
    tr: 'Dil, meal, kod veya yayıncı ara',
    en: 'Search language, translation, code or publisher',
    ar: 'ابحث باللغة أو الترجمة أو الرمز أو الناشر',
    az: 'Dil, tərcümə, kod və ya nəşriyyat axtar',
    ru: 'Язык, перевод, код или издатель',
  );
  String get recommended => _pick(
    tr: 'Önerilen',
    en: 'Recommended',
    ar: 'مقترح',
    az: 'Tövsiyə edilən',
    ru: 'Рекомендуемые',
  );
  String get all =>
      _pick(tr: 'Tümü', en: 'All', ar: 'الكل', az: 'Hamısı', ru: 'Все');
  String get audioAvailable => _pick(
    tr: 'Ses Mevcut',
    en: 'Audio Available',
    ar: 'الصوت متاح',
    az: 'Səs mövcuddur',
    ru: 'Есть аудио',
  );
  String get offline => _pick(
    tr: 'çevrimdışı',
    en: 'offline',
    ar: 'دون اتصال',
    az: 'oflayn',
    ru: 'офлайн',
  );
  String get arabicOriginal => _pick(
    tr: 'Arapça Orijinal',
    en: 'Arabic Original',
    ar: 'النص العربي الأصلي',
    az: 'Ərəbcə orijinal',
    ru: 'Арабский оригинал',
  );
  String get onlyCurrentInstalled => _pick(
    tr: 'Şimdilik yalnızca mevcut okuma kaynağı yüklü.',
    en: 'Only the current reading source is installed for now.',
    ar: 'مصدر القراءة الحالي هو الوحيد المثبت حالياً.',
    az: 'Hələlik yalnız hazırkı oxu mənbəyi quraşdırılıb.',
    ru: 'Пока установлен только текущий источник чтения.',
  );
  String get managerHint => _pick(
    tr: 'İndirilen mealler cihazda kalır. Arapça tilavet, çeviri sesi olarak gösterilmez.',
    en: 'Downloaded translations stay on the device. Arabic recitation is not shown as translation audio.',
    ar: 'تبقى الترجمات المنزلة على الجهاز. لا تُعرض التلاوة العربية كصوت للترجمة.',
    az: 'Endirilən tərcümələr cihazda qalır. Ərəbcə tilavət tərcümə səsi kimi göstərilmir.',
    ru: 'Скачанные переводы остаются на устройстве. Арабское чтение не помечается как аудио перевода.',
  );
  String get download => _pick(
    tr: 'İndir',
    en: 'Download',
    ar: 'تنزيل',
    az: 'Endir',
    ru: 'Скачать',
  );
  String get downloadFailed => _pick(
    tr: 'Çeviri indirilemedi',
    en: 'Could not download translation',
    ar: 'تعذر تنزيل الترجمة',
    az: 'Tərcüməni endirmək mümkün olmadı',
    ru: 'Не удалось скачать перевод',
  );
  String get notReady => _pick(
    tr: 'Bu çeviri için doğrulanmış indirme paketi henüz hazır değil.',
    en: 'A verified download package is not ready for this translation yet.',
    ar: 'حزمة تنزيل موثقة لهذه الترجمة غير جاهزة بعد.',
    az: 'Bu tərcümə üçün təsdiqlənmiş endirmə paketi hələ hazır deyil.',
    ru: 'Проверенный пакет для этого перевода пока не готов.',
  );
  String get noResults => _pick(
    tr: 'Aramanıza uygun çeviri bulunamadı.',
    en: 'No translations match your search.',
    ar: 'لم يتم العثور على ترجمة مطابقة.',
    az: 'Axtarışınıza uyğun tərcümə tapılmadı.',
    ru: 'Подходящих переводов не найдено.',
  );
  String get noAudio => _pick(
    tr: 'Şu an katalogdaki doğrulanmış çeviriler arasında sesli meal bulunmuyor.',
    en: 'None of the currently verified translations has spoken-translation audio.',
    ar: 'لا توجد حالياً ترجمة صوتية ضمن الترجمات الموثقة في الفهرس.',
    az: 'Hazırda təsdiqlənmiş tərcümələr arasında səsli tərcümə yoxdur.',
    ru: 'Среди проверенных переводов пока нет озвученного перевода.',
  );
  String get delete =>
      _pick(tr: 'Sil', en: 'Delete', ar: 'حذف', az: 'Sil', ru: 'Удалить');
  String get deleteTitle => _pick(
    tr: 'İndirilen çeviri silinsin mi?',
    en: 'Delete downloaded translation?',
    ar: 'حذف الترجمة المنزلة؟',
    az: 'Endirilmiş tərcümə silinsin?',
    ru: 'Удалить скачанный перевод?',
  );
  String get deleteBody => _pick(
    tr: 'Çeviri cihazdan kaldırılır; daha sonra yeniden indirebilirsiniz.',
    en: 'The translation will be removed from this device and can be downloaded again later.',
    ar: 'ستُحذف الترجمة من الجهاز ويمكن تنزيلها مرة أخرى لاحقاً.',
    az: 'Tərcümə cihazdan silinəcək və sonra yenidən endirilə bilər.',
    ru: 'Перевод будет удалён с устройства, его можно скачать снова позже.',
  );
  String get cancel => _pick(
    tr: 'Vazgeç',
    en: 'Cancel',
    ar: 'إلغاء',
    az: 'Ləğv et',
    ru: 'Отмена',
  );

  String languageName(String code) => switch (code) {
    'tr' => _pick(
      tr: 'Türkçe',
      en: 'Turkish',
      ar: 'التركية',
      az: 'Türkcə',
      ru: 'Турецкий',
    ),
    'en' => _pick(
      tr: 'İngilizce',
      en: 'English',
      ar: 'الإنجليزية',
      az: 'İngiliscə',
      ru: 'Английский',
    ),
    'az' => _pick(
      tr: 'Azerbaycanca',
      en: 'Azerbaijani',
      ar: 'الأذربيجانية',
      az: 'Azərbaycanca',
      ru: 'Азербайджанский',
    ),
    'ru' => _pick(
      tr: 'Rusça',
      en: 'Russian',
      ar: 'الروسية',
      az: 'Rusca',
      ru: 'Русский',
    ),
    'ar' => _pick(
      tr: 'Arapça',
      en: 'Arabic',
      ar: 'العربية',
      az: 'Ərəbcə',
      ru: 'Арабский',
    ),
    'fr' => _pick(
      tr: 'Fransızca',
      en: 'French',
      ar: 'الفرنسية',
      az: 'Fransızca',
      ru: 'Французский',
    ),
    'pt' => _pick(
      tr: 'Portekizce',
      en: 'Portuguese',
      ar: 'البرتغالية',
      az: 'Portuqalca',
      ru: 'Португальский',
    ),
    'nl' => _pick(
      tr: 'Felemenkçe',
      en: 'Dutch',
      ar: 'الهولندية',
      az: 'Niderlandca',
      ru: 'Нидерландский',
    ),
    'tl' => _pick(
      tr: 'Tagalogca',
      en: 'Tagalog',
      ar: 'التاغالوغية',
      az: 'Taqaloqca',
      ru: 'Тагальский',
    ),
    'zh' => _pick(
      tr: 'Çince',
      en: 'Chinese',
      ar: 'الصينية',
      az: 'Çincə',
      ru: 'Китайский',
    ),
    'vi' => _pick(
      tr: 'Vietnamca',
      en: 'Vietnamese',
      ar: 'الفيتنامية',
      az: 'Vyetnamca',
      ru: 'Вьетнамский',
    ),
    'fa' => _pick(
      tr: 'Farsça',
      en: 'Persian',
      ar: 'الفارسية',
      az: 'Farsca',
      ru: 'Персидский',
    ),
    'as' => _pick(
      tr: 'Assamca',
      en: 'Assamese',
      ar: 'الأسامية',
      az: 'Assamca',
      ru: 'Ассамский',
    ),
    'si' => _pick(
      tr: 'Sinhala',
      en: 'Sinhala',
      ar: 'السنهالية',
      az: 'Sinhala',
      ru: 'Сингальский',
    ),
    'so' => _pick(
      tr: 'Somalice',
      en: 'Somali',
      ar: 'الصومالية',
      az: 'Somalicə',
      ru: 'Сомалийский',
    ),
    _ => code.toUpperCase(),
  };

  String nativeLanguageName(String code) => switch (code) {
    'tr' => 'Türkçe',
    'en' => 'English',
    'az' => 'Azərbaycanca',
    'ru' => 'Русский',
    'ar' => 'العربية',
    'fr' => 'Français',
    'pt' => 'Português',
    'nl' => 'Nederlands',
    'tl' => 'Tagalog',
    'zh' => '中文',
    'vi' => 'Tiếng Việt',
    'fa' => 'فارسی',
    'as' => 'অসমীয়া',
    'si' => 'සිංහල',
    'so' => 'Soomaali',
    _ => code.toUpperCase(),
  };

  String _pick({
    required String tr,
    required String en,
    required String ar,
    required String az,
    required String ru,
  }) => switch (languageCode) {
    'tr' => tr,
    'ar' => ar,
    'az' => az,
    'ru' => ru,
    _ => en,
  };
}
