import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/travel_meeting_point_screen.dart';
import 'package:quran_i_kerim/src/features/discover/travel_meeting_point_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Widget app({required Locale locale, double textScale = 1}) => MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('tr'), Locale('en'), Locale('fr'), Locale('ar'), Locale('az'), Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const TravelMeetingPointScreen(),
      );

  testWidgets('user can save meeting point from the offline form', (tester) async {
    await tester.pumpWidget(app(locale: const Locale('tr')));
    await tester.pumpAndSettle();

    expect(find.text('Buluşma noktası'), findsOneWidget);
    expect(find.textContaining('çevrimdışı'), findsOneWidget);
    final mapButtonBefore = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Haritada aç'));
    expect(mapButtonBefore.onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(0), 'Otel lobisi');
    await tester.enterText(find.byType(TextField).at(1), 'B kapısı');
    await tester.enterText(find.byType(TextField).at(2), 'Saat 18:00');
    await tester.pump();
    final mapButtonAfter = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Haritada aç'));
    expect(mapButtonAfter.onPressed, isNotNull);

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    final stored = await const TravelMeetingPointStore().load();
    expect(stored?.name, 'Otel lobisi');
    expect(stored?.address, 'B kapısı');
    expect(stored?.note, 'Saat 18:00');
    expect(find.text('Buluşma noktası kaydedildi'), findsOneWidget);
  });

  testWidgets('large text keeps core actions reachable', (tester) async {
    await tester.pumpWidget(app(locale: const Locale('en'), textScale: 2));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Copy details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}