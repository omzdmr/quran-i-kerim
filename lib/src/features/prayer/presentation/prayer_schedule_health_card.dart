import 'package:flutter/material.dart';

import '../application/prayer_notification_schedule_health_refresher.dart';
import '../application/prayer_notification_schedule_health_store.dart';
import '../application/prayer_pending_schedule_probe.dart';

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
  static const _refresher = PrayerNotificationScheduleHealthRefresher();
  static const _pendingProbe = SystemPrayerPendingScheduleProbe();
  PrayerNotificationScheduleHealth? _health;
  String? _currentFingerprint;
  int? _platformPendingCount;
  bool _loading = true;
  bool _resyncing = false;
  bool _resyncFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    PrayerNotificationScheduleHealth? value;
    String? fingerprint;
    int? platformPendingCount;
    try {
      value = await _store.load();
      fingerprint = await _refresher.currentConfigurationFingerprint();
      platformPendingCount = await _pendingProbe.pendingCount();
    } catch (_) {
      // Keep whatever durable evidence could be read, but unresolved current
      // configuration must never be promoted to a healthy state.
    }
    if (!mounted) return;
    setState(() {
      _health = value;
      _currentFingerprint = fingerprint;
      _platformPendingCount = platformPendingCount;
      _loading = false;
    });
  }

  Future<void> _resync() async {
    if (_resyncing) return;
    setState(() {
      _resyncing = true;
      _resyncFailed = false;
    });
    try {
      await widget.onResync();
      await _load();
    } catch (_) {
      if (mounted) setState(() => _resyncFailed = true);
    } finally {
      if (mounted) setState(() => _resyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = PrayerScheduleHealthCopy.forLocale(Localizations.localeOf(context));
    final health = _health;
    final fingerprint = _currentFingerprint;
    final legacyEvidence = health != null && health.configurationFingerprint.isEmpty;
    final platformScheduleMissing = _platformPendingCount == 0;
    final configChanged = health != null &&
        fingerprint != null &&
        fingerprint.isNotEmpty &&
        health.configurationFingerprint.isNotEmpty &&
        health.configurationFingerprint != fingerprint;
    final fresh = fingerprint != null &&
        fingerprint.isNotEmpty &&
        !platformScheduleMissing &&
        (health?.isFreshAt(
              widget.now ?? DateTime.now(),
              expectedConfigurationFingerprint: fingerprint,
            ) ??
            false);
    final scheme = Theme.of(context).colorScheme;
    final status = _loading
        ? copy.checking
        : platformScheduleMissing && health != null
            ? copy.platformScheduleMissing
            : configChanged
                ? copy.configurationChanged
                : legacyEvidence
                    ? copy.legacySchedule
                    : fresh
                        ? copy.healthy
                        : copy.needsResync;

    return Semantics(
      container: true,
      liveRegion: (!_loading && !fresh) || _resyncFailed,
      label: '${copy.title}. $status${_resyncFailed ? ' ${copy.resyncFailed}' : ''}',
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
              if (_resyncFailed) ...[
                const SizedBox(height: 6),
                Text(copy.resyncFailed, style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700)),
              ],
              if (health != null) ...[
                const SizedBox(height: 8),
                Text('${copy.next}: ${copy.prayerName(health.nextPrayerId)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(health.nextScheduledAt.toLocal()))}'),
                const SizedBox(height: 4),
                Text('${copy.source}: ${health.locationLabel} · ${health.timeZoneId}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                Text('${copy.method}: ${health.calculationMethodId} · ${copy.pending}: ${_platformPendingCount ?? health.pendingCount}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                Text('${copy.updated}: ${MaterialLocalizations.of(context).formatFullDate(health.scheduledAt.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(health.scheduledAt.toLocal()))}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
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
  const PrayerScheduleHealthCopy(this.title, this.checking, this.healthy, this.needsResync, this.configurationChanged, this.legacySchedule, this.platformScheduleMissing, this.resyncFailed, this.next, this.source, this.method, this.pending, this.updated, this.resync, this.prayers);
  final String title, checking, healthy, needsResync, configurationChanged, legacySchedule, platformScheduleMissing, resyncFailed, next, source, method, pending, updated, resync;
  final Map<String, String> prayers;
  String prayerName(String id) => prayers[id] ?? id;
  static PrayerScheduleHealthCopy forLocale(Locale locale) => _copies[locale.languageCode] ?? _copies['en']!;
}

const _copies = <String, PrayerScheduleHealthCopy>{
  'tr': PrayerScheduleHealthCopy('Bildirim zamanlama sağlığı', 'Kontrol ediliyor…', 'Namaz bildirimleri güncel bir zamanlamaya sahip.', 'Zamanlama eski veya doğrulanamıyor. Yeniden eşitleyin.', 'Namaz ayarları veya konum değişti. Eski zamanlama kullanılmayacak.', 'Bu zamanlama eski sürümden kaldı ve ayarları doğrulanamıyor.', 'Cihazda bekleyen namaz bildirimi kalmamış. Yeniden eşitleyin.', 'Yeniden eşitleme tamamlanamadı. Mevcut zamanlama güncel kabul edilmedi; tekrar deneyebilirsiniz.', 'Sıradaki', 'Konum', 'Yöntem', 'Planlanan', 'Son güncelleme', 'Bildirimleri yeniden eşitle', {'fajr':'Sabah','dhuhr':'Öğle','asr':'İkindi','maghrib':'Akşam','isha':'Yatsı'}),
  'en': PrayerScheduleHealthCopy('Notification schedule health', 'Checking…', 'Prayer notifications have a fresh schedule.', 'The schedule is stale or cannot be verified. Resync it.', 'Prayer settings or location changed. The old schedule will not be treated as current.', 'This schedule is from an older version and its settings cannot be verified.', 'No pending prayer reminders remain on this device. Resync them.', 'Resync could not be completed. The existing schedule is not treated as current; you can retry.', 'Next', 'Location', 'Method', 'Scheduled', 'Last update', 'Resync notifications', {'fajr':'Fajr','dhuhr':'Dhuhr','asr':'Asr','maghrib':'Maghrib','isha':'Isha'}),
  'fr': PrayerScheduleHealthCopy('État de la programmation', 'Vérification…', 'Les notifications de prière sont à jour.', 'La programmation est ancienne ou invérifiable. Resynchronisez-la.', 'Les réglages de prière ou le lieu ont changé. L’ancien horaire ne sera pas considéré comme actuel.', 'Cet horaire vient d’une ancienne version et ses réglages ne peuvent pas être vérifiés.', 'Aucun rappel de prière n’est encore programmé sur cet appareil. Resynchronisez-les.', 'La resynchronisation a échoué. L’horaire actuel n’est pas considéré comme à jour; vous pouvez réessayer.', 'Prochaine', 'Lieu', 'Méthode', 'Planifiées', 'Dernière mise à jour', 'Resynchroniser', {'fajr':'Fajr','dhuhr':'Dhuhr','asr':'Asr','maghrib':'Maghrib','isha':'Isha'}),
  'ar': PrayerScheduleHealthCopy('حالة جدولة التنبيهات', 'جارٍ التحقق…', 'جدول تنبيهات الصلاة محدث.', 'الجدول قديم أو لا يمكن التحقق منه. أعد المزامنة.', 'تغيرت إعدادات الصلاة أو الموقع. لن يُعامل الجدول القديم على أنه محدث.', 'هذا الجدول من إصدار أقدم ولا يمكن التحقق من إعداداته.', 'لا توجد تنبيهات صلاة معلقة على هذا الجهاز. أعد المزامنة.', 'تعذرت إعادة المزامنة. لن يُعتبر الجدول الحالي محدثًا ويمكنك المحاولة مجددًا.', 'التالي', 'الموقع', 'الطريقة', 'المجدولة', 'آخر تحديث', 'إعادة مزامنة التنبيهات', {'fajr':'الفجر','dhuhr':'الظهر','asr':'العصر','maghrib':'المغرب','isha':'العشاء'}),
  'az': PrayerScheduleHealthCopy('Bildiriş cədvəlinin vəziyyəti', 'Yoxlanılır…', 'Namaz bildirişlərinin cədvəli yenidir.', 'Cədvəl köhnədir və ya təsdiqlənmir. Yenidən sinxronlaşdırın.', 'Namaz ayarları və ya məkan dəyişib. Köhnə cədvəl cari sayılmayacaq.', 'Bu cədvəl köhnə versiyadandır və ayarları təsdiqlənmir.', 'Cihazda gözləyən namaz bildirişi qalmayıb. Yenidən sinxronlaşdırın.', 'Yenidən sinxronlaşdırma tamamlanmadı. Mövcud cədvəl cari sayılmır; yenidən cəhd edə bilərsiniz.', 'Növbəti', 'Məkan', 'Metod', 'Planlanan', 'Son yeniləmə', 'Bildirişləri yenidən sinxronlaşdır', {'fajr':'Sübh','dhuhr':'Zöhr','asr':'Əsr','maghrib':'Məğrib','isha':'İşa'}),
  'ru': PrayerScheduleHealthCopy('Состояние расписания', 'Проверка…', 'Расписание уведомлений о намазе актуально.', 'Расписание устарело или не подтверждено. Синхронизируйте снова.', 'Настройки намаза или местоположение изменились. Старое расписание не считается актуальным.', 'Это расписание создано старой версией, его настройки нельзя проверить.', 'На устройстве не осталось ожидающих напоминаний о намазе. Синхронизируйте снова.', 'Не удалось синхронизировать. Текущее расписание не считается актуальным; можно повторить попытку.', 'Следующий', 'Место', 'Метод', 'Запланировано', 'Последнее обновление', 'Синхронизировать', {'fajr':'Фаджр','dhuhr':'Зухр','asr':'Аср','maghrib':'Магриб','isha':'Иша'}),
};
