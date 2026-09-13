import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/surah_localization.dart';
import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_progress_store.dart';
import '../application/memorization_recall_history_store.dart';
import '../application/memorization_recall_quiz.dart';

class MemorizationRecallTestScreen extends StatefulWidget {
  const MemorizationRecallTestScreen({super.key});

  @override
  State<MemorizationRecallTestScreen> createState() =>
      _MemorizationRecallTestScreenState();
}

class _MemorizationRecallTestScreenState
    extends State<MemorizationRecallTestScreen> {
  static const _store = MemorizationProgressStore();
  static const _historyStore = MemorizationRecallHistoryStore();

  Set<int>? _memorizedPages;
  Set<String> _preferredQuestionIds = const <String>{};
  MemorizationRecallQuestion? _question;
  bool _revealed = false;
  bool _savingResult = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snapshot = await _store.load();
    final history = await _historyStore.load();
    final question = pickMemorizationRecallQuestion(
      snapshot.memorizedPages,
      preferredIds: history.weakQuestionIds,
    );
    if (!mounted) return;
    setState(() {
      _memorizedPages = snapshot.memorizedPages;
      _preferredQuestionIds = history.weakQuestionIds;
      _question = question;
      _revealed = false;
    });
  }

  void _nextQuestion() {
    final pages = _memorizedPages;
    if (pages == null || _savingResult) return;
    HapticFeedback.selectionClick();
    final next = pickMemorizationRecallQuestion(
      pages,
      previousId: _question?.id,
      preferredIds: _preferredQuestionIds,
    );
    setState(() {
      _question = next;
      _revealed = false;
    });
  }

  Future<void> _recordResult(bool known) async {
    final question = _question;
    final pages = _memorizedPages;
    if (question == null || pages == null || _savingResult) return;

    setState(() => _savingResult = true);
    if (known) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    final history = await _historyStore.recordResult(
      question.id,
      known: known,
    );
    await _store.recordReview(
      question.page,
      selfAssessment: known
          ? MemorizationSelfAssessment.independent
          : MemorizationSelfAssessment.struggled,
    );

    if (!mounted) return;
    final preferredIds = history.weakQuestionIds;
    final next = pickMemorizationRecallQuestion(
      pages,
      previousId: question.id,
      preferredIds: preferredIds,
    );
    setState(() {
      _preferredQuestionIds = preferredIds;
      _question = next;
      _revealed = false;
      _savingResult = false;
    });
  }

  void _reveal() {
    if (_savingResult) return;
    HapticFeedback.lightImpact();
    setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final question = _question;
    final pages = _memorizedPages;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memorizeTestTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: pages == null
            ? const Center(child: CircularProgressIndicator())
            : question == null
                ? _EmptyRecallState(
                    title: l10n.memorizeTestEmptyTitle,
                    body: l10n.memorizeTestEmptyBody,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    children: [
                      _QuestionCard(
                        question: question,
                        continuePrompt: l10n.memorizeTestContinuePrompt,
                      ),
                      const SizedBox(height: 14),
                      if (!_revealed)
                        FilledButton.icon(
                          onPressed: _savingResult ? null : _reveal,
                          icon: const Icon(Icons.visibility_outlined),
                          label: Text(l10n.memorizeTestShowAnswer),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                          ),
                        )
                      else ...[
                        _AnswerCard(question: question),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: _savingResult
                                    ? null
                                    : () => _recordResult(false),
                                icon: const Icon(Icons.close_rounded),
                                label: Text(l10n.memorizeTestMissed),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  backgroundColor:
                                      scheme.errorContainer.withValues(alpha: .72),
                                  foregroundColor: scheme.onErrorContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: _savingResult
                                    ? null
                                    : () => _recordResult(true),
                                icon: const Icon(Icons.check_rounded),
                                label: Text(l10n.memorizeTestKnown),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  backgroundColor:
                                      scheme.primaryContainer.withValues(alpha: .9),
                                  foregroundColor: scheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _savingResult ? null : _nextQuestion,
                        icon: const Icon(Icons.casino_outlined),
                        label: Text(l10n.memorizeTestAnother),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.continuePrompt,
  });

  final MemorizationRecallQuestion question;
  final String continuePrompt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final localeCode = Localizations.localeOf(context).languageCode;
    final surahName = localizedSurahName(question.surah, localeCode);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: .55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$surahName · ${question.ayah}',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            question.promptArabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 29,
              height: 1.9,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            continuePrompt,
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.question});

  final MemorizationRecallQuestion question;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${question.answerAyah}',
            style: TextStyle(
              color: scheme.onPrimaryContainer.withValues(alpha: .7),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            question.answerArabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontSize: 29,
              height: 1.9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecallState extends StatelessWidget {
  const _EmptyRecallState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.casino_outlined,
                size: 36,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
