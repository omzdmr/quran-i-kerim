import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../data/surah_localization.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/generated/generated_app_localizations.dart';
import '../../navigation/app_navigation.dart';
import '../../settings/app_settings.dart';
import '../plans/reading_plan_store.dart';
import '../reader/reader_navigation.dart';
import '../reader/reader_reading_history.dart';

class QuranProgressOverview extends StatefulWidget {
  const QuranProgressOverview({super.key});

  @override
  State<QuranProgressOverview> createState() => _QuranProgressOverviewState();
}

class _QuranProgressOverviewState extends State<QuranProgressOverview> {
  final ReadingPlanStore _readingPlanStore = const ReadingPlanStore();

  int _tab = 0;
  int _readingPlanLoadGeneration = 0;
  bool _readingPlanLoading = true;
  ReadingPlanSnapshot _readingPlanSnapshot = const ReadingPlanSnapshot();
  bool _readingHistoryLoading = true;
  int _readingHistoryLoadGeneration = 0;
  List<ReaderHistoryEntry> _readingHistory = const <ReaderHistoryEntry>[];

  @override
  void initState() {
    super.initState();
    ReadingPlanStore.changes.addListener(_handleReadingPlanChanged);
    ReaderReadingHistoryRepository.changes.addListener(
      _handleReadingHistoryChanged,
    );
    _loadReadingPlan();
    _loadReadingHistory();
  }

  @override
  void dispose() {
    ReadingPlanStore.changes.removeListener(_handleReadingPlanChanged);
    ReaderReadingHistoryRepository.changes.removeListener(
      _handleReadingHistoryChanged,
    );
    super.dispose();
  }

  void _select(int index) {
    if (_tab == index) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = index);
  }

  void _continueReading(AppSettings settings) {
    AppNavigation.instance.openReader(
      surah: settings.lastSurah,
      ayah: settings.lastAyah,
    );
  }

  void _handleReadingPlanChanged() {
    _loadReadingPlan();
  }

  void _handleReadingHistoryChanged() {
    _loadReadingHistory();
  }

  Future<void> _loadReadingHistory() async {
    final generation = ++_readingHistoryLoadGeneration;
    final entries = await ReaderReadingHistoryRepository.instance.load();
    if (!mounted || generation != _readingHistoryLoadGeneration) return;
    setState(() {
      _readingHistory = entries;
      _readingHistoryLoading = false;
    });
  }

  Future<void> _loadReadingPlan() async {
    final generation = ++_readingPlanLoadGeneration;
    final snapshot = await _readingPlanStore.load();
    if (!mounted || generation != _readingPlanLoadGeneration) return;
    setState(() {
      _readingPlanSnapshot = snapshot;
      _readingPlanLoading = false;
    });
  }

  void _openHistoryEntry(ReaderHistoryEntry entry) {
    HapticFeedback.selectionClick();
    AppNavigation.instance.openReader(surah: entry.surah, ayah: entry.ayah);
  }

  void _openPlans() {
    HapticFeedback.selectionClick();
    AppNavigation.instance.openPlans();
  }

  void _openReadingPlanDay() {
    final day = _readingPlanSnapshot.active?.nextDay;
    if (day == null) {
      _openPlans();
      return;
    }
    final target = firstVerseForPage(day.startPage);
    if (target == null) {
      _openPlans();
      return;
    }
    HapticFeedback.selectionClick();
    AppNavigation.instance.openReader(surah: target.surah, ayah: target.ayah);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final settings = AppSettingsScope.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        _PillSwitcher(
          selectedIndex: _tab,
          labels: [l10n.quranProgressReading, l10n.quranProgressKhatm],
          onSelected: _select,
        ),
        const SizedBox(height: 16),
        if (_tab == 0)
          _ReadingProgress(
            settings: settings,
            readingPlanLoading: _readingPlanLoading,
            readingPlanSnapshot: _readingPlanSnapshot,
            readingHistoryLoading: _readingHistoryLoading,
            readingHistory: _readingHistory,
            onContinue: () => _continueReading(settings),
            onOpenHistoryEntry: _openHistoryEntry,
            onOpenPlans: _openPlans,
            onReadPlan: _openReadingPlanDay,
          )
        else
          _KhatmProgress(
            settings: settings,
            onContinue: () => _continueReading(settings),
          ),
      ],
    );
  }
}

