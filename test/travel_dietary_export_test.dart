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
    expect((raw['dietaryCard'] as Map<String, dynamic>)['staffText'], 'trusted phrase');
  });

  test('v2 restores dietary card and legacy v1 does not erase it', () async {
    const importer = TravelToolsImport();
    final v2 = importer.parse(jsonEncode({'schema':'quran-i-kerim.travel-tools','version':2,'meetingPoint':null,'packing':[],'dietaryCard':{'languageLabel':'fr','staffText':'texte fiable','note':''}}));
    expect(v2.includesDietaryCard, isTrue);
    await importer.apply(v2);
    expect((await const TravelDietaryCardStore().load())?.staffText, 'texte fiable');

    final v1 = importer.parse(jsonEncode({'schema':'quran-i-kerim.travel-tools','version':1,'meetingPoint':null,'packing':[]}));
    expect(v1.includesDietaryCard, isFalse);
    await importer.apply(v1);
    expect((await const TravelDietaryCardStore().load())?.staffText, 'texte fiable');
  });

  test('v2 explicit null clears dietary card', () async {
    const store = TravelDietaryCardStore();
    await store.save(const TravelDietaryCard(languageLabel: 'x', staffText: 'old'));
    final preview = const TravelToolsImport().parse(jsonEncode({'schema':'quran-i-kerim.travel-tools','version':2,'meetingPoint':null,'packing':[],'dietaryCard':null}));
    await const TravelToolsImport().apply(preview);
    expect(await store.load(), isNull);
  });

  test('invalid dietary card rejects whole import preview', () {
    final oversized = List.filled(1201, 'x').join();
    expect(() => const TravelToolsImport().parse(jsonEncode({'schema':'quran-i-kerim.travel-tools','version':2,'meetingPoint':null,'packing':[],'dietaryCard':{'languageLabel':'x','staffText':oversized,'note':''}})), throwsFormatException);
  });
}
