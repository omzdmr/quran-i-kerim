import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'reading_plan.dart';
import 'reading_plan_store.dart';

class OffDeviceReadingScreen extends StatefulWidget {
  const OffDeviceReadingScreen({super.key});

  @override
  State<OffDeviceReadingScreen> createState() => _OffDeviceReadingScreenState();
}

class _OffDeviceReadingScreenState extends State<OffDeviceReadingScreen> {
  final _store = const ReadingPlanStore();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _note = TextEditingController();
  final _form = GlobalKey<FormState>();
  var _date = readingPlanDateOnly(DateTime.now());
  ReadingPlanSnapshot? _snapshot;
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snapshot = await _store.load();
      if (mounted) setState(() { _snapshot = snapshot; _failed = false; });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() { _busy = true; _failed = false; });
    try {
      final snapshot = await _store.addOffDeviceSession(
        readAt: _date,
        startPage: int.parse(_start.text),
        endPage: int.parse(_end.text),
        note: _note.text,
      );
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
      _start.clear(); _end.clear(); _note.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('paperSaved'))),
      );
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.text('paperDelete')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.text('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.text('paperDelete'))),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) return;
    setState(() { _busy = true; _failed = false; });
    try {
      final snapshot = await _store.removeOffDeviceSessionAt(index);
      if (mounted) setState(() => _snapshot = snapshot);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dates = MaterialLocalizations.of(context);
    final sessions = _snapshot?.offDeviceSessions ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('paperTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.text('paperExplanation')),
          const SizedBox(height: 16),
          Form(
            key: _form,
            child: Column(children: [
              ListTile(
                title: Text(l10n.text('paperDate')),
                subtitle: Text(dates.formatMediumDate(_date)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _busy ? null : () async {
                  final picked = await showDatePicker(context: context,
                    initialDate: _date, firstDate: DateTime(1900),
                    lastDate: DateTime.now());
                  if (picked != null && mounted) setState(() => _date = picked);
                },
              ),
              for (final isStart in [true, false])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: isStart ? _start : _end,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: l10n.text(
                      isStart ? 'paperStart' : 'paperEnd')),
                    validator: (value) {
                      final page = int.tryParse(value ?? '');
                      if (page == null || page < 1 || page > 604 ||
                          (!isStart && page < (int.tryParse(_start.text) ?? 1))) {
                        return l10n.text('paperInvalid');
                      }
                      return null;
                    },
                  ),
                ),
              TextFormField(controller: _note, enabled: !_busy, maxLength: 300,
                decoration: InputDecoration(labelText: l10n.text('plansManualKhatmNoteV1'))),
              FilledButton(onPressed: _busy || _snapshot == null ? null : _save,
                child: Text(l10n.text('save'))),
            ]),
          ),
          if (_failed)
            TextButton(onPressed: _snapshot == null ? _load : null,
              child: Text(l10n.text('paperError'))),
          const SizedBox(height: 24),
          Text(l10n.text('paperHistory'), style: Theme.of(context).textTheme.titleLarge),
          if (_snapshot == null && !_failed) const LinearProgressIndicator(),
          if (_snapshot != null && sessions.isEmpty) Text(l10n.text('paperEmpty')),
          for (var i = 0; i < sessions.length; i++)
            ListTile(
              title: Text('${sessions[i].startPage}–${sessions[i].endPage}'),
              subtitle: Text([
                dates.formatMediumDate(sessions[i].readAt),
                l10n.text('paperSource'),
                if (sessions[i].note != null) sessions[i].note!,
              ].join('\n')),
              trailing: IconButton(icon: const Icon(Icons.delete_outline),
                tooltip: l10n.text('paperDelete'),
                onPressed: _busy ? null : () => _remove(i)),
            ),
        ],
      ),
    );
  }
}
