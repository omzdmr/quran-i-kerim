import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/travel_meeting_point_store.dart';

void main() {
  const store = TravelMeetingPointStore();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('meeting point survives local persistence round trip', () async {
    final updatedAt = DateTime(2026, 9, 22, 9, 30);
    await store.save(TravelMeetingPoint(name: 'Hotel lobby', address: 'Gate B', note: 'Meet after prayer', updatedAt: updatedAt));
    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Hotel lobby');
    expect(loaded.address, 'Gate B');
    expect(loaded.note, 'Meet after prayer');
    expect(loaded.updatedAt, updatedAt);
  });

  test('empty meeting point removes persisted data', () async {
    await store.save(TravelMeetingPoint(name: 'Camp', address: 'Zone 4', note: '', updatedAt: DateTime(2026, 9, 22)));
    await store.save(TravelMeetingPoint(name: ' ', address: '', note: '', updatedAt: DateTime(2026, 9, 22)));
    expect(await store.load(), isNull);
  });

  test('corrupt and oversized local payloads fail closed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{TravelMeetingPointStore.storageKey: '{not-json'});
    expect(await store.load(), isNull);

    final tooLong = List<String>.filled(TravelMeetingPoint.maxNameLength + 1, 'x').join();
    expect(
      () => store.save(TravelMeetingPoint(name: tooLong, address: '', note: '', updatedAt: DateTime(2026, 9, 22))),
      throwsFormatException,
    );
  });
}