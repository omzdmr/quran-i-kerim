import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TravelMeetingPoint {
  const TravelMeetingPoint({required this.name, required this.address, required this.note, required this.updatedAt});

  static const maxNameLength = 1000;
  static const maxAddressLength = 5000;
  static const maxNoteLength = 10000;

  final String name;
  final String address;
  final String note;
  final DateTime updatedAt;

  bool get isEmpty => name.trim().isEmpty && address.trim().isEmpty && note.trim().isEmpty;
  bool get isValid => name.length <= maxNameLength && address.length <= maxAddressLength && note.length <= maxNoteLength;

  Map<String, Object> toJson() => <String, Object>{'name': name, 'address': address, 'note': note, 'updatedAt': updatedAt.toUtc().toIso8601String()};

  static TravelMeetingPoint? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    final address = raw['address'];
    final note = raw['note'];
    final updatedAt = raw['updatedAt'];
    if (name is! String || address is! String || note is! String || updatedAt is! String) return null;
    final parsed = DateTime.tryParse(updatedAt);
    if (parsed == null) return null;
    final point = TravelMeetingPoint(name: name.trim(), address: address.trim(), note: note.trim(), updatedAt: parsed.toLocal());
    return point.isValid ? point : null;
  }
}

class TravelMeetingPointStore {
  const TravelMeetingPointStore();
  static const storageKey = 'travel_meeting_point_v1';

  Future<TravelMeetingPoint?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(storageKey);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return TravelMeetingPoint.fromJson(jsonDecode(encoded));
    } on FormatException {
      return null;
    }
  }

  Future<void> save(TravelMeetingPoint value) async {
    if (!value.isValid) throw const FormatException('Travel meeting point is too large.');
    final prefs = await SharedPreferences.getInstance();
    if (value.isEmpty) {
      await prefs.remove(storageKey);
      return;
    }
    await prefs.setString(storageKey, jsonEncode(value.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}