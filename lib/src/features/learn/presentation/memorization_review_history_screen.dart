import 'package:flutter/material.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_practice_history_store.dart';
import '../application/memorization_progress_store.dart';
import '../application/memorization_review_history.dart';
import 'memorization_practice_log_screen.dart';
import 'memorization_review_page_history_screen.dart';

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
      MaterialPageRoute(builder: (_) => MemorizationReviewPageHistoryScreen(page: page)),
    );
    await _load();
  }

  Future<void> _logPractice() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MemorizationPracticeLogScreen()),
    );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final copy = _HistoryCopy.forLocale(Localizations.localeOf(context));
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(
        title: Text(copy.title),
        actions: [
          IconButton(
            onPressed: _logPractice,
            tooltip: copy.logReview,
            icon: const Icon(Icons.add_task_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logPractice,
        icon: const Icon(Icons.add_rounded),
        label: Text(copy.logReview),
      ),
      body: summary == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 18),
                      child: Column(
                        children: [
                          Icon(Icons.history_toggle_off_rounded,
                              size: 46, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 12),
                          Text(copy.empty, textAlign: TextAlign.center),
                        ],
                      ),
                    )
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
                Text(copy.summary,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(avatar: const Icon(Icons.calendar_month_outlined, size: 18), label: Text('${copy.last30Days} ${summary.recentEvents}')),
                    Chip(avatar: const Icon(Icons.history_rounded, size: 18), label: Text('${copy.totalReviews} ${summary.totalEvents}')),
                    Chip(avatar: const Icon(Icons.menu_book_outlined, size: 18), label: Text('${copy.reviewedPages} ${summary.reviewedPageCount}')),
                  ],
                ),
                const SizedBox(height: 10),
                Text(copy.localOnly, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.page, required this.pageLabel, required this.copy, required this.onTap});
  final MemorizationReviewHistoryPage page;
  final String pageLabel;
  final _HistoryCopy copy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latest = page.latestReviewAt;
    final date = latest == null ? copy.noDate : MaterialLocalizations.of(context).formatMediumDate(latest);
    final contexts = page.hasDetailedHistory
        ? page.contexts.map(copy.contextLabel).join(', ')
        : copy.legacyDetail;
    final detail = page.hasDetailedHistory
        ? '${copy.last30Days}: ${page.recentReviews} · ${copy.totalReviews}: ${page.totalReviews} · $date'
        : '${copy.lastReview}: $date';
    return Semantics(
      button: true,
      label: '$pageLabel ${page.page}. $detail. $contexts',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          child: ListTile(
            leading: Icon(page.hasDetailedHistory ? Icons.history_toggle_off_rounded : Icons.history_rounded),
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

class _HistoryCopy {
  const _HistoryCopy({required this.title, required this.summary, required this.last30Days, required this.totalReviews, required this.reviewedPages, required this.localOnly, required this.empty, required this.all, required this.solo, required this.prayer, required this.someone, required this.noDate, required this.logReview, required this.lastReview, required this.legacyDetail});
  final String title, summary, last30Days, totalReviews, reviewedPages, localOnly;
  final String empty, all, solo, prayer, someone, noDate, logReview, lastReview, legacyDetail;

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
  static _HistoryCopy forLocale(Locale locale) => _copies[locale.languageCode] ?? _copies['en']!;
}

const _copies = <String, _HistoryCopy>{
  'tr': _HistoryCopy(title: 'Tekrar geçmişi', summary: 'Tekrar görünümü', last30Days: 'Son 30 gün', totalReviews: 'Toplam tekrar', reviewedPages: 'Tekrar edilen sayfa', localOnly: 'Bu geçmiş cihazında tutulur ve yedekleme kapsamındadır.', empty: 'Bu filtre için henüz tekrar kaydı yok.', all: 'Tümü', solo: 'Tek başına', prayer: 'Namazda', someone: 'Birine okudum', noDate: 'Tarih yok', logReview: 'Tekrar kaydet', lastReview: 'Son tekrar', legacyDetail: 'Eski kayıttan geldi; ayrıntılı tekrar sayısı bilinmiyor'),
  'en': _HistoryCopy(title: 'Review history', summary: 'Review overview', last30Days: 'Last 30 days', totalReviews: 'Total reviews', reviewedPages: 'Reviewed pages', localOnly: 'This history stays on your device and is included in backup.', empty: 'There is no review history for this filter yet.', all: 'All', solo: 'Solo', prayer: 'In prayer', someone: 'Recited to someone', noDate: 'No date', logReview: 'Log review', lastReview: 'Last review', legacyDetail: 'From older data; detailed review count is unavailable'),
  'fr': _HistoryCopy(title: 'Historique des révisions', summary: 'Vue des révisions', last30Days: '30 derniers jours', totalReviews: 'Révisions totales', reviewedPages: 'Pages révisées', localOnly: 'Cet historique reste sur votre appareil et est inclus dans la sauvegarde.', empty: 'Aucun historique pour ce filtre.', all: 'Tout', solo: 'Seul', prayer: 'En prière', someone: 'Récité à quelqu’un', noDate: 'Sans date', logReview: 'Enregistrer', lastReview: 'Dernière révision', legacyDetail: 'Donnée ancienne ; le nombre détaillé de révisions est indisponible'),
  'ar': _HistoryCopy(title: 'سجل المراجعة', summary: 'ملخص المراجعة', last30Days: 'آخر 30 يومًا', totalReviews: 'إجمالي المراجعات', reviewedPages: 'الصفحات المراجعة', localOnly: 'يبقى هذا السجل على جهازك ويُضمّن في النسخة الاحتياطية.', empty: 'لا يوجد سجل مراجعة لهذا المرشح بعد.', all: 'الكل', solo: 'منفردًا', prayer: 'في الصلاة', someone: 'قرأت على شخص', noDate: 'بدون تاريخ', logReview: 'تسجيل مراجعة', lastReview: 'آخر مراجعة', legacyDetail: 'بيانات قديمة؛ عدد المراجعات التفصيلي غير متاح'),
  'az': _HistoryCopy(title: 'Təkrar tarixçəsi', summary: 'Təkrar icmalı', last30Days: 'Son 30 gün', totalReviews: 'Ümumi təkrar', reviewedPages: 'Təkrar edilən səhifələr', localOnly: 'Bu tarixçə cihazınızda qalır və ehtiyat nüsxəyə daxildir.', empty: 'Bu filtr üçün hələ tarixçə yoxdur.', all: 'Hamısı', solo: 'Tək', prayer: 'Namazda', someone: 'Birinə oxudum', noDate: 'Tarix yoxdur', logReview: 'Təkrarı qeyd et', lastReview: 'Son təkrar', legacyDetail: 'Köhnə məlumatdır; ətraflı təkrar sayı məlum deyil'),
  'ru': _HistoryCopy(title: 'История повторений', summary: 'Обзор повторений', last30Days: 'Последние 30 дней', totalReviews: 'Всего повторений', reviewedPages: 'Повторённые страницы', localOnly: 'История хранится на устройстве и входит в резервную копию.', empty: 'Для этого фильтра пока нет истории.', all: 'Все', solo: 'Самостоятельно', prayer: 'В молитве', someone: 'Читал другому', noDate: 'Без даты', logReview: 'Записать повторение', lastReview: 'Последнее повторение', legacyDetail: 'Старые данные; подробное число повторений недоступно'),
};
