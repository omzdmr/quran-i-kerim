import 'package:quran/quran.dart' as quran;

import '../../../data/surah_catalog.dart';

enum MemorizationTargetId {
  fullQuran,
  juzAmma,
  alKahf,
  yaSin,
  arRahman,
  alMulk,
}

class MemorizationTargetDefinition {
  const MemorizationTargetDefinition({
    required this.id,
    required this.surahNumbers,
  });

  final MemorizationTargetId id;
  final List<int> surahNumbers;

  bool get isFullQuran => id == MemorizationTargetId.fullQuran;

  int get verseCount {
    if (isFullQuran) {
      return surahCatalog.fold(0, (sum, surah) => sum + surah.verseCount);
    }
    final selected = surahNumbers.toSet();
    return surahCatalog
        .where((surah) => selected.contains(surah.number))
        .fold(0, (sum, surah) => sum + surah.verseCount);
  }
}

const memorizationTargetDefinitions = <MemorizationTargetDefinition>[
  MemorizationTargetDefinition(
    id: MemorizationTargetId.fullQuran,
    surahNumbers: <int>[],
  ),
  MemorizationTargetDefinition(
    id: MemorizationTargetId.juzAmma,
    surahNumbers: <int>[
      78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94,
      95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108,
      109, 110, 111, 112, 113, 114,
    ],
  ),
  MemorizationTargetDefinition(
    id: MemorizationTargetId.alKahf,
    surahNumbers: <int>[18],
  ),
  MemorizationTargetDefinition(
    id: MemorizationTargetId.yaSin,
    surahNumbers: <int>[36],
  ),
  MemorizationTargetDefinition(
    id: MemorizationTargetId.arRahman,
    surahNumbers: <int>[55],
  ),
  MemorizationTargetDefinition(
    id: MemorizationTargetId.alMulk,
    surahNumbers: <int>[67],
  ),
];

final Map<MemorizationTargetId, MemorizationTargetDefinition>
    _definitionById = <MemorizationTargetId, MemorizationTargetDefinition>{
  for (final target in memorizationTargetDefinitions) target.id: target,
};

final Map<MemorizationTargetId, List<int>> _pagesByTarget =
    <MemorizationTargetId, List<int>>{
  for (final target in memorizationTargetDefinitions)
    target.id: _buildPages(target),
};

MemorizationTargetDefinition memorizationTargetDefinition(
  MemorizationTargetId id,
) =>
    _definitionById[id]!;

List<int> _buildPages(MemorizationTargetDefinition target) {
  if (target.isFullQuran) {
    return List<int>.unmodifiable(List<int>.generate(604, (index) => index + 1));
  }

  final selected = target.surahNumbers.toSet();
  final pages = <int>{};
  for (final surah in surahCatalog) {
    if (!selected.contains(surah.number)) continue;
    for (var ayah = 1; ayah <= surah.verseCount; ayah++) {
      pages.add(quran.getPageNumber(surah.number, ayah));
    }
  }

  final sorted = pages.toList()..sort();
  return List<int>.unmodifiable(sorted);
}

/// Returns Mushaf pages that contain at least one verse from the target.
///
/// Memorization progress is currently page-based, so a single-surah target may
/// include a boundary page that also contains verses from a neighboring surah.
/// This keeps navigation compatible with the existing 604-page map until
/// ayah-level completion metadata is introduced.
List<int> memorizationPagesForTarget(MemorizationTargetId id) =>
    _pagesByTarget[id]!;

int memorizedPageCountForTarget(
  MemorizationTargetId id,
  Set<int> memorizedPages,
) =>
    memorizationPagesForTarget(id)
        .where(memorizedPages.contains)
        .length;

int? nextMemorizationPageForTarget(
  MemorizationTargetId id,
  Set<int> memorizedPages,
) {
  for (final page in memorizationPagesForTarget(id)) {
    if (!memorizedPages.contains(page)) return page;
  }
  return null;
}
