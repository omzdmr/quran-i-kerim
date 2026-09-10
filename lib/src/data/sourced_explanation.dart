import 'translation_pack.dart';

/// A source-bound explanation exposed by the app without rewriting its text.
///
/// The first supported kind is a translation provider's own footnote. Keeping
/// this value separate from UI copy makes provenance explicit before richer
/// explanation/Learn surfaces are added.
class SourcedExplanation {
  const SourcedExplanation({
    required this.surah,
    required this.ayah,
    required this.text,
    required this.sourceId,
    required this.languageCode,
    required this.source,
    required this.version,
  });

  final int surah;
  final int ayah;
  final String text;
  final String sourceId;
  final String languageCode;
  final String source;
  final String version;

  String get reference => '$surah:$ayah';
}

/// Returns the provider-authored footnote for an ayah as a sourced explanation.
///
/// [SourcedExplanation.text] intentionally preserves the exact string stored in
/// the installed translation pack. Whitespace is inspected only to avoid
/// exposing empty notes; it is never trimmed or otherwise rewritten.
SourcedExplanation? sourcedTranslationFootnote({
  required TranslationPack pack,
  required int surah,
  required int ayah,
}) {
  if (surah < 1 || surah > 114 || ayah < 1) return null;
  final raw = pack.footnote(surah, ayah);
  if (raw == null || raw.trim().isEmpty) return null;

  return SourcedExplanation(
    surah: surah,
    ayah: ayah,
    text: raw,
    sourceId: pack.translationId,
    languageCode: pack.languageCode,
    source: pack.source,
    version: pack.version,
  );
}
