import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_plan_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('load drops orphan missed days when plan state is incomplete', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_plan_started_at_v1': '2026-09-01T00:00:00.000',
      'memorization_plan_missed_days_v1': <String>['1', '3'],
    });

    final snapshot = await const MemorizationPlanStore().load();

    expect(snapshot.hasPlan, isFalse);
    expect(snapshot.missedPlanDays, isEmpty);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('memorization_plan_missed_days_v1'), isFalse);
  });
}
