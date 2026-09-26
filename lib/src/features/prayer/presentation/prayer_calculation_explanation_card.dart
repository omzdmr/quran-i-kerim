import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/prayer_calculation_explanation.dart';
import '../domain/prayer_models.dart';

/// User-facing summary of the settings that produced the displayed prayer
/// times. Uses existing localized prayer-setting labels so it remains aligned
/// with the settings screen and does not introduce an English-only surface.
class PrayerCalculationExplanationCard extends StatelessWidget {
  const PrayerCalculationExplanationCard({
    required this.explanation,
    super.key,
  });

  final PrayerCalculationExplanation explanation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final adjustments = explanation.activeAdjustments;

    return Semantics(
      container: true,
      label: l10n.text('calculationMethod'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.text('calculationMethod'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ExplanationRow(
              label: l10n.text('method'),
              value: explanation.methodIsAutomatic
                  ? '${l10n.text('automatic')} · ${_methodLabel(context, explanation.effectiveMethod)}'
                  : _methodLabel(context, explanation.effectiveMethod),
            ),
            _ExplanationRow(
              label: l10n.text('asrCalculation'),
              value: explanation.asrMethod == PrayerAsrMethod.hanafi
                  ? l10n.text('hanafi')
                  : l10n.text('standard'),
            ),
            _ExplanationRow(
              label: l10n.text('highLatitude'),
              value: _highLatitudeLabel(context, explanation.highLatitudeMethod),
            ),
            _ExplanationRow(
              label: l10n.text('minuteAdjustments'),
              value: adjustments.isEmpty
                  ? '0 ${l10n.text('minuteUnit')}'
                  : adjustments
                      .map(
                        (entry) =>
                            '${_prayerLabel(context, entry.prayerId)} ${entry.signedMinutes} ${l10n.text('minuteUnit')}',
                      )
                      .join(' · '),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.text('prayerOfflineInfo'),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.4,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationRow extends StatelessWidget {
  const _ExplanationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

String _methodLabel(BuildContext context, PrayerCalculationMethod value) {
  final l10n = context.l10n;
  return switch (value) {
    PrayerCalculationMethod.turkiye => l10n.text('turkiyeMethod'),
    PrayerCalculationMethod.muslimWorldLeague => l10n.text('mwlMethod'),
    PrayerCalculationMethod.ummAlQura => l10n.text('ummAlQuraMethod'),
    PrayerCalculationMethod.egyptian => l10n.text('egyptianMethod'),
    PrayerCalculationMethod.karachi => l10n.text('karachiMethod'),
    PrayerCalculationMethod.northAmerica => l10n.text('northAmericaMethod'),
    PrayerCalculationMethod.moonsightingCommittee => l10n.text('moonsightingMethod'),
  };
}

String _highLatitudeLabel(
  BuildContext context,
  PrayerHighLatitudeMethod value,
) {
  final l10n = context.l10n;
  return switch (value) {
    PrayerHighLatitudeMethod.recommended => l10n.text('recommended'),
    PrayerHighLatitudeMethod.middleOfTheNight => l10n.text('middleOfNight'),
    PrayerHighLatitudeMethod.seventhOfTheNight => l10n.text('seventhOfNight'),
    PrayerHighLatitudeMethod.twilightAngle => l10n.text('twilightAngle'),
  };
}

String _prayerLabel(BuildContext context, String id) {
  final l10n = context.l10n;
  return switch (id) {
    'fajr' => l10n.text('fajr'),
    'sunrise' => l10n.text('sunrise'),
    'dhuhr' => l10n.text('dhuhr'),
    'asr' => l10n.text('asr'),
    'maghrib' => l10n.text('maghrib'),
    'isha' => l10n.text('isha'),
    _ => id,
  };
}
