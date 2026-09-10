import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/learn_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('lesson progress stays local and resumes from the next pending step', () async {
    const store = LearnProgressStore();

    final first = await store.completeStep(
      lessonId: 'lesson-1',
      stepId: 'intro',
      nextStepId: 'verse',
      updatedAtMs: 100,
    );
    final second = await store.completeStep(
      lessonId: 'lesson-1',
      stepId: 'verse',
      nextStepId: 'summary',
      updatedAtMs: 200,
    );
    final restored = await store.load('lesson-1');

    expect(first.currentStepId, 'verse');
    expect(second.completedStepIds, {'intro', 'verse'});
    expect(restored, isNotNull);
    expect(restored!.currentStepId, 'summary');
    expect(
      restored.nextPendingStep(const ['intro', 'verse', 'summary']),
      'summary',
    );
  });

  test('corrupt persisted progress is ignored instead of breaking Learn', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'learn_progress_v1:lesson-2': '{not valid json',
    });
    const store = LearnProgressStore();

    expect(await store.load('lesson-2'), isNull);
  });

  test('snapshot codec rejects malformed identifiers and preserves progress', () {
    final snapshot = LearnProgressSnapshot.fromJson(<String, Object?>{
      'lessonId': 'lesson-3',
      'completedStepIds': <String>['a', 'b', 'a'],
      'currentStepId': 'c',
      'updatedAtMs': 42,
    });

    expect(snapshot, isNotNull);
    expect(snapshot!.completedStepIds, {'a', 'b'});
    expect(snapshot.currentStepId, 'c');
    expect(
      LearnProgressSnapshot.fromJson(<String, Object?>{
        'lessonId': '',
        'completedStepIds': <String>[],
        'updatedAtMs': 0,
      }),
      isNull,
    );
  });
}
