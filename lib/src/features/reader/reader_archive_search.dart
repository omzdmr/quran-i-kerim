import '../../data/surah_localization.dart';
import 'reader_archive_context.dart';

bool readerArchiveMatchesQuery({
  required String query,
  required String selectionKey,
  required String languageCode,
  String? note,
  String? sourceCode,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return true;

  final reference = parseReaderArchiveReference(selectionKey);
  final surahName = reference == null
      ? ''
      : localizedSurahName(reference.surah, languageCode).toLowerCase();
  final searchable = <String>[
    selectionKey.toLowerCase(),
    surahName,
    note?.toLowerCase() ?? '',
    sourceCode?.toLowerCase() ?? '',
  ].join(' ');

  // Space-separated terms are ANDed so `bakara 255` and `note patience`
  // remain useful without introducing a server-side/full-text dependency.
  final terms = normalizedQuery
      .split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty);
  return terms.every(searchable.contains);
}
