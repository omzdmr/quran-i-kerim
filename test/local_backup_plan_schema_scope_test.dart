import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = LocalBackupService();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('v3 preview does not claim v4 reading plans will be removed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'reading_plan_state_v1': '{"active":{"preset":"quran30"}}',
    });
    final encoded = jsonEncode(<String, Object?>{
      'version': 3,
      'createdAt': '2026-09-16T10:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36},
      },
    });

    final plan = await service.planImportJson(encoded);

    expect(plan.conflictingRecords, 1);
    expect(plan.sectionImpacts.any((impact) => impact.section == 'readingPlans'), isFalse);
    expect(plan.localOnlyRecords, 0);
  });

  test('current-schema preview still reports omitted managed section as removal', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'reading_plan_state_v1': '{"active":{"preset":"quran30"}}',
    });
    final encoded = jsonEncode(<String, Object?>{
      'version': 9,
      'createdAt': '2026-09-16T10:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36},
      },
    });

    final plan = await service.planImportJson(encoded);
    final readingPlans = plan.sectionImpacts.singleWhere((impact) => impact.section == 'readingPlans');
    expect(readingPlans.localOnlyRecords, 1);
  });
}
