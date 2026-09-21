import 'package:flutter/material.dart';

import 'reader_focus_controller.dart';

typedef ReaderFocusText = String Function(String key);

class ReaderFocusControls extends StatelessWidget {
  const ReaderFocusControls({
    required this.controller,
    required this.text,
    required this.onFullScreenChanged,
    required this.onKeepAwakeChanged,
    super.key,
  });

  final ReaderFocusController controller;
  final ReaderFocusText text;
  final Future<void> Function(bool enabled) onFullScreenChanged;
  final Future<void> Function(bool enabled) onKeepAwakeChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                text('focusReading'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.fullscreen_rounded),
              title: Text(text('fullScreen')),
              value: controller.fullScreen,
              onChanged: onFullScreenChanged,
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.brightness_4_outlined),
              title: Text(text('dimScreen')),
              value: controller.dimmed,
              onChanged: controller.setDimmed,
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.center_focus_weak_rounded),
              title: Text(text('lineFocus')),
              subtitle: Text(text('lineFocusHint')),
              value: controller.lineFocus,
              onChanged: controller.setLineFocus,
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.lightbulb_outline_rounded),
              title: Text(text('keepScreenAwake')),
              value: controller.keepAwake,
              onChanged: onKeepAwakeChanged,
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.slow_motion_video_rounded),
              title: Text(text('autoScroll')),
              subtitle: Text(text('autoScrollHint')),
              value: controller.autoScroll,
              onChanged: (value) {
                controller.setAutoScroll(value);
                if (value) Navigator.maybePop(context);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final speed in ReaderAutoScrollSpeed.values)
                    ChoiceChip(
                      label: Text(switch (speed) {
                        ReaderAutoScrollSpeed.slow =>
                          text('scrollSpeedSlow'),
                        ReaderAutoScrollSpeed.normal =>
                          text('scrollSpeedNormal'),
                        ReaderAutoScrollSpeed.fast =>
                          text('scrollSpeedFast'),
                      }),
                      selected: controller.autoScrollSpeed == speed,
                      onSelected: (_) =>
                          controller.setAutoScrollSpeed(speed),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ReaderLineFocusOverlay extends StatelessWidget {
  const ReaderLineFocusOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shade = Colors.black.withValues(alpha: .2);
    return IgnorePointer(
      child: Column(
        children: [
          Expanded(child: ColoredBox(color: shade)),
          Container(
            key: const ValueKey<String>('reader-line-focus-band'),
            height: 132,
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: scheme.primary.withValues(alpha: .45),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Expanded(child: ColoredBox(color: shade)),
        ],
      ),
    );
  }
}
