import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/generated_app_localizations.dart';
import '../application/memorization_practice_history_store.dart';
import '../application/memorization_progress_store.dart';

class MemorizationPracticeLogScreen extends StatefulWidget {
  const MemorizationPracticeLogScreen({super.key});

  @override
  State<MemorizationPracticeLogScreen> createState() =>
      _MemorizationPracticeLogScreenState();
}

class _MemorizationPracticeLogScreenState extends State<MemorizationPracticeLogScreen> {
  static const _progressStore = MemorizationProgressStore();
  static const _historyStore = MemorizationPracticeHistoryStore();

  List<int>? _pages;
  int? _page;
  MemorizationPracticeContext _context = MemorizationPracticeContext.soloReview;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final progress = await _progressStore.load();
    if (!mounted) return;
    final pages = progress.memorizedPages.toList()..sort();
    setState(() {
      _pages = pages;
      _page = pages.isEmpty ? null : pages.first;
    });
  }

  Future<void> _save() async {
    final page = _page;
    if (page == null || _saving) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    await _progressStore.recordReviewActivity(page, now: now);
    await _historyStore.record(page: page, context: _context, now: now);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GeneratedAppLocalizations.of(context)!;
    final copy = _PracticeCopy.forLocale(Localizations.localeOf(context));
    final pages = _pages;
    return Scaffold(
      appBar: AppBar(title: Text(copy.title)),
      body: pages == null
          ? const Center(child: CircularProgressIndicator())
          : pages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(copy.noPages, textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                    Text(copy.pagePrompt,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: _page,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.menu_book_outlined),
                        labelText: l10n.memorizePages,
                      ),
                      items: [
                        for (final page in pages)
                          DropdownMenuItem(value: page, child: Text('${l10n.memorizePages} $page')),
                      ],
                      onChanged: _saving ? null : (value) => setState(() => _page = value),
                    ),
                    const SizedBox(height: 24),
                    Text(copy.contextPrompt,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                    const SizedBox(height: 10),
                    for (final contextValue in MemorizationPracticeContext.values) ...[
                      Semantics(
                        selected: _context == contextValue,
                        button: true,
                        label: copy.contextLabel(contextValue),
                        child: RadioListTile<MemorizationPracticeContext>(
                          value: contextValue,
                          groupValue: _context,
                          title: Text(copy.contextLabel(contextValue)),
                          subtitle: Text(copy.contextHint(contextValue)),
                          onChanged: _saving
                              ? null
                              : (value) {
                                  if (value != null) setState(() => _context = value);
                                },
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(copy.save),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      copy.explanation,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
    );
  }
}

class _PracticeCopy {
  const _PracticeCopy({
    required this.title,
    required this.pagePrompt,
    required this.contextPrompt,
    required this.save,
    required this.noPages,
    required this.explanation,
    required this.solo,
    required this.soloHint,
    required this.prayer,
    required this.prayerHint,
    required this.someone,
    required this.someoneHint,
  });

  final String title;
  final String pagePrompt;
  final String contextPrompt;
  final String save;
  final String noPages;
  final String explanation;
  final String solo;
  final String soloHint;
  final String prayer;
  final String prayerHint;
  final String someone;
  final String someoneHint;

  String contextLabel(MemorizationPracticeContext value) => switch (value) {
        MemorizationPracticeContext.soloReview => solo,
        MemorizationPracticeContext.prayer => prayer,
        MemorizationPracticeContext.recitedToSomeone => someone,
      };

  String contextHint(MemorizationPracticeContext value) => switch (value) {
        MemorizationPracticeContext.soloReview => soloHint,
        MemorizationPracticeContext.prayer => prayerHint,
        MemorizationPracticeContext.recitedToSomeone => someoneHint,
      };

  static _PracticeCopy forLocale(Locale locale) =>
      _copies[locale.languageCode] ?? _copies['en']!;
}

const _copies = <String, _PracticeCopy>{
  'tr': _PracticeCopy(
    title: 'Tekrar kaydet', pagePrompt: 'Hangi sayfayı tekrar ettin?',
    contextPrompt: 'Nasıl tekrar ettin?', save: 'Tekrarı kaydet',
    noPages: 'Önce ezberlediğin en az bir sayfayı işaretle.',
    explanation: 'Bu kayıt yalnız kendi tekrar geçmişindir; kıraat doğruluğunu puanlamaz.',
    solo: 'Tek başına', soloHint: 'Kendi tekrar çalışmam',
    prayer: 'Namazda', prayerHint: 'Ezberimi namazda okudum',
    someone: 'Birine okudum', someoneHint: 'Bir hoca, arkadaş veya aile üyesine okudum'),
  'en': _PracticeCopy(
    title: 'Log review', pagePrompt: 'Which page did you review?',
    contextPrompt: 'How did you review it?', save: 'Save review',
    noPages: 'Mark at least one page as memorized first.',
    explanation: 'This records your own review history only; it does not score recitation correctness.',
    solo: 'Solo review', soloHint: 'My own review session',
    prayer: 'In prayer', prayerHint: 'I recited this memorization in prayer',
    someone: 'Recited to someone', someoneHint: 'I recited to a teacher, friend or family member'),
  'fr': _PracticeCopy(
    title: 'Enregistrer une révision', pagePrompt: 'Quelle page avez-vous révisée ?',
    contextPrompt: 'Comment l’avez-vous révisée ?', save: 'Enregistrer',
    noPages: 'Marquez d’abord au moins une page comme mémorisée.',
    explanation: 'Ceci enregistre votre historique personnel sans noter la justesse de la récitation.',
    solo: 'Seul', soloHint: 'Ma propre séance de révision',
    prayer: 'En prière', prayerHint: 'J’ai récité cette mémorisation en prière',
    someone: 'Récité à quelqu’un', someoneHint: 'J’ai récité à un enseignant, ami ou proche'),
  'ar': _PracticeCopy(
    title: 'تسجيل مراجعة', pagePrompt: 'أي صفحة راجعت؟', contextPrompt: 'كيف راجعتها؟',
    save: 'حفظ المراجعة', noPages: 'حدّد أولًا صفحة واحدة على الأقل كمحفوظة.',
    explanation: 'يسجل هذا تاريخ مراجعتك فقط ولا يقيّم صحة التلاوة.',
    solo: 'مراجعة فردية', soloHint: 'جلسة مراجعة خاصة بي',
    prayer: 'في الصلاة', prayerHint: 'قرأت هذا المحفوظ في الصلاة',
    someone: 'قرأت على شخص', someoneHint: 'قرأت على معلّم أو صديق أو أحد أفراد الأسرة'),
  'az': _PracticeCopy(
    title: 'Təkrarı qeyd et', pagePrompt: 'Hansı səhifəni təkrar etdin?',
    contextPrompt: 'Necə təkrar etdin?', save: 'Təkrarı saxla',
    noPages: 'Əvvəlcə ən azı bir səhifəni əzbərlənmiş kimi işarələ.',
    explanation: 'Bu yalnız şəxsi təkrar tarixçəndir; qiraət düzgünlüyünü qiymətləndirmir.',
    solo: 'Tək', soloHint: 'Öz təkrar məşqim', prayer: 'Namazda',
    prayerHint: 'Əzbərimi namazda oxudum', someone: 'Birinə oxudum',
    someoneHint: 'Müəllimə, dosta və ya ailə üzvünə oxudum'),
  'ru': _PracticeCopy(
    title: 'Записать повторение', pagePrompt: 'Какую страницу вы повторили?',
    contextPrompt: 'Как вы её повторили?', save: 'Сохранить',
    noPages: 'Сначала отметьте хотя бы одну страницу как выученную.',
    explanation: 'Это только ваша история повторений; приложение не оценивает правильность чтения.',
    solo: 'Самостоятельно', soloHint: 'Моё самостоятельное повторение',
    prayer: 'В молитве', prayerHint: 'Я прочитал выученное в молитве',
    someone: 'Читал другому', someoneHint: 'Я прочитал учителю, другу или члену семьи'),
};
