import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_practice_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new practice events persist an explicit UTC timestamp for portable backup', () async {
    SharedPreferences.setMockInitialValues({});
    final localInstant = DateTime.parse('2026-09-21T20:30:00+08:00');

    await const MemorizationPracticeHistoryStore().record(
      page: 12,
      context: MemorizationPracticeContext.prayer,
      now: localInstant,
    );

    final prefs = await SharedPreferences.getInstance();
    final decoded = jsonDecode(prefs.getString('memorization_practice_history_v1')!) as List;
    final occurredAt = (decoded.single as Map)['occurredAt'] as String;
    expect(occurredAt, '2026-09-21T12:30:00.000Z');

    final reloaded = await const MemorizationPracticeHistoryStore().load();
    expect(reloaded.events.single.occurredAt.toUtc(), localInstant.toUtc());
  });
}
