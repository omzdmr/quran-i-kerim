import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:quran_i_kerim/src/features/discover/dhikr_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const adapter = SharedPreferencesBackupAdapter();
  const codec = DhikrCounterDocumentCodec();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('dhikr count document carries history through backup restore', () async {
    final encoded = codec.encode(
      counts: const <String, int>{'subhanallah': 40},
      soundEnabled: true,
      history: const <DhikrDailyHistoryRecord>[
        DhikrDailyHistoryRecord(
          dateKey: '2026-09-25',
          counts: <String, int>{'subhanallah': 33},
        ),
      ],
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dhikr_v2_counts': encoded,
      'dhikr_v2_selected': 'subhanallah',
    });

    final sections = await adapter.captureSections();
    final dhikr = sections['dhikr'] as Map;
    expect(dhikr['dhikr_v2_counts'], encoded);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await adapter.restoreSections(sections);

    final prefs = await SharedPreferences.getInstance();
    final restored = codec.decode(prefs.getString('dhikr_v2_counts'));
    expect(restored.counts['subhanallah'], 40);
    expect(restored.soundEnabled, isTrue);
    expect(restored.history.single.dateKey, '2026-09-25');
    expect(restored.history.single.total, 33);
  });

  test('legacy schema dhikr count payload remains readable', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dhikr_v2_counts': '{"subhanallah":99}',
    });
    final sections = await adapter.captureSections();

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await adapter.restoreSections(sections, schemaVersion: 3);

    final prefs = await SharedPreferences.getInstance();
    final restored = codec.decode(prefs.getString('dhikr_v2_counts'));
    expect(restored.counts['subhanallah'], 99);
    expect(restored.history, isEmpty);
  });

  test('custom dhikr identity label target and count restore together', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dhikr_v2_selected': 'custom_1',
      'dhikr_v2_counts': '{"custom_1":5}',
      'dhikr_v2_targets': '{"custom_1":25}',
      'dhikr_v2_custom': '[{"id":"custom_1","label":"Evening"}]',
    });
    final sections = await adapter.captureSections();

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await adapter.restoreSections(sections);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('dhikr_v2_selected'), 'custom_1');
    expect(prefs.getString('dhikr_v2_counts'), '{"custom_1":5}');
    expect(prefs.getString('dhikr_v2_targets'), '{"custom_1":25}');
    expect(prefs.getString('dhikr_v2_custom'), contains('Evening'));
  });

}
