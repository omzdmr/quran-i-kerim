import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/dhikr_labels.dart';

void main() {
  test('built-in dhikr labels cover every supported UI locale', () {
    const locales = <String>{'tr', 'en', 'fr', 'ar', 'az', 'ru'};
    for (final labels in dhikrBuiltInLabels.values) {
      expect(labels.keys.toSet(), locales);
      expect(labels.values.every((value) => value.trim().isNotEmpty), isTrue);
    }
  });
}
