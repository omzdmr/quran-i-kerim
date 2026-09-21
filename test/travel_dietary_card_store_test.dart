import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/travel_dietary_card_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('card persists locally with language and private note', () async {
    const store = TravelDietaryCardStore();
    await store.save(const TravelDietaryCard(languageLabel: '中文', staffText: 'trusted user text', note: 'private'));
    final restored = await store.load();
    expect(restored?.languageLabel, '中文');
    expect(restored?.staffText, 'trusted user text');
    expect(restored?.note, 'private');
  });

  test('corrupt or oversized persisted payload fails closed', () async {
    SharedPreferences.setMockInitialValues({TravelDietaryCardStore.key: '{broken'});
    expect(await const TravelDietaryCardStore().load(), isNull);
    final oversized = List.filled(1201, 'x').join();
    expect(TravelDietaryCard.fromJson({'languageLabel':'x','staffText':oversized,'note':''}), isNull);
  });

  test('empty staff-facing text cannot be saved', () async {
    expect(() => const TravelDietaryCardStore().save(const TravelDietaryCard(languageLabel: 'x', staffText: '   ')), throwsArgumentError);
  });
}
