import 'package:flutter/material.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_juz_review.dart';
import '../application/memorization_plan_store.dart';
import '../application/memorization_progress_store.dart';
import '../application/memorization_recall_history_store.dart';
import '../application/memorization_target_catalog.dart';
import '../application/memorization_target_store.dart';
import '../application/memorization_today_plan.dart';
import '../application/memorization_weekly_review.dart';
import 'memorization_juz_review_screen.dart';
import 'memorization_map_screen.dart';
import 'memorization_recall_test_screen.dart';
import 'memorization_study_screen.dart';
import 'memorization_target_screen.dart';
import 'memorization_today_session_screen.dart';
import 'memorization_weak_verses_screen.dart';
import 'memorization_weekly_review_screen.dart';

class MemorizationOverview extends StatefulWidget {
  const MemorizationOverview({super.key});

  @override
  State<MemorizationOverview> createState() => _MemorizationOverviewState();
}

class _MemorizationOverviewState extends State<MemorizationOverview> {
  static const _store = MemorizationProgressStore();
  static const _historyStore = MemorizationRecallHistoryStore();
  static const _targetStore = MemorizationTargetStore();
  static const _planStore = MemorizationPlanStore();
  MemorizationProgressSnapshot? _snapshot;
  MemorizationTargetId _target = MemorizationTargetId.fullQuran;
  MemorizationTodayPlan? _todayPlan;
  int _weakVerseCount = 0;
  int _weeklyPageCount = 0;
  int _completedJuzCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snapshot = await _store.load();
    final history = await _historyStore.load();
    final target = await _targetStore.load();
    final plan = await _planStore.load();
    final todayPlan = buildMemorizationTodayPlan(
      plan: plan,
      progress: snapshot,
      target: target,
      weakRecallCount: history.weakQuestionIds.length,
      now: DateTime.now(),
    );
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _target = target;
      _todayPlan = todayPlan;
      _weakVerseCount = history.weakQuestionIds.length;
      _weeklyPageCount = weeklyMemorizedPages(snapshot).length;
      _completedJuzCount = completedMemorizedJuz(snapshot).length;
    });
  }

  Future<void> _openPage(int page) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => MemorizationStudyScreen(page: page)),
    );
    await _load();
  }

  Future<void> _openTodaySession() async {
    final todayPlan = _todayPlan;
    if (todayPlan == null || todayPlan.studyPages.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MemorizationTodaySessionScreen(plan: todayPlan),
      ),
    );
    await _load();
  }

  Future<void> _openMap() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MemorizationMapScreen()),
    );
    await _load();
  }

  Future<void> _openTarget() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MemorizationTargetScreen()),
    );
    await _load();
  }

  Future<void> _openRecallTest() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MemorizationRecallTestScreen()),
    );
    await _load();
  }

  Future<void> _openWeakVerses() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MemorizationWeakVersesScreen()),
    );
    await _load();
  }

  Future<void> _openWeeklyReview() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const MemorizationWeeklyReviewScreen(),
      ),
    );
    await _load();
  }

  Future<void> _openJuzReview() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const MemorizationJuzReviewScreen(),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final snapshot = _snapshot;

    if (snapshot == null) {
      return const Padding(
        padding: EdgeInsets.all(36),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final targetPages = memorizationPagesForTarget(_target);
    final targetMemorizedCount = memorizedPageCountForTarget(
      _target,
      snapshot.memorizedPages,
    );
    final nextPage = nextMemorizationPageForTarget(
      _target,
      snapshot.memorizedPages,
    );
    final todayPlan = _todayPlan;
    final scheduledNextPage = todayPlan == null
        ? nextPage
        : todayPlan.newPages.isEmpty
            ? null
            : todayPlan.newPages.first;
    final todayProgramBadge = todayPlan == null
        ? null
        : todayPlan.isNewLoadReduced
            ? '${todayPlan.newPageCount}/${todayPlan.baseNewPageCount}'
            : '${todayPlan.newPageCount}';
    final progress = targetPages.isEmpty
        ? 0.0
        : targetMemorizedCount / targetPages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF315348), Color(0xFF182B25)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.route_rounded, color: Colors.white, size: 34),
              const SizedBox(height: 16),
              Text(
                l10n.memorizeTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.memorizeWelcomeBody,
                style: const TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$targetMemorizedCount / ${targetPages.length} ${l10n.memorizePages}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _OverviewActionCard(
          icon: Icons.flag_outlined,
          title: memorizationTargetLabel(context, _target),
          body: l10n.memorizeProgress,
          badge: '$targetMemorizedCount/${targetPages.length}',
          onTap: _openTarget,
        ),
        const SizedBox(height: 14),
        _StartGuideCard(
          onTap: todayPlan == null || todayPlan.studyPages.isEmpty
              ? null
              : _openTodaySession,
          steps: [
            _StartGuideStep(
              icon: Icons.today_outlined,
              label: l10n.memorizeTodayProgram,
              badge: todayProgramBadge,
            ),
            _StartGuideStep(
              icon: Icons.menu_book_outlined,
              label: l10n.memorizeNextPage,
              badge: scheduledNextPage == null ? null : '$scheduledNextPage',
            ),
            _StartGuideStep(
              icon: Icons.replay_rounded,
              label: l10n.memorizeTodayReview,
              badge: todayPlan == null ? null : '${todayPlan.reviewPages.length}',
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.check_circle_outline_rounded,
                value: '$targetMemorizedCount',
                label: l10n.memorizeProgress,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.local_fire_department_outlined,
                value: '${snapshot.practiceStreak}',
                label: l10n.memorizeStreak,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (scheduledNextPage != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.menu_book_rounded, color: scheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.memorizeNextPage,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$scheduledNextPage',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => _openPage(scheduledNextPage),
                  child: Text(l10n.memorizeOpenNext),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _OverviewActionCard(
          icon: Icons.event_repeat_rounded,
          title: l10n.memorizeWeeklyTitle,
          body: l10n.memorizeWeeklyBody,
          badge: '$_weeklyPageCount',
          onTap: _openWeeklyReview,
        ),
        const SizedBox(height: 12),
        _OverviewActionCard(
          icon: Icons.workspace_premium_outlined,
          title: '${l10n.memorizeJuz} · ${l10n.memorizeTestTitle}',
          body: l10n.memorizeTestBody,
          badge: '$_completedJuzCount',
          onTap: _openJuzReview,
        ),
        const SizedBox(height: 12),
        _OverviewActionCard(
          icon: Icons.casino_outlined,
          title: l10n.memorizeTestTitle,
          body: l10n.memorizeTestBody,
          onTap: _openRecallTest,
        ),
        const SizedBox(height: 12),
        _OverviewActionCard(
          icon: Icons.psychology_alt_outlined,
          title: l10n.memorizeWeakTitle,
          body: l10n.memorizeWeakBody,
          badge: '$_weakVerseCount',
          onTap: _openWeakVerses,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _openMap,
          icon: const Icon(Icons.grid_view_rounded),
          label: Text(l10n.memorizeOpenMap),
        ),
      ],
    );
  }
}

class _StartGuideStep {
  const _StartGuideStep({
    required this.icon,
    required this.label,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String? badge;
}

class _StartGuideCard extends StatelessWidget {
  const _StartGuideCard({required this.steps, this.onTap});

  final List<_StartGuideStep> steps;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .55),
            ),
          ),
          child: Column(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        steps[index].icon,
                        color: scheme.primary,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        steps[index].label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (steps[index].badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          steps[index].badge!,
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (index != steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: .55),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewActionCard extends StatelessWidget {
  const _OverviewActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
