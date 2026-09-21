import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_calculation_explanation.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_calculation_inspector_sheet.dart';

void main() {
  final explanation = PrayerCalculationExplanation.from(
    defaultMethod: PrayerCalculationMethod.turkiye,
    methodOverride: null,
    asrMethod: PrayerAsrMethod.standard,
    highLatitudeMethod: PrayerHighLatitudeMethod.recommended,
    adjustments: const PrayerMinuteAdjustments(fajr: -2),
    location: const PrayerLocation(
      latitude: 41.0082,
      longitude: 28.9784,
      timeZoneId: 'Europe/Istanbul',
      label: 'Istanbul',
    ),
    localDate: DateTime(2026, 9, 21),
  );

  testWidgets('shows privacy-safe place and selected prayer offset', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        home: Scaffold(
          body: PrayerCalculationInspectorSheet(
            explanation: explanation,
            prayerId: 'fajr',
          ),
        ),
      ),
    );

    expect(find.text('Istanbul'), findsOneWidget);
    expect(find.text('Europe/Istanbul'), findsOneWidget);
    expect(find.textContaining('İmsak: -2 dk'), findsOneWidget);
    expect(find.textContaining('41.0082'), findsNothing);
    expect(find.textContaining('28.9784'), findsNothing);
  });

  testWidgets('copy action writes privacy-safe diagnostic to clipboard', (
    tester,
  ) async {
    String? clipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            final args = call.arguments as Map<Object?, Object?>;
            clipboardText = args['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        home: Scaffold(
          body: PrayerCalculationInspectorSheet(
            explanation: explanation,
            prayerId: 'fajr',
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.copy_all_outlined));
    await tester.pump();

    expect(clipboardText, contains('place: Istanbul'));
    expect(clipboardText, contains('prayer: fajr'));
    expect(clipboardText, isNot(contains('41.0082')));
    expect(clipboardText, isNot(contains('28.9784')));
  });
}
