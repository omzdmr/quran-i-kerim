import 'package:flutter/material.dart';

import '../application/prayer_notification_schedule_health_store.dart';

/// Diagnostics surface for the local prayer-notification schedule contract.
/// It never claims notifications are healthy merely because a preference is on.
class PrayerScheduleHealthCard extends StatefulWidget {
  const PrayerScheduleHealthCard({required this.onResync, super.key, this.now});

  final Future<void> Function() onResync;
  final DateTime? now;

  @override
  State<PrayerScheduleHealthCard> createState() => _PrayerScheduleHealthCardState();
}

class _PrayerScheduleHealthCardState extends State<PrayerScheduleHealthCard> {
  static const _store = PrayerNotificationScheduleHealthStore();
  PrayerNotificationScheduleHealth? _health;
  bool _loading = true;
  bool _resyncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _store.load();
    if (!mounted) return;
    setState(() {
      _health = value;
      _loading = false;
    });
  }

  Future<void> _resync() async {
    if (_resyncing) return;
    setState(() => _resyncing = true);
    try {
      await widget.onResync();
      await _load();
    } finally {
      if (mounted) setState(() => _resyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = PrayerScheduleHealthCopy.forLocale(Localizations.localeOf(context));
    final health = _health;
    final fresh = health?.isFreshAt(widget.now ?? DateTime.now()) ?? false;
    final scheme = Theme.of(context).colorScheme;
    final status = _loading ? copy.checking : fresh ? copy.healthy : copy.needsResync;

    return Semantics(
      container: true,
      label: '${copy.title}. $status',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(fresh ? Icons.verified_outlined : Icons.sync_problem_rounded, color: fresh ? scheme.primary : scheme.error),
                const SizedBox(width: 10),
                Expanded(child: Text(copy.title, style: const TextStyle(fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 10),
              Text(status, style: TextStyle(color: fresh ? scheme.onSurfaceVariant : scheme.error, fontWeight: FontWeight.w700)),
              if (health != null) ...[
                const SizedBox(height: 8),
                Text('${copy.next}: ${copy.prayerName(health.nextPrayerId)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(health.nextScheduledAt.toLocal()))}'),
                const SizedBox(height: 4),
                Text('${copy.source}: ${health.locationLabel} · ${health.timeZoneId}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                Text('${copy.method}: ${health.calculationMethodId} · ${copy.pending}: ${health.pendingCount}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
              ],
              if (!_loading && !fresh) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _resyncing ? null : _resync,
                  icon: _resyncing ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync_rounded),
                  label: Text(copy.resync),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PrayerScheduleHealthCopy {
  const PrayerScheduleHealthCopy(this.title, this.checking, this.healthy, this.needsResync, this.next, this.source, this.method, this.pending, this.resync, this.prayers);
  final String title, checking, healthy, needsResync, next, source, method, pending, resync;
  final Map<String, String> prayers;
  String prayerName(String id) => prayers[id] ?? id;
  static PrayerScheduleHealthCopy forLocale(Locale locale) => _copies[locale.languageCode] ?? _copies['en']!;
}

const _copies = <String, PrayerScheduleHealthCopy>{
  'tr': PrayerScheduleHealthCopy('Bildirim zamanlama sağlığı', 'Kontrol ediliyor…', 'Namaz bildirimleri güncel bir zamanlamaya sahip.', 'Zamanlama eski veya doğrulanamıyor. Yeniden eşitleyin.', 'Sıradaki', 'Konum', 'Yöntem', 'Planlanan', 'Bildirimleri yeniden eşitle', {'fajr':'Sabah','dhuhr':'Öğle','asr':'İkindi','maghrib':'Akşam','isha':'Yatsı'}),
  'en': PrayerScheduleHealthCopy('Notification schedule health', 'Checking…', 'Prayer notifications have a fresh schedule.', 'The schedule is stale or cannot be verified. Resync it.', 'Next', 'Location', 'Method', 'Scheduled', 'Resync notifications', {'fajr':'Fajr','dhuhr':'Dhuhr','asr':'Asr','maghrib':'Maghrib','isha':'Isha'}),
  'fr': PrayerScheduleHealthCopy('État de la programmation', 'Vérification…', 'Les notifications de prière sont à jour.', 'La programmation est ancienne ou invérifiable. Resynchronisez-la.', 'Prochaine', 'Lieu', 'Méthode', 'Planifiées', 'Resynchroniser', {'fajr':'Fajr','dhuhr':'Dhuhr','asr':'Asr','maghrib':'Maghrib','isha':'Isha'}),
  'ar': PrayerScheduleHealthCopy('حالة جدولة التنبيهات', 'جارٍ التحقق…', 'جدول تنبيهات الصلاة محدث.', 'الجدول قديم أو لا يمكن التحقق منه. أعد المزامنة.', 'التالي', 'الموقع', 'الطريقة', 'المجدولة', 'إعادة مزامنة التنبيهات', {'fajr':'الفجر','dhuhr':'الظهر','asr':'العصر','maghrib':'المغرب','isha':'العشاء'}),
  'az': PrayerScheduleHealthCopy('Bildiriş cədvəlinin vəziyyəti', 'Yoxlanılır…', 'Namaz bildirişlərinin cədvəli yenidir.', 'Cədvəl köhnədir və ya təsdiqlənmir. Yenidən sinxronlaşdırın.', 'Növbəti', 'Məkan', 'Metod', 'Planlanan', 'Bildirişləri yenidən sinxronlaşdır', {'fajr':'Sübh','dhuhr':'Zöhr','asr':'Əsr','maghrib':'Məğrib','isha':'İşa'}),
  'ru': PrayerScheduleHealthCopy('Состояние расписания', 'Проверка…', 'Расписание уведомлений о намазе актуально.', 'Расписание устарело или не подтверждено. Синхронизируйте снова.', 'Следующий', 'Место', 'Метод', 'Запланировано', 'Синхронизировать', {'fajr':'Фаджр','dhuhr':'Зухр','asr':'Аср','maghrib':'Магриб','isha':'Иша'}),
};
