import 'dart:convert';

import 'travel_meeting_point_store.dart';
import 'travel_packing_store.dart';

class TravelToolsExport {
  const TravelToolsExport({
    this.meetingPointStore = const TravelMeetingPointStore(),
    this.packingStore = const TravelPackingStore(),
  });

  final TravelMeetingPointStore meetingPointStore;
  final TravelPackingStore packingStore;

  Future<String> createJson() async {
    final meetingPointFuture = meetingPointStore.load();
    final packingFuture = packingStore.load();
    final meetingPoint = await meetingPointFuture;
    final packing = await packingFuture;
    return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schema': 'quran-i-kerim.travel-tools',
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'meetingPoint': meetingPoint?.toJson(),
      'packing': packing.map((item) => item.toJson()).toList(growable: false),
    });
  }
}