import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum LearnLessonVisualStepType {
  introduction,
  verse,
  meaning,
  explanation,
  hadith,
  review,
  quiz,
  summary,
  completion,
}

class LearnLessonVisualStep {
  const LearnLessonVisualStep({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.eyebrow,
    this.arabicText,
    this.transliteration,
    this.reference,
    this.quizOptions = const <String>[],
    this.correctQuizIndex,
  });

  final String id;
  final LearnLessonVisualStepType type;
  final String title;
  final String? body;
  final String? eyebrow;
  final String? arabicText;
  final String? transliteration;
  final String? reference;
  final List<String> quizOptions;
  final int? correctQuizIndex;
}

class LearnLessonVisualLabels {
  const LearnLessonVisualLabels({
    required this.previous,
    required this.next,
    required this.finish,
    required this.correctFeedback,
    required this.incorrectFeedback,
    required this.backToLessons,
    required this.continueInQuran,
  });

  final String previous;
  final String next;
  final String finish;
  final String correctFeedback;
  final String incorrectFeedback;
  final String backToLessons;
  final String continueInQuran;
}

/// Paged lesson shell inspired by the supplied lesson references.
///
/// It contains no religious copy. Lesson text, references, hadith and quiz
/// answers must be injected from a verified source package by the caller.
class LearnLessonVisualFlow extends StatefulWidget {
  const LearnLessonVisualFlow({
    required this.lessonTitle,
    required this.steps,
    required this.labels,
    super.key,
    this.initialStepIndex = 0,
    this.onStepChanged,
    this.onFinished,
    this.onBackToLessons,
    this.onContinueInQuran,
  });

  final String lessonTitle;
  final List<LearnLessonVisualStep> steps;
  final LearnLessonVisualLabels labels;
  final int initialStepIndex;
  final ValueChanged<int>? onStepChanged;
  final VoidCallback? onFinished;
  final VoidCallback? onBackToLessons;
  final VoidCallback? onContinueInQuran;

  @override
  State<LearnLessonVisualFlow> createState() => _LearnLessonVisualFlowState();
}

class _LearnLessonVisualFlowState extends State<LearnLessonVisualFlow> {
  late int _index;
  int? _quizSelection;

  @override
  void initState() {
    super.initState();
    _index = _safeInitialIndex();
  }

