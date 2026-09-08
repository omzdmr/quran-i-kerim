import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

class DhikrCounterScreen extends StatefulWidget {
  const DhikrCounterScreen({super.key});

  @override
  State<DhikrCounterScreen> createState() => _DhikrCounterScreenState();
}

class _DhikrCounterScreenState extends State<DhikrCounterScreen> {
  static const _selectedKey = 'dhikr_v2_selected';
  static const _countsKey = 'dhikr_v2_counts';
  static const _targetsKey = 'dhikr_v2_targets';
  static const _customKey = 'dhikr_v2_custom';
  static const _dailyCountsKey = 'dhikr_v2_daily_counts';
  static const _dailyDateKey = 'dhikr_v2_daily_date';

  // Legacy keys are read once for a graceful migration from early test builds.
  static const _legacyCountKey = 'dhikr_count';
  static const _legacyTargetKey = 'dhikr_target';
  static const _legacyLabelKey = 'dhikr_label';
  static const _legacyDailyTotalKey = 'dhikr_daily_total';
  static const _legacyDailyDateKey = 'dhikr_daily_date';

  static const _builtIns = <_DhikrEntry>[
    _DhikrEntry(id: 'subhanallah', label: 'SubhanAllah'),
    _DhikrEntry(id: 'alhamdulillah', label: 'Alhamdulillah'),
    _DhikrEntry(id: 'allahu_akbar', label: 'Allahu Akbar'),
    _DhikrEntry(id: 'salawat', label: 'Salawat'),
  ];

  static const _builtInLabels = <String, Map<String, String>>{
    'subhanallah': {
      'tr': 'Sübhanallah',
      'en': 'SubhanAllah',
      'ar': 'سبحان الله',
      'az': 'Sübhanallah',
      'ru': 'Субханаллах',
    },
    'alhamdulillah': {
      'tr': 'Elhamdülillah',
      'en': 'Alhamdulillah',
      'ar': 'الحمد لله',
      'az': 'Əlhəmdülillah',
      'ru': 'Альхамдулиллях',
    },
    'allahu_akbar': {
      'tr': 'Allahu Ekber',
      'en': 'Allahu Akbar',
      'ar': 'الله أكبر',
      'az': 'Allahu Əkbər',
      'ru': 'Аллаху Акбар',
    },
    'salawat': {
      'tr': 'Salavat',
      'en': 'Salawat',
      'ar': 'الصلاة على النبي',
      'az': 'Salavat',
      'ru': 'Салават',
    },
  };

  String _selectedId = _builtIns.first.id;
  Map<String, int> _counts = <String, int>{};
  Map<String, int> _targets = <String, int>{
    for (final entry in _builtIns) entry.id: 33,
  };
  Map<String, int> _dailyCounts = <String, int>{};
  List<_DhikrEntry> _customEntries = <_DhikrEntry>[];
  String? _lastIncrementedId;

  List<_DhikrEntry> get _entries => <_DhikrEntry>[
        ..._builtIns,
        ..._customEntries,
      ];

  _DhikrEntry get _selectedEntry => _entries.firstWhere(
        (entry) => entry.id == _selectedId,
        orElse: () => _builtIns.first,
      );

  int get _count => _counts[_selectedId] ?? 0;
  int get _target => _targets[_selectedId] ?? 33;
  int get _todayTotal =>
      _dailyCounts.values.fold<int>(0, (sum, value) => sum + value);

  @override
  void initState() {
    super.initState();
    _restore();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _displayLabel(_DhikrEntry entry, [String? languageCode]) {
    if (entry.custom) return entry.label;
    final language = languageCode ?? Localizations.localeOf(context).languageCode;
    return _builtInLabels[entry.id]?[language] ??
        _builtInLabels[entry.id]?['en'] ??
        entry.label;
  }

  _DhikrEntry? _entryById(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  Map<String, int> _decodeIntMap(String? raw) {
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};
      return decoded.map<String, int>((key, value) {
        final parsed = value is int ? value : int.tryParse('$value') ?? 0;
        return MapEntry('$key', parsed < 0 ? 0 : parsed);
      });
    } catch (_) {
      return <String, int>{};
    }
  }

