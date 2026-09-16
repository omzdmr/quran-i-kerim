import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const adapter = SharedPreferencesBackupAdapter();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('captures only explicitly allowed memorization data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorized_pages_v1': <String>['1', '2'],
      'memorization_practice_days_v1': <String>['2026-09-16'],
      'memorization_page_progress_v1': '{"1":{}}',
      'memorization_plan_pace_v1': 'balanced18Months',
      'memorization_plan_started_at_v1': '2026-09-01T00:00:00.000',
      'memorization_plan_missed_days_v1': <String>['4', '8'],
      'memorization_practice_history_v1': '[{"id":"p1"}]',
      'memorization_recall_history_v1': '{"2:255":{"difficulty":2}}',
      'audio_cache_internal': 'never export this',
      'future_unknown_preference': 'private by default',
    });

    final snapshot = await adapter.capture();

    expect(
      snapshot.keys,
      unorderedEquals(SharedPreferencesBackupAdapter.includedKeys),
    );
    expect(snapshot, isNot(contains('audio_cache_internal')));
    expect(snapshot, isNot(contains('future_unknown_preference')));
  });

  test('restore replaces included values and leaves unrelated preferences alone', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorized_pages_v1': <String>['9'],
      'memorization_plan_pace_v1': 'calm24Months',
      'memorization_recall_history_v1': '{}',
      'unrelated': 'keep me',
    });

    await adapter.restore(<String, Object?>{
      'memorized_pages_v1': <String>['1', '2'],
      'memorization_plan_pace_v1': 'balanced18Months',
      'memorization_recall_history_v1': '{"2:255":{"difficulty":2}}',
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('memorized_pages_v1'), ['1', '2']);
    expect(prefs.getString('memorization_plan_pace_v1'), 'balanced18Months');
    expect(
      prefs.getString('memorization_recall_history_v1'),
      '{"2:255":{"difficulty":2}}',
    );
    expect(prefs.getString('unrelated'), 'keep me');
  });

  test('missing included keys are removed during restore', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorized_pages_v1': <String>['1'],
      'memorization_practice_days_v1': <String>['2026-09-16'],
      'memorization_plan_missed_days_v1': <String>['3'],
      'memorization_practice_history_v1': '[]',
    });

    await adapter.restore(<String, Object?>{
      'memorized_pages_v1': <String>['3'],
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('memorized_pages_v1'), ['3']);
    expect(prefs.containsKey('memorization_practice_days_v1'), isFalse);
    expect(prefs.containsKey('memorization_plan_missed_days_v1'), isFalse);
    expect(prefs.containsKey('memorization_practice_history_v1'), isFalse);
  });

  test('unsupported values fail instead of being silently coerced', () async {
    await expectLater(
      adapter.restore(<String, Object?>{
        'memorized_pages_v1': <Object>[1, 2],
      }),
      throwsFormatException,
    );
  });
}
