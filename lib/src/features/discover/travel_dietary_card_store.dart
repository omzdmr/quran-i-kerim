import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TravelDietaryCard {
  const TravelDietaryCard({required this.languageLabel, required this.staffText, this.note = ''});
  static const maxLanguageLength = 80;
  static const maxStaffTextLength = 1200;
  static const maxNoteLength = 300;

  final String languageLabel;
  final String staffText;
  final String note;

  bool get isEmpty => staffText.trim().isEmpty;
  bool get isValid => !isEmpty && languageLabel.trim().length <= maxLanguageLength && staffText.trim().length <= maxStaffTextLength && note.trim().length <= maxNoteLength;

  Map<String, Object?> toJson() => {'languageLabel': languageLabel.trim(), 'staffText': staffText.trim(), 'note': note.trim()};

  static TravelDietaryCard? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final language = raw['languageLabel'];
    final text = raw['staffText'];
    final note = raw['note'] ?? '';
    if (language is! String || text is! String || note is! String) return null;
    final card = TravelDietaryCard(languageLabel: language.trim(), staffText: text.trim(), note: note.trim());
    return card.isValid ? card : null;
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
    if (!card.isValid) throw ArgumentError('Invalid dietary communication card');
    await (await SharedPreferences.getInstance()).setString(key, jsonEncode(card.toJson()));
  }

  Future<void> clear() async => (await SharedPreferences.getInstance()).remove(key);
}
