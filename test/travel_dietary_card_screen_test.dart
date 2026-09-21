import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/travel_dietary_card_screen.dart';
import 'package:quran_i_kerim/src/features/discover/travel_dietary_card_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('French flow saves and presents staff-facing text', (tester) async {
    await tester.pumpWidget(const MaterialApp(locale: Locale('fr'), supportedLocales: [Locale('fr')], home: TravelDietaryCardScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Carte de communication alimentaire'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Français');
    await tester.enterText(find.byType(TextField).at(1), 'Texte vérifié par utilisateur');
    await tester.enterText(find.byType(TextField).at(2), 'Ne pas montrer au personnel');
    await tester.tap(find.text('Afficher la carte'));
    await tester.pumpAndSettle();
    expect(find.text('Texte vérifié par utilisateur'), findsOneWidget);
    expect(find.text('Ne pas montrer au personnel'), findsNothing);
    expect(find.text('Note privée enregistrée ; elle reste masquée sur la carte.'), findsOneWidget);
    final saved = await const TravelDietaryCardStore().load();
    expect(saved?.languageLabel, 'Français');
    expect(saved?.note, 'Ne pas montrer au personnel');
  });

  testWidgets('empty card is rejected without leaving editor', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TravelDietaryCardScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show card'));
    await tester.pump();
    expect(find.text('Staff-facing text cannot be empty.'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
  });
}
