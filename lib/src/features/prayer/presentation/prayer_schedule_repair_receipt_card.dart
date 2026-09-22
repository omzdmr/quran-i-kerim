import 'package:flutter/material.dart';

import '../application/prayer_schedule_repair_receipt_store.dart';

class PrayerScheduleRepairReceiptCard extends StatefulWidget {
  const PrayerScheduleRepairReceiptCard({super.key, this.now});
  final DateTime? now;
  @override
  State<PrayerScheduleRepairReceiptCard> createState() => _PrayerScheduleRepairReceiptCardState();
}

class _PrayerScheduleRepairReceiptCardState extends State<PrayerScheduleRepairReceiptCard> with WidgetsBindingObserver {
  static const _store = PrayerScheduleRepairReceiptStore();
  PrayerScheduleRepairReceipt? _receipt;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _load(); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) _load(); }
  Future<void> _load() async { final value = await _store.load(); if (mounted) setState(() => _receipt = value); }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;
    if (receipt == null) return const SizedBox.shrink();
    final copy = PrayerScheduleRepairReceiptCopy.forLocale(Localizations.localeOf(context));
    final current = widget.now ?? DateTime.now();
    final age = current.toUtc().difference(receipt.attemptedAt.toUtc());
    if (age.isNegative || age > const Duration(days: 7)) return const SizedBox.shrink();
    final message = copy.message(receipt.outcome);
    final reason = copy.reason(receipt.trigger);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(receipt.attemptedAt.toLocal()));
    final date = MaterialLocalizations.of(context).formatMediumDate(receipt.attemptedAt.toLocal());
    final semanticReason = reason.isEmpty ? '' : ' $reason';
    return Semantics(
      container: true,
      label: '${copy.title}. $message$semanticReason. ${copy.checked}: $date, $time',
      child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.history_toggle_off_rounded), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(copy.title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(message),
          if (reason.isNotEmpty) ...[const SizedBox(height: 4), Text(reason, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))],
          const SizedBox(height: 4), Text('${copy.checked}: $date · $time', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        ])),
      ]))),
    );
  }
}

class PrayerScheduleRepairReceiptCopy {
  const PrayerScheduleRepairReceiptCopy({required this.title, required this.checked, required this.notApplicable, required this.alreadyFresh, required this.repaired, required this.failed, required this.configChanged, required this.scheduleMissing, required this.stale});
  final String title, checked, notApplicable, alreadyFresh, repaired, failed, configChanged, scheduleMissing, stale;
  String message(PrayerScheduleRepairOutcome outcome) => switch (outcome) {
    PrayerScheduleRepairOutcome.notApplicable => notApplicable,
    PrayerScheduleRepairOutcome.alreadyFresh => alreadyFresh,
    PrayerScheduleRepairOutcome.repaired => repaired,
    PrayerScheduleRepairOutcome.failed => failed,
  };
  String reason(PrayerScheduleRepairTrigger trigger) => switch (trigger) {
    PrayerScheduleRepairTrigger.configurationChanged => configChanged,
    PrayerScheduleRepairTrigger.platformScheduleMissing => scheduleMissing,
    PrayerScheduleRepairTrigger.staleEvidence => stale,
    _ => '',
  };
  static PrayerScheduleRepairReceiptCopy forLocale(Locale locale) => _copies[locale.languageCode] ?? _copies['en']!;
}

