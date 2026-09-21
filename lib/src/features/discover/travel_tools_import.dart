import 'dart:convert';

import 'travel_meeting_point_store.dart';
import 'travel_packing_store.dart';

class TravelToolsImportPreview {
  const TravelToolsImportPreview({required this.meetingPoint, required this.packing});
  final TravelMeetingPoint? meetingPoint;
  final List<TravelPackingItem> packing;
}

class TravelToolsImport {
  const TravelToolsImport({this.meetingPointStore = const TravelMeetingPointStore(), this.packingStore = const TravelPackingStore()});
  static const maxEncodedLength = 1024 * 1024;
  final TravelMeetingPointStore meetingPointStore;
  final TravelPackingStore packingStore;

  TravelToolsImportPreview parse(String encoded) {
    if (encoded.length > maxEncodedLength) throw const FormatException('Travel tools export is too large.');
    final raw = jsonDecode(encoded);
    if (raw is! Map || raw['schema'] != 'quran-i-kerim.travel-tools' || raw['version'] != 1) {
      throw const FormatException('Unsupported travel tools export.');
    }
    final meetingRaw = raw['meetingPoint'];
    final meetingPoint = meetingRaw == null ? null : TravelMeetingPoint.fromJson(meetingRaw);
    if (meetingRaw != null && meetingPoint == null) throw const FormatException('Invalid meeting point.');
    final packingRaw = raw['packing'];
    if (packingRaw is! List || packingRaw.length > TravelPackingStore.maxItems) {
      throw const FormatException('Invalid packing list.');
    }
    final packing = <TravelPackingItem>[];
    final ids = <String>{};
    for (final entry in packingRaw) {
      final item = TravelPackingItem.fromJson(entry);
      if (item == null || !ids.add(item.id)) throw const FormatException('Invalid packing item.');
      packing.add(item);
    }
    return TravelToolsImportPreview(meetingPoint: meetingPoint, packing: List.unmodifiable(packing));
  }

  Future<void> apply(TravelToolsImportPreview preview) async {
    final previousMeeting = await meetingPointStore.load();
    final previousPacking = await packingStore.load();
    try {
      if (preview.meetingPoint == null) {
        await meetingPointStore.clear();
      } else {
        await meetingPointStore.save(preview.meetingPoint!);
      }
      await packingStore.save(preview.packing);
    } catch (_) {
      if (previousMeeting == null) {
        await meetingPointStore.clear();
      } else {
        await meetingPointStore.save(previousMeeting);
      }
      await packingStore.save(previousPacking);
      rethrow;
    }
  }
}