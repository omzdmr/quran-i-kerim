import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/prayer_preferences_store.dart';
import '../domain/prayer_city_catalog.dart';
import '../domain/prayer_models.dart';

class PrayerSettingsScreen extends StatefulWidget {
  const PrayerSettingsScreen({
    required this.city,
    required this.initial,
    super.key,
  });

  final PrayerCity city;
  final PrayerSettingsSnapshot initial;

  @override
  State<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends State<PrayerSettingsScreen> {
  late PrayerCalculationMethod? _methodOverride;
  late PrayerAsrMethod _asrMethod;
  late PrayerHighLatitudeMethod _highLatitudeMethod;
  late PrayerMinuteAdjustments _adjustments;

  @override
  void initState() {
    super.initState();
    _methodOverride = widget.initial.methodOverride;
    _asrMethod = widget.initial.asrMethod;
    _highLatitudeMethod = widget.initial.highLatitudeMethod;
    _adjustments = widget.initial.adjustments;
  }

  PrayerSettingsSnapshot get _snapshot => PrayerSettingsSnapshot(
        methodOverride: _methodOverride,
        asrMethod: _asrMethod,
        highLatitudeMethod: _highLatitudeMethod,
        adjustments: _adjustments,
      );

  Future<void> _save() async {
    await PrayerPreferencesStore.save(_snapshot);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    Navigator.pop(context, _snapshot);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz Ayarları'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Kaydet')),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
        children: [
          _SectionCard(
            title: 'Hesaplama yöntemi',
            subtitle:
                'Otomatik seçerseniz ${widget.city.label} için önerilen yöntem kullanılır.',
            child: DropdownButtonFormField<PrayerCalculationMethod?>(
              initialValue: _methodOverride,
              decoration: const InputDecoration(
                labelText: 'Yöntem',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<PrayerCalculationMethod?>(
                  value: null,
                  child: Text(
                    'Otomatik · ${_methodLabel(widget.city.defaultMethod)}',
                  ),
                ),
                for (final method in PrayerCalculationMethod.values)
                  DropdownMenuItem<PrayerCalculationMethod?>(
                    value: method,
                    child: Text(_methodLabel(method)),
                  ),
              ],
              onChanged: (value) {
                setState(() => _methodOverride = value);
                HapticFeedback.selectionClick();
              },
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'İkindi hesabı',
            subtitle: 'Bu ayar yalnızca İkindi vaktini etkiler.',
            child: SegmentedButton<PrayerAsrMethod>(
              segments: const [
                ButtonSegment(
                  value: PrayerAsrMethod.standard,
                  label: Text('Standart'),
                ),
                ButtonSegment(
                  value: PrayerAsrMethod.hanafi,
                  label: Text('Hanefi'),
                ),
              ],
              selected: {_asrMethod},
              onSelectionChanged: (value) {
                setState(() => _asrMethod = value.first);
                HapticFeedback.selectionClick();
              },
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Yüksek enlem',
            subtitle:
                'Uzun yaz/kış günlerinde sabah ve yatsı hesabı için kullanılır.',
            child: DropdownButtonFormField<PrayerHighLatitudeMethod>(
              initialValue: _highLatitudeMethod,
              decoration: const InputDecoration(
                labelText: 'Kural',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final value in PrayerHighLatitudeMethod.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(_highLatitudeLabel(value)),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _highLatitudeMethod = value);
                HapticFeedback.selectionClick();
              },
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Dakika düzeltmeleri',
            subtitle:
                'Yerel takvimle küçük fark varsa vakitleri ayrı ayrı -30 ile +30 dakika arasında düzeltin.',
            child: Column(
              children: [
                _AdjustmentRow(
                  label: 'İmsak',
                  value: _adjustments.fajr,
                  onChanged: (value) => _setAdjustment(fajr: value),
                ),
                _AdjustmentRow(
                  label: 'Güneş',
                  value: _adjustments.sunrise,
                  onChanged: (value) => _setAdjustment(sunrise: value),
                ),
                _AdjustmentRow(
                  label: 'Öğle',
                  value: _adjustments.dhuhr,
                  onChanged: (value) => _setAdjustment(dhuhr: value),
                ),
                _AdjustmentRow(
                  label: 'İkindi',
                  value: _adjustments.asr,
                  onChanged: (value) => _setAdjustment(asr: value),
                ),
                _AdjustmentRow(
                  label: 'Akşam',
                  value: _adjustments.maghrib,
                  onChanged: (value) => _setAdjustment(maghrib: value),
                ),
                _AdjustmentRow(
                  label: 'Yatsı',
                  value: _adjustments.isha,
                  onChanged: (value) => _setAdjustment(isha: value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Hesaplama yöntemi bir başlangıç ayarıdır. Yerel resmi takvimle fark görürseniz yöntem veya dakika düzeltmesini değiştirebilirsiniz. Ayarlar cihazda saklanır.',
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  void _setAdjustment({
    int? fajr,
    int? sunrise,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? isha,
  }) {
    setState(() {
      _adjustments = PrayerMinuteAdjustments(
        fajr: fajr ?? _adjustments.fajr,
        sunrise: sunrise ?? _adjustments.sunrise,
        dhuhr: dhuhr ?? _adjustments.dhuhr,
        asr: asr ?? _adjustments.asr,
        maghrib: maghrib ?? _adjustments.maghrib,
        isha: isha ?? _adjustments.isha,
      );
    });
    HapticFeedback.selectionClick();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AdjustmentRow extends StatelessWidget {
  const _AdjustmentRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        IconButton.filledTonal(
          onPressed: value <= -30 ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_rounded),
          tooltip: '1 dakika azalt',
        ),
        SizedBox(
          width: 54,
          child: Text(
            value == 0 ? '0 dk' : '${value > 0 ? '+' : ''}$value dk',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton.filledTonal(
          onPressed: value >= 30 ? null : () => onChanged(value + 1),
          icon: const Icon(Icons.add_rounded),
          tooltip: '1 dakika artır',
        ),
      ],
    );
  }
}

String _methodLabel(PrayerCalculationMethod method) => switch (method) {
      PrayerCalculationMethod.turkiye => 'Türkiye / Diyanet yaklaşımı',
      PrayerCalculationMethod.muslimWorldLeague => 'Muslim World League',
      PrayerCalculationMethod.ummAlQura => 'Umm al-Qura',
      PrayerCalculationMethod.egyptian => 'Egyptian General Authority',
      PrayerCalculationMethod.karachi => 'University of Islamic Sciences, Karachi',
      PrayerCalculationMethod.northAmerica => 'ISNA / North America',
      PrayerCalculationMethod.moonsightingCommittee => 'Moonsighting Committee',
    };

String _highLatitudeLabel(PrayerHighLatitudeMethod value) => switch (value) {
      PrayerHighLatitudeMethod.recommended => 'Önerilen',
      PrayerHighLatitudeMethod.middleOfTheNight => 'Gecenin yarısı',
      PrayerHighLatitudeMethod.seventhOfTheNight => 'Gecenin yedide biri',
      PrayerHighLatitudeMethod.twilightAngle => 'Alacakaranlık açısı',
    };
