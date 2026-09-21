import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_progress_store.dart';
import '../application/memorization_review_session.dart';
import 'memorization_study_scaffold.dart';
import 'memorization_study_screen.dart';

/// Guided review flow for the bounded coverage batch.
///
/// The coverage model decides which pages need attention. This screen only
/// walks that already-prioritized batch and records the user's own assessment;
/// it does not invent a second Hifz scheduling algorithm.
class MemorizationCoverageReviewSessionScreen extends StatefulWidget {
  const MemorizationCoverageReviewSessionScreen({
    required this.session,
    super.key,
  });

  final MemorizationReviewSession session;

  @override
  State<MemorizationCoverageReviewSessionScreen> createState() =>
      _MemorizationCoverageReviewSessionScreenState();
}

class _MemorizationCoverageReviewSessionScreenState
    extends State<MemorizationCoverageReviewSessionScreen> {
  static const _store = MemorizationProgressStore();

  int _index = 0;
  bool _awaitingAssessment = false;
  bool _saving = false;

  int? get _currentPage =>
      _index >= 0 && _index < widget.session.pages.length
          ? widget.session.pages[_index]
          : null;

  Future<void> _openCurrent() async {
    final page = _currentPage;
    if (page == null || _saving) return;
    HapticFeedback.selectionClick();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MemorizationStudyScreen(
          page: page,
          showCompletionAction: false,
          initialMode: MemorizationStudyMode.memorize,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _awaitingAssessment = true);
  }

  Future<void> _record(MemorizationSelfAssessment assessment) async {
    final page = _currentPage;
    if (page == null || !_awaitingAssessment || _saving) return;
    setState(() => _saving = true);

    if (assessment == MemorizationSelfAssessment.independent) {
      HapticFeedback.lightImpact();
    } else if (assessment == MemorizationSelfAssessment.assisted) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.mediumImpact();
    }

    await _store.recordReview(page, selfAssessment: assessment);
    if (!mounted) return;

    if (_index >= widget.session.pages.length - 1) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _index += 1;
      _awaitingAssessment = false;
      _saving = false;
    });
  }

  void _deferCurrent() {
    if (_currentPage == null || _saving) return;
    HapticFeedback.selectionClick();
    if (_index >= widget.session.pages.length - 1) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      _index += 1;
      _awaitingAssessment = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final copy = _SessionCopy.forLocale(Localizations.localeOf(context));
    final page = _currentPage;
    final total = widget.session.pages.length;
    final completed = _index.clamp(0, total);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memorizeTodayReview),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: page == null
            ? Center(child: Text(l10n.memorizeCompleted))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  Semantics(
                    label: '${l10n.memorizeProgress}: ${_index + 1} / $total',
                    child: ExcludeSemantics(
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: total == 0 ? 0 : completed / total,
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_index + 1}/$total',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: .55),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.replay_rounded,
                            color: scheme.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.memorizeTodayReview,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${l10n.quranProgressCurrentPage} $page',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_awaitingAssessment) ...[
                    FilledButton.tonalIcon(
                      onPressed: _saving
                          ? null
                          : () => _record(MemorizationSelfAssessment.independent),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(l10n.memorizeTestIndependent),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _record(MemorizationSelfAssessment.assisted),
                      icon: const Icon(Icons.help_outline_rounded),
                      label: Text(l10n.memorizeTestAssisted),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _record(MemorizationSelfAssessment.struggled),
                      icon: const Icon(Icons.replay_rounded),
                      label: Text(l10n.memorizeTestStruggled),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        foregroundColor: scheme.error,
                      ),
                    ),
                  ] else
                    FilledButton.icon(
                      onPressed: _saving ? null : _openCurrent,
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(l10n.memorizeReview),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Semantics(
                    button: true,
                    label: copy.defer,
                    onTap: _saving ? null : _deferCurrent,
                    child: ExcludeSemantics(
                      child: TextButton.icon(
                        onPressed: _saving ? null : _deferCurrent,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: Text(copy.defer),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SessionCopy {
  const _SessionCopy(this.defer);

  final String defer;

  static _SessionCopy forLocale(Locale locale) =>
      _copies[locale.languageCode] ?? _copies['en']!;
}

const _copies = <String, _SessionCopy>{
  'tr': _SessionCopy('Şimdilik geç'),
  'en': _SessionCopy('Skip for now'),
  'ar': _SessionCopy('تخطَّ الآن'),
  'az': _SessionCopy('Hələlik keç'),
  'ru': _SessionCopy('Пока пропустить'),
  'fr': _SessionCopy('Passer pour l’instant'),
};
