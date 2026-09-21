import 'prayer_models.dart';

/// A deterministic, local-only explanation of the inputs that affect a prayer
/// schedule. It deliberately describes configuration rather than making a
/// religious/legal claim about which method a user should follow.
class PrayerCalculationExplanation {
  const PrayerCalculationExplanation({
    required this.effectiveMethod,
    required this.methodIsAutomatic,
    required this.asrMethod,
    required this.highLatitudeMethod,
    required this.adjustments,
  });

  factory PrayerCalculationExplanation.from({
    required PrayerCalculationMethod defaultMethod,
    required PrayerCalculationMethod? methodOverride,
    required PrayerAsrMethod asrMethod,
    required PrayerHighLatitudeMethod highLatitudeMethod,
    required PrayerMinuteAdjustments adjustments,
  }) => PrayerCalculationExplanation(
    effectiveMethod: methodOverride ?? defaultMethod,
    methodIsAutomatic: methodOverride == null,
    asrMethod: asrMethod,
    highLatitudeMethod: highLatitudeMethod,
    adjustments: adjustments,
  );

  final PrayerCalculationMethod effectiveMethod;
  final bool methodIsAutomatic;
  final PrayerAsrMethod asrMethod;
  final PrayerHighLatitudeMethod highLatitudeMethod;
  final PrayerMinuteAdjustments adjustments;

  bool get hasManualAdjustments => adjustmentEntries.any((entry) => entry.minutes != 0);

  List<PrayerAdjustmentExplanation> get adjustmentEntries => [
    PrayerAdjustmentExplanation(prayerId: 'fajr', minutes: adjustments.fajr),
    PrayerAdjustmentExplanation(prayerId: 'sunrise', minutes: adjustments.sunrise),
    PrayerAdjustmentExplanation(prayerId: 'dhuhr', minutes: adjustments.dhuhr),
    PrayerAdjustmentExplanation(prayerId: 'asr', minutes: adjustments.asr),
    PrayerAdjustmentExplanation(prayerId: 'maghrib', minutes: adjustments.maghrib),
    PrayerAdjustmentExplanation(prayerId: 'isha', minutes: adjustments.isha),
  ];

  List<PrayerAdjustmentExplanation> get activeAdjustments =>
      adjustmentEntries.where((entry) => entry.minutes != 0).toList(growable: false);
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
