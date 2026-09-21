import 'travel_meeting_point_store.dart';
import 'travel_packing_store.dart';

class TravelToolsReset {
  const TravelToolsReset({
    this.meetingPointStore = const TravelMeetingPointStore(),
    this.packingStore = const TravelPackingStore(),
  });
  final TravelMeetingPointStore meetingPointStore;
  final TravelPackingStore packingStore;

  Future<void> clearAll() async {
    await meetingPointStore.clear();
    await packingStore.save(const []);
  }
}