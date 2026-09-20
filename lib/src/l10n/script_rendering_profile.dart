import 'locale_metadata.dart';

/// Rendering requirements attached to ISO 15924 scripts rather than to a
/// particular language. This keeps future locale/content expansion data-driven.
class ScriptRenderingProfile {
  const ScriptRenderingProfile({
    required this.scriptCode,
    required this.direction,
    required this.requiresComplexShaping,
    required this.requiresBundledFontPack,
    required this.fallbackFontFamilies,
  });

  final String scriptCode;
  final LocaleScriptDirection direction;
  final bool requiresComplexShaping;

  /// True only when system fonts are not considered a sufficient production
  /// fallback for this script. Actual downloadable font packs remain catalog
  /// assets and are not implied by enabling a UI locale.
  final bool requiresBundledFontPack;
  final List<String> fallbackFontFamilies;
}

/// Script-level rendering defaults for the scripts currently exercised by the
/// full application locales. New scripts must be added explicitly instead of
/// silently inheriting Latin assumptions.
const scriptRenderingProfiles = <String, ScriptRenderingProfile>{
  'Latn': ScriptRenderingProfile(
    scriptCode: 'Latn',
    direction: LocaleScriptDirection.ltr,
    requiresComplexShaping: false,
    requiresBundledFontPack: false,
    fallbackFontFamilies: <String>['sans-serif'],
  ),
  'Cyrl': ScriptRenderingProfile(
    scriptCode: 'Cyrl',
    direction: LocaleScriptDirection.ltr,
    requiresComplexShaping: false,
    requiresBundledFontPack: false,
    fallbackFontFamilies: <String>['sans-serif'],
  ),
  'Arab': ScriptRenderingProfile(
    scriptCode: 'Arab',
    direction: LocaleScriptDirection.rtl,
    requiresComplexShaping: true,
    requiresBundledFontPack: false,
    fallbackFontFamilies: <String>['sans-serif'],
  ),
};

ScriptRenderingProfile? renderingProfileForLocaleCode(String languageCode) {
  final metadata = appLocaleMetadata[languageCode.toLowerCase()];
  if (metadata == null) return null;
  return scriptRenderingProfiles[metadata.scriptCode];
}

/// Returns script codes used by enabled UI locales that have no explicit
/// rendering contract. CI can treat a non-empty result as a localization gate.
Set<String> missingScriptRenderingProfiles() {
  return appLocaleMetadata.values
      .map((metadata) => metadata.scriptCode)
      .where((script) => !scriptRenderingProfiles.containsKey(script))
      .toSet();
}
