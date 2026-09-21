import 'dart:convert';

import 'travel_dietary_card_store.dart';
import 'travel_meeting_point_store.dart';
import 'travel_packing_store.dart';

class TravelToolsImportPreview {
  const TravelToolsImportPreview({required this.sourceVersion, required this.meetingPoint, required this.packing, this.dietaryCard});
  final int sourceVersion;
  final TravelMeetingPoint? meetingPoint;
  final List<TravelPackingItem> packing;
  final TravelDietaryCard? dietaryCard;
  bool get includesDietaryCard => sourceVersion >= 2;
}

class TravelToolsImport {
  const TravelToolsImport({this.meetingPointStore = const TravelMeetingPointStore(), this.packingStore = const TravelPackingStore(), this.dietaryCardStore = const TravelDietaryCardStore()});
  static const maxEncodedLength = 1024 * 1024;
  final TravelMeetingPointStore meetingPointStore;
  final TravelPackingStore packingStore;
  final TravelDietaryCardStore dietaryCardStore;

  TravelToolsImportPreview parse(String encoded) {
    if (encoded.length > maxEncodedLength) throw const FormatException('Travel tools export is too large.');
    final raw = jsonDecode(encoded);
    final version = raw is Map ? raw['version'] : null;
    if (raw is! Map || raw['schema'] != 'quran-i-kerim.travel-tools' || (version != 1 && version != 2)) throw const FormatException('Unsupported travel tools export.');
    final meetingRaw = raw['meetingPoint'];
    final meetingPoint = meetingRaw == null ? null : TravelMeetingPoint.fromJson(meetingRaw);
    if (meetingRaw != null && meetingPoint == null) throw const FormatException('Invalid meeting point.');
    final packingRaw = raw['packing'];
    if (packingRaw is! List || packingRaw.length > TravelPackingStore.maxItems) throw const FormatException('Invalid packing list.');
    final packing = <TravelPackingItem>[];
    final ids = <String>{};
    for (final entry in packingRaw) {
      final item = TravelPackingItem.fromJson(entry);
      if (item == null || !ids.add(item.id)) throw const FormatException('Invalid packing item.');
      packing.add(item);
    }
    final dietaryRaw = version == 2 ? raw['dietaryCard'] : null;
    final dietary = dietaryRaw == null ? null : TravelDietaryCard.fromJson(dietaryRaw);
    if (dietaryRaw != null && dietary == null) throw const FormatException('Invalid dietary card.');
    return TravelToolsImportPreview(sourceVersion: version as int, meetingPoint: meetingPoint, packing: List.unmodifiable(packing), dietaryCard: dietary);
  }

  Future<void> apply(TravelToolsImportPreview preview) async {
    final previousMeeting = await meetingPointStore.load();
    final previousPacking = await packingStore.load();
    final previousDietary = await dietaryCardStore.load();
    try {
      if (preview.meetingPoint == null) { await meetingPointStore.clear(); } else { await meetingPointStore.save(preview.meetingPoint!); }
      await packingStore.save(preview.packing);
      if (preview.includesDietaryCard) {
        if (preview.dietaryCard == null) { await dietaryCardStore.clear(); } else { await dietaryCardStore.save(preview.dietaryCard!); }
      }
    } catch (_) {
      if (previousMeeting == null) { await meetingPointStore.clear(); } else { await meetingPointStore.save(previousMeeting); }
      await packingStore.save(previousPacking);
      if (previousDietary == null) { await dietaryCardStore.clear(); } else { await dietaryCardStore.save(previousDietary); }
      rethrow;
    }
  }
}
