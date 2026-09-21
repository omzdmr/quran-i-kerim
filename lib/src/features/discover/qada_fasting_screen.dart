import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/strings/qada_fasting_strings.dart';
import 'qada_fasting_ledger.dart';

class QadaFastingScreen extends StatefulWidget {
  const QadaFastingScreen({super.key});

  @override
  State<QadaFastingScreen> createState() => _QadaFastingScreenState();
}

class _QadaFastingScreenState extends State<QadaFastingScreen> {
  static const _store = QadaFastingStore();

  QadaFastingLedger _ledger = QadaFastingLedger();
  bool _loading = true;

  String _text(String key) => qadaFastingText(
    Localizations.localeOf(context).languageCode,
    key,
  );

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final ledger = await _store.load();
    if (!mounted) return;
    setState(() {
      _ledger = ledger;
      _loading = false;
    });
  }

  Future<void> _save(QadaFastingLedger ledger) async {
    setState(() => _ledger = ledger);
    await _store.save(ledger);
  }

  Future<void> _addDebt() async {
    final daysController = TextEditingController();
    final yearController = TextEditingController();
    final noteController = TextEditingController();
    var unknownYear = true;
    var estimated = false;
    var occurredOn = DateTime.now();
    String? error;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_text('addDebt')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: daysController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _text('dayCount'),
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: yearController,
                  enabled: !unknownYear,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: _text('sourceYear')),
                ),
                CheckboxListTile(
                  value: unknownYear,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_text('unknownYear')),
                  onChanged: (value) {
                    setDialogState(() {
                      unknownYear = value ?? false;
                      if (unknownYear) yearController.clear();
                    });
                  },
                ),
                CheckboxListTile(
                  value: estimated,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_text('estimated')),
                  onChanged: (value) =>
                      setDialogState(() => estimated = value ?? false),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_text('chooseDate')),
                  subtitle: Text(_formatDate(context, occurredOn)),
                  trailing: const Icon(Icons.calendar_month_rounded),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: dialogContext,
                      initialDate: occurredOn,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (selected != null) {
                      setDialogState(() => occurredOn = selected);
                    }
                  },
                ),
                TextField(
                  controller: noteController,
                  maxLength: 500,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: _text('optionalNote'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_text('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final days = int.tryParse(daysController.text);
                final year = unknownYear
                    ? null
                    : int.tryParse(yearController.text);
                if (days == null ||
                    days < 1 ||
                    days > 3650 ||
                    (!unknownYear &&
                        yearController.text.isNotEmpty &&
                        year == null)) {
                  setDialogState(() => error = _text('invalidDays'));
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(_text('save')),
            ),
          ],
        ),
      ),
    );

    final days = int.tryParse(daysController.text);
    final year = unknownYear ? null : int.tryParse(yearController.text);
    final note = noteController.text;
    daysController.dispose();
    yearController.dispose();
    noteController.dispose();
    if (accepted != true || days == null || !mounted) return;
    final now = DateTime.now();
    await _save(
      _ledger.addDebt(
        days: days,
        occurredOn: occurredOn,
        createdAt: now,
        sourceRamadanYear: year,
        estimatedSource: estimated || unknownYear,
        note: note,
      ),
    );
    HapticFeedback.mediumImpact();
  }

  Future<void> _markComplete() async {
    if (_ledger.remainingDays <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_text('noDebt'))));
      return;
    }
    var occurredOn = DateTime.now();
    final noteController = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_text('markComplete')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_text('chooseDate')),
                subtitle: Text(_formatDate(context, occurredOn)),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: dialogContext,
                    initialDate: occurredOn,
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (selected != null) {
                    setDialogState(() => occurredOn = selected);
                  }
                },
              ),
              TextField(
                controller: noteController,
                maxLength: 500,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _text('optionalNote'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(_text('save')),
            ),
          ],
        ),
      ),
    );
    final note = noteController.text;
    noteController.dispose();
    if (accepted != true || !mounted) return;
    await _save(
      _ledger.complete(
        occurredOn: occurredOn,
        createdAt: DateTime.now(),
        note: note,
      ),
    );
    HapticFeedback.mediumImpact();
  }

  Future<void> _correctBalance() async {
    final targetController = TextEditingController(
      text: '${_ledger.remainingDays}',
    );
    final noteController = TextEditingController();
    String? error;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_text('correctBalance')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: targetController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: _text('remaining'),
                  errorText: error,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                maxLength: 500,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _text('optionalNote'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_text('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final target = int.tryParse(targetController.text);
                if (target == null || target < 0 || target > 3650) {
                  setDialogState(() => error = _text('invalidDays'));
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(_text('save')),
            ),
          ],
        ),
      ),
    );
    final target = int.tryParse(targetController.text);
    final note = noteController.text;
    targetController.dispose();
    noteController.dispose();
    if (accepted != true || target == null || !mounted) return;
    await _save(
      _ledger.correctBalance(
        targetDays: target,
        occurredOn: DateTime.now(),
        createdAt: DateTime.now(),
        note: note,
      ),
    );
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = _ledger.entries.reversed.toList(growable: false);
    final debtGroups = _ledger.debtByRamadan.entries.toList(growable: false)
      ..sort((a, b) {
        if (a.key == null) return 1;
        if (b.key == null) return -1;
        return b.key!.compareTo(a.key!);
      });
    return Scaffold(
      appBar: AppBar(title: Text(_text('title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              children: [
                Semantics(
                  container: true,
                  label: '${_text('privacy')} ${_text('backupNotice')}',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline_rounded, color: scheme.secondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _text('privacy'),
                                style: TextStyle(
                                  color: scheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _text('backupNotice'),
                                style: TextStyle(
                                  color: scheme.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Semantics(
                  container: true,
                  label:
                      '${_text('remaining')}: ${_ledger.remainingDays} ${_text('days')}',
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _text('remaining'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_ledger.remainingDays}',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(_text('days')),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                label: _text('recorded'),
                                value: _ledger.recordedDebtDays,
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                label: _text('completed'),
                                value: _ledger.completedDays,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _addDebt,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(_text('addDebt')),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _ledger.remainingDays > 0
                          ? _markComplete
                          : null,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(_text('markComplete')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _correctBalance,
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(_text('correctBalance')),
                    ),
                  ],
                ),
                if (debtGroups.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  Text(
                    _text('byRamadan'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final group in debtGroups)
                        Semantics(
                          label:
                              '${group.key == null ? _text('unknownYear') : 'Ramadan ${group.key}'}, ${group.value} ${_text('days')}',
                          child: Chip(
                            avatar: const Icon(
                              Icons.calendar_month_rounded,
                              size: 18,
                            ),
                            label: Text(
                              '${group.key == null ? _text('unknownYear') : 'Ramadan ${group.key}'} · ${group.value} ${_text('days')}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 26),
                Text(
                  _text('history'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                if (entries.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_text('empty')),
                  )
                else
                  for (final entry in entries)
                    _HistoryCard(
                      entry: entry,
                      text: _text,
                    ),
              ],
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '$value',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      Text(label, textAlign: TextAlign.center),
    ],
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.text});

  final QadaFastingEntry entry;
  final String Function(String key) text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, title) = switch (entry.kind) {
      QadaFastingEntryKind.debt => (
        Icons.add_circle_outline_rounded,
        scheme.tertiary,
        text('debtAdded'),
      ),
      QadaFastingEntryKind.completion => (
        Icons.check_circle_outline_rounded,
        scheme.primary,
        text('fastCompleted'),
      ),
      QadaFastingEntryKind.correction => (
        Icons.tune_rounded,
        scheme.secondary,
        text('balanceCorrected'),
      ),
    };
    final delta = entry.balanceDelta;
    final year = entry.sourceRamadanYear;
    final details = <String>[
      _formatDate(context, entry.occurredOn),
      if (year != null) 'Ramadan $year',
      if (entry.estimatedSource) text('estimated'),
    ];
    return Semantics(
      container: true,
      label:
          '$title, ${delta > 0 ? '+' : ''}$delta ${text('days')}, ${details.join(', ')}',
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            <String>[
              details.join(' · '),
              if (entry.note != null) entry.note!,
            ].join('\n'),
          ),
          isThreeLine: entry.note != null,
          trailing: Text(
            '${delta > 0 ? '+' : ''}$delta',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatMediumDate(value);
