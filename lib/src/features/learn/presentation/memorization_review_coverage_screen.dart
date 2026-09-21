import 'package:flutter/material.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_review_coverage.dart';
import '../application/memorization_review_coverage_store.dart';
import '../application/memorization_review_session.dart';
import 'memorization_study_screen.dart';

class MemorizationReviewCoverageScreen extends StatefulWidget {
  const MemorizationReviewCoverageScreen({super.key});

  @override
  State<MemorizationReviewCoverageScreen> createState() =>
      _MemorizationReviewCoverageScreenState();
}

class _MemorizationReviewCoverageScreenState
    extends State<MemorizationReviewCoverageScreen> {
  static const _coverageStore = MemorizationReviewCoverageStore();
  MemorizationReviewCoverage? _coverage;
  bool _attentionOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final coverage = await _coverageStore.load();
    if (!mounted) return;
    setState(() => _coverage = coverage);
  }

  Future<void> _openPage(int page) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MemorizationStudyScreen(
          page: page,
          initialMode: MemorizationStudyMode.memorize,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final coverage = _coverage;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.memorizeTodayReview)),
      body: coverage == null
          ? const Center(child: CircularProgressIndicator())
          : coverage.total == 0
              ? Center(child: Text(l10n.memorizeProgress))
              : _buildCoverage(context, l10n, coverage),
    );
  }

  Widget _buildCoverage(
    BuildContext context,
    GeneratedAppLocalizations l10n,
    MemorizationReviewCoverage coverage,
  ) {
    final visibleItems = _attentionOnly
        ? coverage.items.where((item) => item.needsAttention).toList()
        : coverage.items;
    final session = buildMemorizationReviewSession(coverage: coverage);
    final nextPage = session.isEmpty ? null : session.pages.first;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Semantics(
            container: true,
            label:
                '${l10n.memorizeTodayReview}: ${coverage.needsAttentionCount} / ${coverage.total}',
            child: _CoverageSummary(coverage: coverage),
          ),
          if (nextPage != null) ...[
            const SizedBox(height: 12),
            Semantics(
              button: true,
              label:
                  '${l10n.memorizeOpenNext}, ${l10n.memorizePages} $nextPage, ${session.sessionSize} / ${session.totalAttentionPages}',
              child: FilledButton.icon(
                onPressed: () => _openPage(nextPage),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  '${l10n.memorizeOpenNext} · ${l10n.memorizePages} $nextPage · ${session.sessionSize}/${session.totalAttentionPages}',
                ),
              ),
            ),
            if (session.deferredCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${l10n.memorizeTodayReview}: ${session.sessionSize} · ${l10n.memorizeProgress}: ${session.deferredCount}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                selected: _attentionOnly,
                label: Text(l10n.memorizeTodayReview),
                onSelected: (_) => setState(() => _attentionOnly = true),
              ),
              ChoiceChip(
                selected: !_attentionOnly,
                label: Text(l10n.memorizeProgress),
                onSelected: (_) => setState(() => _attentionOnly = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (visibleItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else
            for (final item in visibleItems)
              _CoveragePageTile(
                item: item,
                pageLabel: l10n.memorizePages,
                reviewLabel: l10n.memorizeTodayReview,
                onTap: () => _openPage(item.page),
              ),
        ],
      ),
    );
  }
}

class _CoverageSummary extends StatelessWidget {
  const _CoverageSummary({required this.coverage});

  final MemorizationReviewCoverage coverage;

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.memorizeTodayReview,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: coverage.coveredFraction,
              minHeight: 9,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(Icons.priority_high_rounded, color: scheme.error),
                  label: Text(
                    '${l10n.memorizeTodayReview} ${coverage.needsAttentionCount}',
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.schedule_rounded),
                  label: Text(
                    '${l10n.memorizeWeeklyTitle} ${coverage.agingCount}',
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.check_circle_outline_rounded),
                  label: Text('${l10n.memorizeProgress} ${coverage.freshCount}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoveragePageTile extends StatelessWidget {
  const _CoveragePageTile({
    required this.item,
    required this.pageLabel,
    required this.reviewLabel,
    required this.onTap,
  });

  final MemorizationReviewCoverageItem item;
  final String pageLabel;
  final String reviewLabel;
  final VoidCallback onTap;

  IconData get _icon => switch (item.freshness) {
        MemorizationReviewFreshness.neverReviewed => Icons.new_releases_outlined,
        MemorizationReviewFreshness.overdue => Icons.warning_amber_rounded,
        MemorizationReviewFreshness.aging => Icons.schedule_rounded,
        MemorizationReviewFreshness.fresh => Icons.check_circle_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final reviewedAt = item.lastReviewedAt;
    final dateText = reviewedAt == null
        ? reviewLabel
        : MaterialLocalizations.of(context).formatCompactDate(reviewedAt);
    final semantic = '$pageLabel ${item.page}, $reviewLabel, $dateText';
    return Semantics(
      button: true,
      label: semantic,
      child: Card(
        child: ListTile(
          leading: Icon(_icon),
          title: Text('$pageLabel ${item.page}'),
          subtitle: Text(dateText),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
