import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DhikrCounterScreen extends StatefulWidget {
  const DhikrCounterScreen({super.key});

  @override
  State<DhikrCounterScreen> createState() => _DhikrCounterScreenState();
}

class _DhikrCounterScreenState extends State<DhikrCounterScreen> {
  static const _countKey = 'dhikr_count';
  static const _targetKey = 'dhikr_target';
  static const _labelKey = 'dhikr_label';
  static const _dailyTotalKey = 'dhikr_daily_total';
  static const _dailyDateKey = 'dhikr_daily_date';

  int _count = 0;
  int _target = 33;
  int _dailyTotal = 0;
  String _label = 'Sübhanallah';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDay = prefs.getString(_dailyDateKey);
    final dailyTotal = storedDay == today ? prefs.getInt(_dailyTotalKey) ?? 0 : 0;
    if (storedDay != today) {
      await prefs.setString(_dailyDateKey, today);
      await prefs.setInt(_dailyTotalKey, 0);
    }
    if (!mounted) return;
    setState(() {
      _count = prefs.getInt(_countKey) ?? 0;
      _target = prefs.getInt(_targetKey) ?? 33;
      _label = prefs.getString(_labelKey) ?? 'Sübhanallah';
      _dailyTotal = dailyTotal;
    });
  }

  Future<void> _increment() async {
    final next = _count + 1;
    final hitTarget = _target > 0 && next % _target == 0;
    setState(() {
      _count = next;
      _dailyTotal++;
    });
    if (hitTarget) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, _count);
    await prefs.setInt(_dailyTotalKey, _dailyTotal);
    await prefs.setString(_dailyDateKey, _todayKey());
  }

  Future<void> _setTarget(int target) async {
    setState(() => _target = target);
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetKey, target);
  }

  Future<void> _setLabel(String label) async {
    setState(() {
      _label = label;
      _count = 0;
    });
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_labelKey, label);
    await prefs.setInt(_countKey, 0);
  }

  Future<void> _reset() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sayacı sıfırla?'),
        content: const Text('Bugünkü toplam korunur, yalnızca mevcut sayaç sıfırlanır.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => _count = 0);
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, 0);
  }

  Future<void> _customTarget() async {
    final controller = TextEditingController(text: '$_target');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Özel hedef'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Örn. 100'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed < 1 || parsed > 9999) return;
              Navigator.pop(context, parsed);
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await _setTarget(value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = _target <= 0 ? 0.0 : (_count % _target) / _target;
    final cycleValue = _target <= 0 ? _count : _count % _target;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zikirmatik'),
        actions: [
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Sayacı sıfırla',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
        children: [
          Text(
            'Zikir',
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
              for (final label in const [
                'Sübhanallah',
                'Elhamdülillah',
                'Allahu Ekber',
                'Salavat',
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _label == label,
                  onSelected: (_) => _setLabel(label),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Text(
                  _label,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
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
                  'Hedef $_target · Toplam $_count',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 210,
            child: Material(
              color: scheme.primaryContainer,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _increment,
                customBorder: const CircleBorder(),
                child: Center(
                  child: Icon(
                    Icons.touch_app_rounded,
                    size: 64,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _TargetButton(
                  label: '33',
                  selected: _target == 33,
                  onTap: () => _setTarget(33),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TargetButton(
                  label: '99',
                  selected: _target == 99,
                  onTap: () => _setTarget(99),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TargetButton(
                  label: _target != 33 && _target != 99 ? '$_target' : 'Özel',
                  selected: _target != 33 && _target != 99,
                  onTap: _customTarget,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.today_outlined, color: scheme.primary),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Bugünkü toplam: $_dailyTotal',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
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
