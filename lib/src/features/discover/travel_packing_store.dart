import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TravelPackingItem {
  const TravelPackingItem({required this.id, required this.label, required this.packed});
  static const maxIdLength = 256;
  static const maxLabelLength = 1000;
  final String id;
  final String label;
  final bool packed;

  TravelPackingItem copyWith({bool? packed}) => TravelPackingItem(id: id, label: label, packed: packed ?? this.packed);
  bool get isValid => id.isNotEmpty && id.length <= maxIdLength && label.trim().isNotEmpty && label.length <= maxLabelLength;
  Map<String, Object> toJson() => <String, Object>{'id': id, 'label': label, 'packed': packed};

  static TravelPackingItem? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final label = raw['label'];
    final packed = raw['packed'];
    if (id is! String || label is! String || packed is! bool) return null;
    final item = TravelPackingItem(id: id, label: label.trim(), packed: packed);
    return item.isValid ? item : null;
  }
}

class TravelPackingStore {
  const TravelPackingStore();
  static const storageKey = 'travel_packing_checklist_v1';
  static const maxItems = 500;

  Future<List<TravelPackingItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(storageKey);
    if (encoded == null || encoded.isEmpty) return const [];
    try {
      final raw = jsonDecode(encoded);
      if (raw is! List || raw.length > maxItems) return const [];
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
    final ids = <String>{};
    if (items.length > maxItems || items.any((item) => !item.isValid || !ids.add(item.id))) {
      throw const FormatException('Travel packing list is too large or invalid.');
    }
    final prefs = await SharedPreferences.getInstance();
    if (items.isEmpty) {
      await prefs.remove(storageKey);
      return;
    }
    await prefs.setString(storageKey, jsonEncode(items.map((item) => item.toJson()).toList()));
  }
}