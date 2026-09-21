import 'package:shared_preferences/shared_preferences.dart';

import 'reader_focus_controller.dart';

class ReaderFocusPreferencesStore {
  const ReaderFocusPreferencesStore();

  static const autoScrollSpeedKey = 'reader_auto_scroll_speed_v1';

  Future<ReaderAutoScrollSpeed> loadAutoScrollSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(autoScrollSpeedKey);
    return ReaderAutoScrollSpeed.values.firstWhere(
      (speed) => speed.name == stored,
      orElse: () => ReaderAutoScrollSpeed.normal,
    );
  }

  Future<void> saveAutoScrollSpeed(ReaderAutoScrollSpeed speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(autoScrollSpeedKey, speed.name);
  }
}
