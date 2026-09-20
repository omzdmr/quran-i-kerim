import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ARB locale files keep user-visible key parity', () {
    const locales = ['en', 'tr', 'ar', 'az', 'ru', 'fr'];
    Set<String>? expectedKeys;

    for (final locale in locales) {
      final file = File('lib/src/l10n/arb/app_$locale.arb');
      expect(file.existsSync(), isTrue, reason: 'Missing ARB for $locale');

      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final keys = json.keys
          .where((key) => !key.startsWith('@'))
          .toSet();

      expectedKeys ??= keys;
      expect(keys, expectedKeys, reason: 'ARB key mismatch for $locale');
    }
  });
}
