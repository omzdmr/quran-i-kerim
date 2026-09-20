import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/locale_metadata.dart';
import 'package:quran_i_kerim/src/l10n/script_rendering_profile.dart';

void main() {
  test('every enabled UI locale has an explicit script rendering profile', () {
    expect(missingScriptRenderingProfiles(), isEmpty);

    for (final entry in appLocaleMetadata.entries) {
      final profile = renderingProfileForLocaleCode(entry.key);
      expect(profile, isNotNull, reason: 'missing rendering profile for ${entry.key}');
      expect(profile!.scriptCode, entry.value.scriptCode);
      expect(profile.direction, entry.value.direction);
      expect(profile.fallbackFontFamilies, isNotEmpty);
    }
  });

  test('Arabic script explicitly requires RTL complex shaping', () {
    final arabic = scriptRenderingProfiles['Arab']!;
    expect(arabic.direction, LocaleScriptDirection.rtl);
    expect(arabic.requiresComplexShaping, isTrue);
  });

  test('Latin and Cyrillic UI scripts do not inherit RTL shaping rules', () {
    for (final script in <String>['Latn', 'Cyrl']) {
      final profile = scriptRenderingProfiles[script]!;
      expect(profile.direction, LocaleScriptDirection.ltr);
      expect(profile.requiresComplexShaping, isFalse);
    }
  });

  test('French resolves through the Latin rendering contract', () {
    final french = renderingProfileForLocaleCode('FR');
    expect(french, isNotNull);
    expect(french!.scriptCode, 'Latn');
    expect(french.direction, LocaleScriptDirection.ltr);
  });

  test('unknown locale does not silently inherit a font or direction profile', () {
    expect(renderingProfileForLocaleCode('zz'), isNull);
  });
}
