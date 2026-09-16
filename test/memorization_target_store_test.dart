import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_i_kerim/src/features/learn/application/memorization_target_catalog.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_target_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = MemorizationTargetStore();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('defaults to full Quran when no target is saved', () async {
    expect(await store.load(), MemorizationTargetId.fullQuran);
  });

  test('saved target survives a fresh store instance', () async {
    await store.save(MemorizationTargetId.juzAmma);

    const reloadedStore = MemorizationTargetStore();
    expect(await reloadedStore.load(), MemorizationTargetId.juzAmma);
  });

  test('every supported target round-trips through persistence', () async {
    for (final target in MemorizationTargetId.values) {
      await store.save(target);
      expect(
        await const MemorizationTargetStore().load(),
        target,
        reason: 'failed to restore ${target.name}',
      );
    }
  });

  test('unknown persisted target safely falls back to full Quran', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'memorization_target_v1': 'retired-or-corrupt-target',
    });

    expect(await store.load(), MemorizationTargetId.fullQuran);
  });

  test('clear restores the default target', () async {
    await store.save(MemorizationTargetId.alMulk);
    await store.clear();

    expect(await store.load(), MemorizationTargetId.fullQuran);
  });
}
