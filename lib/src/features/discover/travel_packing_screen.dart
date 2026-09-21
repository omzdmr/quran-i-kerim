import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'travel_packing_store.dart';

class TravelPackingScreen extends StatefulWidget {
  const TravelPackingScreen({super.key});

  @override
  State<TravelPackingScreen> createState() => _TravelPackingScreenState();
}

class _TravelPackingScreenState extends State<TravelPackingScreen> {
  static const _store = TravelPackingStore();
  final _controller = TextEditingController();
  List<TravelPackingItem> _items = const [];
  bool _loading = true;

  _PackingCopy get copy => _PackingCopy.forLocale(Localizations.localeOf(context));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _store.load();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _persist(List<TravelPackingItem> next) async {
    final previous = _items;
    setState(() => _items = List.unmodifiable(next));
    try {
      await _store.save(next);
    } catch (_) {
      if (mounted) setState(() => _items = previous);
      rethrow;
    }
  }

  Future<void> _add() async {
    final label = _controller.text.trim();
    if (label.isEmpty) return;
    final item = TravelPackingItem(
      id: '${DateTime.now().microsecondsSinceEpoch}-${label.hashCode}',
      label: label,
      packed: false,
    );
    _controller.clear();
    await _persist([..._items, item]);
  }

  Future<void> _toggle(TravelPackingItem item, bool value) => _persist([
        for (final current in _items)
          current.id == item.id ? current.copyWith(packed: value) : current,
      ]);

  Future<void> _remove(TravelPackingItem item) =>
      _persist(_items.where((current) => current.id != item.id).toList(growable: false));

  Future<void> _resetPacked() => _persist([
        for (final item in _items) item.packed ? item.copyWith(packed: false) : item,
      ]);

  Future<void> _copyChecklist() async {
    if (_items.isEmpty) return;
    final text = _items.map((item) => '${item.packed ? '☑' : '☐'} ${item.label}').join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copy.copied)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = copy;
    final packed = _items.where((item) => item.packed).length;
    return Scaffold(
      appBar: AppBar(title: Text(c.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Semantics(
                  container: true,
                  label: '${c.progress}: $packed / ${_items.length}. ${c.offline}',
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${c.progress}: $packed / ${_items.length}', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: _items.isEmpty ? 0 : packed / _items.length),
                        const SizedBox(height: 8),
                        Text(c.offline, style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _add(),
                      decoration: InputDecoration(labelText: c.newItem, prefixIcon: const Icon(Icons.add_box_outlined)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _add, tooltip: c.add, icon: const Icon(Icons.add_rounded)),
                ]),
                if (_items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton.icon(onPressed: _copyChecklist, icon: const Icon(Icons.copy_rounded), label: Text(c.copy)),
                    if (packed > 0)
                      OutlinedButton.icon(onPressed: _resetPacked, icon: const Icon(Icons.restart_alt_rounded), label: Text(c.reset)),
                  ]),
                ],
                const SizedBox(height: 14),
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(children: [
                      const Icon(Icons.luggage_outlined, size: 44),
                      const SizedBox(height: 10),
                      Text(c.empty, textAlign: TextAlign.center),
                    ]),
                  )
                else
                  for (final item in _items)
                    Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      onDismissed: (_) => _remove(item),
                      child: Semantics(
                        checked: item.packed,
                        label: item.label,
                        child: CheckboxListTile(
                          value: item.packed,
                          onChanged: (value) => _toggle(item, value ?? false),
                          title: Text(item.label, style: item.packed ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
                          secondary: IconButton(onPressed: () => _remove(item), tooltip: c.remove, icon: const Icon(Icons.delete_outline)),
                        ),
                      ),
                    ),
              ],
            ),
    );
  }
}

class _PackingCopy {
  const _PackingCopy(this.title, this.progress, this.offline, this.newItem, this.add, this.remove, this.empty, this.copy, this.copied, this.reset);
  final String title, progress, offline, newItem, add, remove, empty, copy, copied, reset;
  static _PackingCopy forLocale(Locale locale) => _copy[locale.languageCode] ?? _copy['en']!;
}

const _copy = <String, _PackingCopy>{
  'tr': _PackingCopy('Seyahat listesi', 'Hazır', 'Liste yalnızca bu cihazda saklanır ve çevrimdışı çalışır.', 'Listeye ekle', 'Ekle', 'Sil', 'Henüz eşya eklenmedi. Kendi seyahat listenizi oluşturun.', 'Listeyi kopyala', 'Liste kopyalandı', 'İşaretleri sıfırla'),
  'en': _PackingCopy('Travel checklist', 'Ready', 'The list stays on this device and works offline.', 'Add an item', 'Add', 'Remove', 'Nothing added yet. Build your own travel checklist.', 'Copy list', 'Checklist copied', 'Reset checks'),
  'fr': _PackingCopy('Liste de voyage', 'Prêt', 'La liste reste sur cet appareil et fonctionne hors ligne.', 'Ajouter un élément', 'Ajouter', 'Supprimer', 'Aucun élément pour le moment. Créez votre propre liste.', 'Copier la liste', 'Liste copiée', 'Réinitialiser les coches'),
  'ar': _PackingCopy('قائمة السفر', 'جاهز', 'تُحفظ القائمة على هذا الجهاز وتعمل دون اتصال.', 'إضافة عنصر', 'إضافة', 'حذف', 'لم تتم إضافة عناصر بعد. أنشئ قائمة سفرك الخاصة.', 'نسخ القائمة', 'تم نسخ القائمة', 'إعادة ضبط العلامات'),
  'az': _PackingCopy('Səyahət siyahısı', 'Hazır', 'Siyahı bu cihazda saxlanılır və oflayn işləyir.', 'Element əlavə et', 'Əlavə et', 'Sil', 'Hələ heç nə əlavə edilməyib. Öz səyahət siyahınızı yaradın.', 'Siyahını kopyala', 'Siyahı kopyalandı', 'İşarələri sıfırla'),
  'ru': _PackingCopy('Список в поездку', 'Готово', 'Список хранится на этом устройстве и работает офлайн.', 'Добавить пункт', 'Добавить', 'Удалить', 'Пока ничего нет. Создайте свой список для поездки.', 'Копировать список', 'Список скопирован', 'Сбросить отметки'),
};