import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_notification_self_test_strings.dart';

void main() {
  for (final locale in const ['tr', 'en', 'ar', 'az', 'ru', 'fr']) {
    testWidgets('notification self-test copy is complete for $locale', (tester) async {
      late PrayerNotificationSelfTestStrings copy;
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          supportedLocales: const [
            Locale('tr'),
            Locale('en'),
            Locale('ar'),
            Locale('az'),
            Locale('ru'),
            Locale('fr'),
          ],
          home: Builder(
            builder: (context) {
              copy = prayerNotificationSelfTestStrings(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(copy.send.trim(), isNotEmpty);
      expect(copy.sent.trim(), isNotEmpty);
      expect(copy.denied.trim(), isNotEmpty);
      expect(copy.failed.trim(), isNotEmpty);
    });
  }

  testWidgets('unknown locale safely falls back to English', (tester) async {
    late PrayerNotificationSelfTestStrings copy;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: const [Locale('de')],
        home: Builder(
          builder: (context) {
            copy = prayerNotificationSelfTestStrings(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(copy.send, 'Send test notification');
  });
}
