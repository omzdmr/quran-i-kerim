import 'dart:convert';

import 'travel_dietary_card_store.dart';
import 'travel_meeting_point_store.dart';
import 'travel_packing_store.dart';

class TravelToolsExport {
  const TravelToolsExport({
    this.meetingPointStore = const TravelMeetingPointStore(),
    this.packingStore = const TravelPackingStore(),
    this.dietaryCardStore = const TravelDietaryCardStore(),
  });

  final TravelMeetingPointStore meetingPointStore;
  final TravelPackingStore packingStore;
  final TravelDietaryCardStore dietaryCardStore;

  Future<String> createJson() async {
    final meetingPointFuture = meetingPointStore.load();
    final packingFuture = packingStore.load();
    final dietaryFuture = dietaryCardStore.load();
    final meetingPoint = await meetingPointFuture;
    final packing = await packingFuture;
    final dietary = await dietaryFuture;
    return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schema': 'quran-i-kerim.travel-tools',
      'version': 2,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'meetingPoint': meetingPoint?.toJson(),
      'packing': packing.map((item) => item.toJson()).toList(growable: false),
      'dietaryCard': dietary?.toJson(),
    });
  }
}
