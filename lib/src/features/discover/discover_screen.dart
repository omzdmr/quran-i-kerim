import 'package:flutter/material.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cards = const [
      ('Sabır', Color(0xFF6F533F), Icons.hourglass_bottom_rounded),
      ('Kaygı', Color(0xFF8A620D), Icons.psychology_alt_outlined),
      ('Öfke', Color(0xFF493884), Icons.whatshot_outlined),
      ('Umut', Color(0xFF7B1737), Icons.wb_sunny_outlined),
      ('Şükür', Color(0xFF795C5A), Icons.favorite_outline),
      ('Huzur', Color(0xFF25658A), Icons.spa_outlined),
      ('Korku', Color(0xFF747113), Icons.shield_outlined),
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
              hintText: 'Ayet, konu veya plan ara',
              prefixIcon: const Icon(Icons.search_rounded, size: 29),
              filled: true,
              fillColor: scheme.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(
                child: _Shortcut(
                  Icons.library_add_check_outlined,
                  'Okuma Planları',
                ),
              ),
              SizedBox(width: 12),
              Expanded(child: _Shortcut(Icons.menu_book_outlined, 'Ayetler')),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _Shortcut(Icons.auto_stories_outlined, 'Tefsirler'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _Shortcut(Icons.headphones_outlined, 'Sesli Kuran'),
              ),
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
            itemBuilder: (context, index) {
              final card = cards[index];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: card.$2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        card.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Icon(card.$3, size: 40, color: Colors.white70),
                    ),
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w750),
            ),
          ),
        ],
      ),
    );
  }
}
