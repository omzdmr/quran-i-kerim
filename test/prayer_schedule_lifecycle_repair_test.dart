import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/app.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_auto_repair.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountingRepair extends PrayerScheduleAutoRepair {
  _CountingRepair({this.throwOnRepair = false, this.blocker});
  final bool throwOnRepair;
  final Completer<void>? blocker;
  int calls = 0;
  @override
  Future<PrayerScheduleRepairResult> repairIfNeeded({DateTime? now}) async {
    calls++;
    if (throwOnRepair) throw StateError('simulated platform failure');
    if (blocker != null && !blocker!.isCompleted) await blocker!.future;
    return PrayerScheduleRepairResult.alreadyFresh;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('app performs prayer schedule health repair after first frame', (tester) async {
    final settings = AppSettings(); await settings.load(); final repair = _CountingRepair();
    await tester.pumpWidget(QuranModernApp(settings: settings, prayerScheduleRepair: repair)); await tester.pump();
    expect(repair.calls, 1);
  });

  testWidgets('returning to foreground rechecks prayer schedule health', (tester) async {
    final settings = AppSettings(); await settings.load(); final repair = _CountingRepair();
    await tester.pumpWidget(QuranModernApp(settings: settings, prayerScheduleRepair: repair)); await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused); await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed); await tester.pump();
    expect(repair.calls, 2);
  });

  testWidgets('locale change immediately rechecks localized prayer schedule', (tester) async {
    final settings = AppSettings(); await settings.load(); final repair = _CountingRepair();
    await tester.pumpWidget(QuranModernApp(settings: settings, prayerScheduleRepair: repair)); await tester.pump();
    expect(repair.calls, 1);
    await settings.setLocale(const Locale('fr')); await tester.pump();
    expect(repair.calls, 2);
  });

  testWidgets('unrelated visual setting does not probe prayer scheduler', (tester) async {
    final settings = AppSettings(); await settings.load(); final repair = _CountingRepair();
    await tester.pumpWidget(QuranModernApp(settings: settings, prayerScheduleRepair: repair)); await tester.pump();
    await settings.setThemeMode(ThemeMode.dark); await tester.pump();
    expect(repair.calls, 1);
  });

  testWidgets('change during running repair is coalesced and not lost', (tester) async {
    final settings = AppSettings(); await settings.load(); final blocker = Completer<void>(); final repair = _CountingRepair(blocker: blocker);
    await tester.pumpWidget(QuranModernApp(settings: settings, prayerScheduleRepair: repair)); await tester.pump();
    expect(repair.calls, 1);
    await settings.setLocale(const Locale('ar')); await tester.pump();
    expect(repair.calls, 1);
    blocker.complete(); await tester.pump(); await tester.pump();
    expect(repair.calls, 2);
  });

  testWidgets('platform repair failure never blocks app rendering or later retry', (tester) async {
    final settings = AppSettings(); await settings.load(); final repair = _CountingRepair(throwOnRepair: true);
    await tester.pumpWidget(QuranModernApp(settings: settings, prayerScheduleRepair: repair)); await tester.pump();
    expect(repair.calls, 1); expect(tester.takeException(), isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed); await tester.pump();
    expect(repair.calls, 2); expect(tester.takeException(), isNull);
  });
}
