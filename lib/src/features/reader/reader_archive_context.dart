import '../../data/surah_catalog.dart';
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

String? _nonEmpty(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String? readerSourceIdForArchiveCode(String? code) {
  final normalized = _nonEmpty(code);
  if (normalized == null) return null;
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
  if (surah == null || surah < 1 || surah > surahCatalog.length) return null;

  final ayahPart = selectionKey.substring(separator + 1);
  final firstPart = ayahPart.split(RegExp(r'[-,]')).first.trim();
  final ayah = int.tryParse(firstPart);
  if (ayah == null ||
      ayah < 1 ||
      ayah > surahCatalog[surah - 1].verseCount) {
    return null;
  }

  return ReaderArchiveReference(
    surah: surah,
    ayah: ayah,
    selectionKey: selectionKey,
  );
}

String? recentReaderSourceForArchive(
  String selectionKey,
  Iterable<ReaderHistoryEntry> history,
) {
  final reference = parseReaderArchiveReference(selectionKey);
  if (reference == null) return null;

  ReaderHistoryEntry? newest;
  for (final entry in history) {
    if (entry.surah != reference.surah || entry.ayah != reference.ayah) continue;
    if (_nonEmpty(entry.sourceId) == null) continue;
    if (newest == null || entry.updatedAt > newest.updatedAt) newest = entry;
  }
  return _nonEmpty(newest?.sourceId);
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
      _nonEmpty(historySourceId) ??
      _nonEmpty(fallbackSourceId);
  if (sourceId == null) return null;

  return ReaderArchiveContext(
    surah: reference.surah,
    ayah: reference.ayah,
    sourceId: sourceId,
    selectionKey: selectionKey,
  );
}
