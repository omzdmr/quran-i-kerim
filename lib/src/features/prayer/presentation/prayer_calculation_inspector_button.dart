import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../application/prayer_calculation_explanation_loader.dart';
import 'prayer_calculation_inspector_sheet.dart';

/// Small integration widget for PrayerScreen/PrayerSettingsScreen. It loads the
/// explanation from local persisted state only when requested, so it adds no
/// network dependency and does not keep a second settings cache alive.
class PrayerCalculationInspectorButton extends StatefulWidget {
  const PrayerCalculationInspectorButton({
    this.prayerId,
    this.iconOnly = false,
    super.key,
  });

  final String? prayerId;
  final bool iconOnly;

  @override
  State<PrayerCalculationInspectorButton> createState() =>
      _PrayerCalculationInspectorButtonState();
}

class _PrayerCalculationInspectorButtonState
    extends State<PrayerCalculationInspectorButton> {
  bool _loading = false;

  Future<void> _open() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final explanation = await PrayerCalculationExplanationLoader.load();
      if (!mounted) return;
      await showPrayerCalculationInspector(
        context: context,
        explanation: explanation,
        prayerId: widget.prayerId,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.text('calculationMethod');
    if (widget.iconOnly) {
      return IconButton(
        tooltip: label,
        onPressed: _loading ? null : _open,
        icon: _loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.info_outline_rounded),
      );
    }
    return OutlinedButton.icon(
      onPressed: _loading ? null : _open,
      icon: _loading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.info_outline_rounded),
      label: Text(label),
    );
  }
}
