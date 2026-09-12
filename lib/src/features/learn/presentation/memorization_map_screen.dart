import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../../../navigation/app_navigation.dart';
import '../application/memorization_page_catalog.dart';
import '../application/memorization_progress_store.dart';

class MemorizationMapScreen extends StatefulWidget {
  const MemorizationMapScreen({super.key});

  @override
  State<MemorizationMapScreen> createState() => _MemorizationMapScreenState();
}

class _MemorizationMapScreenState extends State<MemorizationMapScreen> {
  static const _store = MemorizationProgressStore();
  MemorizationProgressSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snapshot = await _store.load();
    if (!mounted) return;
    setState(() => _snapshot = snapshot);
  }

  Future<void> _toggle(int page) async {
    HapticFeedback.selectionClick();
    final snapshot = await _store.togglePage(page);
    if (!mounted) return;
    setState(() => _snapshot = snapshot);
  }

  void _openPage(int page) {
    final info = memorizationPageInfo(page);
    if (info == null) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    AppNavigation.instance.openReader(surah: info.surah, ayah: info.ayah);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final snapshot = _snapshot;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.memorizeMapTitle)),
      body: snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.route_rounded,
                        color: scheme.onPrimaryContainer,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.memorizeMapHint,
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.memorizedCount} / 604 ${l10n.memorizePages}',
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (var juz = 1; juz <= 30; juz++)
                  _JuzSection(
                    juz: juz,
                    pages: memorizationPagesForJuz(juz),
                    snapshot: snapshot,
                    onToggle: _toggle,
                    onOpen: _openPage,
                    label: '${l10n.memorizeJuz} $juz',
                    completedLabel: l10n.memorizeCompleted,
                  ),
              ],
            ),
    );
  }
}

class _JuzSection extends StatelessWidget {
  const _JuzSection({
    required this.juz,
    required this.pages,
    required this.snapshot,
    required this.onToggle,
    required this.onOpen,
    required this.label,
    required this.completedLabel,
  });

  final int juz;
  final List<MemorizationPageInfo> pages;
  final MemorizationProgressSnapshot snapshot;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onOpen;
  final String label;
  final String completedLabel;

  @override
  Widget build(BuildContext context) {
    final completed = pages.where((page) => snapshot.containsPage(page.page)).length;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey<String>('memorize-juz-$juz'),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('$completed / ${pages.length} $completedLabel'),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final info = pages[index];
              final selected = snapshot.containsPage(info.page);
              return Semantics(
                button: true,
                selected: selected,
                label: '${info.page}',
                child: Material(
                  color: selected ? scheme.primary : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => onToggle(info.page),
                    onLongPress: () => onOpen(info.page),
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${info.page}',
                          style: TextStyle(
                            color: selected ? scheme.onPrimary : scheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (selected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: scheme.onPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
