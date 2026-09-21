import 'package:flutter/material.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_practice_history_store.dart';
import '../application/memorization_progress_store.dart';
import '../application/memorization_review_history.dart';
import 'memorization_study_screen.dart';

class MemorizationReviewHistoryScreen extends StatefulWidget {
  const MemorizationReviewHistoryScreen({super.key});

  @override
  State<MemorizationReviewHistoryScreen> createState() =>
      _MemorizationReviewHistoryScreenState();
}

class _MemorizationReviewHistoryScreenState
    extends State<MemorizationReviewHistoryScreen> {
  static const _progressStore = MemorizationProgressStore();
  static const _historyStore = MemorizationPracticeHistoryStore();

  MemorizationReviewHistorySummary? _summary;
  MemorizationReviewHistoryFilter _filter = MemorizationReviewHistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final progress = await _progressStore.load();
    final history = await _historyStore.load();
    if (!mounted) return;
    setState(() {
      _summary = buildMemorizationReviewHistory(
        progress: progress,
        history: history,
        now: DateTime.now(),
        filter: _filter,
      );
    });
  }

  Future<void> _setFilter(MemorizationReviewHistoryFilter filter) async {
    if (_filter == filter) return;
    setState(() {
      _filter = filter;
      _summary = null;
    });
    await _load();
  }

  Future<void> _openPage(int page) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => MemorizationStudyScreen(page: page)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final copy = _HistoryCopy.forLocale(Localizations.localeOf(context));
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(title: Text(copy.title)),
      body: summary == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _SummaryCard(summary: summary, copy: copy),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in MemorizationReviewHistoryFilter.values) ...[
                          ChoiceChip(
                            selected: _filter == filter,
                            label: Text(copy.filterLabel(filter)),
                            onSelected: (_) => _setFilter(filter),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (summary.isEmpty)
                    _EmptyState(copy: copy)
                  else
                    for (final page in summary.pages)
                      _HistoryTile(
                        page: page,
                        pageLabel: l10n.memorizePages,
                        copy: copy,
                        onTap: () => _openPage(page.page),
                      ),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.copy});

  final MemorizationReviewHistorySummary summary;
  final _HistoryCopy copy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = '${copy.last30Days}: ${summary.recentEvents}. '
        '${copy.totalReviews}: ${summary.totalEvents}. '
        '${copy.reviewedPages}: ${summary.reviewedPageCount}.';
    return Semantics(
      container: true,
      label: semantic,
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.summary,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(
                      icon: Icons.calendar_month_outlined,
                      label: copy.last30Days,
                      value: summary.recentEvents,
                    ),
                    _MetricChip(
                      icon: Icons.history_rounded,
                      label: copy.totalReviews,
                      value: summary.totalEvents,
                    ),
                    _MetricChip(
                      icon: Icons.menu_book_outlined,
                      label: copy.reviewedPages,
                      value: summary.reviewedPageCount,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(copy.localOnly, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 18),
        label: Text('$label $value'),
      );
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.page,
    required this.pageLabel,
    required this.copy,
    required this.onTap,
  });

  final MemorizationReviewHistoryPage page;
  final String pageLabel;
  final _HistoryCopy copy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latest = page.latestReviewAt;
    final date = latest == null
        ? copy.noDate
        : MaterialLocalizations.of(context).formatMediumDate(latest);
    final contexts = page.contexts.map(copy.contextLabel).join(', ');
    final detail = '${copy.last30Days}: ${page.recentReviews} · '
        '${copy.totalReviews}: ${page.totalReviews} · $date';
    return Semantics(
      button: true,
      label: '$pageLabel ${page.page}. $detail. $contexts',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          child: ListTile(
            leading: const Icon(Icons.history_toggle_off_rounded),
            title: Text('$pageLabel ${page.page}'),
            subtitle: Text('$detail\n$contexts'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.copy});
  final _HistoryCopy copy;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 18),
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 46,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(copy.empty, textAlign: TextAlign.center),
          ],
        ),
      );
}

class _HistoryCopy {
  const _HistoryCopy({
    required this.title,
    required this.summary,
    required this.last30Days,
    required this.totalReviews,
    required this.reviewedPages,
    required this.localOnly,
    required this.empty,
    required this.all,
    required this.solo,
    required this.prayer,
    required this.someone,
    required this.noDate,
  });

