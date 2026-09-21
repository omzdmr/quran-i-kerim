import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_calculation_explanation.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_calculation_explanation_card.dart';

void main() {
  Widget appFor(PrayerCalculationExplanation explanation) => MaterialApp(
    locale: const Locale('tr'),
    home: Scaffold(
      body: PrayerCalculationExplanationCard(explanation: explanation),
    ),
  );

  testWidgets('shows effective automatic method and calculation inputs', (
    tester,
  ) async {
    await tester.pumpWidget(
      appFor(
        PrayerCalculationExplanation.from(
          defaultMethod: PrayerCalculationMethod.turkiye,
          methodOverride: null,
          asrMethod: PrayerAsrMethod.hanafi,
          highLatitudeMethod: PrayerHighLatitudeMethod.middleOfTheNight,
          adjustments: const PrayerMinuteAdjustments(fajr: -2, isha: 5),
        ),
      ),
    );

    expect(find.text('Hesaplama yöntemi'), findsOneWidget);
    expect(find.textContaining('Otomatik'), findsOneWidget);
    expect(find.textContaining('Türkiye'), findsOneWidget);
    expect(find.text('Hanefi'), findsOneWidget);
    expect(find.text('Gecenin yarısı'), findsOneWidget);
    expect(find.textContaining('İmsak -2 dk'), findsOneWidget);
    expect(find.textContaining('Yatsı +5 dk'), findsOneWidget);
  });

  testWidgets('shows zero adjustment when schedule has no manual offsets', (
    tester,
  ) async {
    await tester.pumpWidget(
      appFor(
        PrayerCalculationExplanation.from(
          defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
          methodOverride: PrayerCalculationMethod.muslimWorldLeague,
          asrMethod: PrayerAsrMethod.standard,
          highLatitudeMethod: PrayerHighLatitudeMethod.recommended,
          adjustments: const PrayerMinuteAdjustments(),
        ),
      ),
    );

    expect(find.text('Muslim World League'), findsOneWidget);
    expect(find.text('Standart'), findsOneWidget);
    expect(find.text('Önerilen'), findsOneWidget);
    expect(find.text('0 dk'), findsOneWidget);
  });

  testWidgets('calculation summary exposes a semantic container', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await tester.pumpWidget(
      appFor(
        PrayerCalculationExplanation.from(
          defaultMethod: PrayerCalculationMethod.turkiye,
          methodOverride: null,
          asrMethod: PrayerAsrMethod.standard,
          highLatitudeMethod: PrayerHighLatitudeMethod.recommended,
          adjustments: const PrayerMinuteAdjustments(),
        ),
      ),
    );

    final semantics = tester.getSemantics(
      find.byType(PrayerCalculationExplanationCard),
    );
    expect(semantics.label, contains('Hesaplama yöntemi'));
  });
}
