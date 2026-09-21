import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/reader_focus_controller.dart';

void main() {
  test('focus controls are explicit, reversible and session scoped', () {
    final controller = ReaderFocusController();
    addTearDown(controller.dispose);

    controller
      ..setFullScreen(true)
      ..setDimmed(true)
      ..setLineFocus(true)
      ..setKeepAwake(true)
      ..setAutoScroll(true)
      ..setAutoScrollSpeed(ReaderAutoScrollSpeed.fast);

    expect(controller.fullScreen, isTrue);
    expect(controller.dimmed, isFalse);
    expect(controller.lineFocus, isTrue);
    expect(controller.keepAwake, isTrue);
    expect(controller.autoScroll, isTrue);
    expect(controller.autoScrollSpeed, ReaderAutoScrollSpeed.fast);
    expect(controller.autoScrollSpeed.pixelsPerSecond, 40);

    controller.reset();

    expect(controller.fullScreen, isFalse);
    expect(controller.dimmed, isFalse);
    expect(controller.lineFocus, isFalse);
    expect(controller.keepAwake, isFalse);
    expect(controller.autoScroll, isFalse);
    expect(controller.autoScrollSpeed, ReaderAutoScrollSpeed.normal);
  });

  test('dimming and line focus remain mutually exclusive', () {
    final controller = ReaderFocusController();
    addTearDown(controller.dispose);

    controller.setDimmed(true);
    expect(controller.dimmed, isTrue);
    expect(controller.lineFocus, isFalse);

    controller.setLineFocus(true);
    expect(controller.lineFocus, isTrue);
    expect(controller.dimmed, isFalse);
  });

  test('manual interaction pauses auto-scroll without changing other controls', () {
    final controller = ReaderFocusController();
    addTearDown(controller.dispose);
    controller
      ..setDimmed(true)
      ..setKeepAwake(true)
      ..setAutoScroll(true);

    expect(controller.pauseAutoScrollForInteraction(), isTrue);
    expect(controller.pauseAutoScrollForInteraction(), isFalse);
    expect(controller.autoScroll, isFalse);
    expect(controller.dimmed, isTrue);
    expect(controller.keepAwake, isTrue);
  });

  test('auto-scroll speeds remain deliberately calm and ordered', () {
    expect(
      ReaderAutoScrollSpeed.values.map((speed) => speed.pixelsPerSecond),
      orderedEquals(<double>[12, 24, 40]),
    );
  });
}
