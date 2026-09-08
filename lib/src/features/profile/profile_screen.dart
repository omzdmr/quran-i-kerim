import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../data/surah_catalog.dart';
import '../../data/translation_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/app_settings.dart';
import '../reader/passage_preview_screen.dart';
import '../settings/settings_screen.dart';
import 'downloads_screen.dart';

enum _ArchiveFilter { all, highlights, bookmarks, notes }

enum _ArchiveKind { highlight, bookmark, note }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  _ArchiveFilter _filter = _ArchiveFilter.all;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final settings = AppSettingsScope.of(context);
    final items = _archiveItems(settings)
        .where(
          (item) => switch (_filter) {
            _ArchiveFilter.all => true,
            _ArchiveFilter.highlights => item.kind == _ArchiveKind.highlight,
            _ArchiveFilter.bookmarks => item.kind == _ArchiveKind.bookmark,
            _ArchiveFilter.notes => item.kind == _ArchiveKind.note,
          },
        )
        .toList(growable: false);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.profile,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
                tooltip: l10n.settings,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 29,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.person_rounded, color: scheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.guest,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.text('localOnly'),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActivityCard(
                  title: l10n.text('quranStreak'),
                  value: '${settings.readingStreak}',
                  suffix: l10n.text('dayUnit'),
                  icon: Icons.bolt_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActivityCard(
                  title: l10n.text('daysReadThisYear'),
                  value: '${settings.readingDaysThisYear}',
                  suffix: l10n.text('dayUnit'),
                  icon: Icons.calendar_month_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  value: settings.highlightEntries.length,
                  label: l10n.text('highlight'),
                  icon: Icons.format_color_fill_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  value: settings.bookmarkKeys.length,
                  label: l10n.text('savedLabel'),
                  icon: Icons.bookmark_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  value: settings.noteEntries.length,
                  label: l10n.text('note'),
                  icon: Icons.note_alt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            l10n.text('quranArchive'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(l10n.text('all'), _ArchiveFilter.all),
                _filterChip(l10n.text('highlights'), _ArchiveFilter.highlights),
                _filterChip(l10n.text('savedPlural'), _ArchiveFilter.bookmarks),
                _filterChip(l10n.notes, _ArchiveFilter.notes),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            _EmptyArchive(filter: _filter)
          else
            for (final item in items) ...[
              _ArchiveCard(item: item),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 18),
          _SettingsTile(
            Icons.download_done_rounded,
            l10n.downloads,
            l10n.downloadsDescription,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DownloadsScreen()),
            ),
          ),
          _SettingsTile(
            Icons.language_rounded,
            l10n.languageAndTranslation,
            l10n.currentLanguageAndTranslation,
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _ArchiveFilter value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: _filter == value,
        label: Text(label),
        avatar: switch (value) {
          _ArchiveFilter.all => const Icon(Icons.apps_rounded, size: 18),
          _ArchiveFilter.highlights => const Icon(
            Icons.format_color_fill_rounded,
            size: 18,
          ),
          _ArchiveFilter.bookmarks => const Icon(
            Icons.bookmark_rounded,
            size: 18,
          ),
          _ArchiveFilter.notes => const Icon(Icons.note_alt_rounded, size: 18),
        },
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  List<_ArchiveItem> _archiveItems(AppSettings settings) {
    final items = <_ArchiveItem>[];
    var fallbackOrder = 0;

    for (final entry in settings.highlightEntries.entries) {
      final parsed = _parseSelectionKey(entry.key);
      if (parsed == null) continue;
      final matches = VerseHighlightColor.values.where(
        (value) => value.name == entry.value,
      );
      items.add(
        _ArchiveItem(
          key: entry.key,
          kind: _ArchiveKind.highlight,
          surah: parsed.$1,
          ayahs: parsed.$2,
          highlight: matches.isEmpty ? null : matches.first,
          timestamp: settings.archiveTimestamp('highlight', entry.key),
          fallbackOrder: fallbackOrder++,
        ),
      );
    }

    for (final key in settings.bookmarkKeys) {
      final parsed = _parseSelectionKey(key);
      if (parsed == null) continue;
      items.add(
        _ArchiveItem(
          key: key,
          kind: _ArchiveKind.bookmark,
          surah: parsed.$1,
          ayahs: parsed.$2,
          timestamp: settings.archiveTimestamp('bookmark', key),
          fallbackOrder: fallbackOrder++,
        ),
      );
    }

    for (final entry in settings.noteEntries.entries) {
      final parsed = _parseSelectionKey(entry.key);
      if (parsed == null) continue;
      items.add(
        _ArchiveItem(
          key: entry.key,
          kind: _ArchiveKind.note,
          surah: parsed.$1,
          ayahs: parsed.$2,
          note: entry.value,
          sourceCode: settings.noteSourceForKey(entry.key),
          timestamp: settings.archiveTimestamp('note', entry.key),
          fallbackOrder: fallbackOrder++,
        ),
      );
    }

    items.sort((a, b) {
      final timeCompare = b.timestamp.compareTo(a.timestamp);
      if (timeCompare != 0) return timeCompare;
      return b.fallbackOrder.compareTo(a.fallbackOrder);
    });
    return items;
  }

  (int, List<int>)? _parseSelectionKey(String key) {
    final separator = key.indexOf(':');
    if (separator < 1 || separator == key.length - 1) return null;
    final surah = int.tryParse(key.substring(0, separator));
    if (surah == null || surah < 1 || surah > 114) return null;

    final ayahPart = key.substring(separator + 1);
    final ayahs = <int>[];
    if (ayahPart.contains('-')) {
      final bounds = ayahPart.split('-');
      if (bounds.length != 2) return null;
      final start = int.tryParse(bounds.first);
      final end = int.tryParse(bounds.last);
      if (start == null || end == null || start < 1 || end < start) return null;
      ayahs.addAll([for (var value = start; value <= end; value++) value]);
    } else if (ayahPart.contains(',')) {
      for (final raw in ayahPart.split(',')) {
        final value = int.tryParse(raw);
        if (value == null || value < 1) return null;
        ayahs.add(value);
      }
    } else {
      final value = int.tryParse(ayahPart);
      if (value == null || value < 1) return null;
      ayahs.add(value);
    }

    return ayahs.isEmpty ? null : (surah, ayahs);
  }
}

class _ArchiveItem {
  const _ArchiveItem({
    required this.key,
    required this.kind,
    required this.surah,
    required this.ayahs,
    required this.timestamp,
    required this.fallbackOrder,
    this.highlight,
    this.note,
    this.sourceCode = 'RWD',
  });

  final String key;
  final _ArchiveKind kind;
  final int surah;
  final List<int> ayahs;
  final VerseHighlightColor? highlight;
  final String? note;
  final String sourceCode;
  final int timestamp;
  final int fallbackOrder;

  String get reference {
    final surahInfo = surahByNumber(surah);
    final ayahPart = ayahs.length == 1
        ? '${ayahs.single}'
        : _isContiguous
        ? '${ayahs.first}-${ayahs.last}'
        : ayahs.join(',');
    return '${surahInfo.nameTr} $surah:$ayahPart';
  }

  bool get _isContiguous {
    for (var i = 1; i < ayahs.length; i++) {
      if (ayahs[i] != ayahs[i - 1] + 1) return false;
    }
    return true;
  }

  String get arabic {
    final visible = ayahs.take(4);
    final text = visible.map((ayah) => quran.getVerse(surah, ayah)).join(' ');
    return ayahs.length > 4 ? '$text …' : text;
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.value,
    required this.suffix,
    required this.icon,
  });

  final String title;
  final String value;
  final String suffix;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 142,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(icon, color: scheme.primary, size: 21),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  suffix,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 105,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const Spacer(),
          Text(
            '$value',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({required this.item});

  final _ArchiveItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final accent = item.highlight == null
        ? scheme.primary
        : _highlightMaterialColor(item.highlight!);
    final label = switch (item.kind) {
      _ArchiveKind.highlight => l10n.text('highlight'),
      _ArchiveKind.bookmark => l10n.text('savedLabel'),
      _ArchiveKind.note => l10n.text('note'),
    };
    final icon = switch (item.kind) {
      _ArchiveKind.highlight => Icons.format_color_fill_rounded,
      _ArchiveKind.bookmark => Icons.bookmark_rounded,
      _ArchiveKind.note => Icons.note_alt_rounded,
    };
    final showArabic =
        item.kind == _ArchiveKind.note && item.sourceCode == 'AR';

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PassagePreviewScreen(
                selectionKey: item.key,
                sourceCode: item.kind == _ArchiveKind.note
                    ? item.sourceCode
                    : null,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 17, color: accent),
                          const SizedBox(width: 7),
                          Text(
                            label,
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (item.kind == _ArchiveKind.note) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.sourceCode,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Flexible(
                            child: Text(
                              item.reference,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (showArabic)
                        Text(
                          item.arabic,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 20,
                            height: 1.65,
                          ),
                        )
                      else
                        FutureBuilder<Map<String, String>>(
                          future: TranslationRepository.instance
                              .loadBundledTurkish(),
                          builder: (context, snapshot) {
                            final map = snapshot.data;
                            if (map == null) {
                              return const SizedBox.shrink();
                            }
                            final text = item.ayahs
                                .take(4)
                                .map((ayah) => map['${item.surah}:$ayah'])
                                .whereType<String>()
                                .join(' ');
                            if (text.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              item.ayahs.length > 4 ? '$text …' : text,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 18,
                                height: 1.45,
                              ),
                            );
                          },
                        ),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          '${l10n.text('note')}: ${item.note!}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyArchive extends StatelessWidget {
  const _EmptyArchive({required this.filter});

  final _ArchiveFilter filter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final text = switch (filter) {
      _ArchiveFilter.all => l10n.text('archiveEmptyAll'),
      _ArchiveFilter.highlights => l10n.text('archiveEmptyHighlights'),
      _ArchiveFilter.bookmarks => l10n.text('archiveEmptySaved'),
      _ArchiveFilter.notes => l10n.text('archiveEmptyNotes'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_outlined, size: 38, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile(this.icon, this.title, this.subtitle, {this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: TextStyle(color: scheme.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

Color _highlightMaterialColor(VerseHighlightColor color) => switch (color) {
  VerseHighlightColor.yellow => const Color(0xFFFFEB00),
  VerseHighlightColor.green => const Color(0xFF45E879),
  VerseHighlightColor.blue => const Color(0xFF18C4E8),
  VerseHighlightColor.orange => const Color(0xFFFFB45E),
  VerseHighlightColor.pink => const Color(0xFFE88AC6),
};
