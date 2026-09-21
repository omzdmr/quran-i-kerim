import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../application/prayer_calculation_diagnostic_export.dart';
import '../domain/prayer_calculation_explanation.dart';
import 'prayer_calculation_explanation_card.dart';

Future<void> showPrayerCalculationInspector({
  required BuildContext context,
  required PrayerCalculationExplanation explanation,
  String? prayerId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheetContext) => PrayerCalculationInspectorSheet(
    explanation: explanation,
    prayerId: prayerId,
  ),
);

/// Read-only offline inspector for the calculation inputs behind a prayer time.
/// It intentionally has no settings controls: changing the method remains an
/// explicit action in Prayer Settings rather than a side effect of inspection.
class PrayerCalculationInspectorSheet extends StatelessWidget {
  const PrayerCalculationInspectorSheet({
    required this.explanation,
    this.prayerId,
    super.key,
  });

  final PrayerCalculationExplanation explanation;
  final String? prayerId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final materialL10n = MaterialLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final selectedOffset = prayerId == null
        ? null
        : explanation.adjustmentFor(prayerId!);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.text('calculationMethod'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: materialL10n.copyButtonLabel,
                  onPressed: () async {
                    final text = PrayerCalculationDiagnosticExport.asText(
                      explanation,
                      prayerId: prayerId,
                    );
                    await Clipboard.setData(ClipboardData(text: text));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(materialL10n.copyButtonLabel)),
                    );
                  },
                  icon: const Icon(Icons.copy_all_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (explanation.placeLabel != null ||
                explanation.timeZoneId != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (explanation.placeLabel != null)
                            Text(
                              explanation.placeLabel!,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          if (explanation.timeZoneId != null)
                            Text(
                              explanation.timeZoneId!,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            PrayerCalculationExplanationCard(explanation: explanation),
            if (selectedOffset != null) ...[
              const SizedBox(height: 12),
              Semantics(
                container: true,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_prayerLabel(context, selectedOffset.prayerId)}: '
                          '${selectedOffset.signedMinutes} ${l10n.text('minuteUnit')}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
