import '../../data/translation_catalog.dart';

/// Immutable navigation context for a saved Reader artifact (bookmark, note or
/// highlight). The canonical Qur'an identity is always surah/ayah; [sourceId]
/// only restores the display layer that was active when the artifact was made.
class ReaderArchiveContext {
  const ReaderArchiveContext({
    required this.surah,
    required this.ayah,
    required this.sourceId,
    required this.selectionKey,
  });

  final int surah;
  final int ayah;
  final String sourceId;
  final String selectionKey;

  bool get isValid => surah >= 1 && surah <= 114 && ayah >= 1;
}

/// Resolves legacy source codes stored with notes into stable translation IDs.
///
/// Older notes store short codes (for example `RWD`) rather than catalog IDs.
/// Keeping this conversion in one place prevents archive navigation from
/// accidentally treating a display label as canonical Qur'an identity.
String? readerSourceIdForArchiveCode(String? code) {
  final normalized = code?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  if (normalized == 'AR') return arabicOriginalSourceId;

  for (final source in translationCatalog) {
    if (source.id == normalized || source.code == normalized) return source.id;
  }
  return null;
}

/// Parses the first canonical ayah from a persisted selection key such as
/// `2:255`, `2:255-257` or `2:255,257`. Invalid/corrupt keys are rejected.
ReaderArchiveContext? parseReaderArchiveContext({
  required String selectionKey,
  String? sourceCode,
  String? fallbackSourceId,
}) {
  final separator = selectionKey.indexOf(':');
  if (separator <= 0 || separator == selectionKey.length - 1) return null;

  final surah = int.tryParse(selectionKey.substring(0, separator));
  if (surah == null || surah < 1 || surah > 114) return null;

  final ayahPart = selectionKey.substring(separator + 1);
  final firstPart = ayahPart.split(RegExp(r'[-,]')).first.trim();
  final ayah = int.tryParse(firstPart);
  if (ayah == null || ayah < 1) return null;

  final sourceId = readerSourceIdForArchiveCode(sourceCode) ??
      readerSourceIdForArchiveCode(fallbackSourceId) ??
      fallbackSourceId?.trim();
  if (sourceId == null || sourceId.isEmpty) return null;

  return ReaderArchiveContext(
    surah: surah,
    ayah: ayah,
    sourceId: sourceId,
    selectionKey: selectionKey,
  );
}
