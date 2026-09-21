import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/travel_meeting_point_store.dart';
import 'package:quran_i_kerim/src/features/discover/travel_packing_store.dart';
import 'package:quran_i_kerim/src/features/discover/travel_tools_import.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('valid export previews before replacing local travel data', () async {
    const encoded = '''{"schema":"quran-i-kerim.travel-tools","version":1,"meetingPoint":{"name":"Camp","address":"Gate 3","note":"18:00","updatedAt":"2026-09-22T00:00:00.000Z"},"packing":[{"id":"p","label":"Passport","packed":true}]}''';
    const importer = TravelToolsImport();
    final preview = importer.parse(encoded);
    expect(preview.meetingPoint?.name, 'Camp');
    expect(preview.packing.single.label, 'Passport');

    expect(await const TravelMeetingPointStore().load(), isNull);
    await importer.apply(preview);
    expect((await const TravelMeetingPointStore().load())?.address, 'Gate 3');
    expect((await const TravelPackingStore().load()).single.packed, isTrue);
  });

  test('unknown schema and duplicate item ids are rejected without writes', () async {
    const importer = TravelToolsImport();
    expect(() => importer.parse('{"schema":"other","version":1,"packing":[]}'), throwsFormatException);
    expect(
      () => importer.parse('{"schema":"quran-i-kerim.travel-tools","version":1,"meetingPoint":null,"packing":[{"id":"x","label":"A","packed":false},{"id":"x","label":"B","packed":false}]}'),
      throwsFormatException,
    );
    expect(await const TravelPackingStore().load(), isEmpty);
  });
}