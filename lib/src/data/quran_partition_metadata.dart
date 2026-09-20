// Structural Quran metadata used for offline navigation/planning.
//
// Hizb starts are derived from Tanzil Quran Metadata's 240 <quarter> entries:
// each Hizb begins at quarter 1, 5, 9, ... 237.
// Source: https://tanzil.net/docs/quran_metadata
// Retrieval mirror: https://github.com/Mushaf-Learning/quran-text/blob/main/metadata/quran-data.xml
// Upstream metadata license: Creative Commons Attribution 3.0 (CC BY 3.0).
// Attribution to Tanzil.net must be retained. Do not hand-edit these boundaries
// without comparing against the canonical upstream metadata.

class QuranPartitionReference {
  const QuranPartitionReference({required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  String get key => '$surah:$ayah';
}

const int quranHizbCount = 60;

const tanzilHizbStartReferences = <QuranPartitionReference>[
  QuranPartitionReference(surah: 1, ayah: 1),
  QuranPartitionReference(surah: 2, ayah: 75),
  QuranPartitionReference(surah: 2, ayah: 142),
  QuranPartitionReference(surah: 2, ayah: 203),
  QuranPartitionReference(surah: 2, ayah: 253),
  QuranPartitionReference(surah: 3, ayah: 15),
  QuranPartitionReference(surah: 3, ayah: 93),
  QuranPartitionReference(surah: 3, ayah: 171),
  QuranPartitionReference(surah: 4, ayah: 24),
  QuranPartitionReference(surah: 4, ayah: 88),
  QuranPartitionReference(surah: 4, ayah: 148),
  QuranPartitionReference(surah: 5, ayah: 27),
  QuranPartitionReference(surah: 5, ayah: 82),
  QuranPartitionReference(surah: 6, ayah: 36),
  QuranPartitionReference(surah: 6, ayah: 111),
  QuranPartitionReference(surah: 7, ayah: 1),
  QuranPartitionReference(surah: 7, ayah: 88),
  QuranPartitionReference(surah: 7, ayah: 171),
  QuranPartitionReference(surah: 8, ayah: 41),
  QuranPartitionReference(surah: 9, ayah: 34),
  QuranPartitionReference(surah: 9, ayah: 93),
  QuranPartitionReference(surah: 10, ayah: 26),
  QuranPartitionReference(surah: 11, ayah: 6),
  QuranPartitionReference(surah: 11, ayah: 84),
  QuranPartitionReference(surah: 12, ayah: 53),
  QuranPartitionReference(surah: 13, ayah: 19),
  QuranPartitionReference(surah: 15, ayah: 1),
  QuranPartitionReference(surah: 16, ayah: 51),
  QuranPartitionReference(surah: 17, ayah: 1),
  QuranPartitionReference(surah: 17, ayah: 99),
  QuranPartitionReference(surah: 18, ayah: 75),
  QuranPartitionReference(surah: 20, ayah: 1),
  QuranPartitionReference(surah: 21, ayah: 1),
  QuranPartitionReference(surah: 22, ayah: 1),
  QuranPartitionReference(surah: 23, ayah: 1),
  QuranPartitionReference(surah: 24, ayah: 21),
  QuranPartitionReference(surah: 25, ayah: 21),
  QuranPartitionReference(surah: 26, ayah: 111),
  QuranPartitionReference(surah: 27, ayah: 56),
  QuranPartitionReference(surah: 28, ayah: 51),
  QuranPartitionReference(surah: 29, ayah: 46),
  QuranPartitionReference(surah: 31, ayah: 22),
  QuranPartitionReference(surah: 33, ayah: 31),
  QuranPartitionReference(surah: 34, ayah: 24),
  QuranPartitionReference(surah: 36, ayah: 28),
  QuranPartitionReference(surah: 37, ayah: 145),
  QuranPartitionReference(surah: 39, ayah: 32),
  QuranPartitionReference(surah: 40, ayah: 41),
  QuranPartitionReference(surah: 41, ayah: 47),
  QuranPartitionReference(surah: 43, ayah: 24),
  QuranPartitionReference(surah: 46, ayah: 1),
  QuranPartitionReference(surah: 48, ayah: 18),
  QuranPartitionReference(surah: 51, ayah: 31),
  QuranPartitionReference(surah: 55, ayah: 1),
  QuranPartitionReference(surah: 58, ayah: 1),
  QuranPartitionReference(surah: 62, ayah: 1),
  QuranPartitionReference(surah: 67, ayah: 1),
  QuranPartitionReference(surah: 72, ayah: 1),
  QuranPartitionReference(surah: 78, ayah: 1),
  QuranPartitionReference(surah: 87, ayah: 1),
];
