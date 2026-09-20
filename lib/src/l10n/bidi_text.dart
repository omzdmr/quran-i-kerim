import 'locale_metadata.dart';

const _ltrIsolate = '\u2066';
const _rtlIsolate = '\u2067';
const _firstStrongIsolate = '\u2068';
const _popDirectionalIsolate = '\u2069';

/// Isolates a dynamic fragment before embedding it in localized UI copy.
///
/// This prevents account names, dates, references such as `2:255`, and other
/// user/content-provided fragments from leaking their direction into the
/// surrounding Arabic/Latin/Cyrillic sentence. Unicode isolates are preferred
/// over directional override characters because they do not reorder unrelated
/// surrounding text.
String isolateBidiFragment(
  String value, {
  LocaleScriptDirection? direction,
}) {
  if (value.isEmpty) return value;
  final opener = switch (direction) {
    LocaleScriptDirection.ltr => _ltrIsolate,
    LocaleScriptDirection.rtl => _rtlIsolate,
    null => _firstStrongIsolate,
  };
  return '$opener$value$_popDirectionalIsolate';
}

String isolateLtrFragment(String value) => isolateBidiFragment(
      value,
      direction: LocaleScriptDirection.ltr,
    );

String isolateRtlFragment(String value) => isolateBidiFragment(
      value,
      direction: LocaleScriptDirection.rtl,
    );
