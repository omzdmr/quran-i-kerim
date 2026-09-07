import 'package:flutter/material.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const topics = ['SABIR', 'HUZUR', 'KAYGI', 'ŞÜKÜR', 'AİLE', 'RAMAZAN'];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
        children: [
          Row(
            children: [
              Expanded(child: Text('Okuma Planları', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
            ],
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _TopPill('Okuma Planlarım'),
                _TopPill('Planlar Bul', selected: true),
                _TopPill('Kaydedildi'),
                _TopPill('Tamamlandı'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final t in topics)
                SizedBox(
                  width: 145,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25473C),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                )
            ],
          ),
          const SizedBox(height: 34),
          const _PlanSection('Huzur', [
            ('7 Gün', 'İç Huzuru', '7'),
            ('5 Gün', 'Dinlenmek için Zaman Ayırmak', '5'),
            ('10 Gün', 'Tevekkül', '10'),
          ]),
          const SizedBox(height: 30),
          const _PlanSection('Kuran’ın Tümü', [
            ('30 Gün', '30 Günde Kuran’a Başlangıç', '30'),
            ('90 Gün', '90 Günde Kuran Okuma', '90'),
            ('1 Yıl', 'Bir Yılda Kuran', '365'),
          ]),
          const SizedBox(height: 30),
          const _PlanSection('Ramazan', [
            ('30 Gün', 'Ramazan Hatmi', '30'),
            ('10 Gün', 'Son On Gece', '10'),
            ('7 Gün', 'Ramazan’a Hazırlık', '7'),
          ]),
        ],
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill(this.text, {this.selected = false});
  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFF333131),
          borderRadius: BorderRadius.circular(23),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class _PlanSection extends StatelessWidget {
  const _PlanSection(this.title, this.items);
  final String title;
  final List<(String, String, String)> items;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
              const Text('Hepsini Gör  ›', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 14),
          for (final p in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C443B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(p.$3, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.$1, style: const TextStyle(color: Colors.white60)),
                        const SizedBox(height: 2),
                        Text(p.$2, style: const TextStyle(fontSize: 17)),
                      ],
                    ),
                  ),
                  FilledButton.tonal(onPressed: () {}, child: const Text('Başla')),
                ],
              ),
            )
        ],
      );
}
