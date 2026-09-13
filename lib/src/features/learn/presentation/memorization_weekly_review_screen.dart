import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/surah_localization.dart';
import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_progress_store.dart';
import '../application/memorization_recall_history_store.dart';
import '../application/memorization_recall_quiz.dart';
import '../application/memorization_weekly_review.dart';

class MemorizationWeeklyReviewScreen extends StatefulWidget {
  const MemorizationWeeklyReviewScreen({super.key});

  @override
  State<MemorizationWeeklyReviewScreen> createState() =>
      _MemorizationWeeklyReviewScreenState();
}

class _MemorizationWeeklyReviewScreenState
    extends State<MemorizationWeeklyReviewScreen> {
  static const _progressStore = MemorizationProgressStore();
  static const _historyStore = MemorizationRecallHistoryStore();

  List<MemorizationRecallQuestion>? _questions;
  int _index = 0;
  int _knownCount = 0;
  bool _revealed = false;
  bool _saving = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final snapshot = await _progressStore.load();
    final history = await _historyStore.load();
    final questions = buildWeeklyReviewQuestions(
      snapshot,
      preferredIds: history.weakQuestionIds,
    );
    if (!mounted) return;
    setState(() {
      _questions = questions;
      _index = 0;
      _knownCount = 0;
      _revealed = false;
      _saving = false;
      _completed = false;
    });
  }

  void _reveal() {
    if (_saving) return;
    HapticFeedback.lightImpact();
    setState(() => _revealed = true);
  }

  Future<void> _recordResult(bool known) async {
    final questions = _questions;
    if (questions == null ||
        questions.isEmpty ||
        _completed ||
        _saving ||
        _index >= questions.length) {
      return;
    }

    final question = questions[_index];
    setState(() => _saving = true);
    if (known) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    await _historyStore.recordResult(question.id, known: known);
    await _progressStore.recordReview(
      question.page,
      selfAssessment: known
          ? MemorizationSelfAssessment.independent
          : MemorizationSelfAssessment.struggled,
    );

    if (!mounted) return;
    final nextKnownCount = _knownCount + (known ? 1 : 0);
    final isLast = _index >= questions.length - 1;
    setState(() {
      _knownCount = nextKnownCount;
      _saving = false;
      _revealed = false;
      if (isLast) {
        _completed = true;
      } else {
        _index += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final questions = _questions;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memorizeWeeklyTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: questions == null
            ? const Center(child: CircularProgressIndicator())
            : questions.isEmpty
                ? _WeeklyEmptyState(
                    title: l10n.memorizeWeeklyEmptyTitle,
                    body: l10n.memorizeWeeklyEmptyBody,
                  )
                : _completed
                    ? _WeeklyCompleteState(
                        knownCount: _knownCount,
                        totalCount: questions.length,
                        title: l10n.memorizeWeeklyCompleteTitle,
                        body: l10n.memorizeWeeklyCompleteBody,
                        restartLabel: l10n.memorizeWeeklyRestart,
                        onRestart: _loadSession,
                      )
                    : _buildQuestion(context, questions),
      ),
    );
  }

  Widget _buildQuestion(
    BuildContext context,
    List<MemorizationRecallQuestion> questions,
  ) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final question = questions[_index];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (_index + 1) / questions.length,
                  minHeight: 7,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_index + 1}/${questions.length}',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _WeeklyQuestionCard(
          question: question,
          continuePrompt: l10n.memorizeTestContinuePrompt,
        ),
        const SizedBox(height: 14),
        if (!_revealed)
          FilledButton.icon(
            onPressed: _saving ? null : _reveal,
            icon: const Icon(Icons.visibility_outlined),
            label: Text(l10n.memorizeTestShowAnswer),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          )
        else ...[
          _WeeklyAnswerCard(question: question),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _saving ? null : () => _recordResult(false),
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
                  onPressed: _saving ? null : () => _recordResult(true),
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
      ],
    );
  }
}

class _WeeklyQuestionCard extends StatelessWidget {
  const _WeeklyQuestionCard({
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

class _WeeklyAnswerCard extends StatelessWidget {
  const _WeeklyAnswerCard({required this.question});

  final MemorizationRecallQuestion question;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
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

class _WeeklyEmptyState extends StatelessWidget {
  const _WeeklyEmptyState({required this.title, required this.body});

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
                Icons.event_repeat_rounded,
                color: scheme.primary,
                size: 36,
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

class _WeeklyCompleteState extends StatelessWidget {
  const _WeeklyCompleteState({
    required this.knownCount,
    required this.totalCount,
    required this.title,
    required this.body,
    required this.restartLabel,
    required this.onRestart,
  });

  final int knownCount;
  final int totalCount;
  final String title;
  final String body;
  final String restartLabel;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = totalCount == 0 ? 0.0 : knownCount / totalCount;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 10,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                  Text(
                    '$knownCount/$totalCount',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.replay_rounded),
              label: Text(restartLabel),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
