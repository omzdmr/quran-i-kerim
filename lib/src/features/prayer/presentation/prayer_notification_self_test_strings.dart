import 'package:flutter/widgets.dart';

class PrayerNotificationSelfTestStrings {
  const PrayerNotificationSelfTestStrings({
    required this.send,
    required this.sent,
    required this.denied,
    required this.failed,
  });

  final String send;
  final String sent;
  final String denied;
  final String failed;
}

PrayerNotificationSelfTestStrings prayerNotificationSelfTestStrings(
  BuildContext context,
) {
  final language = Localizations.localeOf(context).languageCode;
  return switch (language) {
    'tr' => const PrayerNotificationSelfTestStrings(
        send: 'Test bildirimi gönder',
        sent: 'Test bildirimi gönderildi.',
        denied: 'Bildirim izni kapalı.',
        failed: 'Test bildirimi gönderilemedi.',
      ),
    'ar' => const PrayerNotificationSelfTestStrings(
        send: 'إرسال إشعار تجريبي',
        sent: 'تم إرسال الإشعار التجريبي.',
        denied: 'إذن الإشعارات متوقف.',
        failed: 'تعذر إرسال الإشعار التجريبي.',
      ),
    'az' => const PrayerNotificationSelfTestStrings(
        send: 'Test bildirişi göndər',
        sent: 'Test bildirişi göndərildi.',
        denied: 'Bildiriş icazəsi bağlıdır.',
        failed: 'Test bildirişi göndərilə bilmədi.',
      ),
    'ru' => const PrayerNotificationSelfTestStrings(
        send: 'Отправить тестовое уведомление',
        sent: 'Тестовое уведомление отправлено.',
        denied: 'Разрешение на уведомления отключено.',
        failed: 'Не удалось отправить тестовое уведомление.',
      ),
    'fr' => const PrayerNotificationSelfTestStrings(
        send: 'Envoyer une notification test',
        sent: 'Notification test envoyée.',
        denied: 'Les notifications ne sont pas autorisées.',
        failed: 'Impossible d’envoyer la notification test.',
      ),
    _ => const PrayerNotificationSelfTestStrings(
        send: 'Send test notification',
        sent: 'Test notification sent.',
        denied: 'Notification permission is off.',
        failed: 'Could not send the test notification.',
      ),
  };
}
