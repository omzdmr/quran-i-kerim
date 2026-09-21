import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/surah_localization.dart';
import '../../data/translation_catalog.dart';
import '../../navigation/app_navigation.dart';
import '../../settings/app_settings.dart';
import 'reader_archive_context.dart';
import 'reader_archive_search.dart';
import 'reader_reading_history.dart';

class ReaderArchiveScreen extends StatefulWidget {
  const ReaderArchiveScreen({super.key});

  @override
  State<ReaderArchiveScreen> createState() => _ReaderArchiveScreenState();
}

class _ReaderArchiveScreenState extends State<ReaderArchiveScreen> {
  String _filter = 'all';
  String _query = '';
  late Future<List<ReaderHistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ReaderReadingHistoryRepository.instance.load();
  }

  String _text(String languageCode, String key) {
    const values = <String, Map<String, String>>{
      'tr': {
        'title': 'Kaydedilenler',
        'empty': 'Henüz kaydedilmiş ayet, not veya vurgu yok.',
        'emptyFilter': 'Bu filtrede henüz bir kayıt yok.',
        'noResults': 'Aramana uyan bir kayıt bulunamadı.',
        'search': 'Sure, ayet veya notlarda ara',
        'all': 'Tümü',
        'bookmark': 'Kaydedilen ayet',
        'bookmarks': 'Kayıtlar',
        'highlight': 'Vurgulanan ayet',
        'highlights': 'Vurgular',
        'note': 'Not',
        'notes': 'Notlar',
        'source': 'Görüntüleme kaynağı',
      },
      'en': {
        'title': 'Saved activity',
        'empty': 'No saved verses, notes or highlights yet.',
        'emptyFilter': 'Nothing saved in this filter yet.',
        'noResults': 'No saved item matches your search.',
        'search': 'Search surah, verse or notes',
        'all': 'All',
        'bookmark': 'Saved verse',
        'bookmarks': 'Saved',
        'highlight': 'Highlighted verse',
        'highlights': 'Highlights',
        'note': 'Note',
        'notes': 'Notes',
        'source': 'Display source',
      },
      'fr': {
        'title': 'Éléments enregistrés',
        'empty': 'Aucun verset, note ou surlignage enregistré.',
        'emptyFilter': 'Aucun élément dans ce filtre.',
        'noResults': 'Aucun élément ne correspond à votre recherche.',
        'search': 'Rechercher une sourate, un verset ou une note',
        'all': 'Tout',
        'bookmark': 'Verset enregistré',
        'bookmarks': 'Enregistrés',
        'highlight': 'Verset surligné',
        'highlights': 'Surlignages',
        'note': 'Note',
        'notes': 'Notes',
        'source': 'Source d’affichage',
      },
      'ar': {
        'title': 'المحفوظات',
        'empty': 'لا توجد آيات أو ملاحظات أو تمييزات محفوظة بعد.',
        'emptyFilter': 'لا توجد عناصر محفوظة في هذا التصنيف.',
        'noResults': 'لا توجد عناصر محفوظة تطابق البحث.',
        'search': 'ابحث في السورة أو الآية أو الملاحظات',
        'all': 'الكل',
        'bookmark': 'آية محفوظة',
        'bookmarks': 'المحفوظات',
        'highlight': 'آية مميزة',
        'highlights': 'التمييزات',
        'note': 'ملاحظة',
        'notes': 'الملاحظات',
        'source': 'مصدر العرض',
      },
      'az': {
        'title': 'Yadda saxlanılanlar',
        'empty': 'Hələ yadda saxlanmış ayə, qeyd və ya vurğu yoxdur.',
        'emptyFilter': 'Bu filtrdə hələ heç nə yoxdur.',
        'noResults': 'Axtarışa uyğun yadda saxlanmış nəticə yoxdur.',
        'search': 'Surə, ayə və ya qeydlərdə axtar',
        'all': 'Hamısı',
        'bookmark': 'Yadda saxlanmış ayə',
        'bookmarks': 'Yadda saxlanılanlar',
        'highlight': 'Vurğulanmış ayə',
        'highlights': 'Vurğular',
        'note': 'Qeyd',
        'notes': 'Qeydlər',
        'source': 'Göstərmə mənbəyi',
      },
      'ru': {
        'title': 'Сохранённое',
        'empty': 'Пока нет сохранённых аятов, заметок или выделений.',
        'emptyFilter': 'В этом фильтре пока ничего нет.',
        'noResults': 'По вашему запросу ничего не найдено.',
        'search': 'Поиск по суре, аяту или заметкам',
        'all': 'Все',
        'bookmark': 'Сохранённый аят',
        'bookmarks': 'Сохранённые',
        'highlight': 'Выделенный аят',
        'highlights': 'Выделения',
        'note': 'Заметка',
        'notes': 'Заметки',
        'source': 'Источник отображения',
      },
    };
    return values[languageCode]?[key] ?? values['en']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final items = <_ArchiveItem>[
      for (final key in settings.bookmarkKeys)
        _ArchiveItem(
          kind: 'bookmark',
          selectionKey: key,
          timestamp: settings.archiveTimestamp('bookmark', key),
        ),
      for (final key in settings.highlightEntries.keys)
        _ArchiveItem(
          kind: 'highlight',
          selectionKey: key,
          timestamp: settings.archiveTimestamp('highlight', key),
        ),
      for (final entry in settings.noteEntries.entries)
        _ArchiveItem(
          kind: 'note',
          selectionKey: entry.key,
          timestamp: settings.archiveTimestamp('note', entry.key),
          note: entry.value,
          sourceCode: settings.noteSourceEntries[entry.key],
        ),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final kindFiltered = _filter == 'all'
        ? items
        : items.where((item) => item.kind == _filter).toList(growable: false);
    final visible = kindFiltered
        .where(
          (item) => readerArchiveMatchesQuery(
            query: _query,
            selectionKey: item.selectionKey,
            languageCode: languageCode,
            note: item.note,
            sourceCode: item.sourceCode,
          ),
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(_text(languageCode, 'title'))),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _text(languageCode, 'empty'),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: TextField(
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: _text(languageCode, 'search'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .deleteButtonTooltip,
                              onPressed: () => setState(() => _query = ''),
                              icon: const Icon(Icons.close_rounded),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      _filterChip(languageCode, 'all', 'all', items.length),
                      const SizedBox(width: 8),
                      _filterChip(
                        languageCode,
                        'bookmark',
                        'bookmarks',
                        items.where((item) => item.kind == 'bookmark').length,
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        languageCode,
                        'note',
                        'notes',
                        items.where((item) => item.kind == 'note').length,
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        languageCode,
                        'highlight',
                        'highlights',
                        items.where((item) => item.kind == 'highlight').length,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Text(
                            _query.trim().isEmpty
                                ? _text(languageCode, 'emptyFilter')
                                : _text(languageCode, 'noResults'),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : FutureBuilder<List<ReaderHistoryEntry>>(
                          future: _historyFuture,
                          initialData: const <ReaderHistoryEntry>[],
                          builder: (context, historySnapshot) {
                            final history = historySnapshot.data ??
                                const <ReaderHistoryEntry>[];
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                              itemCount: visible.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = visible[index];
                                return _ArchiveTile(
                                  item: item,
                                  languageCode: languageCode,
                                  label: _text(languageCode, item.kind),
                                  sourceLabel: _text(languageCode, 'source'),
                                  historySourceId: recentReaderSourceForArchive(
                                    item.selectionKey,
                                    history,
                                  ),
                                  fallbackSourceId:
                                      settings.selectedQuranSourceId,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(
    String languageCode,
    String value,
    String labelKey,
    int count,
  ) {
    return FilterChip(
      selected: _filter == value,
      label: Text('${_text(languageCode, labelKey)} ($count)'),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _filter = value);
      },
    );
  }
}

class _ArchiveItem {
  const _ArchiveItem({
    required this.kind,
    required this.selectionKey,
    required this.timestamp,
    this.note,
    this.sourceCode,
  });

  final String kind;
  final String selectionKey;
  final int timestamp;
  final String? note;
  final String? sourceCode;
}

class _ArchiveTile extends StatelessWidget {
  const _ArchiveTile({
    required this.item,
    required this.languageCode,
    required this.label,
    required this.sourceLabel,
    required this.historySourceId,
    required this.fallbackSourceId,
  });

  final _ArchiveItem item;
  final String languageCode;
  final String label;
  final String sourceLabel;
  final String? historySourceId;
  final String fallbackSourceId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final target = parseReaderArchiveContext(
      selectionKey: item.selectionKey,
      sourceCode: item.sourceCode,
      historySourceId: historySourceId,
      fallbackSourceId: fallbackSourceId,
    );
    final source = target == null ? null : translationById(target.sourceId);
    final sourceCode = target?.sourceId == arabicOriginalSourceId
        ? 'AR'
        : source?.code;
    final reference = target == null
        ? item.selectionKey
        : '${localizedSurahName(target.surah, languageCode)} ${item.selectionKey}';
    final icon = switch (item.kind) {
      'note' => Icons.sticky_note_2_outlined,
      'highlight' => Icons.format_color_fill_rounded,
      _ => Icons.bookmark_added_outlined,
    };

    return Semantics(
      button: target != null,
      label: '$label, $reference${sourceCode == null ? '' : ', $sourceLabel $sourceCode'}',
      child: Material(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: target == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                  AppNavigation.instance.openReader(
                    surah: target.surah,
                    ayah: target.ayah,
                    sourceId: target.sourceId,
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(reference, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
                      if (sourceCode != null) ...[
                        const SizedBox(height: 3),
                        Text('$sourceLabel: $sourceCode', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      ],
                      if (item.note?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(item.note!, maxLines: 3, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                if (target != null) const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
