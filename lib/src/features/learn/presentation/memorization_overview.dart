import 'package:flutter/material.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../../../navigation/app_navigation.dart';
import '../application/memorization_page_catalog.dart';
import '../application/memorization_progress_store.dart';
import 'memorization_map_screen.dart';

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

  void _openPage(int page) {
    final info = memorizationPageInfo(page);
    if (info == null) return;
    AppNavigation.instance.openReader(surah: info.surah, ayah: info.ayah);
  }

  Future<void> _openMap() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MemorizationMapScreen()),
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

    final nextPage = snapshot.nextPage;
    final progress = snapshot.memorizedCount / 604;

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
                '${snapshot.memorizedCount} / 604 ${l10n.memorizePages}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.check_circle_outline_rounded,
                value: '${snapshot.memorizedCount}',
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
        if (nextPage != null)
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
                        '$nextPage',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => _openPage(nextPage),
                  child: Text(l10n.memorizeOpenNext),
                ),
              ],
            ),
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
