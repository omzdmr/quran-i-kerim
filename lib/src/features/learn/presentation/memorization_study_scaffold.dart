import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum MemorizationStudyMode { read, memorize }

class MemorizationStudyMeta {
  const MemorizationStudyMeta({this.leading, this.center, this.trailing});

  final String? leading;
  final String? center;
  final String? trailing;
}

/// Reader-compatible memorisation chrome derived from the supplied reference.
///
/// This widget owns presentation only. Quran text, audio, page navigation,
/// progress persistence and hide/reveal memorisation behaviour are injected by
/// the caller so the same surface can be used on Android and iOS.
class MemorizationStudyScaffold extends StatelessWidget {
  const MemorizationStudyScaffold({
    required this.title,
    required this.readLabel,
    required this.memorizeLabel,
    required this.mode,
    required this.onModeChanged,
    required this.body,
    super.key,
    this.onBack,
    this.actions = const <Widget>[],
    this.meta,
    this.bottomBar,
  });

  final String title;
  final String readLabel;
  final String memorizeLabel;
  final MemorizationStudyMode mode;
  final ValueChanged<MemorizationStudyMode> onModeChanged;
  final Widget body;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final MemorizationStudyMeta? meta;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: actions,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: _StudyModeSwitcher(
              readLabel: readLabel,
              memorizeLabel: memorizeLabel,
              mode: mode,
              onModeChanged: onModeChanged,
            ),
          ),
          if (meta != null) _StudyMetaStrip(meta: meta!),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(top: false, child: bottomBar!),
    );
  }
}

class MemorizationStudyAudioBar extends StatelessWidget {
  const MemorizationStudyAudioBar({
    required this.title,
    required this.subtitle,
    required this.onPlayPause,
    super.key,
    this.isPlaying = false,
    this.onDetails,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPlayPause;
  final bool isPlaying;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            if (onDetails != null) ...[
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onDetails!();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.graphic_eq_rounded, color: scheme.primary),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 54,
              height: 54,
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onPlayPause();
                },
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 31,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyModeSwitcher extends StatelessWidget {
  const _StudyModeSwitcher({
    required this.readLabel,
    required this.memorizeLabel,
    required this.mode,
    required this.onModeChanged,
  });

  final String readLabel;
  final String memorizeLabel;
  final MemorizationStudyMode mode;
  final ValueChanged<MemorizationStudyMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget item(MemorizationStudyMode value, String label, IconData icon) {
      final selected = mode == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (selected) return;
            HapticFeedback.selectionClick();
            onModeChanged(value);
          },
          child: AnimatedContainer(
            duration:
                reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? scheme.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          selected ? scheme.primary : scheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            item(MemorizationStudyMode.read, readLabel, Icons.menu_book_rounded),
            item(
              MemorizationStudyMode.memorize,
              memorizeLabel,
              Icons.visibility_off_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyMetaStrip extends StatelessWidget {
  const _StudyMetaStrip({required this.meta});

  final MemorizationStudyMeta meta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Widget cell(String? value, TextAlign align) {
      if (value == null || value.isEmpty) return const SizedBox.shrink();
      return Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: TextStyle(
            color: isDark ? scheme.onSurfaceVariant : const Color(0xFF665F50),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? scheme.surfaceContainerHighest : const Color(0xFFF3EDDF),
      child: Row(
        children: [
          cell(meta.leading, TextAlign.start),
          if (meta.leading != null && meta.center != null)
            const SizedBox(width: 8),
          cell(meta.center, TextAlign.center),
          if (meta.center != null && meta.trailing != null)
            const SizedBox(width: 8),
          cell(meta.trailing, TextAlign.end),
        ],
      ),
    );
  }
}
