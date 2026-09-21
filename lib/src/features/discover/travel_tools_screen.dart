import 'package:flutter/material.dart';

import 'travel_meeting_point_screen.dart';
import 'travel_packing_screen.dart';

class TravelToolsScreen extends StatelessWidget {
  const TravelToolsScreen({super.key});

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
          _ToolCard(
            icon: Icons.pin_drop_outlined,
            title: c.meetingPoint,
            subtitle: c.meetingPointBody,
            onTap: () => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const TravelMeetingPointScreen())),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.checklist_rounded,
            title: c.packing,
            subtitle: c.packingBody,
            onTap: () => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const TravelPackingScreen())),
          ),
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
  const _TravelToolsCopy(this.title, this.body, this.meetingPoint, this.meetingPointBody, this.packing, this.packingBody);
  final String title, body, meetingPoint, meetingPointBody, packing, packingBody;
  static _TravelToolsCopy forLocale(Locale locale) => _copy[locale.languageCode] ?? _copy['en']!;
}

const _copy = <String, _TravelToolsCopy>{
  'tr': _TravelToolsCopy('Seyahat araçları', 'İnternet olmasa da ihtiyaç duyacağınız temel seyahat bilgilerini cihazınızda tutun.', 'Buluşma noktası', 'Otel, kamp veya grup buluşma yerini kaydedin.', 'Seyahat listesi', 'Kendi eşya listenizi oluşturun ve hazırladıklarınızı işaretleyin.'),
  'en': _TravelToolsCopy('Travel tools', 'Keep essential trip information on your device even when you are offline.', 'Meeting point', 'Save your hotel, camp or group meeting place.', 'Travel checklist', 'Build your own packing list and mark items ready.'),
  'fr': _TravelToolsCopy('Outils de voyage', 'Gardez les informations essentielles du voyage sur votre appareil, même hors ligne.', 'Point de rendez-vous', 'Enregistrez votre hôtel, camp ou lieu de rendez-vous.', 'Liste de voyage', 'Créez votre liste et cochez les éléments prêts.'),
  'ar': _TravelToolsCopy('أدوات السفر', 'احتفظ بمعلومات السفر الأساسية على جهازك حتى دون اتصال.', 'نقطة اللقاء', 'احفظ الفندق أو المخيم أو مكان لقاء المجموعة.', 'قائمة السفر', 'أنشئ قائمة أغراضك وحدد ما تم تجهيزه.'),
  'az': _TravelToolsCopy('Səyahət alətləri', 'İnternet olmasa belə əsas səyahət məlumatlarını cihazınızda saxlayın.', 'Görüş yeri', 'Otel, düşərgə və ya qrup görüş yerini saxlayın.', 'Səyahət siyahısı', 'Öz əşya siyahınızı yaradın və hazır olanları işarələyin.'),
  'ru': _TravelToolsCopy('Инструменты поездки', 'Храните важную информацию о поездке на устройстве даже без интернета.', 'Место встречи', 'Сохраните отель, лагерь или место встречи группы.', 'Список в поездку', 'Создайте свой список вещей и отмечайте готовые пункты.'),
};