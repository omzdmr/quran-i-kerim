import 'package:flutter/material.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_progress_store.dart';
import '../application/memorization_review_coverage.dart';
import 'memorization_study_screen.dart';

class MemorizationReviewCoverageScreen extends StatefulWidget {
  const MemorizationReviewCoverageScreen({super.key});

  @override
  State<MemorizationReviewCoverageScreen> createState() =>
      _MemorizationReviewCoverageScreenState();
}

class _MemorizationReviewCoverageScreenState
    extends State<MemorizationReviewCoverageScreen> {
  static const _store = MemorizationProgressStore();
  MemorizationReviewCoverage? _coverage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final progress = await _store.load();
    final coverage = buildMemorizationReviewCoverage(
      progress: progress,
      now: DateTime.now(),
    );
    if (!mounted) return;
    setState(() => _coverage = coverage);
  }

  Future<void> _openPage(int page) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => MemorizationStudyScreen(page: page)),
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
              : RefreshIndicator(
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
                      const SizedBox(height: 16),
                      for (final item in coverage.items)
                        _CoveragePageTile(
                          item: item,
                          pageLabel: l10n.memorizePages,
                          reviewLabel: l10n.memorizeTodayReview,
                          onTap: () => _openPage(item.page),
                        ),
                    ],
                  ),
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
                  label: Text('${coverage.needsAttentionCount}'),
                ),
                Chip(
                  avatar: const Icon(Icons.schedule_rounded),
                  label: Text('${coverage.agingCount}'),
                ),
                Chip(
                  avatar: const Icon(Icons.check_circle_outline_rounded),
                  label: Text('${coverage.freshCount}'),
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
    final age = item.ageDays;
    final ageText = age == null ? reviewLabel : '$age';
    final semantic = '$pageLabel ${item.page}, $reviewLabel, $ageText';
    return Semantics(
      button: true,
      label: semantic,
      child: Card(
        child: ListTile(
          leading: Icon(_icon),
          title: Text('$pageLabel ${item.page}'),
          subtitle: Text(ageText),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
