import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'travel_meeting_point_screen.dart';
import 'travel_packing_screen.dart';
import 'travel_tools_export.dart';
import 'travel_tools_import.dart';

class TravelToolsScreen extends StatelessWidget {
  const TravelToolsScreen({super.key});

  Future<void> _copyExport(BuildContext context, _TravelToolsCopy c) async {
    final data = await const TravelToolsExport().createJson();
    await Clipboard.setData(ClipboardData(text: data));
    if (!context.mounted) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(c.exportCopied)));
  }

  Future<void> _pasteImport(BuildContext context, _TravelToolsCopy c) async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted) return;
    final text = clipboard?.text;
    if (text == null || text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(c.importInvalid)));
      return;
    }
    TravelToolsImportPreview preview;
    try {
      preview = const TravelToolsImport().parse(text);
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(c.importInvalid)));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(c.importTitle),
        content: Text(c.importPreview(preview)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(c.cancel)),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(c.restore)),
        ],
      ),
    );
    if (confirmed != true) return;
    await const TravelToolsImport().apply(preview);
    if (!context.mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(c.importDone)));
  }

  @override
  Widget build(BuildContext context) {
    final c = _TravelToolsCopy.forLocale(Localizations.localeOf(context));
    return Scaffold(
      appBar: AppBar(title: Text(c.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(c.body, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 18),
          _ToolCard(icon: Icons.pin_drop_outlined, title: c.meetingPoint, subtitle: c.meetingPointBody, onTap: () => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const TravelMeetingPointScreen()))),
          const SizedBox(height: 12),
          _ToolCard(icon: Icons.checklist_rounded, title: c.packing, subtitle: c.packingBody, onTap: () => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const TravelPackingScreen()))),
          const SizedBox(height: 20),
          Text(c.privacy, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: () => _copyExport(context, c), icon: const Icon(Icons.file_copy_outlined), label: Text(c.export)),
            OutlinedButton.icon(onPressed: () => _pasteImport(context, c), icon: const Icon(Icons.restore_rounded), label: Text(c.import)),
          ]),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$title. $subtitle',
        onTap: onTap,
        child: ExcludeSemantics(
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              leading: Icon(icon, size: 30),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onTap,
            ),
          ),
        ),
      );
}

class _TravelToolsCopy {
  const _TravelToolsCopy(this.title, this.body, this.meetingPoint, this.meetingPointBody, this.packing, this.packingBody, this.privacy, this.export, this.exportCopied, this.import, this.importTitle, this.importInvalid, this.importDone, this.cancel, this.restore, this.items, this.hasMeeting);
  final String title, body, meetingPoint, meetingPointBody, packing, packingBody, privacy, export, exportCopied, import, importTitle, importInvalid, importDone, cancel, restore, items, hasMeeting;
  String importPreview(TravelToolsImportPreview preview) => '$items: ${preview.packing.length}\n$hasMeeting: ${preview.meetingPoint == null ? '—' : preview.meetingPoint!.name}';
  static _TravelToolsCopy forLocale(Locale locale) => _copy[locale.languageCode] ?? _copy['en']!;
}

