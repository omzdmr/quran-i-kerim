import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/surah_localization.dart';
import '../../data/translation_catalog.dart';
import '../../navigation/app_navigation.dart';
import '../../settings/app_settings.dart';
import 'reader_archive_context.dart';

class ReaderArchiveScreen extends StatelessWidget {
  const ReaderArchiveScreen({super.key});

  String _text(String languageCode, String key) {
    const values = <String, Map<String, String>>{
      'tr': {
        'title': 'Kaydedilenler',
        'empty': 'Henüz kaydedilmiş ayet, not veya vurgu yok.',
        'bookmark': 'Kaydedilen ayet',
        'highlight': 'Vurgulanan ayet',
        'note': 'Not',
        'source': 'Görüntüleme kaynağı',
      },
      'en': {
        'title': 'Saved activity',
        'empty': 'No saved verses, notes or highlights yet.',
        'bookmark': 'Saved verse',
        'highlight': 'Highlighted verse',
        'note': 'Note',
        'source': 'Display source',
      },
      'fr': {
        'title': 'Éléments enregistrés',
        'empty': 'Aucun verset, note ou surlignage enregistré.',
        'bookmark': 'Verset enregistré',
        'highlight': 'Verset surligné',
        'note': 'Note',
        'source': 'Source d’affichage',
      },
      'ar': {
        'title': 'المحفوظات',
        'empty': 'لا توجد آيات أو ملاحظات أو تمييزات محفوظة بعد.',
        'bookmark': 'آية محفوظة',
        'highlight': 'آية مميزة',
        'note': 'ملاحظة',
        'source': 'مصدر العرض',
      },
      'az': {
        'title': 'Yadda saxlanılanlar',
        'empty': 'Hələ yadda saxlanmış ayə, qeyd və ya vurğu yoxdur.',
        'bookmark': 'Yadda saxlanmış ayə',
        'highlight': 'Vurğulanmış ayə',
        'note': 'Qeyd',
        'source': 'Göstərmə mənbəyi',
      },
      'ru': {
        'title': 'Сохранённое',
        'empty': 'Пока нет сохранённых аятов, заметок или выделений.',
        'bookmark': 'Сохранённый аят',
        'highlight': 'Выделенный аят',
        'note': 'Заметка',
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
          sourceCode: settings.noteSourceForKey(entry.key),
        ),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

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
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _ArchiveTile(
                item: items[index],
                languageCode: languageCode,
                label: _text(languageCode, items[index].kind),
                sourceLabel: _text(languageCode, 'source'),
                fallbackSourceId: settings.selectedQuranSourceId,
              ),
            ),
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
    required this.fallbackSourceId,
  });

  final _ArchiveItem item;
  final String languageCode;
  final String label;
  final String sourceLabel;
  final String fallbackSourceId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final target = parseReaderArchiveContext(
      selectionKey: item.selectionKey,
      sourceCode: item.sourceCode,
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
