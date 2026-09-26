import '../domain/prayer_calculation_explanation.dart';

/// Serializes calculation diagnostics without coordinates or unrelated user
/// data. The output is intentionally plain text so it can be copied into a bug
/// report without a backend/account.
class PrayerCalculationDiagnosticExport {
  const PrayerCalculationDiagnosticExport._();

  static String asText(
    PrayerCalculationExplanation explanation, {
    String? prayerId,
  }) {
    final snapshot = explanation.diagnosticSnapshot(prayerId: prayerId);
    final orderedKeys = <String>[
      'place',
      'localDate',
      'timezone',
      'source',
      'sourceVersion',
      'prayer',
      'method',
      'methodSelection',
      'asr',
      'highLatitude',
      'manualOffsetMinutes',
    ];
    final buffer = StringBuffer('Prayer time diagnostic\n');
    final written = <String>{};
    for (final key in orderedKeys) {
      final value = snapshot[key];
      if (value == null) continue;
      buffer.writeln('$key: $value');
      written.add(key);
    }
    for (final entry in snapshot.entries) {
      if (written.contains(entry.key)) continue;
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    return buffer.toString().trimRight();
  }
}
