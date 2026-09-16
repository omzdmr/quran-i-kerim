/// Central contract for data that may leave the device in a user-owned backup.
///
/// Keep this list explicit. Adding a new local preference does not silently make
/// it part of backups, and large/re-downloadable assets stay device-local.
class BackupManifest {
  const BackupManifest._();

  static const int schemaVersion = 4;
  static const Set<int> supportedVersions = <int>{1, 2, 3, schemaVersion};

  static const Set<String> version1Sections = <String>{
    'reading',
    'bookmarks',
    'highlights',
    'notes',
    'memorization',
    'memorizationPractice',
    'preferences',
  };

  static const Set<String> version2Sections = <String>{
    ...version1Sections,
    'learning',
  };

  static const Set<String> version3Sections = <String>{
    ...version2Sections,
    'dhikr',
    'prayerPreferences',
  };

  static const Set<String> includedSections = <String>{
    ...version3Sections,
    'readingPlans',
  };

  static const Set<String> excludedSections = <String>{
    'quranText',
    'translations',
    'audioCache',
    'memorizationRecordings',
    'prayerLocation',
  };

  static bool isIncluded(String section) => includedSections.contains(section);
  static bool isExcluded(String section) => excludedSections.contains(section);
  static bool isVersionSupported(int version) => supportedVersions.contains(version);

  static Set<String> sectionsForVersion(int version) {
    return switch (version) {
      1 => version1Sections,
      2 => version2Sections,
      3 => version3Sections,
      schemaVersion => includedSections,
      _ => const <String>{},
    };
  }

  static Map<String, Object?> selectBackupData(Map<String, Object?> localData) {
    return Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final section in includedSections)
        if (localData.containsKey(section)) section: localData[section],
    });
  }
}
