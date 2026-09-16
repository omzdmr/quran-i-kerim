import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../navigation/app_navigation.dart';
import '../plans/reading_plan_store.dart';

class ProfileReadingPlanCard extends StatefulWidget {
  const ProfileReadingPlanCard({super.key});

  @override
  State<ProfileReadingPlanCard> createState() => _ProfileReadingPlanCardState();
}

class _ProfileReadingPlanCardState extends State<ProfileReadingPlanCard> {
  final ReadingPlanStore _store = const ReadingPlanStore();

  ReadingPlanSnapshot _snapshot = const ReadingPlanSnapshot();
  int _loadGeneration = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ReadingPlanStore.changes.addListener(_handleChanged);
    _load();
  }

  @override
  void dispose() {
    ReadingPlanStore.changes.removeListener(_handleChanged);
    super.dispose();
  }

  void _handleChanged() {
    _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final snapshot = await _store.load();
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  void _openPlans() {
    HapticFeedback.selectionClick();
    AppNavigation.instance.openPlans();
  }

  @override
  Widget build(BuildContext context) {
    final active = _snapshot.active;
    if (_loading || active == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final total = active.preset.durationDays;
    final completed = active.completedPrefixDays;
    final schedule = active.scheduleStatus(DateTime.now());
    final scheduleText = active.isPaused
        ? l10n.text('plansPausedV1')
        : schedule.isBehind
        ? l10n
              .text('plansScheduleBehindV1')
              .replaceAll('{count}', '${schedule.behindByDays}')
        : schedule.isAhead
        ? l10n
              .text('plansScheduleAheadV1')
              .replaceAll('{count}', '${schedule.aheadByDays}')
        : l10n.text('plansScheduleOnTrackV1');
    final progressText = l10n
        .text('plansProgressV1')
        .replaceAll('{done}', '$completed')
        .replaceAll('{total}', '$total');

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: _openPlans,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.route_rounded, color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.text('myPlans'),
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.text(active.preset.titleKey),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(value: active.progress.clamp(0, 1)),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        progressText,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      scheduleText,
                      style: TextStyle(
                        color: active.isPaused
                            ? scheme.primary
                            : schedule.isBehind
                            ? scheme.error
                            : scheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
