import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 120),
        children: [
          Row(
            children: [
              Expanded(child: Text('Siz', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF211F1F),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 28, child: Icon(Icons.person_rounded)),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Misafir', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      SizedBox(height: 3),
                      Text('Hesap açmadan da okuyabilirsiniz', style: TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _Tile(Icons.bolt_outlined, '12 günlük seri', 'Bu hafta 5 gün okudunuz'),
          _Tile(Icons.bookmark_border_rounded, 'Kaydedilen ayetler', null),
          _Tile(Icons.note_alt_outlined, 'Notlar', null),
          _Tile(Icons.download_done_rounded, 'İndirilenler', 'Mealler ve ses paketleri'),
          _Tile(Icons.language_rounded, 'Dil ve Meal', 'Türkçe · DİB'),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF211F1F),
          borderRadius: BorderRadius.circular(18),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(color: Colors.white60)),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}
