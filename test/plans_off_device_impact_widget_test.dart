import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/plans/plans_screen.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_store.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget harness() {
    return MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(body: PlansScreen()),
    );
  }

  testWidgets('off-device reading opens a read-only active-plan impact preview', (
    tester,
  ) async {
    const store = ReadingPlanStore();
    final now = DateTime(2026, 9, 20);
    await store.start(ReadingPlanPreset.quran30, now: now);
    final day = readingPlanDay(ReadingPlanPreset.quran30, 2);
    await store.addOffDevicePageSession(
      startPage: day.startPage + 2,
      endPage: day.endPage - 1,
      readAt: now,
      now: now,
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Preview plan impact'), findsOneWidget);

    await tester.tap(find.text('Preview plan impact'));
    await tester.pumpAndSettle();

    expect(find.text('Plan impact'), findsOneWidget);
    expect(find.text('Day 2'), findsOneWidget);
    expect(
      find.text('Pages ${day.startPage + 2}–${day.endPage - 1}'),
      findsOneWidget,
    );
    expect(find.text('Remaining'), findsOneWidget);
    expect(
      find.textContaining('The record does not change plan progress.'),
      findsOneWidget,
    );

    final snapshot = await store.load();
    expect(snapshot.active?.completedDays, isEmpty);
    expect(snapshot.active?.nextDayNumber, 1);
  });

  testWidgets('impact action stays hidden when there is no active plan', (
    tester,
  ) async {
    const store = ReadingPlanStore();
    final now = DateTime(2026, 9, 20);
    await store.addOffDevicePageSession(
      startPage: 1,
      endPage: 3,
      readAt: now,
      now: now,
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Preview plan impact'), findsNothing);
  });
}
