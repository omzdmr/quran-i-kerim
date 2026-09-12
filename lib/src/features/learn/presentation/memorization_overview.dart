import 'package:flutter/material.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_progress_store.dart';
import 'memorization_dashboard_panel.dart';
import 'memorization_map_screen.dart';
import 'memorization_study_screen.dart';

class MemorizationOverview extends StatefulWidget {
  const MemorizationOverview({super.key});

  @override
  State<MemorizationOverview> createState() => _MemorizationOverviewState();
}

class _MemorizationOverviewState extends State<MemorizationOverview> {
  static const _store = MemorizationProgressStore();
  MemorizationProgressSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snapshot = await _store.load();
    if (!mounted) return;
    setState(() => _snapshot = snapshot);
  }

  Future<void> _openPage(int page) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MemorizationStudyScreen(page: page),
      ),
    );
    await _load();
  }

  Future<void> _openMap() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const MemorizationMapScreen()),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final snapshot = _snapshot;

    if (snapshot == null) {
      return const Padding(
        padding: EdgeInsets.all(36),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final nextPage = snapshot.nextPage;
    final today = DateTime.now();
    final month = today.month.toString().padLeft(2, '0');
    final day = today.day.toString().padLeft(2, '0');
    final todayKey = '${today.year}-$month-$day';
    final practicedToday = snapshot.practiceDays.contains(todayKey);

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
            ],
          ),
        ),
        const SizedBox(height: 14),
        MemorizationDashboardPanel(
          data: MemorizationDashboardData(
            completedPages: snapshot.memorizedCount,
            totalPages: 604,
            streakDays: snapshot.practiceStreak,
            reviewPages: 0,
            todayCompleted: practicedToday ? 1 : 0,
            todayTarget: 1,
            nextReference: nextPage == null
                ? null
                : '${l10n.quranProgressCurrentPage} $nextPage',
          ),
          labels: MemorizationDashboardLabels(
            todayProgram: l10n.memorizeTodayProgram,
            currentPlace: l10n.memorizeCurrentPlace,
            progress: l10n.memorizeProgress,
            streak: l10n.memorizeStreak,
            todayReview: l10n.memorizeTodayReview,
            next: l10n.memorizeNextPage,
            openMap: l10n.memorizeOpenMap,
            continueLabel: l10n.memorizeOpenNext,
            reviewLabel: l10n.memorizeReview,
          ),
          onOpenMap: _openMap,
          onContinue: nextPage == null ? null : () => _openPage(nextPage),
          onReview: null,
        ),
      ],
    );
  }
}