class _ReadingProgress extends StatelessWidget {
  const _ReadingProgress({
    required this.settings,
    required this.readingPlanLoading,
    required this.readingPlanSnapshot,
    required this.readingHistoryLoading,
    required this.readingHistory,
    required this.onContinue,
    required this.onOpenHistoryEntry,
    required this.onOpenPlans,
    required this.onReadPlan,
  });

  final AppSettings settings;
  final bool readingPlanLoading;
  final ReadingPlanSnapshot readingPlanSnapshot;
  final bool readingHistoryLoading;
  final List<ReaderHistoryEntry> readingHistory;
  final VoidCallback onContinue;
  final ValueChanged<ReaderHistoryEntry> onOpenHistoryEntry;
  final VoidCallback onOpenPlans;
  final VoidCallback onReadPlan;

  String _dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final lastSurahName = localizedSurahName(settings.lastSurah, languageCode);
    final currentPage = quran.getPageNumber(settings.lastSurah, settings.lastAyah);
    final now = DateTime.now();
    final days = [
      for (var offset = 6; offset >= 0; offset--)
        DateTime(now.year, now.month, now.day).subtract(Duration(days: offset)),
    ];
    final weekdayLabels = MaterialLocalizations.of(context).narrowWeekdays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF315348), Color(0xFF182B25)],
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (settings.readingStreak / 7).clamp(0, 1).toDouble(),
                      strokeWidth: 7,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${settings.readingStreak}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          l10n.quranProgressStreak,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.quranProgressLastRead,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$lastSurahName ${settings.lastSurah}:${settings.lastAyah}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${l10n.quranProgressCurrentPage}: $currentPage / 604',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: onContinue,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF203C33),
                      ),
                      child: Text(l10n.quranProgressContinue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: l10n.quranProgressWeek,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in days)
                _DayRing(
                  label: weekdayLabels[day.weekday % 7],
                  active: settings.readingDays.contains(_dayKey(day)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.bookmark_outline_rounded,
                value: settings.bookmarkKeys.length,
                label: l10n.quranProgressSaved,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.note_alt_outlined,
                value: settings.noteEntries.length,
                label: l10n.quranProgressNotes,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.border_color_outlined,
                value: settings.highlightEntries.length,
                label: l10n.quranProgressHighlights,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _RecentReadingHistoryCard(
          loading: readingHistoryLoading,
          entries: readingHistory.take(3).toList(growable: false),
          onOpen: onOpenHistoryEntry,
        ),
        const SizedBox(height: 16),
        _ReadingPlanProgressCard(
          loading: readingPlanLoading,
          snapshot: readingPlanSnapshot,
          onOpenPlans: onOpenPlans,
          onReadPlan: onReadPlan,
        ),
      ],
    );
  }
}

class _RecentReadingHistoryCard extends StatelessWidget {
  const _RecentReadingHistoryCard({
    required this.loading,
    required this.entries,
    required this.onOpen,
  });

  final bool loading;
  final List<ReaderHistoryEntry> entries;
  final ValueChanged<ReaderHistoryEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.text('readerHistoryTitle'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            l10n.text('readerHistorySubtitle'),
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 12),
          if (loading)
            const LinearProgressIndicator()
          else if (entries.isEmpty)
            Text(
              l10n.text('readerHistoryEmpty'),
              style: TextStyle(color: scheme.onSurfaceVariant),
            )
          else
            for (var index = 0; index < entries.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              Builder(
                builder: (context) {
                  final entry = entries[index];
                  final metadata = quranVerseMetadata(entry.surah, entry.ayah);
                  final surahName = localizedSurahName(
                    entry.surah,
                    languageCode,
                  );
                  final meta = l10n
                      .text('readerHistoryMeta')
                      .replaceAll('{juz}', '${metadata.juz}')
                      .replaceAll('{page}', '${metadata.page}');
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${entry.surah}')),
                    title: Text(
                      '$surahName ${entry.surah}:${entry.ayah}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(meta),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => onOpen(entry),
                  );
                },
              ),
            ],
        ],
      ),
    );
  }
}

