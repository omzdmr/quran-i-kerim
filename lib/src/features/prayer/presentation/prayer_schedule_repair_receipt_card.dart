import 'package:flutter/material.dart';

import '../application/prayer_schedule_repair_receipt_store.dart';

/// Explains the last automatic schedule check/repair in human terms.
///
/// The card intentionally does not expose configuration fingerprints. They are
/// useful for local verification but are implementation detail, not user data.
class PrayerScheduleRepairReceiptCard extends StatefulWidget {
  const PrayerScheduleRepairReceiptCard({super.key, this.now});

  final DateTime? now;

  @override
  State<PrayerScheduleRepairReceiptCard> createState() =>
      _PrayerScheduleRepairReceiptCardState();
}

class _PrayerScheduleRepairReceiptCardState
    extends State<PrayerScheduleRepairReceiptCard> {
  static const _store = PrayerScheduleRepairReceiptStore();
  PrayerScheduleRepairReceipt? _receipt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _store.load();
    if (mounted) setState(() => _receipt = value);
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;
    if (receipt == null) return const SizedBox.shrink();

    final copy = PrayerScheduleRepairReceiptCopy.forLocale(
      Localizations.localeOf(context),
    );
    final current = widget.now ?? DateTime.now();
    // Old receipts stop being useful diagnostics. Do not keep telling a user
    // that a repair from weeks ago describes today's platform schedule.
    if (current.toUtc().difference(receipt.attemptedAt.toUtc()) >
        const Duration(days: 7)) {
      return const SizedBox.shrink();
    }

    final message = copy.message(receipt.outcome);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(receipt.attemptedAt.toLocal()),
    );
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(receipt.attemptedAt.toLocal());

    return Semantics(
      container: true,
      label: '${copy.title}. $message. ${copy.checked}: $date, $time',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.history_toggle_off_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(copy.title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(message),
                    const SizedBox(height: 4),
                    Text(
                      '${copy.checked}: $date · $time',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrayerScheduleRepairReceiptCopy {
  const PrayerScheduleRepairReceiptCopy({
    required this.title,
    required this.checked,
    required this.notApplicable,
    required this.alreadyFresh,
    required this.repaired,
    required this.failed,
  });

  final String title;
  final String checked;
  final String notApplicable;
  final String alreadyFresh;
  final String repaired;
  final String failed;

  String message(PrayerScheduleRepairOutcome outcome) => switch (outcome) {
        PrayerScheduleRepairOutcome.notApplicable => notApplicable,
        PrayerScheduleRepairOutcome.alreadyFresh => alreadyFresh,
        PrayerScheduleRepairOutcome.repaired => repaired,
        PrayerScheduleRepairOutcome.failed => failed,
      };

  static PrayerScheduleRepairReceiptCopy forLocale(Locale locale) =>
      _copies[locale.languageCode] ?? _copies['en']!;
}

const _copies = <String, PrayerScheduleRepairReceiptCopy>{
  'tr': PrayerScheduleRepairReceiptCopy(title: 'Otomatik kontrol', checked: 'Kontrol', notApplicable: 'Zamanlanacak etkin namaz bildirimi bulunmuyor.', alreadyFresh: 'Cihazdaki namaz bildirimleri kontrol edildi ve güncel.', repaired: 'Eski veya eksik bildirim zamanlaması otomatik olarak yenilendi.', failed: 'Otomatik yenileme tamamlanamadı. Yukarıdaki yeniden eşitleme seçeneğini kullanabilirsiniz.'),
  'en': PrayerScheduleRepairReceiptCopy(title: 'Automatic check', checked: 'Checked', notApplicable: 'There are no enabled prayer reminders to schedule.', alreadyFresh: 'Prayer reminders on this device were checked and are current.', repaired: 'A stale or missing reminder schedule was refreshed automatically.', failed: 'Automatic refresh could not finish. You can use the resync option above.'),
  'fr': PrayerScheduleRepairReceiptCopy(title: 'Vérification automatique', checked: 'Vérifié', notApplicable: 'Aucun rappel de prière actif n’est à programmer.', alreadyFresh: 'Les rappels de prière de cet appareil ont été vérifiés et sont à jour.', repaired: 'Une programmation ancienne ou manquante a été actualisée automatiquement.', failed: 'L’actualisation automatique a échoué. Utilisez la resynchronisation ci-dessus.'),
  'ar': PrayerScheduleRepairReceiptCopy(title: 'فحص تلقائي', checked: 'تم الفحص', notApplicable: 'لا توجد تنبيهات صلاة مفعلة لجدولتها.', alreadyFresh: 'تم فحص تنبيهات الصلاة على هذا الجهاز وهي محدثة.', repaired: 'تم تحديث جدول تنبيهات قديم أو مفقود تلقائيًا.', failed: 'تعذر إكمال التحديث التلقائي. يمكنك استخدام إعادة المزامنة أعلاه.'),
  'az': PrayerScheduleRepairReceiptCopy(title: 'Avtomatik yoxlama', checked: 'Yoxlanıldı', notApplicable: 'Planlanacaq aktiv namaz bildirişi yoxdur.', alreadyFresh: 'Bu cihazdakı namaz bildirişləri yoxlanıldı və yenidir.', repaired: 'Köhnə və ya çatışmayan bildiriş cədvəli avtomatik yeniləndi.', failed: 'Avtomatik yeniləmə tamamlanmadı. Yuxarıdakı yenidən sinxronlaşdırmadan istifadə edin.'),
  'ru': PrayerScheduleRepairReceiptCopy(title: 'Автоматическая проверка', checked: 'Проверено', notApplicable: 'Нет включённых напоминаний о намазе для планирования.', alreadyFresh: 'Напоминания о намазе на устройстве проверены и актуальны.', repaired: 'Устаревшее или отсутствующее расписание напоминаний обновлено автоматически.', failed: 'Автоматическое обновление не завершилось. Используйте синхронизацию выше.'),
};
