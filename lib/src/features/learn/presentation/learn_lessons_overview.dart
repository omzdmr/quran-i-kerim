import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../../../l10n/strings/learn_catalog_strings.dart';
import '../../../l10n/strings/learn_strings.dart';
import '../application/learn_lesson_catalog.dart';
import '../application/learn_progress_store.dart';
import 'curated_lesson_screen.dart';

class LearnLessonsOverview extends StatefulWidget {
  const LearnLessonsOverview({super.key});

  @override
  State<LearnLessonsOverview> createState() => _LearnLessonsOverviewState();
}

class _LearnLessonsOverviewState extends State<LearnLessonsOverview> {
  final LearnProgressStore _progressStore = const LearnProgressStore();
  late Future<Map<String, LearnProgressSnapshot?>> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _loadProgress();
  }

  Future<Map<String, LearnProgressSnapshot?>> _loadProgress() async {
    final entries = await Future.wait(
      curatedLearnLessons.map((lesson) async {
        return MapEntry<String, LearnProgressSnapshot?>(
          lesson.id,
          await _progressStore.load(lesson.id),
        );
      }),
    );
    return <String, LearnProgressSnapshot?>{
      for (final entry in entries) entry.key: entry.value,
    };
  }

  Future<void> _openLesson(LearnLessonDefinition lesson) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CuratedLearnLessonScreen(lesson: lesson),
      ),
    );
    if (!mounted) return;
    setState(() => _progressFuture = _loadProgress());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;
    final steps = <({IconData icon, String label})>[
      (icon: Icons.menu_book_outlined, label: l10n.quranLearnFlowVerse),
      (icon: Icons.translate_rounded, label: l10n.quranLearnFlowMeaning),
      (icon: Icons.fact_check_outlined, label: l10n.quranLearnFlowSource),
      (icon: Icons.quiz_outlined, label: l10n.quranLearnFlowReview),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.quranLearnFlowTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                l10n.quranLearnFlowBody,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              for (var index = 0; index < steps.length; index++) ...[
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(steps[index].icon, color: scheme.primary),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        steps[index].label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (index != steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: SizedBox(
                      height: 16,
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: scheme.outlineVariant,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, LearnProgressSnapshot?>>(
          future: _progressFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const LinearProgressIndicator(),
              );
            }

            final progressByLesson =
                snapshot.data ?? const <String, LearnProgressSnapshot?>{};
            final completedCount = curatedLearnLessons.where((lesson) {
              return progressByLesson[lesson.id]
                      ?.completedStepIds
                      .contains('completion') ??
                  false;
            }).length;
            final summary = learnCatalogText(
              languageCode,
              'learnLessonProgressSummaryV1',
            )
                .replaceAll('{completed}', '$completedCount')
                .replaceAll('{total}', '${curatedLearnLessons.length}');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CatalogProgressCard(
                  completed: completedCount,
                  total: curatedLearnLessons.length,
                  label: summary,
                ),
                const SizedBox(height: 12),
                for (var index = 0;
                    index < curatedLearnLessons.length;
                    index++) ...[
                  _LessonCard(
                    lesson: curatedLearnLessons[index],
                    progress: progressByLesson[curatedLearnLessons[index].id],
                    languageCode: languageCode,
                    onTap: () => _openLesson(curatedLearnLessons[index]),
                  ),
                  if (index != curatedLearnLessons.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CatalogProgressCard extends StatelessWidget {
  const _CatalogProgressCard({
    required this.completed,
    required this.total,
    required this.label,
  });

  final int completed;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: scheme.surface.withValues(alpha: .65),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.progress,
    required this.languageCode,
    required this.onTap,
  });

  final LearnLessonDefinition lesson;
  final LearnProgressSnapshot? progress;
  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completed = progress?.completedStepIds.contains('completion') ?? false;
    final started = progress != null && progress!.completedStepIds.isNotEmpty;
    final actionKey = completed
        ? 'learnLessonCompletedV1'
        : started
        ? 'learnLessonContinueV1'
        : 'learnLessonStartV1';

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(
                      completed ? Icons.check_rounded : Icons.auto_stories_rounded,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          learnText(languageCode, 'learnLessonSourceBadgeV1'),
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          learnText(languageCode, lesson.titleKey),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                learnText(languageCode, lesson.subtitleKey),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 15),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonalIcon(
                  onPressed: onTap,
                  icon: Icon(
                    completed
                        ? Icons.replay_rounded
                        : started
                        ? Icons.play_arrow_rounded
                        : Icons.school_outlined,
                  ),
                  label: Text(learnText(languageCode, actionKey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
