import 'package:flutter/material.dart';

import '../../settings/app_settings.dart';

class ReaderMixedVerseList extends StatefulWidget {
  const ReaderMixedVerseList({
    required this.surahNumber,
    required this.verseCount,
    required this.arabicForAyah,
    required this.transliterations,
    required this.translations,
    required this.footnotes,
    required this.translationLanguageCode,
    required this.arabicTextSize,
    required this.translationTextSize,
    required this.arabicLineHeight,
    required this.translationLineHeight,
    required this.selectedAyahs,
    required this.activeAudioAyah,
    required this.settings,
    required this.onAyahTap,
    required this.onNoteTap,
    required this.onFootnoteTap,
    super.key,
  });

  final int surahNumber;
  final int verseCount;
  final String Function(int ayah) arabicForAyah;
  final Map<String, String> transliterations;
  final Map<String, String> translations;
  final Map<String, String> footnotes;
  final String translationLanguageCode;
  final double arabicTextSize;
  final double translationTextSize;
  final double arabicLineHeight;
  final double translationLineHeight;
  final Set<int> selectedAyahs;
  final int? activeAudioAyah;
  final AppSettings settings;
  final ValueChanged<int> onAyahTap;
  final ValueChanged<int> onNoteTap;
  final ValueChanged<int> onFootnoteTap;

  @override
  State<ReaderMixedVerseList> createState() => ReaderMixedVerseListState();
}

class ReaderMixedVerseListState extends State<ReaderMixedVerseList> {
  final Map<int, GlobalKey> _ayahKeys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _syncKeys();
  }

  @override
  void didUpdateWidget(covariant ReaderMixedVerseList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
  }

  void _syncKeys() {
    for (final ayah in _ayahKeys.keys.toList()) {
      if (ayah > widget.verseCount) _ayahKeys.remove(ayah);
    }
    for (var ayah = 1; ayah <= widget.verseCount; ayah++) {
      _ayahKeys.putIfAbsent(ayah, GlobalKey.new);
    }
  }

  double? globalYForAyah(int ayah) {
    final context = _ayahKeys[ayah]?.currentContext;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return null;
    return renderObject.localToGlobal(Offset.zero).dy;
  }

  int? ayahClosestToGlobalY(double targetY) {
    int? bestAyah;
    var bestDistance = double.infinity;
    for (var ayah = 1; ayah <= widget.verseCount; ayah++) {
      final y = globalYForAyah(ayah);
      if (y == null) continue;
      final distance = (y - targetY).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestAyah = ayah;
      }
    }
    return bestAyah;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var ayah = 1; ayah <= widget.verseCount; ayah++) ...[
        _ReaderMixedVerseBlock(
          key: _ayahKeys[ayah],
          surahNumber: widget.surahNumber,
          ayah: ayah,
          arabic: widget.arabicForAyah(ayah),
          transliteration:
              widget.transliterations['${widget.surahNumber}:$ayah'],
          translation: widget.translations['${widget.surahNumber}:$ayah'],
          footnote: widget.footnotes['${widget.surahNumber}:$ayah'],
          translationLanguageCode: widget.translationLanguageCode,
          arabicTextSize: widget.arabicTextSize,
          translationTextSize: widget.translationTextSize,
          arabicLineHeight: widget.arabicLineHeight,
          translationLineHeight: widget.translationLineHeight,
          selected: widget.selectedAyahs.contains(ayah),
          activeAudio: widget.activeAudioAyah == ayah,
          highlight: widget.settings.highlightFor(widget.surahNumber, ayah),
          hasNote:
              widget.settings.noteKeyForAyah(widget.surahNumber, ayah) != null,
          bookmarked: widget.settings.isBookmarked(widget.surahNumber, ayah),
          onTap: () => widget.onAyahTap(ayah),
          onNoteTap: () => widget.onNoteTap(ayah),
          onFootnoteTap: () => widget.onFootnoteTap(ayah),
        ),
        if (ayah != widget.verseCount) const SizedBox(height: 12),
      ],
    ],
  );
}

class _ReaderMixedVerseBlock extends StatelessWidget {
  const _ReaderMixedVerseBlock({
    required this.surahNumber,
    required this.ayah,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.footnote,
    required this.translationLanguageCode,
    required this.arabicTextSize,
    required this.translationTextSize,
    required this.arabicLineHeight,
    required this.translationLineHeight,
    required this.selected,
    required this.activeAudio,
    required this.highlight,
    required this.hasNote,
    required this.bookmarked,
    required this.onTap,
    required this.onNoteTap,
    required this.onFootnoteTap,
    super.key,
  });

  final int surahNumber;
  final int ayah;
  final String arabic;
  final String? transliteration;
  final String? translation;
  final String? footnote;
  final String translationLanguageCode;
  final double arabicTextSize;
  final double translationTextSize;
  final double arabicLineHeight;
  final double translationLineHeight;
  final bool selected;
  final bool activeAudio;
  final VerseHighlightColor? highlight;
  final bool hasNote;
  final bool bookmarked;
  final VoidCallback onTap;
  final VoidCallback onNoteTap;
  final VoidCallback onFootnoteTap;

  bool get _translationRtl => const <String>{
    'ar',
    'fa',
    'ur',
    'ps',
    'ku',
    'prs',
    'ug',
  }.contains(translationLanguageCode.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlightedColor = highlight == null
        ? null
        : _highlightMaterialColor(highlight!).withValues(alpha: .20);
    final borderColor = activeAudio
        ? scheme.primary
        : selected
        ? scheme.onSurface.withValues(alpha: .55)
        : scheme.outlineVariant.withValues(alpha: .55);
    final safeTransliteration = transliteration?.trim();
    final safeTranslation = translation?.trim();
    final hasFootnote = footnote != null && footnote!.trim().isNotEmpty;

    return Material(
      color: highlightedColor ?? scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: activeAudio ? 2 : selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$ayah',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (hasFootnote)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Footnote',
                      onPressed: onFootnoteTap,
                      icon: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                    ),
                  if (hasNote)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Note',
                      onPressed: onNoteTap,
                      icon: Icon(
                        Icons.note_alt_outlined,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (bookmarked)
                    Icon(
                      Icons.bookmark_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                arabic,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: arabicTextSize,
                  height: arabicLineHeight,
                  fontWeight: FontWeight.w500,
                  decoration: activeAudio
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationColor: scheme.primary,
                  decorationThickness: 2.4,
                ),
              ),
              if (safeTransliteration != null &&
                  safeTransliteration.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  safeTransliteration,
                  key: ValueKey('transliteration-$surahNumber-$ayah'),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: (translationTextSize * .72)
                        .clamp(13.0, 20.0)
                        .toDouble(),
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (safeTranslation != null && safeTranslation.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  safeTranslation,
                  key: ValueKey('translation-$surahNumber-$ayah'),
                  textDirection:
                      _translationRtl ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: _translationRtl ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: translationTextSize,
                    height: translationLineHeight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Color _highlightMaterialColor(VerseHighlightColor color) => switch (color) {
  VerseHighlightColor.yellow => const Color(0xFFFFEB00),
  VerseHighlightColor.green => const Color(0xFF45E879),
  VerseHighlightColor.blue => const Color(0xFF18C4E8),
  VerseHighlightColor.orange => const Color(0xFFFFB45E),
  VerseHighlightColor.pink => const Color(0xFFE88AC6),
};
