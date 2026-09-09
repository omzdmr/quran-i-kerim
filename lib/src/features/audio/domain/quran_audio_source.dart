enum QuranAudioKind { quran, translation }

/// One human-recorded audio edition exposed by an approved upstream provider.
class QuranAudioSource {
  const QuranAudioSource({
    required this.identifier,
    required this.languageCode,
    required this.name,
    required this.englishName,
    required this.kind,
    required this.providerName,
    required this.providerUri,
    required this.termsUri,
  });

  final String identifier;
  final String languageCode;
  final String name;
  final String englishName;
  final QuranAudioKind kind;
  final String providerName;
  final Uri providerUri;
  final Uri termsUri;

  bool get isTranslation => kind == QuranAudioKind.translation;

  String get displayName => name.trim().isNotEmpty ? name : englishName;
}

/// Immutable catalog with language/kind grouping for alternative human voices.
class QuranAudioCatalog {
  const QuranAudioCatalog(this.sources);

  final List<QuranAudioSource> sources;

  List<String> get languageCodes {
    final values = sources.map((source) => source.languageCode).toSet().toList();
    values.sort();
    return List<String>.unmodifiable(values);
  }

  List<QuranAudioSource> alternatives({
    required String languageCode,
    required QuranAudioKind kind,
  }) {
    final matches = sources
        .where(
          (source) =>
              source.languageCode == languageCode && source.kind == kind,
        )
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return List<QuranAudioSource>.unmodifiable(matches);
  }
}
