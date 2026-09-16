import 'package:flutter/material.dart';

import '../../../data/translation_catalog.dart';
import '../../../data/translation_pack.dart';
import '../../../data/translation_repository.dart';
import '../../../l10n/strings/learn_strings.dart';
import '../../../navigation/app_navigation.dart';
import '../../../settings/app_settings.dart';
import '../application/learn_lesson_builder.dart';
import '../application/learn_lesson_catalog.dart';
import '../application/learn_progress_store.dart';
import 'lesson_visual_flow.dart';

class CuratedLearnLessonScreen extends StatefulWidget {
  const CuratedLearnLessonScreen({
    required this.lesson,
    super.key,
  });

  final LearnLessonDefinition lesson;

  @override
  State<CuratedLearnLessonScreen> createState() =>
      _CuratedLearnLessonScreenState();
}

class _CuratedLearnLessonScreenState extends State<CuratedLearnLessonScreen> {
  Future<_LoadedLesson>? _future;
  String? _loadKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final key = '${settings.selectedQuranSourceId}|$languageCode';
    if (_future != null && _loadKey == key) return;
    _loadKey = key;
    _future = _load(
      sourceId: settings.selectedQuranSourceId,
      languageCode: languageCode,
    );
  }

  Future<_LoadedLesson> _load({
    required String sourceId,
    required String languageCode,
  }) async {
    final pack = await _resolvePack(sourceId, languageCode);
    final steps = buildSourcedLearnLessonSteps(
      lesson: widget.lesson,
      pack: pack,
      languageCode: languageCode,
      text: (key) => learnText(languageCode, key),
    );
    final progress = await const LearnProgressStore().load(widget.lesson.id);
    return _LoadedLesson(
      steps: steps,
      progress: progress,
      languageCode: languageCode,
    );
  }

  Future<TranslationPack> _resolvePack(
    String sourceId,
    String languageCode,
  ) async {
    final repository = TranslationRepository.instance;
    if (sourceId != arabicOriginalSourceId) {
      try {
        if (await repository.isInstalled(sourceId)) {
          return await repository.loadSourcePack(sourceId);
        }
      } catch (_) {
        // Fall through to a bundled source so Learn remains local-first.
      }
    }

    final fallbackId = languageCode == 'tr'
        ? bundledTurkishTranslationId
        : englishTranslationId;
    return repository.loadSourcePack(fallbackId);
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return FutureBuilder<_LoadedLesson>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    learnText(languageCode, 'learnLessonLoadErrorV1'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }
        final loaded = snapshot.data;
        if (loaded == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _LessonSession(
          lesson: widget.lesson,
          loaded: loaded,
        );
      },
    );
  }
}

class _LessonSession extends StatefulWidget {
  const _LessonSession({required this.lesson, required this.loaded});

  final LearnLessonDefinition lesson;
  final _LoadedLesson loaded;

  @override
  State<_LessonSession> createState() => _LessonSessionState();
}

class _LessonSessionState extends State<_LessonSession> {
  final LearnProgressStore _progressStore = const LearnProgressStore();
  Future<void> _writeQueue = Future<void>.value();
  late int _lastIndex;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _lastIndex = _initialIndex(widget.loaded);
  }

  int _initialIndex(_LoadedLesson loaded) {
    final stepIds = loaded.steps.map((step) => step.id).toList(growable: false);
    final progress = loaded.progress;
    if (progress == null) return 0;

    final current = progress.currentStepId;
    if (current != null) {
      final index = stepIds.indexOf(current);
      if (index >= 0) return index;
    }

    final pending = progress.nextPendingStep(stepIds);
    if (pending != null) {
      final index = stepIds.indexOf(pending);
      if (index >= 0) return index;
    }

    return loaded.steps.isEmpty ? 0 : loaded.steps.length - 1;
  }

  void _handleStepChanged(int nextIndex) {
    final previousIndex = _lastIndex;
    _lastIndex = nextIndex;
    if (nextIndex <= previousIndex) return;

    final steps = widget.loaded.steps;
    final previous = steps[previousIndex];
    final next = steps[nextIndex];
    _writeQueue = _writeQueue.then((_) async {
      await _progressStore.completeStep(
        lessonId: widget.lesson.id,
        stepId: previous.id,
        nextStepId: next.id,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      if (next.type == LearnLessonVisualStepType.completion) {
        await _progressStore.completeStep(
          lessonId: widget.lesson.id,
          stepId: next.id,
          nextStepId: null,
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        );
      }
    });
  }

  Future<void> _backToLessons() async {
    if (_leaving) return;
    _leaving = true;
    await _writeQueue;
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _continueInQuran() async {
    if (_leaving) return;
    _leaving = true;
    await _writeQueue;
    if (!mounted) return;
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNavigation.instance.openReader(
        surah: widget.lesson.surah,
        ayah: widget.lesson.firstAyah,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = widget.loaded.languageCode;
    String text(String key) => learnText(languageCode, key);

    return LearnLessonVisualFlow(
      lessonTitle: text(widget.lesson.titleKey),
      steps: widget.loaded.steps,
      initialStepIndex: _lastIndex,
      labels: LearnLessonVisualLabels(
        previous: text('learnLessonPreviousV1'),
        next: text('learnLessonNextV1'),
        finish: text('learnLessonFinishV1'),
        correctFeedback: text('learnLessonCorrectV1'),
        incorrectFeedback: text('learnLessonIncorrectV1'),
        backToLessons: text('learnLessonBackV1'),
        continueInQuran: text('learnLessonContinueQuranV1'),
      ),
      onStepChanged: _handleStepChanged,
      onBackToLessons: () {
        _backToLessons();
      },
      onContinueInQuran: () {
        _continueInQuran();
      },
    );
  }
}

class _LoadedLesson {
  const _LoadedLesson({
    required this.steps,
    required this.progress,
    required this.languageCode,
  });

  final List<LearnLessonVisualStep> steps;
  final LearnProgressSnapshot? progress;
  final String languageCode;
}
