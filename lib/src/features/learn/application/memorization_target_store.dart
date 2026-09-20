import 'package:shared_preferences/shared_preferences.dart';

import 'memorization_target_catalog.dart';

class MemorizationTargetStore {
  const MemorizationTargetStore();

  static const _targetKey = 'memorization_target_v1';

  MemorizationTargetId _parse(String? raw) {
    if (raw != null) {
      for (final value in MemorizationTargetId.values) {
        if (value.name == raw) return value;
      }
    }
    return MemorizationTargetId.fullQuran;
  }

  Future<MemorizationTargetId> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _parse(prefs.getString(_targetKey));
  }

  Future<MemorizationTargetId> save(MemorizationTargetId target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_targetKey, target.name);
    return target;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_targetKey);
  }
}
