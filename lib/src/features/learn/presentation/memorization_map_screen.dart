import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_page_catalog.dart';
import '../application/memorization_practice_history_store.dart';
import '../application/memorization_progress_store.dart';
import '../application/memorization_strength.dart';
import 'memorization_study_screen.dart';

class MemorizationMapScreen extends StatefulWidget {
  const MemorizationMapScreen({super.key});

  @override
  State<MemorizationMapScreen> createState() => _MemorizationMapScreenState();
}

class _MemorizationMapScreenState extends State<MemorizationMapScreen> {
  static const _store = MemorizationProgressStore();
  static const _practiceStore = MemorizationPracticeHistoryStore();
  MemorizationProgressSnapshot? _snapshot;
  MemorizationPracticeHistorySnapshot? _practice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snapshot = await _store.load();
    final practice = await _practiceStore.load();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _practice = practice;
    });
  }

  Future<void> _toggle(int page) async {
    HapticFeedback.selectionClick();
    final snapshot = await _store.togglePage(page);
    if (!mounted) return;
    setState(() => _snapshot = snapshot);
  }

  Future<void> _openPage(int page) async {
    if (memorizationPageInfo(page) == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MemorizationStudyScreen(page: page),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final snapshot = _snapshot;
    final practice = _practice;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.memorizeMapTitle)),
      body: snapshot == null || practice == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.route_rounded,
                        color: scheme.onPrimaryContainer,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.memorizeMapHint,
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.memorizedCount} / 604 ${l10n.memorizePages}',
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _StrengthLegend(l10n: l10n),
                const SizedBox(height: 16),
                for (var juz = 1; juz <= 30; juz++)
                  _JuzSection(
                    juz: juz,
                    pages: memorizationPagesForJuz(juz),
                    snapshot: snapshot,
                    practice: practice,
                    onToggle: _toggle,
                    onOpen: _openPage,
                    label: '${l10n.memorizeJuz} $juz',
                    completedLabel: l10n.memorizeCompleted,
                    l10n: l10n,
                  ),
              ],
            ),
    );
  }
}

class _StrengthLegend extends StatelessWidget {
  const _StrengthLegend({required this.l10n});

  final GeneratedAppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const strengths = <MemorizationStrength>[
      MemorizationStrength.learning,
      MemorizationStrength.recentReview,
      MemorizationStrength.oldReview,
      MemorizationStrength.solid,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final strength in strengths)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: .55),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _strengthColor(scheme, strength),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  _strengthLabel(l10n, strength),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _JuzSection extends StatelessWidget {
  const _JuzSection({
    required this.juz,
    required this.pages,
    required this.snapshot,
    required this.practice,
    required this.onToggle,
    required this.onOpen,
    required this.label,
    required this.completedLabel,
    required this.l10n,
  });

  final int juz;
  final List<MemorizationPageInfo> pages;
  final MemorizationProgressSnapshot snapshot;
  final MemorizationPracticeHistorySnapshot practice;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onOpen;
  final String label;
  final String completedLabel;
  final GeneratedAppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final completed = pages.where((page) => snapshot.containsPage(page.page)).length;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey<String>('memorize-juz-$juz'),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('$completed / ${pages.length} $completedLabel'),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final info = pages[index];
              final selected = snapshot.containsPage(info.page);
              final strength = selected
                  ? deriveMemorizationStrength(
                      progress: snapshot.progressForPage(info.page) ??
                          const MemorizationPageProgress(),
                      latestPracticeAt:
                          practice.latestForPage(info.page)?.occurredAt,
                    )
                  : MemorizationStrength.newItem;
              final foreground = selected
                  ? _strengthForeground(scheme, strength)
                  : scheme.onSurface;
              final semanticsLabel = selected
                  ? '${info.page}, ${_strengthLabel(l10n, strength)}'
                  : '${info.page}';

              return Semantics(
                button: true,
                selected: selected,
                label: semanticsLabel,
                child: Material(
                  color: selected
                      ? _strengthColor(scheme, strength)
                      : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => onOpen(info.page),
                    onLongPress: () => onToggle(info.page),
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${info.page}',
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (selected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(
                              _strengthIcon(strength),
                              size: 13,
                              color: foreground,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _strengthLabel(
  GeneratedAppLocalizations l10n,
  MemorizationStrength strength,
) {
  return switch (strength) {
    MemorizationStrength.learning => l10n.memorizeStrengthLearning,
    MemorizationStrength.recentReview => l10n.memorizeStrengthRecent,
    MemorizationStrength.oldReview => l10n.memorizeStrengthOld,
    MemorizationStrength.solid => l10n.memorizeStrengthSolid,
    MemorizationStrength.newItem => l10n.memorizeProgress,
  };
}

Color _strengthColor(ColorScheme scheme, MemorizationStrength strength) {
  return switch (strength) {
    MemorizationStrength.learning => scheme.tertiaryContainer,
    MemorizationStrength.recentReview => scheme.secondaryContainer,
    MemorizationStrength.oldReview => scheme.primaryContainer,
    MemorizationStrength.solid => scheme.primary,
    MemorizationStrength.newItem => scheme.surfaceContainerHigh,
  };
}

Color _strengthForeground(ColorScheme scheme, MemorizationStrength strength) {
  return switch (strength) {
    MemorizationStrength.learning => scheme.onTertiaryContainer,
    MemorizationStrength.recentReview => scheme.onSecondaryContainer,
    MemorizationStrength.oldReview => scheme.onPrimaryContainer,
    MemorizationStrength.solid => scheme.onPrimary,
    MemorizationStrength.newItem => scheme.onSurface,
  };
}

IconData _strengthIcon(MemorizationStrength strength) {
  return switch (strength) {
    MemorizationStrength.learning => Icons.edit_outlined,
    MemorizationStrength.recentReview => Icons.schedule_rounded,
    MemorizationStrength.oldReview => Icons.history_rounded,
    MemorizationStrength.solid => Icons.check_rounded,
    MemorizationStrength.newItem => Icons.circle_outlined,
  };
}
