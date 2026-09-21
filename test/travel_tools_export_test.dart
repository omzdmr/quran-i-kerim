import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/travel_meeting_point_store.dart';
import 'package:quran_i_kerim/src/features/discover/travel_packing_store.dart';
import 'package:quran_i_kerim/src/features/discover/travel_tools_export.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('explicit export contains private travel surfaces only on user action', () async {
    await const TravelMeetingPointStore().save(TravelMeetingPoint(name:'Hotel',address:'Gate B',note:'18:00',updatedAt:DateTime(2026,9,22)));
    await const TravelPackingStore().save(const [TravelPackingItem(id:'passport',label:'Passport',packed:true)]);

    final raw = await const TravelToolsExport().createJson();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    expect(json['schema'], 'quran-i-kerim.travel-tools');
    expect(json['version'], 2);
    expect((json['meetingPoint'] as Map<String,dynamic>)['address'], 'Gate B');
    expect(((json['packing'] as List).single as Map<String,dynamic>)['packed'], isTrue);
    expect(json['dietaryCard'], isNull);
  });
}
