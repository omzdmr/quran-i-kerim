import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MemorizationDashboardData {
  const MemorizationDashboardData({
    required this.completedPages,
    required this.totalPages,
    required this.streakDays,
    required this.reviewPages,
    required this.todayCompleted,
    required this.todayTarget,
    this.currentReference,
    this.nextReference,
  });

  final int completedPages;
  final int totalPages;
  final int streakDays;
  final int reviewPages;
  final int todayCompleted;
  final int todayTarget;
  final String? currentReference;
  final String? nextReference;
}

class MemorizationDashboardLabels {
  const MemorizationDashboardLabels({
    required this.todayProgram,
    required this.currentPlace,
    required this.progress,
    required this.streak,
    required this.todayReview,
    required this.next,
    required this.openMap,
    required this.continueLabel,
    required this.reviewLabel,
  });

  final String todayProgram;
  final String currentPlace;
  final String progress;
  final String streak;
  final String todayReview;
  final String next;
  final String openMap;
  final String continueLabel;
  final String reviewLabel;
}

/// Compact memorisation dashboard matching the information hierarchy of the
/// supplied reference while remaining data-source agnostic.
class MemorizationDashboardPanel extends StatelessWidget {
  const MemorizationDashboardPanel({
    required this.data,
    required this.labels,
    required this.onOpenMap,
    super.key,
    this.onContinue,
    this.onReview,
  });

  final MemorizationDashboardData data;
  final MemorizationDashboardLabels labels;
  final VoidCallback onOpenMap;
  final VoidCallback? onContinue;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final total = data.totalPages <= 0 ? 1 : data.totalPages;
    final progress = (data.completedPages / total).clamp(0.0, 1.0).toDouble();
    final todayTarget = data.todayTarget <= 0 ? 1 : data.todayTarget;
    final todayProgress =
        (data.todayCompleted / todayTarget).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C785A), Color(0xFF0B3D35)],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labels.todayProgram,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${data.todayCompleted}/${data.todayTarget}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (data.nextReference != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${labels.next}: ${data.nextReference}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: todayProgress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                    Text(
                      '${(todayProgress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (data.currentReference != null) ...[
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.play_circle_outline_rounded,
            title: labels.currentPlace,
            value: data.currentReference!,
            buttonLabel: labels.continueLabel,
            onTap: onContinue,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.route_rounded,
                title: labels.progress,
                value: '${data.completedPages}/${data.totalPages}',
                progress: progress,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.local_fire_department_outlined,
                title: labels.streak,
                value: '${data.streakDays}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.replay_rounded,
          title: labels.todayReview,
          value: '${data.reviewPages}',
          buttonLabel: labels.reviewLabel,
          onTap: onReview,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            onOpenMap();
          },
          icon: const Icon(Icons.grid_view_rounded),
          label: Text(labels.openMap),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    this.progress,
  });

  final IconData icon;
  final String title;
  final String value;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
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
            title,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: progress, minHeight: 6),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.buttonLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String buttonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
