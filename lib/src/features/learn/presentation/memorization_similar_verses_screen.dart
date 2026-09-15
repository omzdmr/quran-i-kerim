import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/surah_localization.dart';
import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_recall_history_store.dart';
import '../application/memorization_similar_verses.dart';

class MemorizationSimilarVersesScreen extends StatefulWidget {
  const MemorizationSimilarVersesScreen({
    required this.surah,
    required this.ayah,
    super.key,
  });

  final int surah;
  final int ayah;

  @override
  State<MemorizationSimilarVersesScreen> createState() =>
      _MemorizationSimilarVersesScreenState();
}

class _MemorizationSimilarVersesScreenState
    extends State<MemorizationSimilarVersesScreen> {
  static const _historyStore = MemorizationRecallHistoryStore();

  late final List<MemorizationVerseSimilarity> _matches;
  Set<String> _manuallyWeakIds = const <String>{};
  Set<String> _savingIds = const <String>{};

  @override
  void initState() {
    super.initState();
    _matches = findSimilarMemorizationVerses(
      surah: widget.surah,
      ayah: widget.ayah,
    );
    _loadWeakStatus();
  }

  Future<void> _loadWeakStatus() async {
    final history = await _historyStore.load();
    if (!mounted) return;
    setState(() => _manuallyWeakIds = history.manuallyWeakQuestionIds);
  }

  String _candidateId(MemorizationVerseSimilarity similarity) =>
      '${similarity.candidate.surah}:${similarity.candidate.ayah}';

  Future<void> _toggleWeak(MemorizationVerseSimilarity similarity) async {
    final id = _candidateId(similarity);
    if (_savingIds.contains(id)) return;

    final shouldMark = !_manuallyWeakIds.contains(id);
    HapticFeedback.selectionClick();
    setState(() => _savingIds = <String>{..._savingIds, id});

    final history = await _historyStore.setManuallyWeak(
      id,
      weak: shouldMark,
    );
    if (!mounted) return;

    setState(() {
      _manuallyWeakIds = history.manuallyWeakQuestionIds;
      _savingIds = <String>{..._savingIds}..remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.memorizeSimilarTitle)),
      body: _matches.isEmpty
          ? _EmptyState(
              title: l10n.memorizeSimilarEmptyTitle,
              body: l10n.memorizeSimilarEmptyBody,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Material(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: scheme.primary,
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.memorizeSimilarBody,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                for (var index = 0; index < _matches.length; index++) ...[
                  _SimilarityCard(
                    similarity: _matches[index],
                    localeCode: localeCode,
                    sourceLabel: l10n.memorizeSimilarSource,
                    candidateLabel: l10n.memorizeSimilarCandidate,
                    pageLabel: l10n.quranProgressCurrentPage,
                    weakLabel: l10n.memorizeWeakTitle,
                    isWeak: _manuallyWeakIds.contains(
                      _candidateId(_matches[index]),
                    ),
                    isSaving: _savingIds.contains(
                      _candidateId(_matches[index]),
                    ),
                    onToggleWeak: () => _toggleWeak(_matches[index]),
                  ),
                  if (index != _matches.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _SimilarityCard extends StatelessWidget {
  const _SimilarityCard({
    required this.similarity,
    required this.localeCode,
    required this.sourceLabel,
    required this.candidateLabel,
    required this.pageLabel,
    required this.weakLabel,
    required this.isWeak,
    required this.isSaving,
    required this.onToggleWeak,
  });

  final MemorizationVerseSimilarity similarity;
  final String localeCode;
  final String sourceLabel;
  final String candidateLabel;
  final String pageLabel;
  final String weakLabel;
  final bool isWeak;
  final bool isSaving;
  final VoidCallback onToggleWeak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final source = similarity.source;
    final candidate = similarity.candidate;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VerseComparisonBlock(
              label: sourceLabel,
              reference:
                  '${localizedSurahName(source.surah, localeCode)} · ${source.surah}:${source.ayah}',
              arabic: source.arabic,
              sharedPrefixWords: similarity.sharedPrefixWords,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(color: scheme.outlineVariant),
            ),
            _VerseComparisonBlock(
              label: candidateLabel,
              reference:
                  '${localizedSurahName(candidate.surah, localeCode)} · ${candidate.surah}:${candidate.ayah} · $pageLabel ${candidate.page}',
              arabic: candidate.arabic,
              sharedPrefixWords: similarity.sharedPrefixWords,
            ),
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilterChip(
                selected: isWeak,
                onSelected: isSaving ? null : (_) => onToggleWeak(),
                avatar: isSaving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isWeak
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        size: 18,
                      ),
                label: Text(weakLabel),
                showCheckmark: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseComparisonBlock extends StatelessWidget {
  const _VerseComparisonBlock({
    required this.label,
    required this.reference,
    required this.arabic,
    required this.sharedPrefixWords,
  });

  final String label;
  final String reference;
  final String arabic;
  final int sharedPrefixWords;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wordMatches = RegExp(r'\S+').allMatches(arabic).toList();
    final highlightedWordCount = sharedPrefixWords < wordMatches.length
        ? sharedPrefixWords
        : wordMatches.length;
    final highlightEnd = highlightedWordCount <= 0
        ? 0
        : wordMatches[highlightedWordCount - 1].end;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            color: scheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          reference,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            children: [
              if (highlightEnd > 0)
                TextSpan(
                  text: arabic.substring(0, highlightEnd),
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              TextSpan(
                text: arabic.substring(highlightEnd),
                style: TextStyle(color: scheme.onSurface),
              ),
            ],
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 25, height: 1.85),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.compare_arrows_rounded,
              size: 42,
              color: scheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
