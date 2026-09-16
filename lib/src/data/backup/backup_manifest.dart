/// Central contract for data that may leave the device in a user-owned backup.
///
/// Keep this list explicit. Adding a new local preference does not silently make
/// it part of backups, and large/re-downloadable assets stay device-local.
class BackupManifest {
  const BackupManifest._();

  static const int schemaVersion = 1;

  static const Set<String> includedSections = <String>{
    'reading',
    'bookmarks',
    'highlights',
    'notes',
    'memorization',
    'memorizationPractice',
    'preferences',
  };

  static const Set<String> excludedSections = <String>{
    'quranText',
    'translations',
    'audioCache',
    'memorizationRecordings',
  };

  static bool isIncluded(String section) => includedSections.contains(section);
  static bool isExcluded(String section) => excludedSections.contains(section);

  static Map<String, Object?> selectBackupData(Map<String, Object?> localData) {
    return Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final section in includedSections)
        if (localData.containsKey(section)) section: localData[section],
    });
  }
}
