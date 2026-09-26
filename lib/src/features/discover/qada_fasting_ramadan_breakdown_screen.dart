import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'qada_fasting_ledger.dart';

/// Local-first per-Ramadan view for users whose qada balance spans multiple years.
/// It never infers a religious obligation: attribution is always an explicit user action.
class QadaFastingRamadanBreakdownScreen extends StatefulWidget {
  const QadaFastingRamadanBreakdownScreen({super.key});

  @override
  State<QadaFastingRamadanBreakdownScreen> createState() =>
      _QadaFastingRamadanBreakdownScreenState();
}

class _QadaFastingRamadanBreakdownScreenState
    extends State<QadaFastingRamadanBreakdownScreen> {
  static const _store = QadaFastingStore();
  QadaFastingLedger _ledger = QadaFastingLedger();
  bool _loading = true;

  String get _language => Localizations.localeOf(context).languageCode;
  String _t(String key) => (_labels[_language] ?? _labels['en']!)[key] ?? key;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final ledger = await _store.load();
    if (!mounted) return;
    setState(() {
      _ledger = ledger;
      _loading = false;
    });
  }

  Future<void> _save(QadaFastingLedger ledger) async {
    setState(() => _ledger = ledger);
    await _store.save(ledger);
  }

  Future<void> _completeForRamadan(int year) async {
    final available = _ledger.remainingForRamadan(year);
    if (available <= 0) return;
    final daysController = TextEditingController(text: '1');
    final noteController = TextEditingController();
    var occurredOn = DateTime.now();
    String? error;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${_t('completeFor')} $year'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_t('available')}: $available ${_t('days')}'),
                const SizedBox(height: 12),
                TextField(
                  controller: daysController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _t('dayCount'),
                    errorText: error,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_t('date')),
                  subtitle: Text(
                    MaterialLocalizations.of(context).formatMediumDate(occurredOn),
                  ),
                  trailing: const Icon(Icons.calendar_month_rounded),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: dialogContext,
                      initialDate: occurredOn,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (selected != null) {
                      setDialogState(() => occurredOn = selected);
                    }
                  },
                ),
                TextField(
                  controller: noteController,
                  maxLength: 500,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: _t('note')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final days = int.tryParse(daysController.text);
                if (days == null || days < 1 || days > available) {
                  setDialogState(() => error = _t('invalidDays'));
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(_t('save')),
            ),
          ],
        ),
      ),
    );
    final days = int.tryParse(daysController.text);
    final note = noteController.text;
    daysController.dispose();
    noteController.dispose();
    if (accepted != true || days == null || !mounted) return;
    await _save(
      _ledger.complete(
        days: days,
        occurredOn: occurredOn,
        createdAt: DateTime.now(),
        sourceRamadanYear: year,
        attributeWhenUnambiguous: false,
        note: note,
      ),
    );
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final years = _ledger.debtByRamadan.keys.whereType<int>().toList()
      ..sort((a, b) => b.compareTo(a));
    final unknownDebt = _ledger.debtByRamadan[null] ?? 0;
    final attributedCompleted = _ledger.attributedCompletionsByRamadan.values
        .fold<int>(0, (sum, value) => sum + value);
    final unattributedCompleted = _ledger.completedDays - attributedCompleted;

    return Scaffold(
      appBar: AppBar(title: Text(_t('title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_t('explanation')),
                ),
                const SizedBox(height: 18),
                if (years.isEmpty)
                  Text(_t('empty'))
                else
                  for (final year in years) ...[
                    _RamadanCard(
                      year: year,
                      recorded: _ledger.debtByRamadan[year] ?? 0,
                      completed: _ledger.attributedCompletionsByRamadan[year] ?? 0,
                      remaining: _ledger.remainingForRamadan(year),
                      daysLabel: _t('days'),
                      recordedLabel: _t('recorded'),
                      completedLabel: _t('completed'),
                      remainingLabel: _t('remaining'),
                      actionLabel: _t('complete'),
                      onComplete: _ledger.remainingForRamadan(year) > 0
                          ? () => _completeForRamadan(year)
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                if (unknownDebt > 0 || unattributedCompleted > 0) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('unattributed'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          if (unknownDebt > 0)
                            Text('${_t('unknownDebt')}: $unknownDebt ${_t('days')}'),
                          if (unattributedCompleted > 0)
                            Text('${_t('unattributedCompleted')}: $unattributedCompleted ${_t('days')}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _RamadanCard extends StatelessWidget {
  const _RamadanCard({
    required this.year,
    required this.recorded,
    required this.completed,
    required this.remaining,
    required this.daysLabel,
    required this.recordedLabel,
    required this.completedLabel,
    required this.remainingLabel,
    required this.actionLabel,
    required this.onComplete,
  });

  final int year;
  final int recorded;
  final int completed;
  final int remaining;
  final String daysLabel;
  final String recordedLabel;
  final String completedLabel;
  final String remainingLabel;
  final String actionLabel;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label:
            'Ramadan $year, $remainingLabel $remaining $daysLabel, $completedLabel $completed $daysLabel',
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ramadan $year',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text('$recordedLabel: $recorded'),
                    Text('$completedLabel: $completed'),
                    Text('$remainingLabel: $remaining'),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      );
}

const Map<String, Map<String, String>> _labels = {
  'tr': {
    'title': 'Ramazanlara göre', 'explanation': 'Birden fazla Ramazan’dan borcun varsa, tuttuğun kaza orucunu hangi yıla yazacağını sen seçersin. Uygulama dini hüküm çıkarmaz.', 'empty': 'Yılı belli bir Ramazan kaydı henüz yok.', 'recorded': 'Kaydedilen', 'completed': 'Tutulan', 'remaining': 'Kalan', 'complete': 'Bu Ramazan için oruç ekle', 'completeFor': 'Kaza orucunu Ramazan yılına yaz:', 'available': 'Bu yıl için kalan', 'days': 'gün', 'dayCount': 'Gün sayısı', 'date': 'Tarih', 'note': 'Özel not (isteğe bağlı)', 'cancel': 'İptal', 'save': 'Kaydet', 'invalidDays': 'Bu Ramazan için kalan gün sayısını aşmayan geçerli bir sayı gir.', 'unattributed': 'Yıla bağlanmamış kayıtlar', 'unknownDebt': 'Yılı bilinmeyen borç', 'unattributedCompleted': 'Ramazan yılı seçilmeden tutulan'
  },
  'en': {
    'title': 'By Ramadan', 'explanation': 'If your balance spans multiple Ramadans, you choose which year a completed qada fast belongs to. The app does not infer a religious ruling.', 'empty': 'No debt with a known Ramadan year yet.', 'recorded': 'Recorded', 'completed': 'Completed', 'remaining': 'Remaining', 'complete': 'Add completed fast for this Ramadan', 'completeFor': 'Attribute qada fast to Ramadan:', 'available': 'Remaining for this year', 'days': 'days', 'dayCount': 'Number of days', 'date': 'Date', 'note': 'Private note (optional)', 'cancel': 'Cancel', 'save': 'Save', 'invalidDays': 'Enter a valid number that does not exceed this Ramadan’s remaining balance.', 'unattributed': 'Records without a year', 'unknownDebt': 'Debt with unknown year', 'unattributedCompleted': 'Completed without Ramadan attribution'
  },
  'fr': {
    'title': 'Par Ramadan', 'explanation': 'Si votre solde couvre plusieurs Ramadans, vous choisissez l’année à laquelle rattacher un jeûne rattrapé. L’application ne déduit aucune règle religieuse.', 'empty': 'Aucune dette avec une année de Ramadan connue.', 'recorded': 'Enregistré', 'completed': 'Rattrapé', 'remaining': 'Restant', 'complete': 'Ajouter un jeûne pour ce Ramadan', 'completeFor': 'Rattacher le jeûne au Ramadan :', 'available': 'Restant pour cette année', 'days': 'jours', 'dayCount': 'Nombre de jours', 'date': 'Date', 'note': 'Note privée (facultatif)', 'cancel': 'Annuler', 'save': 'Enregistrer', 'invalidDays': 'Saisissez un nombre valide ne dépassant pas le solde de ce Ramadan.', 'unattributed': 'Entrées sans année', 'unknownDebt': 'Dette d’année inconnue', 'unattributedCompleted': 'Rattrapé sans attribution de Ramadan'
  },
  'ar': {
    'title': 'حسب رمضان', 'explanation': 'إذا كان الرصيد يعود إلى أكثر من رمضان، فأنت تختار السنة التي يُنسب إليها صيام القضاء. التطبيق لا يستنبط حكمًا شرعيًا.', 'empty': 'لا توجد ديون مرتبطة بسنة رمضان معروفة بعد.', 'recorded': 'المسجل', 'completed': 'تم قضاؤه', 'remaining': 'المتبقي', 'complete': 'إضافة صيام لهذا الرمضان', 'completeFor': 'نسب صيام القضاء إلى رمضان:', 'available': 'المتبقي لهذه السنة', 'days': 'أيام', 'dayCount': 'عدد الأيام', 'date': 'التاريخ', 'note': 'ملاحظة خاصة (اختياري)', 'cancel': 'إلغاء', 'save': 'حفظ', 'invalidDays': 'أدخل عددًا صالحًا لا يتجاوز المتبقي لهذا الرمضان.', 'unattributed': 'سجلات بلا سنة', 'unknownDebt': 'دين بسنة غير معروفة', 'unattributedCompleted': 'قضاء دون تحديد سنة رمضان'
  },
  'az': {
    'title': 'Ramazanlara görə', 'explanation': 'Borc bir neçə Ramazana aiddirsə, tutduğun qəza orucunun hansı ilə aid olduğunu sən seçirsən. Tətbiq dini hökm çıxarmır.', 'empty': 'İli məlum Ramazan borcu hələ yoxdur.', 'recorded': 'Qeyd olunan', 'completed': 'Tutulan', 'remaining': 'Qalan', 'complete': 'Bu Ramazan üçün oruc əlavə et', 'completeFor': 'Qəza orucunu Ramazana aid et:', 'available': 'Bu il üçün qalan', 'days': 'gün', 'dayCount': 'Gün sayı', 'date': 'Tarix', 'note': 'Məxfi qeyd (istəyə bağlı)', 'cancel': 'Ləğv et', 'save': 'Yadda saxla', 'invalidDays': 'Bu Ramazanın qalan borcunu aşmayan düzgün say daxil et.', 'unattributed': 'İlə bağlanmamış qeydlər', 'unknownDebt': 'İli bilinməyən borc', 'unattributedCompleted': 'Ramazan ili seçilmədən tutulan'
  },
  'ru': {
    'title': 'По Рамаданам', 'explanation': 'Если долг относится к нескольким Рамаданам, вы сами выбираете год для выполненного поста када. Приложение не выносит религиозных решений.', 'empty': 'Пока нет долга с известным годом Рамадана.', 'recorded': 'Записано', 'completed': 'Выполнено', 'remaining': 'Осталось', 'complete': 'Добавить пост для этого Рамадана', 'completeFor': 'Отнести пост када к Рамадану:', 'available': 'Осталось за этот год', 'days': 'дн.', 'dayCount': 'Количество дней', 'date': 'Дата', 'note': 'Личная заметка (необязательно)', 'cancel': 'Отмена', 'save': 'Сохранить', 'invalidDays': 'Введите допустимое число, не превышающее остаток за этот Рамадан.', 'unattributed': 'Записи без года', 'unknownDebt': 'Долг с неизвестным годом', 'unattributedCompleted': 'Выполнено без привязки к Рамадану'
  },
};
