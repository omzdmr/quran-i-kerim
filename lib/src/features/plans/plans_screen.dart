import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../navigation/app_navigation.dart';
import '../reader/reader_navigation.dart';
import 'reading_plan.dart';
import 'reading_plan_recovery_coordinator.dart';
import 'reading_plan_recovery_destination.dart';
import 'reading_plan_store.dart';

enum _PlansTab { mine, find, saved, completed }

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  static const _presets = ReadingPlanPreset.values;

  final ReadingPlanStore _store = const ReadingPlanStore();
  final ReadingPlanRecoveryCoordinator _recoveryCoordinator =
      const ReadingPlanRecoveryCoordinator();
  final TextEditingController _searchController = TextEditingController();

  ReadingPlanSnapshot _snapshot = const ReadingPlanSnapshot();
  ReadingPlanRecoveryDestination? _recoveryDestination;
  _PlansTab _tab = _PlansTab.find;
  bool _loading = true;
  bool _busy = false;
  bool _searching = false;
  int _completedYearFilter = 0;

  @override
  void initState() {
    super.initState();
    ReadingPlanStore.changes.addListener(_handleStoreChanged);
    _load();
  }

  @override
  void dispose() {
    ReadingPlanStore.changes.removeListener(_handleStoreChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleStoreChanged() {
    _load(selectActiveTab: false);
  }

  Future<void> _load({bool selectActiveTab = true}) async {
    final snapshot = await _store.load();
    final recovery = snapshot.active == null
        ? null
        : await _recoveryCoordinator.currentDestination();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _recoveryDestination = recovery;
      _loading = false;
      if (selectActiveTab && snapshot.active != null) _tab = _PlansTab.mine;
    });
  }

  Future<void> _start(ReadingPlanPreset preset) async {
    if (_busy) return;
    final active = _snapshot.active;
    if (active?.preset == preset) {
      setState(() => _tab = _PlansTab.mine);
      return;
    }

    if (active != null) {
      final confirmed = await _confirm(
        titleKey: 'plansReplaceTitleV1',
        bodyKey: 'plansReplaceBodyV1',
        actionKey: 'start',
      );
      if (!confirmed || !mounted) return;
    }

    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    try {
      final snapshot = await _store.start(preset);
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _tab = _PlansTab.mine;
      });
      _snack('plansStartedV1');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleSaved(ReadingPlanPreset preset) async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    try {
      final snapshot = await _store.toggleSaved(preset);
      if (mounted) setState(() => _snapshot = snapshot);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    if (_busy || _snapshot.active == null) return;
    final confirmed = await _confirm(
      titleKey: 'plansStopTitleV1',
      bodyKey: 'plansStopBodyV1',
      actionKey: 'plansStopV1',
    );
    if (!confirmed || !mounted) return;

    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    try {
      final snapshot = await _store.stopActive();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _tab = _PlansTab.find;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePause() async {
    final active = _snapshot.active;
    if (_busy || active == null) return;
    final wasPaused = active.isPaused;
    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    try {
      final snapshot = wasPaused
          ? await _store.resumeActive()
          : await _store.pauseActive();
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
      _snack(wasPaused ? 'plansResumedV1' : 'plansPausedV1');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeNextDay() async {
    final active = _snapshot.active;
    if (_busy || active?.nextDay == null || active!.isPaused) return;
    final now = DateTime.now();
    final schedule = active.scheduleStatus(now);
    final catchUp = schedule.isBehind ? active.catchUpTarget(now) : null;
    final completeThroughDay = catchUp?.lastDayNumber;
    final finishing = (completeThroughDay ?? active.completedPrefixDays + 1) >=
        active.preset.durationDays;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final snapshot = completeThroughDay == null
          ? await _store.completeNextDay(now: now)
          : await _store.completeThroughDay(completeThroughDay, now: now);
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        if (snapshot.active == null) _tab = _PlansTab.completed;
      });
      _snack(finishing ? 'plansPlanCompletedV1' : 'plansMarkDoneV1');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openNextDay() {
    final recovery = _recoveryDestination;
    if (recovery != null) {
      HapticFeedback.selectionClick();
      AppNavigation.instance.openReader(
        surah: recovery.surah,
        ayah: recovery.ayah,
      );
      return;
    }

    final day = _snapshot.active?.nextDay;
    if (day == null) return;
    final target = firstVerseForPage(day.startPage);
    if (target == null) return;
    HapticFeedback.selectionClick();
    AppNavigation.instance.openReader(surah: target.surah, ayah: target.ayah);
  }

  Future<void> _removeCompleted(CompletedReadingPlan item) async {
    if (_busy) return;
    final index = _snapshot.completed.indexOf(item);
    if (index < 0) return;
    final confirmed = await _confirm(
      titleKey: 'plansArchiveDeleteTitleV1',
      bodyKey: 'plansArchiveDeleteBodyV1',
      actionKey: 'plansArchiveDeleteActionV1',
    );
    if (!confirmed || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final snapshot = await _store.removeCompletedAt(index);
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editYearlyKhatmTarget() async {
    if (_busy) return;
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: _snapshot.yearlyKhatmTarget?.toString() ?? '',
    );
    var parsedTarget = _snapshot.yearlyKhatmTarget;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final valid = parsedTarget != null &&
              parsedTarget! >= 1 &&
              parsedTarget! <= 99;
          return AlertDialog(
            title: Text(l10n.text('plansYearlyKhatmEditTitleV1')),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: InputDecoration(
                labelText: l10n.text('plansYearlyKhatmTargetFieldV1'),
                helperText: l10n.text('plansYearlyKhatmTargetHelperV1'),
              ),
              onChanged: (value) {
                setDialogState(() => parsedTarget = int.tryParse(value));
              },
              onSubmitted: (_) {
                if (valid) Navigator.of(dialogContext).pop(parsedTarget);
              },
            ),
            actions: [
              if (_snapshot.yearlyKhatmTarget != null)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(0),
                  child: Text(l10n.text('plansYearlyKhatmClearTargetV1')),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                ),
              ),
              FilledButton(
                onPressed: valid
                    ? () => Navigator.of(dialogContext).pop(parsedTarget)
                    : null,
                child: Text(l10n.text('plansYearlyKhatmSaveTargetV1')),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (!mounted || result == null) return;

    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    try {
      final snapshot = await _store.setYearlyKhatmTarget(
        result == 0 ? null : result,
      );
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm({
    required String titleKey,
    required String bodyKey,
    required String actionKey,
  }) async {
    final l10n = context.l10n;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.text(titleKey)),
            content: Text(l10n.text(bodyKey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.text(actionKey)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.text(key))),
    );
  }

  List<ReadingPlanPreset> _filteredPresets({bool savedOnly = false}) {
    final query = _searchController.text.trim().toLowerCase();
    final l10n = context.l10n;
    return <ReadingPlanPreset>[
      for (final preset in _presets)
        if ((!savedOnly || _snapshot.savedPresetIds.contains(preset.id)) &&
            (query.isEmpty ||
                l10n.text(preset.titleKey).toLowerCase().contains(query) ||
                l10n.text(preset.durationKey).toLowerCase().contains(query)))
          preset,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: _searching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: l10n.text('plansSearchHintV1'),
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searching = false);
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      )
                    : Text(
                        l10n.text('readingPlans'),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
              ),
              if (!_searching)
                IconButton.filledTonal(
                  onPressed: () => setState(() => _searching = true),
                  icon: const Icon(Icons.search_rounded),
                  tooltip: l10n.text('plansSearchHintV1'),
                ),
            ],
          ),
          const SizedBox(height: 22),
          _TabStrip(
            selected: _tab,
            onSelected: (value) => setState(() => _tab = value),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else
            _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return switch (_tab) {
      _PlansTab.mine => _buildMine(),
      _PlansTab.find => _buildPresetList(_filteredPresets()),
      _PlansTab.saved => _buildPresetList(
          _filteredPresets(savedOnly: true),
          emptyKey: 'plansEmptySavedV1',
        ),
      _PlansTab.completed => _buildCompleted(),
    };
  }

  Widget _buildMine() {
    final active = _snapshot.active;
    if (active == null) {
      return _EmptyState(
        icon: Icons.menu_book_outlined,
        text: context.l10n.text('plansEmptyActiveV1'),
        action: FilledButton(
          onPressed: () => setState(() => _tab = _PlansTab.find),
          child: Text(context.l10n.text('findPlans')),
        ),
      );
    }
    final now = DateTime.now();
    final schedule = active.scheduleStatus(now);
    final catchUpTarget = schedule.isBehind ? active.catchUpTarget(now) : null;
    return _ActivePlanCard(
      active: active,
      catchUpTarget: catchUpTarget,
      busy: _busy,
      onRead: _openNextDay,
      onComplete: _completeNextDay,
      onPauseResume: _togglePause,
      onStop: _stop,
    );
  }

  Widget _buildPresetList(
    List<ReadingPlanPreset> presets, {
    String? emptyKey,
  }) {
    if (presets.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        text: context.l10n.text(
          _searchController.text.trim().isNotEmpty
              ? 'plansNoResultsV1'
              : (emptyKey ?? 'plansNoResultsV1'),
        ),
      );
    }
    return Column(
      children: [
        for (final preset in presets) ...[
          _PresetCard(
            preset: preset,
            saved: _snapshot.savedPresetIds.contains(preset.id),
            active: _snapshot.active?.preset == preset,
            busy: _busy,
            onStart: () => _start(preset),
            onToggleSaved: () => _toggleSaved(preset),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildCompleted() {
    final year = DateTime.now().year;
    final completedThisYear = _snapshot.completedInYear(year);
    final target = _snapshot.yearlyKhatmTarget;
    final remaining = _snapshot.remainingForYear(year);
    final years = _snapshot.completed
        .map((item) => item.completedAt.year)
        .toSet()
        .toList(growable: false)
      ..sort((a, b) => b.compareTo(a));
    final filtered = _completedYearFilter == 0
        ? _snapshot.completed
        : _snapshot.completed
            .where((item) => item.completedAt.year == _completedYearFilter)
            .toList(growable: false);

    return Column(
      children: [
        _YearlyKhatmCard(
          year: year,
          completed: completedThisYear,
          target: target,
          remaining: remaining,
          busy: _busy,
          onEdit: _editYearlyKhatmTarget,
        ),
        const SizedBox(height: 16),
        if (_snapshot.completed.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.text('plansKhatmArchiveTitleV1'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              DropdownButton<int>(
                value: _completedYearFilter,
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _completedYearFilter = value);
                        }
                      },
                items: <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(
                    value: 0,
                    child: Text(context.l10n.text('plansArchiveAllYearsV1')),
                  ),
                  for (final archiveYear in years)
                    DropdownMenuItem<int>(
                      value: archiveYear,
                      child: Text('$archiveYear'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_snapshot.completed.isEmpty)
          _EmptyState(
            icon: Icons.task_alt_rounded,
            text: context.l10n.text('plansEmptyCompletedV1'),
          )
        else if (filtered.isEmpty)
          _EmptyState(
            icon: Icons.filter_alt_off_rounded,
            text: context.l10n.text('plansArchiveNoResultsV1'),
          )
        else
          for (final item in filtered) ...[
            _CompletedPlanCard(
              item: item,
              busy: _busy,
              onDelete: () => _removeCompleted(item),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.selected, required this.onSelected});

  final _PlansTab selected;
  final ValueChanged<_PlansTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = <_PlansTab, String>{
      _PlansTab.mine: l10n.text('myPlans'),
      _PlansTab.find: l10n.text('findPlans'),
      _PlansTab.saved: l10n.text('saved'),
      _PlansTab.completed: l10n.text('completed'),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in _PlansTab.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                selected: selected == tab,
                label: Text(labels[tab]!),
                onSelected: (_) => onSelected(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.saved,
    required this.active,
    required this.busy,
    required this.onStart,
    required this.onToggleSaved,
  });

  final ReadingPlanPreset preset;
  final bool saved;
  final bool active;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final firstDay = readingPlanDay(preset, 1);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${preset.durationDays}',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.text(preset.titleKey),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.text(preset.durationKey)} · '
                      '${l10n.text('plansPagesV1').replaceAll('{start}', '${firstDay.startPage}').replaceAll('{end}', '${firstDay.endPage}')} / ${l10n.today.toLowerCase()}',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: busy ? null : onToggleSaved,
                icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                tooltip: l10n.text(saved ? 'plansUnsaveV1' : 'plansSaveV1'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: active
                ? FilledButton.tonal(
                    onPressed: busy ? null : onStart,
                    child: Text(l10n.text('myPlans')),
                  )
                : FilledButton(
                    onPressed: busy ? null : onStart,
                    child: Text(l10n.text('start')),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({
    required this.active,
    required this.catchUpTarget,
    required this.busy,
    required this.onRead,
    required this.onComplete,
    required this.onPauseResume,
    required this.onStop,
  });

  final ActiveReadingPlan active;
  final ReadingPlanCatchUpTarget? catchUpTarget;
  final bool busy;
  final VoidCallback onRead;
  final VoidCallback onComplete;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final day = active.nextDay;
    final done = active.completedPrefixDays;
    final total = active.preset.durationDays;
    if (day == null) return const SizedBox.shrink();

    String value(String key) => l10n.text(key);
    final dayText = value('plansDayProgressV1')
        .replaceAll('{day}', '${day.dayNumber}')
        .replaceAll('{total}', '$total');
    final pagesText = value('plansPagesV1')
        .replaceAll('{start}', '${day.startPage}')
        .replaceAll('{end}', '${day.endPage}');
    final progressText = value('plansProgressV1')
        .replaceAll('{done}', '$done')
        .replaceAll('{total}', '$total');
    final schedule = active.scheduleStatus(DateTime.now());
    final scheduleText = active.isPaused
        ? value('plansPausedV1')
        : schedule.isBehind
            ? value('plansScheduleBehindV1').replaceAll(
                '{count}',
                '${schedule.behindByDays}',
              )
            : schedule.isAhead
                ? value('plansScheduleAheadV1').replaceAll(
                    '{count}',
                    '${schedule.aheadByDays}',
                  )
                : value('plansScheduleOnTrackV1');
    final scheduleDayText = value('plansScheduleDayV1')
        .replaceAll('{day}', '${schedule.calendarDayNumber}')
        .replaceAll('{total}', '$total');
    final scheduledEnd = MaterialLocalizations.of(context).formatMediumDate(
      schedule.scheduledEndDate,
    );
    final scheduledEndText = value('plansScheduledEndV1').replaceAll(
      '{date}',
      scheduledEnd,
    );
    final statusColor = active.isPaused
        ? scheme.secondary
        : schedule.isBehind
            ? scheme.error
            : scheme.primary;
    final statusIcon = active.isPaused
        ? Icons.pause_circle_outline_rounded
        : schedule.isBehind
            ? Icons.schedule_rounded
            : schedule.isAhead
                ? Icons.fast_forward_rounded
                : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text(active.preset.titleKey),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$dayText · $pagesText',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: .22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheduleText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$scheduleDayText · $scheduledEndText',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      if (active.isPaused) ...[
                        const SizedBox(height: 5),
                        Text(
                          value('plansPausedHintV1'),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (catchUpTarget?.spansMultipleDays ?? false) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value('plansRecoveryTitleV1'),
                    style: TextStyle(
                      color: scheme.onTertiaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value('plansRecoveryBodyV1')
                        .replaceAll('{days}', '${catchUpTarget!.dayCount}')
                        .replaceAll('{pages}', '${catchUpTarget!.pageCount}'),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          LinearProgressIndicator(value: active.progress.clamp(0, 1)),
          const SizedBox(height: 8),
          Text(
            progressText,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onRead,
              icon: const Icon(Icons.menu_book_rounded),
              label: Text(
                l10n.text(
                  (catchUpTarget?.spansMultipleDays ?? false)
                      ? 'plansRecoveryOpenV1'
                      : 'plansReadTodayV1',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: busy || active.isPaused ? null : onComplete,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                l10n.text(
                  (catchUpTarget?.spansMultipleDays ?? false)
                      ? 'plansRecoveryCompleteV1'
                      : 'plansMarkDoneV1',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onPauseResume,
              icon: Icon(
                active.isPaused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
              ),
              label: Text(
                l10n.text(
                  active.isPaused ? 'plansResumeV1' : 'plansPauseV1',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.center,
            child: TextButton(
              onPressed: busy ? null : onStop,
              child: Text(l10n.text('plansStopV1')),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearlyKhatmCard extends StatelessWidget {
  const _YearlyKhatmCard({
    required this.year,
    required this.completed,
    required this.target,
    required this.remaining,
    required this.busy,
    required this.onEdit,
  });

  final int year;
  final int completed;
  final int? target;
  final int remaining;
  final bool busy;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final targetValue = target;
    final title = l10n
        .text('plansYearlyKhatmTitleV1')
        .replaceAll('{year}', '$year');
    final body = targetValue == null
        ? l10n
            .text('plansYearlyKhatmNoTargetV1')
            .replaceAll('{done}', '$completed')
        : remaining > 0
            ? l10n
                .text('plansYearlyKhatmProgressV1')
                .replaceAll('{done}', '$completed')
                .replaceAll('{target}', '$targetValue')
                .replaceAll('{remaining}', '$remaining')
            : l10n
                .text('plansYearlyKhatmReachedV1')
                .replaceAll('{done}', '$completed')
                .replaceAll('{target}', '$targetValue');
    final progress = targetValue == null
        ? null
        : (completed / targetValue).clamp(0.0, 1.0).toDouble();

    return Semantics(
      container: true,
      label: '$title. $body',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_stories_rounded, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(body),
                      ],
                    ),
                  ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: 14),
                LinearProgressIndicator(value: progress),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(
                    l10n.text(
                      targetValue == null
                          ? 'plansYearlyKhatmSetTargetV1'
                          : 'plansYearlyKhatmEditTargetV1',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedPlanCard extends StatelessWidget {
  const _CompletedPlanCard({
    required this.item,
    required this.busy,
    required this.onDelete,
  });

  final CompletedReadingPlan item;
  final bool busy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final date = MaterialLocalizations.of(context).formatMediumDate(item.completedAt);
    final subtitle = l10n.text('plansCompletedOnV1').replaceAll('{date}', date);
    return ListTile(
      tileColor: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Icon(Icons.check_rounded, color: scheme.onPrimaryContainer),
      ),
      title: Text(
        l10n.text(item.preset.titleKey),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle),
      trailing: IconButton(
        onPressed: busy ? null : onDelete,
        tooltip: l10n.text('plansArchiveDeleteActionV1'),
        icon: const Icon(Icons.delete_outline_rounded),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          if (action != null) ...[
            const SizedBox(height: 18),
            action!,
          ],
        ],
      ),
    );
  }
}
