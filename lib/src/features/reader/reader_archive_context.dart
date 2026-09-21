import '../../data/translation_catalog.dart';
import 'reader_reading_history.dart';

class ReaderArchiveReference {
  const ReaderArchiveReference({
    required this.surah,
    required this.ayah,
    required this.selectionKey,
  });

  final int surah;
  final int ayah;
  final String selectionKey;
}

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

String? readerSourceIdForArchiveCode(String? code) {
  final normalized = code?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  if (normalized == 'AR') return arabicOriginalSourceId;

  for (final source in translationCatalog) {
    if (source.id == normalized || source.code == normalized) return source.id;
  }
  return null;
}

ReaderArchiveReference? parseReaderArchiveReference(String selectionKey) {
  final separator = selectionKey.indexOf(':');
  if (separator <= 0 || separator == selectionKey.length - 1) return null;

  final surah = int.tryParse(selectionKey.substring(0, separator));
  if (surah == null || surah < 1 || surah > 114) return null;

  final ayahPart = selectionKey.substring(separator + 1);
  final firstPart = ayahPart.split(RegExp(r'[-,]')).first.trim();
  final ayah = int.tryParse(firstPart);
  if (ayah == null || ayah < 1) return null;

  return ReaderArchiveReference(
    surah: surah,
    ayah: ayah,
    selectionKey: selectionKey,
  );
}

/// Best-effort migration path for source-neutral legacy bookmarks/highlights.
/// Reader history already persists source identity. If the exact saved ayah was
/// recently read, its newest context is safer than blindly applying whichever
/// translation happens to be selected today.
String? recentReaderSourceForArchive(
  String selectionKey,
  Iterable<ReaderHistoryEntry> history,
) {
  final reference = parseReaderArchiveReference(selectionKey);
  if (reference == null) return null;

  ReaderHistoryEntry? newest;
  for (final entry in history) {
    if (entry.surah != reference.surah || entry.ayah != reference.ayah) continue;
    if (newest == null || entry.updatedAt > newest.updatedAt) newest = entry;
  }
  return newest?.sourceId;
}

ReaderArchiveContext? parseReaderArchiveContext({
  required String selectionKey,
  String? sourceCode,
  String? historySourceId,
  String? fallbackSourceId,
}) {
  final reference = parseReaderArchiveReference(selectionKey);
  if (reference == null) return null;

  final sourceId = readerSourceIdForArchiveCode(sourceCode) ??
      readerSourceIdForArchiveCode(historySourceId) ??
      readerSourceIdForArchiveCode(fallbackSourceId) ??
      historySourceId?.trim() ??
      fallbackSourceId?.trim();
  if (sourceId == null || sourceId.isEmpty) return null;

  return ReaderArchiveContext(
    surah: reference.surah,
    ayah: reference.ayah,
    sourceId: sourceId,
    selectionKey: selectionKey,
  );
}