  final String title;
  final String summary;
  final String last30Days;
  final String totalReviews;
  final String reviewedPages;
  final String localOnly;
  final String empty;
  final String all;
  final String solo;
  final String prayer;
  final String someone;
  final String noDate;

  String filterLabel(MemorizationReviewHistoryFilter filter) => switch (filter) {
        MemorizationReviewHistoryFilter.all => all,
        MemorizationReviewHistoryFilter.soloReview => solo,
        MemorizationReviewHistoryFilter.prayer => prayer,
        MemorizationReviewHistoryFilter.recitedToSomeone => someone,
      };

  String contextLabel(MemorizationPracticeContext context) => switch (context) {
        MemorizationPracticeContext.soloReview => solo,
        MemorizationPracticeContext.prayer => prayer,
        MemorizationPracticeContext.recitedToSomeone => someone,
      };

  static _HistoryCopy forLocale(Locale locale) =>
      _copies[locale.languageCode] ?? _copies['en']!;
}

const _copies = <String, _HistoryCopy>{
  'tr': _HistoryCopy(
    title: 'Tekrar geçmişi', summary: 'Tekrar görünümü', last30Days: 'Son 30 gün',
    totalReviews: 'Toplam tekrar', reviewedPages: 'Tekrar edilen sayfa',
    localOnly: 'Bu geçmiş cihazında tutulur ve yedekleme kapsamındadır.',
    empty: 'Bu filtre için henüz tekrar kaydı yok.', all: 'Tümü', solo: 'Tek başına',
    prayer: 'Namazda', someone: 'Birine okudum', noDate: 'Tarih yok'),
  'en': _HistoryCopy(
    title: 'Review history', summary: 'Review overview', last30Days: 'Last 30 days',
    totalReviews: 'Total reviews', reviewedPages: 'Reviewed pages',
    localOnly: 'This history stays on your device and is included in backup.',
    empty: 'There is no review history for this filter yet.', all: 'All', solo: 'Solo',
    prayer: 'In prayer', someone: 'Recited to someone', noDate: 'No date'),
  'fr': _HistoryCopy(
    title: 'Historique des révisions', summary: 'Vue des révisions', last30Days: '30 derniers jours',
    totalReviews: 'Révisions totales', reviewedPages: 'Pages révisées',
    localOnly: 'Cet historique reste sur votre appareil et est inclus dans la sauvegarde.',
    empty: 'Aucun historique pour ce filtre.', all: 'Tout', solo: 'Seul',
    prayer: 'En prière', someone: 'Récité à quelqu’un', noDate: 'Sans date'),
  'ar': _HistoryCopy(
    title: 'سجل المراجعة', summary: 'ملخص المراجعة', last30Days: 'آخر 30 يومًا',
    totalReviews: 'إجمالي المراجعات', reviewedPages: 'الصفحات المراجعة',
    localOnly: 'يبقى هذا السجل على جهازك ويُضمّن في النسخة الاحتياطية.',
    empty: 'لا يوجد سجل مراجعة لهذا المرشح بعد.', all: 'الكل', solo: 'منفردًا',
    prayer: 'في الصلاة', someone: 'قرأت على شخص', noDate: 'بدون تاريخ'),
  'az': _HistoryCopy(
    title: 'Təkrar tarixçəsi', summary: 'Təkrar icmalı', last30Days: 'Son 30 gün',
    totalReviews: 'Ümumi təkrar', reviewedPages: 'Təkrar edilən səhifələr',
    localOnly: 'Bu tarixçə cihazınızda qalır və ehtiyat nüsxəyə daxildir.',
    empty: 'Bu filtr üçün hələ tarixçə yoxdur.', all: 'Hamısı', solo: 'Tək',
    prayer: 'Namazda', someone: 'Birinə oxudum', noDate: 'Tarix yoxdur'),
  'ru': _HistoryCopy(
    title: 'История повторений', summary: 'Обзор повторений', last30Days: 'Последние 30 дней',
    totalReviews: 'Всего повторений', reviewedPages: 'Повторённые страницы',
    localOnly: 'История хранится на устройстве и входит в резервную копию.',
    empty: 'Для этого фильтра пока нет истории.', all: 'Все', solo: 'Самостоятельно',
    prayer: 'В молитве', someone: 'Читал другому', noDate: 'Без даты'),
};
