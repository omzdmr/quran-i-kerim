import 'package:shared_preferences/shared_preferences.dart';

/// Explicit SharedPreferences adapter used by backup/restore.
///
/// Only keys listed here can leave the device. Unknown preferences, downloaded
/// content and caches are intentionally ignored.
class SharedPreferencesBackupAdapter {
  const SharedPreferencesBackupAdapter();

  static const Set<String> includedKeys = <String>{
    'memorized_pages_v1',
    'memorization_practice_days_v1',
    'memorization_page_progress_v1',
  };

  Future<Map<String, Object?>> capture() async {
    final prefs = await SharedPreferences.getInstance();
    return Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final key in includedKeys)
        if (prefs.containsKey(key)) key: _copyValue(prefs.get(key)),
    });
  }

  Future<void> restore(Map<String, Object?> snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in includedKeys) {
      if (!snapshot.containsKey(key)) {
        await prefs.remove(key);
        continue;
      }
      await _writeValue(prefs, key, snapshot[key]);
    }
  }

  Object? _copyValue(Object? value) {
    if (value is List<String>) return List<String>.unmodifiable(value);
    return value;
  }

  Future<void> _writeValue(
    SharedPreferences prefs,
    String key,
    Object? value,
  ) async {
    if (value == null) {
      await prefs.remove(key);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, List<String>.from(value));
    } else {
      throw FormatException('Unsupported backup preference type for $key');
    }
  }
}
