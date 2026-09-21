import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/generated_app_localizations.dart';
import '../../navigation/app_navigation.dart';
import '../reader/quran_reader_screen.dart';
import 'quran_learn_overview.dart';
import 'quran_progress_overview.dart';

class QuranAreaScreen extends StatefulWidget {
  const QuranAreaScreen({super.key});

  @override
  State<QuranAreaScreen> createState() => _QuranAreaScreenState();
}

class _QuranAreaScreenState extends State<QuranAreaScreen> {
  int _section = 0;

  @override
  void initState() {
    super.initState();
    AppNavigation.instance.readerRequest.addListener(_handleReaderRequest);
    AppNavigation.instance.quranReadRequest.addListener(_handleQuranReadRequest);
    AppNavigation.instance.reportQuranSection(_section);
  }

  @override
  void dispose() {
    AppNavigation.instance.readerRequest.removeListener(_handleReaderRequest);
    AppNavigation.instance.quranReadRequest.removeListener(
      _handleQuranReadRequest,
    );
    super.dispose();
  }

  void _handleReaderRequest() {
    if (!mounted || AppNavigation.instance.readerRequest.value == null) return;
    _showReadSection();
  }

  void _handleQuranReadRequest() {
    if (!mounted) return;
    _showReadSection();
  }

  void _showReadSection() {
    if (_section == 0) {
      AppNavigation.instance.reportQuranSection(_section);
      return;
    }
    setState(() => _section = 0);
    AppNavigation.instance.reportQuranSection(_section);
  }

  void _selectSection(int index) {
    if (_section == index) return;
    HapticFeedback.selectionClick();
    setState(() => _section = index);
    AppNavigation.instance.reportQuranSection(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: AppNavigation.instance.readerSelectionActive,
            builder: (context, selectionActive, _) {
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 140),
                opacity: selectionActive ? .48 : 1,
                child: AbsorbPointer(
                  absorbing: selectionActive,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                    child: _SectionSwitcher(
                      selectedIndex: _section,
                      labels: [
                        l10n.quranTabRead,
                        l10n.quranTabLearn,
                        l10n.quranTabProgress,
                      ],
                      onSelected: _selectSection,
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: IndexedStack(
              index: _section,
              children: const [
                QuranReaderScreen(),
                QuranLearnOverview(),
                QuranProgressOverview(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionSwitcher extends StatelessWidget {
  const _SectionSwitcher({
    required this.selectedIndex,
    required this.labels,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = selectedIndex == index;
            return Expanded(
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? scheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
