import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/travel_packing_store.dart';

void main() {
  const store = TravelPackingStore();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('packing list preserves order and completion', () async {
    await store.save(const [
      TravelPackingItem(id: 'a', label: 'Passport', packed: true),
      TravelPackingItem(id: 'b', label: 'Charger', packed: false),
    ]);
    final loaded = await store.load();
    expect(loaded.map((item) => item.label), ['Passport', 'Charger']);
    expect(loaded.first.packed, isTrue);
    expect(loaded.last.packed, isFalse);
  });

  test('invalid and duplicate records do not poison local checklist', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      TravelPackingStore.storageKey:
          '[{"id":"a","label":"Bag","packed":false},{"id":"a","label":"Duplicate","packed":true},{"bad":1}]',
    });
    final loaded = await store.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.label, 'Bag');
  });

  test('empty checklist removes persisted value', () async {
    await store.save(const [TravelPackingItem(id: 'a', label: 'Bag', packed: false)]);
    await store.save(const []);
    expect(await store.load(), isEmpty);
  });
}