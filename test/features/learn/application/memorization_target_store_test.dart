import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_target_catalog.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_target_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('load defaults to full Quran when no target is persisted', () async {
    final target = await const MemorizationTargetStore().load();

    expect(target, MemorizationTargetId.fullQuran);
  });

  test('save persists the selected memorization target', () async {
    const store = MemorizationTargetStore();

    await store.save(MemorizationTargetId.juzAmma);

    expect(await store.load(), MemorizationTargetId.juzAmma);
  });

  test('unknown persisted target safely falls back to full Quran', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_target_v1': 'removedTarget',
    });

    final target = await const MemorizationTargetStore().load();

    expect(target, MemorizationTargetId.fullQuran);
  });

  test('clear restores the default memorization target', () async {
    const store = MemorizationTargetStore();
    await store.save(MemorizationTargetId.alMulk);

    await store.clear();

    expect(await store.load(), MemorizationTargetId.fullQuran);
  });
}