  List<_DhikrEntry> _decodeCustom(String? raw) {
    if (raw == null || raw.isEmpty) return <_DhikrEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <_DhikrEntry>[];
      return decoded
          .whereType<Map>()
          .map((item) {
            final id = '${item['id'] ?? ''}'.trim();
            final label = '${item['label'] ?? ''}'.trim();
            if (id.isEmpty || label.isEmpty) return null;
            return _DhikrEntry(id: id, label: label, custom: true);
          })
          .whereType<_DhikrEntry>()
          .toList(growable: false);
    } catch (_) {
      return <_DhikrEntry>[];
    }
  }

  String? _idForLegacyLabel(String? label, [List<_DhikrEntry>? custom]) {
    if (label == null || label.trim().isEmpty) return null;
    final normalized = label.trim().toLowerCase();
    for (final entry in _builtIns) {
      if (entry.label.toLowerCase() == normalized) return entry.id;
      for (final translated in _builtInLabels[entry.id]?.values ?? const <String>[]) {
        if (translated.toLowerCase() == normalized) return entry.id;
      }
    }
    for (final entry in custom ?? _customEntries) {
      if (entry.label.toLowerCase() == normalized) return entry.id;
    }
    return null;
  }

  Map<String, int> _migrateDailyKeys(
    Map<String, int> raw,
    List<_DhikrEntry> custom,
  ) {
    final migrated = <String, int>{};
    for (final entry in raw.entries) {
      final stableId = _builtIns.any((item) => item.id == entry.key) ||
              custom.any((item) => item.id == entry.key)
          ? entry.key
          : _idForLegacyLabel(entry.key, custom);
      if (stableId == null) continue;
      migrated[stableId] = (migrated[stableId] ?? 0) + entry.value;
    }
    return migrated;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    final custom = _decodeCustom(prefs.getString(_customKey));
    final counts = _decodeIntMap(prefs.getString(_countsKey));
    final targets = _decodeIntMap(prefs.getString(_targetsKey));
    var selected = prefs.getString(_selectedKey);

    if (selected == null) {
      final legacyLabel = prefs.getString(_legacyLabelKey);
      final migratedId = _idForLegacyLabel(legacyLabel, custom);
      if (migratedId != null) {
        selected = migratedId;
        final oldCount = prefs.getInt(_legacyCountKey) ?? 0;
        final oldTarget = prefs.getInt(_legacyTargetKey) ?? 33;
        if (oldCount > 0) counts[migratedId] = oldCount;
        if (oldTarget > 0) targets[migratedId] = oldTarget;
      }
    }

    for (final entry in _builtIns) {
      targets.putIfAbsent(entry.id, () => 33);
    }
    for (final entry in custom) {
      targets.putIfAbsent(entry.id, () => 0);
    }

    final storedDailyDate = prefs.getString(_dailyDateKey);
    Map<String, int> daily;
    if (storedDailyDate == today) {
      daily = _migrateDailyKeys(
        _decodeIntMap(prefs.getString(_dailyCountsKey)),
        custom,
      );
    } else {
      daily = <String, int>{};
      final legacyDay = prefs.getString(_legacyDailyDateKey);
      final legacyTotal = prefs.getInt(_legacyDailyTotalKey) ?? 0;
      if (legacyDay == today && legacyTotal > 0) {
        final legacyId = selected ?? _builtIns.first.id;
        daily[legacyId] = legacyTotal;
      }
      await prefs.setString(_dailyDateKey, today);
    }
    await prefs.setString(_dailyCountsKey, jsonEncode(daily));

    final validIds = <String>{
      for (final entry in _builtIns) entry.id,
      for (final entry in custom) entry.id,
    };
    if (selected == null || !validIds.contains(selected)) {
      selected = _builtIns.first.id;
    }

    if (!mounted) return;
    setState(() {
      _customEntries = custom;
      _counts = counts;
      _targets = targets;
      _dailyCounts = daily;
      _selectedId = selected!;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_selectedKey, _selectedId),
      prefs.setString(_countsKey, jsonEncode(_counts)),
      prefs.setString(_targetsKey, jsonEncode(_targets)),
      prefs.setString(
        _customKey,
        jsonEncode([
          for (final entry in _customEntries)
            <String, String>{'id': entry.id, 'label': entry.label},
        ]),
      ),
      prefs.setString(_dailyCountsKey, jsonEncode(_dailyCounts)),
      prefs.setString(_dailyDateKey, _todayKey()),
    ]);
  }

  Future<void> _select(String id) async {
    if (_selectedId == id) return;
    setState(() {
      _selectedId = id;
      _lastIncrementedId = null;
    });
    HapticFeedback.selectionClick();
    await _persist();
  }

  Future<void> _increment() async {
    final entry = _selectedEntry;
    final next = _count + 1;
    final target = _target;
    final hitTarget = target > 0 && next % target == 0;
    setState(() {
      _counts[entry.id] = next;
      _dailyCounts[entry.id] = (_dailyCounts[entry.id] ?? 0) + 1;
      _lastIncrementedId = entry.id;
    });
    if (hitTarget) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    await _persist();
  }

  Future<void> _undo() async {
    if (_lastIncrementedId != _selectedId || _count <= 0) return;
    final entry = _selectedEntry;
    setState(() {
      _counts[entry.id] = _count - 1;
      final daily = _dailyCounts[entry.id] ?? 0;
      if (daily <= 1) {
        _dailyCounts.remove(entry.id);
      } else {
        _dailyCounts[entry.id] = daily - 1;
      }
      _lastIncrementedId = null;
    });
    HapticFeedback.lightImpact();
    await _persist();
  }

  Future<void> _setTarget(int target) async {
    setState(() => _targets[_selectedId] = target.clamp(0, 9999));
    HapticFeedback.selectionClick();
    await _persist();
  }

  Future<void> _reset() async {
    final l10n = context.l10n;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.text('resetCounterTitle')),
        content: Text(l10n.text('resetCounterBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.text('reset')),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() {
      _counts[_selectedId] = 0;
      _lastIncrementedId = null;
    });
    HapticFeedback.lightImpact();
    await _persist();
  }

  Future<void> _customTarget() async {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: _target > 0 ? '$_target' : '',
    );
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.text('customTarget')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: l10n.text('example100')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.text('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final raw = controller.text.trim();
              final parsed = raw.isEmpty ? 0 : int.tryParse(raw);
              if (parsed == null || parsed < 0 || parsed > 9999) return;
              Navigator.pop(context, parsed);
            },
            child: Text(l10n.text('apply')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await _setTarget(value);
  }

  Future<void> _addCustomDhikr() async {
    final l10n = context.l10n;
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final result = await showDialog<(String, int)?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.text('addDhikr')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              maxLength: 50,
              decoration: InputDecoration(labelText: l10n.text('dhikrName')),
            ),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.text('optionalTarget'),
                hintText: l10n.text('example100'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.text('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final duplicate = _entries.any(
                (entry) => _displayLabel(entry).toLowerCase() == name.toLowerCase(),
              );
              if (duplicate) return;
              final rawTarget = targetController.text.trim();
              final target = rawTarget.isEmpty ? 0 : int.tryParse(rawTarget);
              if (target == null || target < 0 || target > 9999) return;
              Navigator.pop(dialogContext, (name, target));
            },
            child: Text(l10n.text('add')),
          ),
        ],
      ),
    );
    nameController.dispose();
    targetController.dispose();
    if (result == null || !mounted) return;

    final entry = _DhikrEntry(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      label: result.$1,
      custom: true,
    );
    setState(() {
      _customEntries = <_DhikrEntry>[..._customEntries, entry];
      _targets[entry.id] = result.$2;
      _counts[entry.id] = 0;
      _selectedId = entry.id;
      _lastIncrementedId = null;
    });
    HapticFeedback.lightImpact();
    await _persist();
  }

  Future<void> _removeSelectedCustom() async {
    final entry = _selectedEntry;
    if (!entry.custom) return;
    setState(() {
      _customEntries = _customEntries
          .where((item) => item.id != entry.id)
          .toList(growable: false);
      _counts.remove(entry.id);
      _targets.remove(entry.id);
      _dailyCounts.remove(entry.id);
      _selectedId = _builtIns.first.id;
      _lastIncrementedId = null;
    });
    HapticFeedback.lightImpact();
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final target = _target;
    final progress = target <= 0 ? null : (_count % target) / target;
    final cycleValue = target <= 0 ? _count : _count % target;
    final dailyItems = _dailyCounts.entries
        .where((entry) => entry.value > 0 && _entryById(entry.key) != null)
        .toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('dhikrCounter')),
        actions: [
          IconButton(
            onPressed: _lastIncrementedId == _selectedId ? _undo : null,
            icon: const Icon(Icons.undo_rounded),
            tooltip: l10n.text('undo'),
          ),
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: l10n.text('resetCounter'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
        children: [
          Text(
            l10n.text('dhikr'),
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _entries)
                ChoiceChip(
                  label: Text(_displayLabel(entry)),
                  selected: _selectedId == entry.id,
                  onSelected: (_) => _select(entry.id),
                ),
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.text('addDhikr')),
                onPressed: _addCustomDhikr,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    Expanded(
                      flex: 5,
                      child: Text(
                        _displayLabel(_selectedEntry),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _selectedEntry.custom
                          ? IconButton(
                              onPressed: _removeSelectedCustom,
                              icon: const Icon(Icons.delete_outline_rounded),
                              tooltip: l10n.text('removeDhikr'),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$cycleValue',
                  style: const TextStyle(
                    fontSize: 74,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -3,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  target <= 0
                      ? '${l10n.text('total')} $_count'
                      : '${l10n.text('target')} $target · ${l10n.text('total')} $_count',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 210,
            child: _CounterButton(onPressed: _increment),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _TargetButton(
                  label: '33',
                  selected: target == 33,
                  onTap: () => _setTarget(33),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TargetButton(
                  label: '99',
                  selected: target == 99,
                  onTap: () => _setTarget(99),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TargetButton(
                  label: target != 33 && target != 99 && target > 0
                      ? '$target'
                      : l10n.text('custom'),
                  selected: target != 33 && target != 99,
                  onTap: _customTarget,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.text('todayBreakdown'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                '${l10n.text('todayTotal')}: $_todayTotal',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (dailyItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.text('noDhikrToday'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < dailyItems.length; index++) ...[
                    ListTile(
                      leading: Icon(
                        Icons.radio_button_checked_rounded,
                        color: scheme.primary,
                        size: 18,
                      ),
                      title: Text(
                        _displayLabel(_entryById(dailyItems[index].key)!),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      trailing: Text(
                        '${dailyItems[index].value}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (index != dailyItems.length - 1)
                      const Divider(height: 1, indent: 52),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DhikrEntry {
  const _DhikrEntry({
    required this.id,
    required this.label,
    this.custom = false,
  });

  final String id;
  final String label;
  final bool custom;
}

class _CounterButton extends StatefulWidget {
  const _CounterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<_CounterButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? .955 : 1,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 105),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pressed
                ? scheme.primary.withValues(alpha: .24)
                : scheme.primaryContainer,
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: _pressed ? .10 : .16),
                blurRadius: _pressed ? 8 : 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: AnimatedScale(
              scale: _pressed ? .9 : 1,
              duration: const Duration(milliseconds: 90),
              child: Icon(
                Icons.touch_app_rounded,
                size: 64,
                color: scheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetButton extends StatelessWidget {
  const _TargetButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? scheme.primary : scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
