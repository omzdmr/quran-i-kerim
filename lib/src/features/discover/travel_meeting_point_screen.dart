import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'travel_map_launcher.dart';
import 'travel_meeting_point_store.dart';

class TravelMeetingPointScreen extends StatefulWidget {
  const TravelMeetingPointScreen({super.key});

  @override
  State<TravelMeetingPointScreen> createState() => _TravelMeetingPointScreenState();
}

class _TravelMeetingPointScreenState extends State<TravelMeetingPointScreen> {
  static const _store = TravelMeetingPointStore();
  static const _mapLauncher = TravelMapLauncher();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  DateTime? _updatedAt;

  _TravelMeetingCopy get copy => _TravelMeetingCopy.forLocale(Localizations.localeOf(context));
  bool get _hasContent => [_name.text, _address.text, _note.text].any((value) => value.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final point = await _store.load();
    if (!mounted) return;
    if (point != null) {
      _name.text = point.name;
      _address.text = point.address;
      _note.text = point.note;
      _updatedAt = point.updatedAt;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_saving) return;
    final now = DateTime.now();
    setState(() => _saving = true);
    await _store.save(TravelMeetingPoint(name: _name.text.trim(), address: _address.text.trim(), note: _note.text.trim(), updatedAt: now));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _updatedAt = _hasContent ? now : null;
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copy.saved)));
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(copy.clearTitle),
        content: Text(copy.clearBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(copy.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(copy.clear)),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.clear();
    if (!mounted) return;
    _name.clear();
    _address.clear();
    _note.clear();
    setState(() => _updatedAt = null);
  }

  Future<void> _copyPoint() async {
    final parts = <String>[
      if (_name.text.trim().isNotEmpty) _name.text.trim(),
      if (_address.text.trim().isNotEmpty) _address.text.trim(),
      if (_note.text.trim().isNotEmpty) _note.text.trim(),
    ];
    if (parts.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: parts.join('\n')));
    if (!mounted) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copy.copied)));
  }

  Future<void> _openMap() async {
    final address = _address.text.trim();
    if (address.isEmpty) return;
    final opened = await _mapLauncher.openAddress(address);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copy.mapFailed)));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = copy;
    return Scaffold(
      appBar: AppBar(title: Text(c.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Semantics(
                  container: true,
                  label: c.offlineHint,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [const Icon(Icons.offline_pin_outlined), const SizedBox(width: 12), Expanded(child: Text(c.offlineHint))]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: _name, onChanged: (_) => setState(() {}), textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: c.name, prefixIcon: const Icon(Icons.place_outlined))),
                const SizedBox(height: 12),
                TextField(controller: _address, onChanged: (_) => setState(() {}), textInputAction: TextInputAction.next, minLines: 1, maxLines: 3, decoration: InputDecoration(labelText: c.address, prefixIcon: const Icon(Icons.map_outlined))),
                const SizedBox(height: 12),
                TextField(controller: _note, onChanged: (_) => setState(() {}), minLines: 3, maxLines: 6, decoration: InputDecoration(labelText: c.note, alignLabelWithHint: true, prefixIcon: const Icon(Icons.notes_rounded))),
                if (_updatedAt != null) ...[
                  const SizedBox(height: 10),
                  Text('${c.updated}: ${MaterialLocalizations.of(context).formatCompactDate(_updatedAt!)}', style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 20),
                Semantics(
                  button: true,
                  label: c.save,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                    label: Text(c.save),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(onPressed: _hasContent ? _copyPoint : null, icon: const Icon(Icons.copy_rounded), label: Text(c.copy)),
                  OutlinedButton.icon(onPressed: _address.text.trim().isNotEmpty ? _openMap : null, icon: const Icon(Icons.map_rounded), label: Text(c.openMap)),
                ]),
                const SizedBox(height: 10),
                TextButton.icon(onPressed: _updatedAt == null ? null : _clear, icon: const Icon(Icons.delete_outline), label: Text(c.clear)),
              ],
            ),
    );
  }
}