const _copies = <String, PrayerScheduleRepairReceiptCopy>{
  'tr': PrayerScheduleRepairReceiptCopy(title:'Otomatik kontrol',checked:'Kontrol',notApplicable:'Zamanlanacak etkin namaz bildirimi bulunmuyor.',alreadyFresh:'Cihazdaki namaz bildirimleri kontrol edildi ve güncel.',repaired:'Bildirim zamanlaması otomatik olarak yenilendi.',failed:'Otomatik yenileme tamamlanamadı. Yukarıdaki yeniden eşitleme seçeneğini kullanabilirsiniz.',configChanged:'Konum, dil veya namaz ayarları değiştiği için zamanlama yenilendi.',scheduleMissing:'Cihazdaki bekleyen namaz bildirimleri kaybolduğu için yeniden oluşturuldu.',stale:'Kayıtlı zamanlama eski olduğu için güncellendi.'),
  'en': PrayerScheduleRepairReceiptCopy(title:'Automatic check',checked:'Checked',notApplicable:'There are no enabled prayer reminders to schedule.',alreadyFresh:'Prayer reminders on this device were checked and are current.',repaired:'The reminder schedule was refreshed automatically.',failed:'Automatic refresh could not finish. You can use the resync option above.',configChanged:'The schedule was refreshed because location, language, or prayer settings changed.',scheduleMissing:'Pending prayer reminders were missing from the device and were created again.',stale:'The saved schedule was old, so it was refreshed.'),
  'fr': PrayerScheduleRepairReceiptCopy(title:'Vérification automatique',checked:'Vérifié',notApplicable:'Aucun rappel de prière actif n’est à programmer.',alreadyFresh:'Les rappels de prière de cet appareil ont été vérifiés et sont à jour.',repaired:'La programmation des rappels a été actualisée automatiquement.',failed:'L’actualisation automatique a échoué. Utilisez la resynchronisation ci-dessus.',configChanged:'La programmation a été actualisée après un changement de lieu, de langue ou de réglages de prière.',scheduleMissing:'Les rappels de prière en attente avaient disparu de l’appareil et ont été recréés.',stale:'La programmation enregistrée était ancienne et a été actualisée.'),
  'ar': PrayerScheduleRepairReceiptCopy(title:'فحص تلقائي',checked:'تم الفحص',notApplicable:'لا توجد تنبيهات صلاة مفعلة لجدولتها.',alreadyFresh:'تم فحص تنبيهات الصلاة على هذا الجهاز وهي محدثة.',repaired:'تم تحديث جدول التنبيهات تلقائيًا.',failed:'تعذر إكمال التحديث التلقائي. يمكنك استخدام إعادة المزامنة أعلاه.',configChanged:'تم تحديث الجدول بسبب تغير الموقع أو اللغة أو إعدادات الصلاة.',scheduleMissing:'كانت تنبيهات الصلاة المعلقة مفقودة من الجهاز، فتم إنشاؤها من جديد.',stale:'كان الجدول المحفوظ قديمًا، فتم تحديثه.'),
  'az': PrayerScheduleRepairReceiptCopy(title:'Avtomatik yoxlama',checked:'Yoxlanıldı',notApplicable:'Planlanacaq aktiv namaz bildirişi yoxdur.',alreadyFresh:'Bu cihazdakı namaz bildirişləri yoxlanıldı və yenidir.',repaired:'Bildiriş cədvəli avtomatik yeniləndi.',failed:'Avtomatik yeniləmə tamamlanmadı. Yuxarıdakı yenidən sinxronlaşdırmadan istifadə edin.',configChanged:'Məkan, dil və ya namaz ayarları dəyişdiyi üçün cədvəl yeniləndi.',scheduleMissing:'Cihazda gözləyən namaz bildirişləri yox idi və yenidən yaradıldı.',stale:'Saxlanmış cədvəl köhnə olduğu üçün yeniləndi.'),
  'ru': PrayerScheduleRepairReceiptCopy(title:'Автоматическая проверка',checked:'Проверено',notApplicable:'Нет включённых напоминаний о намазе для планирования.',alreadyFresh:'Напоминания о намазе на устройстве проверены и актуальны.',repaired:'Расписание напоминаний обновлено автоматически.',failed:'Автоматическое обновление не завершилось. Используйте синхронизацию выше.',configChanged:'Расписание обновлено из-за изменения местоположения, языка или настроек намаза.',scheduleMissing:'Ожидающие напоминания о намазе отсутствовали на устройстве и были созданы заново.',stale:'Сохранённое расписание устарело и было обновлено.'),
};
