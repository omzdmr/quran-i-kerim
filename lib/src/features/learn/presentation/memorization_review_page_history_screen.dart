import 'package:flutter/material.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_practice_history_store.dart';
import 'memorization_study_screen.dart';

class MemorizationReviewPageHistoryScreen extends StatefulWidget {
  const MemorizationReviewPageHistoryScreen({required this.page, super.key});
  final int page;

  @override
  State<MemorizationReviewPageHistoryScreen> createState() => _MemorizationReviewPageHistoryScreenState();
}

class _MemorizationReviewPageHistoryScreenState extends State<MemorizationReviewPageHistoryScreen> {
  static const _store = MemorizationPracticeHistoryStore();
  List<MemorizationPracticeEvent>? _events;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final snapshot = await _store.load();
    if (!mounted) return;
    setState(() => _events = snapshot.eventsForPage(widget.page));
  }

  Future<void> _openStudy() async {
    await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => MemorizationStudyScreen(page: widget.page)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final copy = _PageHistoryCopy.forLocale(Localizations.localeOf(context));
    final events = _events;
    return Scaffold(
      appBar: AppBar(title: Text('${l10n.memorizePages} ${widget.page}')),
      body: events == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                FilledButton.icon(
                  onPressed: _openStudy,
                  icon: const Icon(Icons.menu_book_rounded),
                  label: Text(copy.openStudy),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
                const SizedBox(height: 16),
                if (events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Text(copy.noDetailedHistory, textAlign: TextAlign.center),
                  )
                else
                  for (final event in events)
                    _EventTile(event: event, copy: copy),
              ],
            ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.copy});
  final MemorizationPracticeEvent event;
  final _PageHistoryCopy copy;

  @override
  Widget build(BuildContext context) {
    final localTime = event.occurredAt.toLocal();
    final material = MaterialLocalizations.of(context);
    final date = material.formatFullDate(localTime);
    final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(localTime));
    return Semantics(
      label: '${copy.contextLabel(event.context)}, $date, $time',
      child: ExcludeSemantics(
        child: Card(
          child: ListTile(
            leading: Icon(copy.contextIcon(event.context)),
            title: Text(copy.contextLabel(event.context)),
            subtitle: Text('$date · $time'),
          ),
        ),
      ),
    );
  }
}

class _PageHistoryCopy {
  const _PageHistoryCopy({required this.openStudy, required this.noDetailedHistory, required this.solo, required this.prayer, required this.someone});
  final String openStudy, noDetailedHistory, solo, prayer, someone;
  String contextLabel(MemorizationPracticeContext value) => switch (value) {
    MemorizationPracticeContext.soloReview => solo,
    MemorizationPracticeContext.prayer => prayer,
    MemorizationPracticeContext.recitedToSomeone => someone,
  };
  IconData contextIcon(MemorizationPracticeContext value) => switch (value) {
    MemorizationPracticeContext.soloReview => Icons.person_outline_rounded,
    MemorizationPracticeContext.prayer => Icons.mosque_outlined,
    MemorizationPracticeContext.recitedToSomeone => Icons.people_outline_rounded,
  };
  static _PageHistoryCopy forLocale(Locale locale) => _copies[locale.languageCode] ?? _copies['en']!;
}

const _copies = <String, _PageHistoryCopy>{
  'tr': _PageHistoryCopy(openStudy: 'Sayfayı çalış', noDetailedHistory: 'Bu sayfa için ayrıntılı tekrar olayı henüz yok. Eski son-tekrar tarihi yine genel geçmişte korunur.', solo: 'Tek başına', prayer: 'Namazda', someone: 'Birine okudum'),
  'en': _PageHistoryCopy(openStudy: 'Study this page', noDetailedHistory: 'There are no detailed review events for this page yet. Legacy last-review data remains visible in the overview.', solo: 'Solo review', prayer: 'In prayer', someone: 'Recited to someone'),
  'fr': _PageHistoryCopy(openStudy: 'Étudier cette page', noDetailedHistory: 'Aucun événement détaillé pour cette page. La dernière révision historique reste visible dans l’aperçu.', solo: 'Seul', prayer: 'En prière', someone: 'Récité à quelqu’un'),
  'ar': _PageHistoryCopy(openStudy: 'مراجعة هذه الصفحة', noDetailedHistory: 'لا توجد أحداث مراجعة مفصلة لهذه الصفحة بعد. يبقى تاريخ آخر مراجعة القديم ظاهرًا في الملخص.', solo: 'مراجعة فردية', prayer: 'في الصلاة', someone: 'قرأت على شخص'),
  'az': _PageHistoryCopy(openStudy: 'Bu səhifəni çalış', noDetailedHistory: 'Bu səhifə üçün hələ ətraflı təkrar hadisəsi yoxdur. Köhnə son-təkrar məlumatı icmalda qalır.', solo: 'Tək', prayer: 'Namazda', someone: 'Birinə oxudum'),
  'ru': _PageHistoryCopy(openStudy: 'Повторить страницу', noDetailedHistory: 'Подробных событий для этой страницы пока нет. Старая дата последнего повторения остаётся в обзоре.', solo: 'Самостоятельно', prayer: 'В молитве', someone: 'Читал другому'),
};
