import 'package:flutter/material.dart';

import '../application/qada_fasting_store.dart';
import '../domain/qada_fasting_ledger.dart';

class QadaFastingScreen extends StatefulWidget {
  const QadaFastingScreen({super.key, this.store = const QadaFastingStore()});

  final QadaFastingStore store;

  @override
  State<QadaFastingScreen> createState() => _QadaFastingScreenState();
}

class _QadaFastingScreenState extends State<QadaFastingScreen> {
  QadaFastingLedger _ledger = const QadaFastingLedger([]);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final value = await widget.store.load();
    if (!mounted) return;
    setState(() { _ledger = value; _loading = false; });
  }

  Future<void> _add(QadaFastEntryKind kind) async {
    final result = await showModalBottomSheet<_Draft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _QadaEntrySheet(kind: kind, maxCompletion: _ledger.balance),
    );
    if (result == null) return;
    final now = DateTime.now();
    final entry = QadaFastEntry(
      id: '${now.microsecondsSinceEpoch}-${kind.name}',
      kind: kind,
      days: result.days,
      recordedAt: now,
      sourceHijriYear: result.hijriYear,
      completedAt: kind == QadaFastEntryKind.completion ? now : null,
      note: result.note,
    );
    await widget.store.append(entry);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kaza oruçları')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Semantics(
                  container: true,
                  label: 'Kalan kaza orucu ${_ledger.balance} gün',
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Kalan', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text('${_ledger.balance} gün', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text('Kaydedilen borç ${_ledger.totalRecordedDebt} · Tamamlanan ${_ledger.totalCompleted}'),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: FilledButton.icon(onPressed: () => _add(QadaFastEntryKind.debt), icon: const Icon(Icons.add), label: const Text('Borç ekle'))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: _ledger.balance == 0 ? null : () => _add(QadaFastEntryKind.completion), icon: const Icon(Icons.check), label: const Text('Kaza yaptım'))),
                ]),
                const SizedBox(height: 22),
                Text('Geçmiş', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (_ledger.entries.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Henüz kayıt yok. Eski borcun tam tarihini bilmiyorsan yalnız toplam gün ve tahmini Hicri yılı kaydedebilirsin.'))
                else
                  for (final entry in _ledger.newestFirst)
                    Dismissible(
                      key: ValueKey(entry.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async => await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Kaydı sil?'), content: const Text('Bu işlem kalan toplamı yeniden hesaplar.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil'))])) ?? false,
                      onDismissed: (_) async { await widget.store.remove(entry.id); await _reload(); },
                      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 18), color: theme.colorScheme.errorContainer, child: const Icon(Icons.delete_outline)),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Icon(entry.kind == QadaFastEntryKind.completion ? Icons.check : Icons.add)),
                        title: Text(entry.kind == QadaFastEntryKind.completion ? '${entry.days} gün tamamlandı' : '${entry.days} gün borç eklendi'),
                        subtitle: Text([if (entry.sourceHijriYear != null) '${entry.sourceHijriYear} H', if (entry.note?.isNotEmpty == true) entry.note!].join(' · ')),
                      ),
                    ),
              ],
            ),
    );
  }
}

class _Draft { const _Draft(this.days, this.hijriYear, this.note); final int days; final int? hijriYear; final String? note; }

class _QadaEntrySheet extends StatefulWidget {
  const _QadaEntrySheet({required this.kind, required this.maxCompletion});
  final QadaFastEntryKind kind;
  final int maxCompletion;
  @override State<_QadaEntrySheet> createState() => _QadaEntrySheetState();
}

class _QadaEntrySheetState extends State<_QadaEntrySheet> {
  final _days = TextEditingController(text: '1');
  final _year = TextEditingController();
  final _note = TextEditingController();
  String? _error;
  @override void dispose() { _days.dispose(); _year.dispose(); _note.dispose(); super.dispose(); }
  void _submit() {
    final days = int.tryParse(_days.text.trim());
    final year = _year.text.trim().isEmpty ? null : int.tryParse(_year.text.trim());
    if (days == null || days <= 0) { setState(() => _error = 'Gün sayısı 1 veya daha büyük olmalı.'); return; }
    if (widget.kind == QadaFastEntryKind.completion && days > widget.maxCompletion) { setState(() => _error = 'Kalan borçtan fazla gün tamamlanamaz.'); return; }
    if (_year.text.trim().isNotEmpty && (year == null || year < 1200 || year > 1700)) { setState(() => _error = 'Hicri yılı kontrol et.'); return; }
    Navigator.pop(context, _Draft(days, year, _note.text.trim().isEmpty ? null : _note.text.trim()));
  }
  @override Widget build(BuildContext context) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.viewInsetsOf(context).bottom), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text(widget.kind == QadaFastEntryKind.completion ? 'Kaza tamamla' : 'Kaza borcu ekle', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 14),
    TextField(controller: _days, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gün sayısı')),
    if (widget.kind != QadaFastEntryKind.completion) TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hicri yıl (isteğe bağlı)')),
    TextField(controller: _note, maxLength: 160, decoration: const InputDecoration(labelText: 'Özel not (isteğe bağlı)')),
    if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    const SizedBox(height: 12), FilledButton(onPressed: _submit, child: const Text('Kaydet')),
  ])));
}
