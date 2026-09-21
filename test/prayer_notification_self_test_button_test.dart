import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_notification_self_test_button.dart';

void main() {
  testWidgets('self-test control exposes localized button semantics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: [Locale('tr')],
        home: Scaffold(body: PrayerNotificationSelfTestButton()),
      ),
    );

    expect(find.text('Test bildirimi gönder'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
    final semantics = tester.getSemantics(find.byType(OutlinedButton));
    expect(semantics.label, contains('Test bildirimi gönder'));
  });

  testWidgets('self-test control supports RTL layout', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar')],
        home: Scaffold(body: PrayerNotificationSelfTestButton()),
      ),
    );

    expect(find.text('إرسال إشعار تجريبي'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(OutlinedButton))), TextDirection.rtl);
  });
}
