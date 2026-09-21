import 'travel_meeting_point_store.dart';
import 'travel_packing_store.dart';

class TravelToolsSummary {
  const TravelToolsSummary({required this.hasMeetingPoint, required this.packedItems, required this.totalItems});
  final bool hasMeetingPoint;
  final int packedItems;
  final int totalItems;
}

class TravelToolsSummaryLoader {
  const TravelToolsSummaryLoader({
    this.meetingPointStore = const TravelMeetingPointStore(),
    this.packingStore = const TravelPackingStore(),
  });
  final TravelMeetingPointStore meetingPointStore;
  final TravelPackingStore packingStore;

  Future<TravelToolsSummary> load() async {
    final meetingFuture = meetingPointStore.load();
    final packingFuture = packingStore.load();
    final meeting = await meetingFuture;
    final packing = await packingFuture;
    return TravelToolsSummary(
      hasMeetingPoint: meeting != null && !meeting.isEmpty,
      packedItems: packing.where((item) => item.packed).length,
      totalItems: packing.length,
    );
  }
}