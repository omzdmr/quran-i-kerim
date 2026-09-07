import 'package:flutter/material.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = const [
      ('Sabır', Color(0xFF6F533F), Icons.hourglass_bottom_rounded),
      ('Kaygı', Color(0xFF976500), Icons.psychology_alt_outlined),
      ('Öfke', Color(0xFF493884), Icons.whatshot_outlined),
      ('Umut', Color(0xFF7B1737), Icons.wb_sunny_outlined),
      ('Şükür', Color(0xFF795C5A), Icons.favorite_outline),
      ('Huzur', Color(0xFF25658A), Icons.spa_outlined),
      ('Korku', Color(0xFF888100), Icons.shield_outlined),
      ('Aile', Color(0xFF4A7080), Icons.groups_outlined),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 44, 20, 120),
        children: [
          Text('Keşfedin', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 26),
          TextField(
            decoration: InputDecoration(
              hintText: 'Ara',
              prefixIcon: const Icon(Icons.search_rounded, size: 30),
              filled: true,
              fillColor: const Color(0xFF373535),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(child: _Shortcut(Icons.library_add_check_outlined, 'Okuma Planları')),
              SizedBox(width: 12),
              Expanded(child: _Shortcut(Icons.menu_book_outlined, 'Ayetler')),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _Shortcut(Icons.auto_stories_outlined, 'Tefsirler')),
              SizedBox(width: 12),
              Expanded(child: _Shortcut(Icons.headphones_outlined, 'Sesli Kuran')),
            ],
          ),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, i) {
              final c = cards[i];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: c.$2, borderRadius: BorderRadius.circular(14)),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(c.$1, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                    ),
                    Align(alignment: Alignment.topRight, child: Icon(c.$3, size: 42, color: Colors.white70)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
        decoration: BoxDecoration(
          color: const Color(0xFF211F1F),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          ],
        ),
      );
}
