import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/discover_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Discover opens focused offline travel hub', (tester) async {
    await tester.pumpWidget(const MaterialApp(locale: Locale('tr'), home: Scaffold(body: DiscoverScreen())));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Seyahat araçları'), 180, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Seyahat araçları'));
    await tester.pumpAndSettle();

    expect(find.text('Buluşma noktası'), findsOneWidget);
    expect(find.text('Seyahat listesi'), findsOneWidget);

    await tester.tap(find.text('Buluşma noktası'));
    await tester.pumpAndSettle();
    expect(find.text('Yer adı'), findsOneWidget);
    expect(find.text('Adres / tarif'), findsOneWidget);
  });
}