class _TravelMeetingCopy {
  const _TravelMeetingCopy(this.title, this.offlineHint, this.name, this.address, this.note, this.save, this.saved, this.copy, this.copied, this.clear, this.clearTitle, this.clearBody, this.cancel, this.updated, this.openMap, this.mapFailed);
  final String title, offlineHint, name, address, note, save, saved, copy, copied, clear, clearTitle, clearBody, cancel, updated, openMap, mapFailed;
  static _TravelMeetingCopy forLocale(Locale locale) => _copy[locale.languageCode] ?? _copy['en']!;
}

const _copy = <String, _TravelMeetingCopy>{
  'tr': _TravelMeetingCopy('Buluşma noktası', 'Bu bilgi yalnızca bu cihazda saklanır ve çevrimdışı kullanılabilir.', 'Yer adı', 'Adres / tarif', 'Özel not', 'Kaydet', 'Buluşma noktası kaydedildi', 'Bilgileri kopyala', 'Bilgiler kopyalandı', 'Sil', 'Buluşma noktasını sil?', 'Kayıtlı yer, adres ve not bu cihazdan silinecek.', 'Vazgeç', 'Son güncelleme', 'Haritada aç', 'Harita uygulaması açılamadı'),
  'en': _TravelMeetingCopy('Meeting point', 'This information stays on this device and remains available offline.', 'Place name', 'Address / directions', 'Private note', 'Save', 'Meeting point saved', 'Copy details', 'Details copied', 'Delete', 'Delete meeting point?', 'The saved place, address and note will be removed from this device.', 'Cancel', 'Last updated', 'Open in map', 'Could not open a map app'),
  'fr': _TravelMeetingCopy('Point de rendez-vous', 'Ces informations restent sur cet appareil et sont disponibles hors ligne.', 'Nom du lieu', 'Adresse / itinéraire', 'Note privée', 'Enregistrer', 'Point de rendez-vous enregistré', 'Copier les informations', 'Informations copiées', 'Supprimer', 'Supprimer le point de rendez-vous ?', 'Le lieu, l’adresse et la note seront supprimés de cet appareil.', 'Annuler', 'Dernière mise à jour', 'Ouvrir dans la carte', 'Impossible d’ouvrir une application de carte'),
  'ar': _TravelMeetingCopy('نقطة اللقاء', 'تُحفظ هذه المعلومات على هذا الجهاز وتبقى متاحة دون اتصال.', 'اسم المكان', 'العنوان / الوصف', 'ملاحظة خاصة', 'حفظ', 'تم حفظ نقطة اللقاء', 'نسخ التفاصيل', 'تم نسخ التفاصيل', 'حذف', 'حذف نقطة اللقاء؟', 'سيتم حذف المكان والعنوان والملاحظة المحفوظة من هذا الجهاز.', 'إلغاء', 'آخر تحديث', 'فتح في الخريطة', 'تعذر فتح تطبيق الخرائط'),
  'az': _TravelMeetingCopy('Görüş yeri', 'Bu məlumat yalnız bu cihazda saxlanılır və oflayn əlçatandır.', 'Yer adı', 'Ünvan / istiqamət', 'Şəxsi qeyd', 'Yadda saxla', 'Görüş yeri yadda saxlanıldı', 'Məlumatı kopyala', 'Məlumat kopyalandı', 'Sil', 'Görüş yerini sil?', 'Saxlanmış yer, ünvan və qeyd bu cihazdan silinəcək.', 'Ləğv et', 'Son yenilənmə', 'Xəritədə aç', 'Xəritə tətbiqi açıla bilmədi'),
  'ru': _TravelMeetingCopy('Место встречи', 'Эти данные хранятся только на этом устройстве и доступны офлайн.', 'Название места', 'Адрес / ориентир', 'Личная заметка', 'Сохранить', 'Место встречи сохранено', 'Копировать данные', 'Данные скопированы', 'Удалить', 'Удалить место встречи?', 'Сохранённое место, адрес и заметка будут удалены с устройства.', 'Отмена', 'Последнее обновление', 'Открыть на карте', 'Не удалось открыть приложение карт'),
};