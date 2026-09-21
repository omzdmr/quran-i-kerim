import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/reader_focus_controller.dart';
import 'package:quran_i_kerim/src/features/reader/reader_focus_controls.dart';

void main() {
  testWidgets('focus sheet exposes reversible accessible reading controls', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final controller = ReaderFocusController();
    addTearDown(controller.dispose);
    var fullScreenRequested = false;
    var keepAwakeRequested = false;
    final labels = <String, String>{
      'focusReading': 'Focus reading',
      'fullScreen': 'Full screen',
      'dimScreen': 'Dim screen',
      'keepScreenAwake': 'Keep screen awake',
      'autoScroll': 'Auto-scroll',
      'autoScrollHint': 'Pauses on manual scrolling',
      'scrollSpeedSlow': 'Slow',
      'scrollSpeedNormal': 'Normal',
      'scrollSpeedFast': 'Fast',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderFocusControls(
            controller: controller,
            text: (key) => labels[key]!,
            onFullScreenChanged: (enabled) async {
              fullScreenRequested = enabled;
              controller.setFullScreen(enabled);
            },
            onKeepAwakeChanged: (enabled) async {
              keepAwakeRequested = enabled;
              controller.setKeepAwake(enabled);
            },
          ),
        ),
      ),
    );

    expect(find.text('Focus reading'), findsOneWidget);
    expect(find.bySemanticsLabel('Full screen'), findsOneWidget);
    expect(find.bySemanticsLabel('Keep screen awake'), findsOneWidget);

    await tester.tap(find.text('Full screen'));
    await tester.pump();
    expect(fullScreenRequested, isTrue);
    expect(controller.fullScreen, isTrue);

    await tester.tap(find.text('Dim screen'));
    await tester.pump();
    expect(controller.dimmed, isTrue);

    await tester.tap(find.text('Keep screen awake'));
    await tester.pump();
    expect(keepAwakeRequested, isTrue);
    expect(controller.keepAwake, isTrue);

    await tester.tap(find.text('Fast'));
    await tester.pump();
    expect(controller.autoScrollSpeed, ReaderAutoScrollSpeed.fast);

    await tester.tap(find.text('Auto-scroll'));
    await tester.pump();
    expect(controller.autoScroll, isTrue);
    expect(tester.takeException(), isNull);
  });
}
