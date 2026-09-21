import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TravelDietaryCard {
  const TravelDietaryCard({required this.languageLabel, required this.staffText, this.note = ''});
  final String languageLabel;
  final String staffText;
  final String note;

  bool get isEmpty => staffText.trim().isEmpty;
  Map<String, Object?> toJson() => {'languageLabel': languageLabel.trim(), 'staffText': staffText.trim(), 'note': note.trim()};
  static TravelDietaryCard? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final language = raw['languageLabel'];
    final text = raw['staffText'];
    final note = raw['note'];
    if (language is! String || text is! String || note is! String) return null;
    if (language.trim().length > 80 || text.trim().length > 1200 || note.trim().length > 300) return null;
    return TravelDietaryCard(languageLabel: language.trim(), staffText: text.trim(), note: note.trim());
  }
}

class TravelDietaryCardStore {
  const TravelDietaryCardStore();
  static const key = 'travel_dietary_card_v1';

  Future<TravelDietaryCard?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return null;
    try { return TravelDietaryCard.fromJson(jsonDecode(raw)); } catch (_) { return null; }
  }

  Future<void> save(TravelDietaryCard card) async {
    if (card.staffText.trim().isEmpty) throw ArgumentError('staffText cannot be empty');
    await (await SharedPreferences.getInstance()).setString(key, jsonEncode(card.toJson()));
  }

  Future<void> clear() async => (await SharedPreferences.getInstance()).remove(key);
}
