import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/surah_catalog.dart';
import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_target_catalog.dart';
import '../application/memorization_target_store.dart';

String memorizationTargetLabel(
  BuildContext context,
  MemorizationTargetId target,
) {
  final l10n = GeneratedAppLocalizations.of(context)!;
  if (target == MemorizationTargetId.fullQuran) return l10n.appTitle;
  if (target == MemorizationTargetId.juzAmma) {
    return '30 ${l10n.memorizeJuz}';
  }

  final definition = memorizationTargetDefinition(target);
  final surahNumber = definition.surahNumbers.single;
  final surah = surahCatalog.firstWhere((item) => item.number == surahNumber);
  return Localizations.localeOf(context).languageCode == 'ar'
      ? surah.nameAr
      : surah.nameTr;
}

class MemorizationTargetScreen extends StatefulWidget {
  const MemorizationTargetScreen({super.key});

  @override
  State<MemorizationTargetScreen> createState() =>
      _MemorizationTargetScreenState();
}

class _MemorizationTargetScreenState extends State<MemorizationTargetScreen> {
  static const _store = MemorizationTargetStore();
  MemorizationTargetId? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final selected = await _store.load();
    if (!mounted) return;
    setState(() => _selected = selected);
  }

  Future<void> _select(MemorizationTargetId target) async {
    HapticFeedback.selectionClick();
    await _store.save(target);
    if (!mounted) return;
    setState(() => _selected = target);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final selected = _selected;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.memorizeTitle)),
      body: selected == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Text(
                  l10n.memorizeWelcomeBody,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                for (final target in memorizationTargetDefinitions) ...[
                  _TargetCard(
                    title: memorizationTargetLabel(context, target.id),
                    pageCount: memorizationPagesForTarget(target.id).length,
                    selected: selected == target.id,
                    icon: _iconFor(target.id),
                    onTap: () => _select(target.id),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  IconData _iconFor(MemorizationTargetId target) {
    return switch (target) {
      MemorizationTargetId.fullQuran => Icons.auto_stories_rounded,
      MemorizationTargetId.juzAmma => Icons.view_agenda_outlined,
      MemorizationTargetId.alKahf => Icons.landscape_outlined,
      MemorizationTargetId.yaSin => Icons.favorite_border_rounded,
      MemorizationTargetId.arRahman => Icons.spa_outlined,
      MemorizationTargetId.alMulk => Icons.nightlight_outlined,
    };
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.title,
    required this.pageCount,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int pageCount;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary.withValues(alpha: .12)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pageCount ${l10n.memorizePages}',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
