import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../prayer/presentation/prayer_screen.dart';
import 'dhikr_counter_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final cards = [
      (l10n.text('patience'), const Color(0xFF6F533F), Icons.hourglass_bottom_rounded),
      (l10n.text('anxiety'), const Color(0xFF8A620D), Icons.psychology_alt_outlined),
      (l10n.text('anger'), const Color(0xFF493884), Icons.whatshot_outlined),
      (l10n.text('hope'), const Color(0xFF7B1737), Icons.wb_sunny_outlined),
      (l10n.text('gratitude'), const Color(0xFF795C5A), Icons.favorite_outline),
      (l10n.text('peace'), const Color(0xFF25658A), Icons.spa_outlined),
      (l10n.text('fear'), const Color(0xFF747113), Icons.shield_outlined),
      (l10n.text('family'), const Color(0xFF4A7080), Icons.groups_outlined),
    ];

    void openPrayer() {
      HapticFeedback.selectionClick();
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PrayerScreen()),
      );
    }

    void openDhikr() {
      HapticFeedback.selectionClick();
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const DhikrCounterScreen()),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 44, 20, 120),
        children: [
          Text(l10n.text('discoverTitle'), style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 26),
          TextField(
            decoration: InputDecoration(
              hintText: l10n.text('discoverSearchHint'),
              prefixIcon: const Icon(Icons.search_rounded, size: 29),
              filled: true,
              fillColor: scheme.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _PrayerFeatureCard(
            onTap: openPrayer,
            title: l10n.text('prayerTimes'),
            subtitle: l10n.text('prayerSubtitle'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Shortcut(
                  Icons.touch_app_outlined,
                  l10n.text('dhikrCounter'),
                  onTap: openDhikr,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Shortcut(
                  Icons.nights_stay_outlined,
                  l10n.text('morningEvening'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Shortcut(
                  Icons.library_add_check_outlined,
                  l10n.text('readingPlans'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _Shortcut(Icons.menu_book_outlined, l10n.text('verses'))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Shortcut(Icons.auto_stories_outlined, l10n.text('tafsirs')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Shortcut(Icons.headphones_outlined, l10n.text('audioQuran')),
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

class _PrayerFeatureCard extends StatelessWidget {
  const _PrayerFeatureCard({
    required this.onTap,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback onTap;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.mosque_outlined, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(this.icon, this.label, {this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: content,
      );
    }

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}
