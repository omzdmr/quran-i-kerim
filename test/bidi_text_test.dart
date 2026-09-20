import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/bidi_text.dart';
import 'package:quran_i_kerim/src/l10n/locale_metadata.dart';

void main() {
  test('unknown-direction fragment uses first-strong isolate', () {
    expect(isolateBidiFragment('2:255'), '\u20682:255\u2069');
  });

  test('LTR dynamic fragment uses LTR isolate', () {
    expect(isolateLtrFragment('user@example.com'), '\u2066user@example.com\u2069');
  });

  test('RTL dynamic fragment uses RTL isolate', () {
    expect(isolateRtlFragment('البقرة'), '\u2067البقرة\u2069');
  });

  test('explicit direction maps to matching isolate', () {
    expect(
      isolateBidiFragment('12/09/2026', direction: LocaleScriptDirection.ltr),
      '\u206612/09/2026\u2069',
    );
    expect(
      isolateBidiFragment('العربية', direction: LocaleScriptDirection.rtl),
      '\u2067العربية\u2069',
    );
  });

  test('empty dynamic fragment remains empty', () {
    expect(isolateBidiFragment(''), isEmpty);
  });
}