class _ReadingPlanProgressCard extends StatelessWidget {
  const _ReadingPlanProgressCard({
    required this.loading,
    required this.snapshot,
    required this.onOpenPlans,
    required this.onReadPlan,
  });

  final bool loading;
  final ReadingPlanSnapshot snapshot;
  final VoidCallback onOpenPlans;
  final VoidCallback onReadPlan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    if (loading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const LinearProgressIndicator(),
      );
    }

    final active = snapshot.active;
    if (active == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.text('readingPlans'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              l10n.text('plansEmptyActiveV1'),
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onOpenPlans,
              icon: const Icon(Icons.explore_outlined),
              label: Text(l10n.text('findPlans')),
            ),
          ],
        ),
      );
    }

    final day = active.nextDay;
    if (day == null) return const SizedBox.shrink();

    final total = active.preset.durationDays;
    final done = active.completedPrefixDays;
    final schedule = active.scheduleStatus(DateTime.now());
    final dayText = l10n
        .text('plansDayProgressV1')
        .replaceAll('{day}', '${day.dayNumber}')
        .replaceAll('{total}', '$total');
    final pagesText = l10n
        .text('plansPagesV1')
        .replaceAll('{start}', '${day.startPage}')
        .replaceAll('{end}', '${day.endPage}');
    final progressText = l10n
        .text('plansProgressV1')
        .replaceAll('{done}', '$done')
        .replaceAll('{total}', '$total');
    final scheduleText = active.isPaused
        ? l10n.text('plansPausedV1')
        : schedule.isBehind
        ? l10n
              .text('plansScheduleBehindV1')
              .replaceAll('{count}', '${schedule.behindByDays}')
        : schedule.isAhead
        ? l10n
              .text('plansScheduleAheadV1')
              .replaceAll('{count}', '${schedule.aheadByDays}')
        : l10n.text('plansScheduleOnTrackV1');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: schedule.isBehind
              ? scheme.error.withValues(alpha: .35)
              : scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.route_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.text('readingPlans'),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.text(active.preset.titleKey),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onOpenPlans,
                child: Text(l10n.text('myPlans')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: active.progress, minHeight: 8),
          ),
          const SizedBox(height: 10),
          Text(
            progressText,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            '$dayText · $pagesText',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                active.isPaused
                    ? Icons.pause_circle_outline_rounded
                    : schedule.isBehind
                    ? Icons.schedule_rounded
                    : schedule.isAhead
                    ? Icons.fast_forward_rounded
                    : Icons.check_circle_outline_rounded,
                size: 17,
                color: schedule.isBehind ? scheme.error : scheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  scheduleText,
                  style: TextStyle(
                    color: schedule.isBehind
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onReadPlan,
              icon: const Icon(Icons.menu_book_rounded),
              label: Text(l10n.text('plansReadTodayV1')),
            ),
          ),
        ],
      ),
    );
  }
}

class _KhatmProgress extends StatelessWidget {
  const _KhatmProgress({required this.settings, required this.onContinue});

  final AppSettings settings;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final currentPage = quran.getPageNumber(settings.lastSurah, settings.lastAyah);
    final progress = currentPage / 604;
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.auto_stories_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.quranProgressKhatmTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.quranProgressKhatmBody,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '$percent%',
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 10),
          ),
          const SizedBox(height: 10),
          Text(
            '$currentPage / 604 ${l10n.quranProgressPages}',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.menu_book_rounded),
            label: Text(l10n.quranProgressContinue),
          ),
        ],
      ),
    );
  }
}

class _PillSwitcher extends StatelessWidget {
  const _PillSwitcher({
    required this.selectedIndex,
    required this.labels,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = index == selectedIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: selected ? scheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? scheme.primary : scheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DayRing extends StatelessWidget {
  const _DayRing({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? scheme.primary : Colors.transparent,
            border: Border.all(
              color: active ? scheme.primary : scheme.outlineVariant,
              width: 2,
            ),
          ),
          child: active
              ? Icon(Icons.check_rounded, size: 18, color: scheme.onPrimary)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