const _copy = <String, _TravelToolsCopy>{
  'tr': _TravelToolsCopy('Seyahat araçları', 'İnternet olmasa da ihtiyaç duyacağınız temel seyahat bilgilerini cihazınızda tutun.', 'Buluşma noktası', 'Otel, kamp veya grup buluşma yerini kaydedin.', 'Seyahat listesi', 'Kendi eşya listenizi oluşturun ve hazırladıklarınızı işaretleyin.', 'Seyahat verileri otomatik yedeğe eklenmez. Taşınabilir kopyayı yalnız siz oluşturup geri yükleyebilirsiniz.', 'Seyahat verisini kopyala', 'Seyahat verisi kopyalandı', 'Panodan geri yükle', 'Seyahat verisi geri yüklensin mi?', 'Panoda geçerli seyahat verisi yok', 'Seyahat verisi geri yüklendi', 'Vazgeç', 'Geri yükle', 'Liste öğesi', 'Buluşma noktası'),
  'en': _TravelToolsCopy('Travel tools', 'Keep essential trip information on your device even when you are offline.', 'Meeting point', 'Save your hotel, camp or group meeting place.', 'Travel checklist', 'Build your own packing list and mark items ready.', 'Travel data is excluded from automatic backup. Only you can create and restore a portable copy.', 'Copy travel data', 'Travel data copied', 'Restore from clipboard', 'Restore travel data?', 'Clipboard does not contain valid travel data', 'Travel data restored', 'Cancel', 'Restore', 'Checklist items', 'Meeting point'),
  'fr': _TravelToolsCopy('Outils de voyage', 'Gardez les informations essentielles du voyage sur votre appareil, même hors ligne.', 'Point de rendez-vous', 'Enregistrez votre hôtel, camp ou lieu de rendez-vous.', 'Liste de voyage', 'Créez votre liste et cochez les éléments prêts.', 'Les données de voyage sont exclues de la sauvegarde automatique. Vous seul pouvez créer et restaurer une copie portable.', 'Copier les données de voyage', 'Données de voyage copiées', 'Restaurer depuis le presse-papiers', 'Restaurer les données de voyage ?', 'Le presse-papiers ne contient pas de données de voyage valides', 'Données de voyage restaurées', 'Annuler', 'Restaurer', 'Éléments de la liste', 'Point de rendez-vous'),
  'ar': _TravelToolsCopy('أدوات السفر', 'احتفظ بمعلومات السفر الأساسية على جهازك حتى دون اتصال.', 'نقطة اللقاء', 'احفظ الفندق أو المخيم أو مكان لقاء المجموعة.', 'قائمة السفر', 'أنشئ قائمة أغراضك وحدد ما تم تجهيزه.', 'لا تُضاف بيانات السفر إلى النسخ الاحتياطي التلقائي. أنت فقط تنشئ النسخة المحمولة وتستعيدها.', 'نسخ بيانات السفر', 'تم نسخ بيانات السفر', 'استعادة من الحافظة', 'استعادة بيانات السفر؟', 'لا تحتوي الحافظة على بيانات سفر صالحة', 'تمت استعادة بيانات السفر', 'إلغاء', 'استعادة', 'عناصر القائمة', 'نقطة اللقاء'),
  'az': _TravelToolsCopy('Səyahət alətləri', 'İnternet olmasa belə əsas səyahət məlumatlarını cihazınızda saxlayın.', 'Görüş yeri', 'Otel, düşərgə və ya qrup görüş yerini saxlayın.', 'Səyahət siyahısı', 'Öz əşya siyahınızı yaradın və hazır olanları işarələyin.', 'Səyahət məlumatları avtomatik ehtiyat nüsxəyə daxil edilmir. Daşına bilən nüsxəni yalnız siz yaradıb bərpa edə bilərsiniz.', 'Səyahət məlumatını kopyala', 'Səyahət məlumatı kopyalandı', 'Mübadilə buferindən bərpa et', 'Səyahət məlumatı bərpa edilsin?', 'Mübadilə buferində etibarlı səyahət məlumatı yoxdur', 'Səyahət məlumatı bərpa edildi', 'Ləğv et', 'Bərpa et', 'Siyahı elementləri', 'Görüş yeri'),
  'ru': _TravelToolsCopy('Инструменты поездки', 'Храните важную информацию о поездке на устройстве даже без интернета.', 'Место встречи', 'Сохраните отель, лагерь или место встречи группы.', 'Список в поездку', 'Создайте свой список вещей и отмечайте готовые пункты.', 'Данные поездки не входят в автоматическую резервную копию. Переносимую копию создаёте и восстанавливаете только вы.', 'Копировать данные поездки', 'Данные поездки скопированы', 'Восстановить из буфера', 'Восстановить данные поездки?', 'В буфере нет корректных данных поездки', 'Данные поездки восстановлены', 'Отмена', 'Восстановить', 'Пункты списка', 'Место встречи'),
};