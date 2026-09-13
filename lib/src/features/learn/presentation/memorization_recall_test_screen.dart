import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/surah_localization.dart';
import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_hint_quiz.dart';
import '../application/memorization_progress_store.dart';
import '../application/memorization_recall_history_store.dart';
import '../application/memorization_recall_quiz.dart';

enum _RecallTestMode { continuation, hint }

class MemorizationRecallTestScreen extends StatefulWidget {
  const MemorizationRecallTestScreen({super.key, this.initialQuestionId});

  final String? initialQuestionId;

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
  MemorizationHintQuestion? _hintQuestion;
  _RecallTestMode _mode = _RecallTestMode.continuation;
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
    final initialId = widget.initialQuestionId;
    final preferred = initialId == null
        ? history.weakQuestionIds
        : <String>{initialId};

    if (!mounted) return;
    setState(() {
      _memorizedPages = snapshot.memorizedPages;
      _preferredQuestionIds = history.weakQuestionIds;
      _question = pickMemorizationRecallQuestion(
        snapshot.memorizedPages,
        preferredIds: preferred,
      );
      _hintQuestion = pickMemorizationHintQuestion(
        snapshot.memorizedPages,
        preferredIds: preferred,
      );
    });
  }

  void _setMode(_RecallTestMode mode) {
    if (_mode == mode || _savingResult) return;
    HapticFeedback.selectionClick();
    setState(() {
      _mode = mode;
      _revealed = false;
    });
  }

  void _nextQuestion() {
    final pages = _memorizedPages;
    if (pages == null || _savingResult) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_mode == _RecallTestMode.continuation) {
        _question = pickMemorizationRecallQuestion(
          pages,
          previousId: _question?.id,
          preferredIds: _preferredQuestionIds,
        );
      } else {
        _hintQuestion = pickMemorizationHintQuestion(
          pages,
          previousId: _hintQuestion?.id,
          preferredIds: _preferredQuestionIds,
        );
      }
      _revealed = false;
    });
  }

  MemorizationSelfAssessment _pageAssessment(
    MemorizationRecallAssessment assessment,
  ) {
    return switch (assessment) {
      MemorizationRecallAssessment.independent =>
        MemorizationSelfAssessment.independent,
      MemorizationRecallAssessment.assisted => MemorizationSelfAssessment.assisted,
      MemorizationRecallAssessment.struggled =>
        MemorizationSelfAssessment.struggled,
    };
  }

  Future<void> _recordAssessment(
    MemorizationRecallAssessment assessment,
  ) async {
    final pages = _memorizedPages;
    if (pages == null || _savingResult) return;

    final questionId = _mode == _RecallTestMode.continuation
        ? _question?.id
        : _hintQuestion?.id;
    final page = _mode == _RecallTestMode.continuation
        ? _question?.page
        : _hintQuestion?.page;
    if (questionId == null || page == null) return;

    setState(() => _savingResult = true);
    if (assessment == MemorizationRecallAssessment.independent) {
      HapticFeedback.lightImpact();
    } else if (assessment == MemorizationRecallAssessment.assisted) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.mediumImpact();
    }

    final history = await _historyStore.recordAssessment(
      questionId,
      assessment: assessment,
    );
    await _store.recordReview(
      page,
      selfAssessment: _pageAssessment(assessment),
    );
    if (!mounted) return;

    final preferredIds = history.weakQuestionIds;
    setState(() {
      _preferredQuestionIds = preferredIds;
      if (_mode == _RecallTestMode.continuation) {
        _question = pickMemorizationRecallQuestion(
          pages,
          previousId: questionId,
          preferredIds: preferredIds,
        );
      } else {
        _hintQuestion = pickMemorizationHintQuestion(
          pages,
          previousId: questionId,
          preferredIds: preferredIds,
        );
      }
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
    final pages = _memorizedPages;
    final recall = _question;
    final hint = _hintQuestion;
    final isHint = _mode == _RecallTestMode.hint;
    final hasQuestion = isHint ? hint != null : recall != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memorizeTestTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: pages == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  SegmentedButton<_RecallTestMode>(
                    segments: [
                      ButtonSegment(
                        value: _RecallTestMode.continuation,
                        icon: const Icon(Icons.redo_rounded),
                        label: Text(l10n.memorizeTestModeContinue),
                      ),
                      ButtonSegment(
                        value: _RecallTestMode.hint,
                        icon: const Icon(Icons.lightbulb_outline_rounded),
                        label: Text(l10n.memorizeTestModeHint),
                      ),
                    ],
                    selected: <_RecallTestMode>{_mode},
                    onSelectionChanged: _savingResult
                        ? null
                        : (selection) => _setMode(selection.first),
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: 18),
                  if (!hasQuestion)
                    _EmptyRecallState(
                      title: l10n.memorizeTestEmptyTitle,
                      body: isHint
                          ? l10n.memorizeHintEmptyBody
                          : l10n.memorizeTestEmptyBody,
                    )
                  else ...[
                    _ArabicQuestionCard(
                      surah: isHint ? hint!.surah : recall!.surah,
                      ayah: isHint ? hint!.ayah : recall!.ayah,
                      arabic: isHint ? hint!.hintArabic : recall!.promptArabic,
                      prompt: isHint
                          ? l10n.memorizeHintPrompt
                          : l10n.memorizeTestContinuePrompt,
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
                      _ArabicAnswerCard(
                        ayah: isHint ? hint!.ayah : recall!.answerAyah,
                        arabic:
                            isHint ? hint!.answerArabic : recall!.answerArabic,
                      ),
                      const SizedBox(height: 14),
                      _AssessmentButton(
                        icon: Icons.check_circle_outline_rounded,
                        label: l10n.memorizeTestIndependent,
                        onPressed: _savingResult
                            ? null
                            : () => _recordAssessment(
                                  MemorizationRecallAssessment.independent,
                                ),
                        tone: _AssessmentTone.positive,
                      ),
                      const SizedBox(height: 10),
                      _AssessmentButton(
                        icon: Icons.lightbulb_outline_rounded,
                        label: l10n.memorizeTestAssisted,
                        onPressed: _savingResult
                            ? null
                            : () => _recordAssessment(
                                  MemorizationRecallAssessment.assisted,
                                ),
                        tone: _AssessmentTone.neutral,
                      ),
                      const SizedBox(height: 10),
                      _AssessmentButton(
                        icon: Icons.replay_rounded,
                        label: l10n.memorizeTestStruggled,
                        onPressed: _savingResult
                            ? null
                            : () => _recordAssessment(
                                  MemorizationRecallAssessment.struggled,
                                ),
                        tone: _AssessmentTone.negative,
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _savingResult ? null : _nextQuestion,
                      icon: const Icon(Icons.casino_outlined),
                      label: Text(l10n.memorizeTestAnother),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ArabicQuestionCard extends StatelessWidget {
  const _ArabicQuestionCard({
    required this.surah,
    required this.ayah,
    required this.arabic,
    required this.prompt,
  });

  final int surah;
  final int ayah;
  final String arabic;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final localeCode = Localizations.localeOf(context).languageCode;
    final surahName = localizedSurahName(surah, localeCode);
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
            '$surahName · $ayah',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            arabic,
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
            prompt,
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

class _ArabicAnswerCard extends StatelessWidget {
  const _ArabicAnswerCard({required this.ayah, required this.arabic});

  final int ayah;
  final String arabic;

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
            '$ayah',
            style: TextStyle(
              color: scheme.onPrimaryContainer.withValues(alpha: .7),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            arabic,
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

enum _AssessmentTone { positive, neutral, negative }

class _AssessmentButton extends StatelessWidget {
  const _AssessmentButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final _AssessmentTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      _AssessmentTone.positive => (
          scheme.primaryContainer.withValues(alpha: .9),
          scheme.onPrimaryContainer,
        ),
      _AssessmentTone.neutral => (
          scheme.secondaryContainer.withValues(alpha: .85),
          scheme.onSecondaryContainer,
        ),
      _AssessmentTone.negative => (
          scheme.errorContainer.withValues(alpha: .72),
          scheme.onErrorContainer,
        ),
    };
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: background,
        foregroundColor: foreground,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
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
    );
  }
}
