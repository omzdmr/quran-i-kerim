import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/travel_meeting_point_screen.dart';
import 'package:quran_i_kerim/src/features/discover/travel_meeting_point_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('user can save meeting point from the offline form', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('tr'),
      home: TravelMeetingPointScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Buluşma noktası'), findsOneWidget);
    expect(find.textContaining('çevrimdışı'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Otel lobisi');
    await tester.enterText(find.byType(TextField).at(1), 'B kapısı');
    await tester.enterText(find.byType(TextField).at(2), 'Saat 18:00');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    final stored = await const TravelMeetingPointStore().load();
    expect(stored?.name, 'Otel lobisi');
    expect(stored?.address, 'B kapısı');
    expect(stored?.note, 'Saat 18:00');
    expect(find.text('Buluşma noktası kaydedildi'), findsOneWidget);
  });

  testWidgets('large text keeps core actions reachable', (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
      child: const MaterialApp(locale: Locale('en'), home: TravelMeetingPointScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Copy details'), findsOneWidget);
  });
}