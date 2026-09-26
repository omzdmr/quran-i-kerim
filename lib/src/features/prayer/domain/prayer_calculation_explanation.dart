import 'prayer_models.dart';

/// Deterministic, local-only audit data for the inputs that produced a prayer
/// schedule. It describes configuration without declaring one jurisprudential
/// method universally correct.
class PrayerCalculationExplanation {
  const PrayerCalculationExplanation({
    required this.effectiveMethod,
    required this.methodIsAutomatic,
    required this.asrMethod,
    required this.highLatitudeMethod,
    required this.adjustments,
    this.placeLabel,
    this.timeZoneId,
    this.localDate,
    this.sourceKind = PrayerTimeSourceKind.calculated,
    this.sourceVersion,
  });

  factory PrayerCalculationExplanation.from({
    required PrayerCalculationMethod defaultMethod,
    required PrayerCalculationMethod? methodOverride,
    required PrayerAsrMethod asrMethod,
    required PrayerHighLatitudeMethod highLatitudeMethod,
    required PrayerMinuteAdjustments adjustments,
    PrayerLocation? location,
    DateTime? localDate,
    PrayerTimeSourceKind sourceKind = PrayerTimeSourceKind.calculated,
    String? sourceVersion,
  }) => PrayerCalculationExplanation(
    effectiveMethod: methodOverride ?? defaultMethod,
    methodIsAutomatic: methodOverride == null,
    asrMethod: asrMethod,
    highLatitudeMethod: highLatitudeMethod,
    adjustments: adjustments,
    placeLabel: location?.label,
    timeZoneId: location?.timeZoneId,
    localDate: localDate,
    sourceKind: sourceKind,
    sourceVersion: sourceVersion,
  );

  final PrayerCalculationMethod effectiveMethod;
  final bool methodIsAutomatic;
  final PrayerAsrMethod asrMethod;
  final PrayerHighLatitudeMethod highLatitudeMethod;
  final PrayerMinuteAdjustments adjustments;

  /// Human-readable place label only. Precise coordinates are intentionally
  /// not retained in the explanation/diagnostic object.
  final String? placeLabel;
  final String? timeZoneId;
  final DateTime? localDate;
  final PrayerTimeSourceKind sourceKind;
  final String? sourceVersion;

  bool get hasManualAdjustments =>
      adjustmentEntries.any((entry) => entry.minutes != 0);

  List<PrayerAdjustmentExplanation> get adjustmentEntries => [
    PrayerAdjustmentExplanation(prayerId: 'fajr', minutes: adjustments.fajr),
    PrayerAdjustmentExplanation(prayerId: 'sunrise', minutes: adjustments.sunrise),
    PrayerAdjustmentExplanation(prayerId: 'dhuhr', minutes: adjustments.dhuhr),
    PrayerAdjustmentExplanation(prayerId: 'asr', minutes: adjustments.asr),
    PrayerAdjustmentExplanation(prayerId: 'maghrib', minutes: adjustments.maghrib),
    PrayerAdjustmentExplanation(prayerId: 'isha', minutes: adjustments.isha),
  ];

  List<PrayerAdjustmentExplanation> get activeAdjustments => adjustmentEntries
      .where((entry) => entry.minutes != 0)
      .toList(growable: false);

  PrayerAdjustmentExplanation adjustmentFor(String prayerId) =>
      adjustmentEntries.firstWhere(
        (entry) => entry.prayerId == prayerId,
        orElse: () => PrayerAdjustmentExplanation(
          prayerId: prayerId,
          minutes: 0,
        ),
      );

  /// Privacy-safe, copy/export-ready diagnostic data. Coordinates are excluded
  /// by design so callers cannot accidentally leak precise location.
  Map<String, String> diagnosticSnapshot({String? prayerId}) {
    final result = <String, String>{
      if (placeLabel != null && placeLabel!.trim().isNotEmpty)
        'place': placeLabel!.trim(),
      if (timeZoneId != null && timeZoneId!.trim().isNotEmpty)
        'timezone': timeZoneId!.trim(),
      if (localDate != null)
        'localDate':
            '${localDate!.year.toString().padLeft(4, '0')}-${localDate!.month.toString().padLeft(2, '0')}-${localDate!.day.toString().padLeft(2, '0')}',
      'source': sourceKind.name,
      if (sourceVersion != null && sourceVersion!.trim().isNotEmpty)
        'sourceVersion': sourceVersion!.trim(),
      'method': effectiveMethod.name,
      'methodSelection': methodIsAutomatic ? 'automatic' : 'manual',
      'asr': asrMethod.name,
      'highLatitude': highLatitudeMethod.name,
    };
    if (prayerId != null) {
      result['prayer'] = prayerId;
      result['manualOffsetMinutes'] = '${adjustmentFor(prayerId).minutes}';
    } else {
      for (final entry in activeAdjustments) {
        result['offset.${entry.prayerId}'] = '${entry.minutes}';
      }
    }
    return result;
  }
}

enum PrayerTimeSourceKind {
  calculated,
  authorizedTimetable,
  manualTimetable,
  mosqueIqamah,
}

class PrayerAdjustmentExplanation {
  const PrayerAdjustmentExplanation({
    required this.prayerId,
    required this.minutes,
  });

  final String prayerId;
  final int minutes;

  String get signedMinutes => '${minutes > 0 ? '+' : ''}$minutes';
}
