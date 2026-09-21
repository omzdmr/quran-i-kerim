import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/travel_dietary_card_store.dart';
import 'package:quran_i_kerim/src/features/discover/travel_tools_export.dart';
import 'package:quran_i_kerim/src/features/discover/travel_tools_import.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('portable travel export carries user-owned dietary card', () async {
    const dietary = TravelDietaryCardStore();
    await dietary.save(const TravelDietaryCard(languageLabel: '中文', staffText: 'trusted phrase', note: 'private note'));
    final encoded = await const TravelToolsExport().createJson();
    final raw = jsonDecode(encoded) as Map<String, dynamic>;
    expect(raw['version'], 2);
    expect(raw['dietaryCard']['staffText'], 'trusted phrase');
  });

  test('v2 preview restores dietary card while v1 remains compatible', () async {
    const importer = TravelToolsImport();
    final v2 = importer.parse(jsonEncode({
      'schema': 'quran-i-kerim.travel-tools', 'version': 2,
      'meetingPoint': null, 'packing': [],
      'dietaryCard': {'languageLabel': 'fr', 'staffText': 'texte fiable', 'note': ''},
    }));
    expect(v2.dietaryCard?.staffText, 'texte fiable');
    await importer.apply(v2);
    expect((await const TravelDietaryCardStore().load())?.staffText, 'texte fiable');

    final v1 = importer.parse(jsonEncode({'schema':'quran-i-kerim.travel-tools','version':1,'meetingPoint':null,'packing':[]}));
    expect(v1.dietaryCard, isNull);
  });

  test('invalid dietary card rejects whole import preview', () {
    expect(
      () => const TravelToolsImport().parse(jsonEncode({
        'schema':'quran-i-kerim.travel-tools','version':2,'meetingPoint':null,'packing':[],
        'dietaryCard': {'languageLabel':'x','staffText':'x' * 1201,'note':''},
      })),
      throwsFormatException,
    );
  });
}
