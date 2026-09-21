import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/travel_dietary_card_screen.dart';
import 'package:quran_i_kerim/src/features/discover/travel_tools_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('travel hub exposes dietary card without adding a sixth root tab', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TravelToolsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Dietary communication card'), findsOneWidget);
    await tester.tap(find.text('Dietary communication card'));
    await tester.pumpAndSettle();
    expect(find.byType(TravelDietaryCardScreen), findsOneWidget);
  });

  testWidgets('French travel hub keeps dietary entry localized', (tester) async {
    await tester.pumpWidget(const MaterialApp(locale: Locale('fr'), supportedLocales: [Locale('fr')], home: TravelToolsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Carte de communication alimentaire'), findsOneWidget);
    expect(find.text('Montrez au personnel un texte local fiable, même hors ligne.'), findsOneWidget);
  });
}
