import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final topics = [
      l10n.text('patience').toUpperCase(),
      l10n.text('peace').toUpperCase(),
      l10n.text('anxiety').toUpperCase(),
      l10n.text('gratitude').toUpperCase(),
      l10n.text('family').toUpperCase(),
      l10n.text('ramadan').toUpperCase(),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.text('readingPlans'),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded),
              ),
            ],
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 44,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TopPill(l10n.text('myPlans')),
                  _TopPill(l10n.text('findPlans'), selected: true),
                  _TopPill(l10n.text('saved')),
                  _TopPill(l10n.text('completed')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final topic in topics)
                Container(
                  width: 145,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    topic,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 34),
          _PlanSection(l10n.text('peace'), [
            (l10n.text('day7'), l10n.text('innerPeace'), '7'),
            (l10n.text('day5'), l10n.text('makeTimeRest'), '5'),
            (l10n.text('day10'), l10n.text('trust'), '10'),
          ]),
          const SizedBox(height: 30),
          _PlanSection(l10n.text('allQuran'), [
            (l10n.text('day30'), l10n.text('quran30'), '30'),
            (l10n.text('day90'), l10n.text('quran90'), '90'),
            (l10n.text('year1'), l10n.text('quranYear'), '365'),
          ]),
          const SizedBox(height: 30),
          _PlanSection(l10n.text('ramadan'), [
            (l10n.text('day30'), l10n.text('ramadanKhatm'), '30'),
            (l10n.text('day10'), l10n.text('lastTenNights'), '10'),
            (l10n.text('day7'), l10n.text('prepareRamadan'), '7'),
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: selected ? scheme.primary : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? scheme.onPrimary : scheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PlanSection extends StatelessWidget {
  const _PlanSection(this.title, this.items);

  final String title;
  final List<(String, String, String)> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
            ),
            Text(
              l10n.text('viewAll'),
              style: TextStyle(color: scheme.primary, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final plan in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    plan.$3,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.$1,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(plan.$2, style: const TextStyle(fontSize: 17)),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () {},
                  child: Text(l10n.text('start')),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
