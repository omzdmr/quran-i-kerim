import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/translation_catalog.dart';
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
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _languageName(String code) => switch (code) {
        'tr' => 'Türkçe',
        'en' => 'English',
        'az' => 'Azərbaycanca',
        'ru' => 'Русский',
        _ => code.toUpperCase(),
      };

  bool _matches(TranslationInfo item) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return item.name.toLowerCase().contains(query) ||
        item.publisher.toLowerCase().contains(query) ||
        item.code.toLowerCase().contains(query) ||
        _languageName(item.languageCode).toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final settings = AppSettingsScope.of(context);
    final items = translationCatalog.where(_matches).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quranLanguage)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: l10n.language,
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
            selected: settings.readerMode == ReaderDisplayMode.arabic,
            onTap: () {
              HapticFeedback.selectionClick();
              settings.setReaderMode(ReaderDisplayMode.arabic);
            },
          ),
          for (final item in items) ...[
            const SizedBox(height: 10),
            _TranslationTile(
              info: item,
              languageName: _languageName(item.languageCode),
              selected: item.bundled &&
                  settings.readerMode != ReaderDisplayMode.arabic,
              onTap: () {
                HapticFeedback.selectionClick();
                if (item.bundled) {
                  settings.setReaderMode(ReaderDisplayMode.translation);
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.moreTranslationsSoon)),
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
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
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
    required this.onTap,
  });

  final TranslationInfo info;
  final String languageName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                      '${info.source} · v${info.version}',
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
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
              Icon(
                info.bundled
                    ? Icons.download_done_rounded
                    : Icons.cloud_download_outlined,
                color: info.bundled ? scheme.primary : scheme.onSurfaceVariant,
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
