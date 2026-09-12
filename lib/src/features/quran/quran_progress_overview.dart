import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../data/surah_localization.dart';
import '../../l10n/generated/generated_app_localizations.dart';
import '../../navigation/app_navigation.dart';
import '../../settings/app_settings.dart';

class QuranProgressOverview extends StatefulWidget {
  const QuranProgressOverview({super.key});

  @override
  State<QuranProgressOverview> createState() => _QuranProgressOverviewState();
}

class _QuranProgressOverviewState extends State<QuranProgressOverview> {
  int _tab = 0;

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
            onContinue: () => _continueReading(settings),
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
  const _ReadingProgress({required this.settings, required this.onContinue});

  final AppSettings settings;
  final VoidCallback onContinue;

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
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
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
      ],
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.quranProgressKhatmBody,
                      style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
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
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
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
          Text('$value', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
