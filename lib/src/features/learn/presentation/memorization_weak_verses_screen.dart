import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../../../data/surah_localization.dart';
import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_recall_history_store.dart';
import 'memorization_recall_test_screen.dart';

class MemorizationWeakVersesScreen extends StatefulWidget {
  const MemorizationWeakVersesScreen({super.key});

  @override
  State<MemorizationWeakVersesScreen> createState() =>
      _MemorizationWeakVersesScreenState();
}

class _MemorizationWeakVersesScreenState
    extends State<MemorizationWeakVersesScreen> {
  static const _historyStore = MemorizationRecallHistoryStore();

  List<_WeakVerseItem>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _historyStore.load();
    final items = history.weakStatsByPriority
        .map(_WeakVerseItem.tryParse)
        .whereType<_WeakVerseItem>()
        .toList(growable: false);
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _review(_WeakVerseItem item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MemorizationRecallTestScreen(
          initialQuestionId: item.id,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final items = _items;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memorizeWeakTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: items == null
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? _EmptyWeakState(
                    title: l10n.memorizeWeakTitle,
                    body: l10n.memorizeWeakEmptyBody,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    children: [
                      _WeakSummaryCard(
                        count: items.length,
                        title: l10n.memorizeWeakTitle,
                        body: l10n.memorizeWeakBody,
                      ),
                      const SizedBox(height: 14),
                      for (final item in items) ...[
                        _WeakVerseCard(
                          item: item,
                          difficultyLabel: l10n.memorizeWeakDifficulty,
                          attemptsLabel: l10n.memorizeWeakAttempts,
                          reviewLabel: l10n.memorizeWeakReview,
                          onReview: () => _review(item),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _WeakVerseItem {
  const _WeakVerseItem({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.arabic,
    required this.stat,
  });

  final String id;
  final int surah;
  final int ayah;
  final String arabic;
  final MemorizationRecallStat stat;

  static _WeakVerseItem? tryParse(
    MapEntry<String, MemorizationRecallStat> entry,
  ) {
    final parts = entry.key.split(':');
    if (parts.length != 2) return null;
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null || surah < 1 || surah > 114 || ayah < 1) {
      return null;
    }

    try {
      final arabic = quran.getVerse(surah, ayah);
      if (arabic.trim().isEmpty) return null;
      return _WeakVerseItem(
        id: entry.key,
        surah: surah,
        ayah: ayah,
        arabic: arabic,
        stat: entry.value,
      );
    } on RangeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }
}

class _WeakSummaryCard extends StatelessWidget {
  const _WeakSummaryCard({
    required this.count,
    required this.title,
    required this.body,
  });

  final int count;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.surfaceContainer,
          ],
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: .45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: scheme.primary,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
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
    );
  }
}

class _WeakVerseCard extends StatelessWidget {
  const _WeakVerseCard({
    required this.item,
    required this.difficultyLabel,
    required this.attemptsLabel,
    required this.reviewLabel,
    required this.onReview,
  });

  final _WeakVerseItem item;
  final String difficultyLabel;
  final String attemptsLabel;
  final String reviewLabel;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final localeCode = Localizations.localeOf(context).languageCode;
    final surahName = localizedSurahName(item.surah, localeCode);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: .48),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$surahName · ${item.ayah}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              _MetricPill(
                icon: Icons.priority_high_rounded,
                label: difficultyLabel,
                value: item.stat.difficulty,
              ),
              const SizedBox(width: 8),
              _MetricPill(
                icon: Icons.replay_rounded,
                label: attemptsLabel,
                value: item.stat.attempts,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            item.arabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 25,
              height: 1.85,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onReview,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(reviewLabel),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: scheme.primary),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWeakState extends StatelessWidget {
  const _EmptyWeakState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 38,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
