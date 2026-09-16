enum BackupPreviewIssue {
  invalidRoot,
  unsupportedVersion,
  invalidCreatedAt,
  invalidData,
}

class BackupPreview {
  const BackupPreview({
    required this.version,
    required this.createdAt,
    required this.recordCounts,
    required this.issues,
  });

  final int? version;
  final DateTime? createdAt;
  final Map<String, int> recordCounts;
  final Set<BackupPreviewIssue> issues;

  bool get canRestore => issues.isEmpty;
  int get totalRecords =>
      recordCounts.values.fold<int>(0, (total, count) => total + count);
}

class BackupPreviewParser {
  const BackupPreviewParser();

  static const int currentVersion = 1;

  BackupPreview parse(Object? decoded) {
    if (decoded is! Map) {
      return const BackupPreview(
        version: null,
        createdAt: null,
        recordCounts: <String, int>{},
        issues: <BackupPreviewIssue>{BackupPreviewIssue.invalidRoot},
      );
    }

    final issues = <BackupPreviewIssue>{};
    final version = decoded['version'];
    final parsedVersion = version is int ? version : null;
    if (parsedVersion != currentVersion) {
      issues.add(BackupPreviewIssue.unsupportedVersion);
    }

    final rawCreatedAt = decoded['createdAt'];
    final createdAt = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt)?.toUtc()
        : null;
    if (createdAt == null) {
      issues.add(BackupPreviewIssue.invalidCreatedAt);
    }

    final data = decoded['data'];
    final counts = <String, int>{};
    if (data is Map) {
      for (final entry in data.entries) {
        if (entry.key is! String) {
          issues.add(BackupPreviewIssue.invalidData);
          continue;
        }
        final value = entry.value;
        if (value is List) {
          counts[entry.key as String] = value.length;
        } else if (value is Map) {
          counts[entry.key as String] = value.length;
        } else if (value == null) {
          counts[entry.key as String] = 0;
        } else {
          issues.add(BackupPreviewIssue.invalidData);
        }
      }
    } else {
      issues.add(BackupPreviewIssue.invalidData);
    }

    return BackupPreview(
      version: parsedVersion,
      createdAt: createdAt,
      recordCounts: Map<String, int>.unmodifiable(counts),
      issues: Set<BackupPreviewIssue>.unmodifiable(issues),
    );
  }
}