  @override
  void didUpdateWidget(covariant LearnLessonVisualFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.steps.isEmpty) {
      _index = 0;
      _quizSelection = null;
      return;
    }
    if (_index >= widget.steps.length) {
      _index = widget.steps.length - 1;
      _quizSelection = null;
    }
  }

  int _safeInitialIndex() {
    if (widget.steps.isEmpty) return 0;
    return widget.initialStepIndex.clamp(0, widget.steps.length - 1).toInt();
  }

  LearnLessonVisualStep get _step => widget.steps[_index];

  bool get _isLast => _index >= widget.steps.length - 1;

  bool get _canAdvance {
    if (_step.type != LearnLessonVisualStepType.quiz) return true;
    if (_step.quizOptions.isEmpty) return true;
    return _quizSelection != null;
  }

  void _goTo(int index) {
    if (widget.steps.isEmpty) return;
    final safe = index.clamp(0, widget.steps.length - 1).toInt();
    if (safe == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _index = safe;
      _quizSelection = null;
    });
    widget.onStepChanged?.call(safe);
  }

  void _next() {
    if (!_canAdvance) return;
    if (_isLast) {
      widget.onFinished?.call();
      return;
    }
    _goTo(_index + 1);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();
    final step = _step;
    final progress = (_index + 1) / widget.steps.length;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _backgroundFor(step.type),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.lessonTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      color: Colors.white,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: SingleChildScrollView(
                    key: ValueKey(step.id),
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                    child: _LessonStepCard(
                      step: step,
                      selectedQuizIndex: _quizSelection,
                      labels: widget.labels,
                      onQuizSelected: (index) {
                        if (_quizSelection != null) return;
                        HapticFeedback.selectionClick();
                        setState(() => _quizSelection = index);
                      },
                    ),
                  ),
                ),
              ),
              if (step.type == LearnLessonVisualStepType.completion)
                _CompletionActions(
                  labels: widget.labels,
                  onBackToLessons: widget.onBackToLessons,
                  onContinueInQuran: widget.onContinueInQuran,
                )
              else
                _LessonNavigation(
                  labels: widget.labels,
                  canGoBack: _index > 0,
                  isLast: _isLast,
                  onPrevious: () => _goTo(_index - 1),
                  onNext: _canAdvance ? _next : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Color> _backgroundFor(LearnLessonVisualStepType type) {
  return switch (type) {
    LearnLessonVisualStepType.quiz || LearnLessonVisualStepType.review => const [
        Color(0xFF6C356F),
        Color(0xFF3A244B),
      ],
    LearnLessonVisualStepType.completion => const [
        Color(0xFF49A56A),
        Color(0xFF0E3B35),
      ],
    _ => const [Color(0xFF9B652A), Color(0xFF3A160D)],
  };
}

class _LessonStepCard extends StatelessWidget {
  const _LessonStepCard({
    required this.step,
    required this.selectedQuizIndex,
    required this.labels,
    required this.onQuizSelected,
  });

  final LearnLessonVisualStep step;
  final int? selectedQuizIndex;
  final LearnLessonVisualLabels labels;
  final ValueChanged<int> onQuizSelected;

  @override
  Widget build(BuildContext context) {
    if (step.type == LearnLessonVisualStepType.completion) {
      return _CompletionCard(step: step);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white38),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (step.eyebrow != null) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  step.eyebrow!,
                  style: const TextStyle(
                    color: Color(0xFF3D2A24),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            step.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          if (step.arabicText != null) ...[
            const SizedBox(height: 20),
            Text(
              step.arabicText!,
              textAlign: TextAlign.end,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                height: 1.8,
              ),
            ),
          ],
          if (step.transliteration != null) ...[
            const SizedBox(height: 12),
            Text(
              step.transliteration!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          if (step.body != null) ...[
            const SizedBox(height: 16),
            Text(
              step.body!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.55,
              ),
            ),
          ],
          if (step.reference != null) ...[
            const SizedBox(height: 14),
            Text(
              step.reference!,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (step.type == LearnLessonVisualStepType.quiz &&
              step.quizOptions.isNotEmpty) ...[
            const SizedBox(height: 20),
            for (var index = 0; index < step.quizOptions.length; index++) ...[
              _QuizOption(
                label: step.quizOptions[index],
                selected: selectedQuizIndex == index,
                correct: selectedQuizIndex != null &&
                    step.correctQuizIndex == index,
                wrong: selectedQuizIndex == index &&
                    step.correctQuizIndex != null &&
                    step.correctQuizIndex != index,
                onTap: () => onQuizSelected(index),
              ),
              const SizedBox(height: 10),
            ],
            if (selectedQuizIndex != null && step.correctQuizIndex != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    selectedQuizIndex == step.correctQuizIndex
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: selectedQuizIndex == step.correctQuizIndex
                        ? const Color(0xFF33D68B)
                        : const Color(0xFFFF7D83),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedQuizIndex == step.correctQuizIndex
                          ? labels.correctFeedback
                          : labels.incorrectFeedback,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.label,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = correct
        ? const Color(0xFF16B972)
        : wrong
        ? const Color(0xFFD65B67)
        : selected
        ? Colors.white24
        : Colors.white10;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.step});

  final LearnLessonVisualStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 10),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (step.body != null) ...[
            const SizedBox(height: 12),
            Text(
              step.body!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LessonNavigation extends StatelessWidget {
  const _LessonNavigation({
    required this.labels,
    required this.canGoBack,
    required this.isLast,
    required this.onPrevious,
    required this.onNext,
  });

  final LearnLessonVisualLabels labels;
  final bool canGoBack;
  final bool isLast;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Row(
        children: [
          IconButton.outlined(
            onPressed: canGoBack ? onPrevious : null,
            color: Colors.white,
            disabledColor: Colors.white24,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: labels.previous,
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF24362F),
            ),
            icon: Icon(
              isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
            ),
            label: Text(isLast ? labels.finish : labels.next),
          ),
        ],
      ),
    );
  }
}

class _CompletionActions extends StatelessWidget {
  const _CompletionActions({
    required this.labels,
    required this.onBackToLessons,
    required this.onContinueInQuran,
  });

  final LearnLessonVisualLabels labels;
  final VoidCallback? onBackToLessons;
  final VoidCallback? onContinueInQuran;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: onBackToLessons,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1C4A3A),
            ),
            child: Text(labels.backToLessons),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onContinueInQuran,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
            ),
            child: Text(labels.continueInQuran),
          ),
        ],
      ),
    );
  }
}
