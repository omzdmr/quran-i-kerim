import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TravelPackingItem {
  const TravelPackingItem({required this.id, required this.label, required this.packed});

  final String id;
  final String label;
  final bool packed;

  TravelPackingItem copyWith({bool? packed}) => TravelPackingItem(
        id: id,
        label: label,
        packed: packed ?? this.packed,
      );

  Map<String, Object> toJson() => <String, Object>{'id': id, 'label': label, 'packed': packed};

  static TravelPackingItem? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final label = raw['label'];
    final packed = raw['packed'];
    if (id is! String || label is! String || packed is! bool || id.isEmpty || label.trim().isEmpty) return null;
    return TravelPackingItem(id: id, label: label.trim(), packed: packed);
  }
}

class TravelPackingStore {
  const TravelPackingStore();

  static const storageKey = 'travel_packing_checklist_v1';

  Future<List<TravelPackingItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(storageKey);
    if (encoded == null || encoded.isEmpty) return const [];
    try {
      final raw = jsonDecode(encoded);
      if (raw is! List) return const [];
      final seen = <String>{};
      final items = <TravelPackingItem>[];
      for (final entry in raw) {
        final item = TravelPackingItem.fromJson(entry);
        if (item != null && seen.add(item.id)) items.add(item);
      }
      return List.unmodifiable(items);
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<TravelPackingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    if (items.isEmpty) {
      await prefs.remove(storageKey);
      return;
    }
    await prefs.setString(storageKey, jsonEncode(items.map((item) => item.toJson()).toList()));
  }
}