import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_progress_store.dart';
import '../application/memorization_review_coverage.dart';
import '../application/memorization_review_coverage_store.dart';
import '../application/memorization_review_session.dart';
import 'memorization_coverage_review_session_screen.dart';
import 'memorization_study_scaffold.dart';
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

  Future<void> _openSession(MemorizationReviewSession session) async {
    if (session.isEmpty) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MemorizationCoverageReviewSessionScreen(session: session),
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
    final copy = _CoverageCopy.forLocale(Localizations.localeOf(context));
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
                  '${l10n.memorizeOpenNext}, ${l10n.memorizePages} $nextPage. ${copy.batchSemantics(session)}',
              onTap: () => _openSession(session),
              child: ExcludeSemantics(
                child: FilledButton.icon(
                  onPressed: () => _openSession(session),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    '${l10n.memorizeOpenNext} · ${l10n.memorizePages} $nextPage',
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                copy.batchSummary(session),
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
                daysLabel: AppLocalizations.of(context).text('daysUnit'),
                assessmentLabel: switch (item.selfAssessment) {
                  MemorizationSelfAssessment.struggled =>
                    l10n.memorizeTestStruggled,
                  MemorizationSelfAssessment.assisted =>
                    l10n.memorizeTestAssisted,
                  MemorizationSelfAssessment.independent =>
                    l10n.memorizeTestIndependent,
                  null => null,
                },
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
    required this.daysLabel,
    required this.assessmentLabel,
    required this.onTap,
  });

  final MemorizationReviewCoverageItem item;
  final String pageLabel;
  final String reviewLabel;
  final String daysLabel;
  final String? assessmentLabel;
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
    final details = <String>[
      dateText,
      if (item.ageDays != null) '${item.ageDays} $daysLabel',
      if (assessmentLabel != null) assessmentLabel!,
    ];
    final detailText = details.join(' · ');
    final semantic = '$pageLabel ${item.page}, $reviewLabel, $detailText';
    return Semantics(
      button: true,
      label: semantic,
      child: Card(
        child: ListTile(
          leading: Icon(_icon),
          title: Text('$pageLabel ${item.page}'),
          subtitle: Text(detailText),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _CoverageCopy {
  const _CoverageCopy({
    required this.batch,
    required this.remaining,
  });

  final String batch;
  final String remaining;

  String batchSummary(MemorizationReviewSession session) {
    final base = '$batch: ${session.sessionSize}';
    return session.deferredCount == 0
        ? base
        : '$base · $remaining: ${session.deferredCount}';
  }

  String batchSemantics(MemorizationReviewSession session) =>
      batchSummary(session).replaceAll('·', '.');

  static _CoverageCopy forLocale(Locale locale) =>
      _copies[locale.languageCode] ?? _copies['en']!;
}

const _copies = <String, _CoverageCopy>{
  'tr': _CoverageCopy(batch: 'Bu tekrar turu', remaining: 'Sonraya kalan'),
  'en': _CoverageCopy(batch: 'This review round', remaining: 'Remaining later'),
  'ar': _CoverageCopy(batch: 'جولة المراجعة هذه', remaining: 'المتبقي لاحقًا'),
  'az': _CoverageCopy(batch: 'Bu təkrar turu', remaining: 'Sonraya qalan'),
  'ru': _CoverageCopy(batch: 'Этот подход повторения', remaining: 'Останется на потом'),
  'fr': _CoverageCopy(batch: 'Cette session de révision', remaining: 'À revoir ensuite'),
};
