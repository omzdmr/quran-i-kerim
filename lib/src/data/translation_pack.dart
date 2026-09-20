class TranslationPack {
  const TranslationPack({
    required this.translationId,
    required this.languageCode,
    required this.version,
    required this.source,
    required this.verses,
    required this.footnotes,
  });

  final String translationId;
  final String languageCode;
  final String version;
  final String source;
  final Map<String, String> verses;
  final Map<String, String> footnotes;

  String? verse(int surah, int ayah) => verses['$surah:$ayah'];

  String? footnote(int surah, int ayah) => footnotes['$surah:$ayah'];
}
