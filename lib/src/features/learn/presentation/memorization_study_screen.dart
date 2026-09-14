import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../data/surah_catalog.dart';
import '../../../data/surah_localization.dart';
import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_page_catalog.dart';
import '../application/memorization_progress_store.dart';
import '../application/memorization_voice_recording_controller.dart';
import 'memorization_study_scaffold.dart';

class MemorizationStudyScreen extends StatefulWidget {
  const MemorizationStudyScreen({
    required this.page,
    super.key,
    this.showCompletionAction = true,
    this.initialMode = MemorizationStudyMode.read,
  });

  final int page;
  final bool showCompletionAction;
  final MemorizationStudyMode initialMode;

  @override
  State<MemorizationStudyScreen> createState() => _MemorizationStudyScreenState();
}

class _MemorizationStudyScreenState extends State<MemorizationStudyScreen> {
  static const _store = MemorizationProgressStore();

  late MemorizationStudyMode _mode;
  final Set<String> _revealed = <String>{};
  late final List<_MemorizationVerse> _verses;
  late final MemorizationVoiceRecordingController _recordingController;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _verses = _versesForPage();
    _recordingController = MemorizationVoiceRecordingController(page: widget.page)
      ..addListener(_handleRecordingChanged);
    unawaited(_recordingController.initialize());
    _loadCompletion();
  }

  void _handleRecordingChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _recordingController.removeListener(_handleRecordingChanged);
    _recordingController.dispose();
    super.dispose();
  }

  Future<void> _loadCompletion() async {
    final snapshot = await _store.load();
    if (!mounted) return;
    setState(() => _completed = snapshot.containsPage(widget.page));
  }

  Future<void> _toggleCompleted() async {
    HapticFeedback.selectionClick();
    final snapshot = await _store.togglePage(widget.page);
    if (!mounted) return;
    setState(() => _completed = snapshot.containsPage(widget.page));
  }

  List<_MemorizationVerse> _versesForPage() {
    final verses = <_MemorizationVerse>[];
    for (final surah in surahCatalog) {
      for (var ayah = 1; ayah <= surah.verseCount; ayah++) {
        if (quran.getPageNumber(surah.number, ayah) != widget.page) continue;
        verses.add(
          _MemorizationVerse(
            surah: surah.number,
            ayah: ayah,
            arabic: quran.getVerse(surah.number, ayah),
          ),
        );
      }
    }
    return verses;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final info = memorizationPageInfo(widget.page);
    final first = _verses.isEmpty ? null : _verses.first;
    final last = _verses.isEmpty ? null : _verses.last;
    final title = first == null
        ? '${l10n.quranProgressCurrentPage} ${widget.page}'
        : localizedSurahName(first.surah, localeCode);
    final juz = info?.juz ??
        (first == null ? null : quran.getJuzNumber(first.surah, first.ayah));
    final reference = first == null || last == null
        ? null
        : first.surah == last.surah
            ? '${first.surah}:${first.ayah}-${last.ayah}'
            : '${first.surah}:${first.ayah} · ${last.surah}:${last.ayah}';

    return MemorizationStudyScaffold(
      title: title,
      readLabel: l10n.quranTabRead,
      memorizeLabel: l10n.quranLearnMemorize,
      mode: _mode,
      onModeChanged: (value) {
        setState(() {
          _mode = value;
          if (value == MemorizationStudyMode.read) _revealed.clear();
        });
      },
      actions: [
        IconButton(
          tooltip: _recordingController.isRecording
              ? l10n.memorizeStopRecording
              : l10n.memorizeStartRecording,
          onPressed: _recordingController.phase ==
                  MemorizationVoiceRecordingPhase.loading
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  unawaited(_recordingController.toggleRecording());
                },
          icon: Icon(
            _recordingController.isRecording
                ? Icons.stop_circle_rounded
                : Icons.mic_rounded,
          ),
        ),
      ],
      meta: MemorizationStudyMeta(
        leading: juz == null ? null : '${l10n.memorizeJuz} $juz',
        center: '${l10n.quranProgressCurrentPage} ${widget.page}',
        trailing: reference,
      ),
      body: _MemorizationPageBody(
        verses: _verses,
        mode: _mode,
        revealed: _revealed,
        onToggleReveal: (key) {
          HapticFeedback.selectionClick();
          setState(() {
            if (!_revealed.remove(key)) _revealed.add(key);
          });
        },
        revealLabel: l10n.memorizeRevealVerse,
      ),
      bottomBar: _buildBottomBar(l10n),
    );
  }

  Widget? _buildBottomBar(GeneratedAppLocalizations l10n) {
    final hasRecording = _recordingController.hasRecording;
    if (!hasRecording && !widget.showCompletionAction) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasRecording)
          MemorizationStudyAudioBar(
            title: l10n.memorizeReview,
            subtitle: '${l10n.quranProgressCurrentPage} ${widget.page}',
            isPlaying: _recordingController.isPlaying,
            onPlayPause: () => unawaited(_recordingController.togglePlayback()),
          ),
        if (widget.showCompletionAction)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: FilledButton.icon(
              onPressed: _toggleCompleted,
              icon: Icon(
                _completed
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              label: Text(
                _completed
                    ? l10n.memorizePageCompleted
                    : l10n.memorizeMarkPage,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
      ],
    );
  }
}

class _MemorizationPageBody extends StatelessWidget {
  const _MemorizationPageBody({
    required this.verses,
    required this.mode,
    required this.revealed,
    required this.onToggleReveal,
    required this.revealLabel,
  });

  final List<_MemorizationVerse> verses;
  final MemorizationStudyMode mode;
  final Set<String> revealed;
  final ValueChanged<String> onToggleReveal;
  final String revealLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (verses.isEmpty) {
      return Center(
        child: Icon(
          Icons.menu_book_outlined,
          size: 42,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? scheme.surface : const Color(0xFFF8F3E7),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
        itemCount: verses.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final verse = verses[index];
          final key = '${verse.surah}:${verse.ayah}';
          final isRevealed = mode == MemorizationStudyMode.read ||
              revealed.contains(key);

          return Material(
            color: isDark
                ? scheme.surfaceContainer
                : const Color(0xFFFFFBF1),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: mode == MemorizationStudyMode.memorize
                  ? () => onToggleReveal(key)
                  : null,
              borderRadius: BorderRadius.circular(22),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: isRevealed
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              verse.arabic,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 27,
                                height: 1.9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: _ReferenceChip(
                                label: '${verse.surah}:${verse.ayah}',
                                revealed: mode == MemorizationStudyMode.memorize,
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          height: 104,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility_off_outlined,
                                color: scheme.primary,
                                size: 30,
                              ),
                              const SizedBox(height: 9),
                              Text(
                                revealLabel,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${verse.surah}:${verse.ayah}',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReferenceChip extends StatelessWidget {
  const _ReferenceChip({required this.label, required this.revealed});

  final String label;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (revealed) ...[
            Icon(Icons.visibility_rounded, size: 14, color: scheme.primary),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MemorizationVerse {
  const _MemorizationVerse({
    required this.surah,
    required this.ayah,
    required this.arabic,
  });

  final int surah;
  final int ayah;
  final String arabic;
}
