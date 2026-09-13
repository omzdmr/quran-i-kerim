import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_progress_store.dart';
import '../application/memorization_today_plan.dart';
import '../application/memorization_today_session.dart';
import 'memorization_study_scaffold.dart';
import 'memorization_study_screen.dart';

class MemorizationTodaySessionScreen extends StatefulWidget {
  const MemorizationTodaySessionScreen({
    required this.plan,
    super.key,
  });

  final MemorizationTodayPlan plan;

  @override
  State<MemorizationTodaySessionScreen> createState() =>
      _MemorizationTodaySessionScreenState();
}

class _MemorizationTodaySessionScreenState
    extends State<MemorizationTodaySessionScreen> {
  static const _store = MemorizationProgressStore();

  late final List<MemorizationTodaySessionItem> _items;
  int _index = 0;
  bool _awaitingAssessment = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = buildMemorizationTodaySessionItems(widget.plan);
  }

  MemorizationTodaySessionItem? get _currentItem {
    if (_items.isEmpty || _index < 0 || _index >= _items.length) return null;
    return _items[_index];
  }

  Future<void> _openCurrent() async {
    final item = _currentItem;
    if (item == null || _saving) return;
    HapticFeedback.selectionClick();

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MemorizationStudyScreen(
          page: item.page,
          showCompletionAction: !item.isReview,
          initialMode: item.isReview
              ? MemorizationStudyMode.memorize
              : MemorizationStudyMode.read,
        ),
      ),
    );
    if (!mounted) return;

    if (item.isReview) {
      setState(() => _awaitingAssessment = true);
      return;
    }

    final snapshot = await _store.load();
    if (!mounted) return;
    if (snapshot.containsPage(item.page)) {
      setState(() => _awaitingAssessment = true);
    }
  }

  Future<void> _recordAssessment(
    MemorizationSelfAssessment assessment,
  ) async {
    final item = _currentItem;
    if (item == null || !_awaitingAssessment || _saving) return;

    setState(() => _saving = true);
    if (assessment == MemorizationSelfAssessment.independent) {
      HapticFeedback.lightImpact();
    } else if (assessment == MemorizationSelfAssessment.assisted) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.mediumImpact();
    }

    if (item.isReview) {
      await _store.recordReview(
        item.page,
        selfAssessment: assessment,
      );
    } else {
      await _store.recordSelfAssessment(
        item.page,
        selfAssessment: assessment,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    _advance();
  }

  void _advance() {
    if (!mounted) return;
    if (_index >= _items.length - 1) {
      Navigator.of(context).pop();
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
    final item = _currentItem;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memorizeTodayProgram),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: item == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.memorizeCompleted,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _items.isEmpty ? 0 : _index / _items.length,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_index + 1}/${_items.length}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
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
                            item.isReview
                                ? Icons.replay_rounded
                                : Icons.menu_book_rounded,
                            color: scheme.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.isReview
                              ? l10n.memorizeTodayReview
                              : l10n.memorizeNextPage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${l10n.quranProgressCurrentPage} ${item.page}',
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
                          : () => _recordAssessment(
                                MemorizationSelfAssessment.independent,
                              ),
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
                          : () => _recordAssessment(
                                MemorizationSelfAssessment.assisted,
                              ),
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
                          : () => _recordAssessment(
                                MemorizationSelfAssessment.struggled,
                              ),
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
                      icon: Icon(
                        item.isReview
                            ? Icons.replay_rounded
                            : Icons.menu_book_rounded,
                      ),
                      label: Text(
                        item.isReview
                            ? l10n.memorizeReview
                            : l10n.memorizeOpenNext,
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
