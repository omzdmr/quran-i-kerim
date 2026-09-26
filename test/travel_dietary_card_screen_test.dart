import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/travel_dietary_card_screen.dart';
import 'package:quran_i_kerim/src/features/discover/travel_dietary_card_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('French flow saves and presents staff-facing text', (tester) async {
    await tester.pumpWidget(const MaterialApp(locale:Locale('fr'),supportedLocales:[Locale('fr')],home:TravelDietaryCardScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0),'Français');
    await tester.enterText(find.byType(TextField).at(1),'Texte vérifié par utilisateur');
    await tester.enterText(find.byType(TextField).at(2),'Ne pas montrer au personnel');
    await tester.tap(find.text('Afficher la carte')); await tester.pumpAndSettle();
    expect(find.text('Texte vérifié par utilisateur'),findsOneWidget);
    expect(find.text('Ne pas montrer au personnel'),findsNothing);
    expect((await const TravelDietaryCardStore().load())?.note,'Ne pas montrer au personnel');
  });

  testWidgets('saved card can be deleted only after confirmation', (tester) async {
    const store=TravelDietaryCardStore();
    await store.save(const TravelDietaryCard(languageLabel:'English',staffText:'trusted text',note:'private'));
    await tester.pumpWidget(const MaterialApp(home:TravelDietaryCardScreen())); await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete')); await tester.pumpAndSettle();
    expect(find.text('Delete card?'),findsOneWidget);
    await tester.tap(find.text('Cancel')); await tester.pumpAndSettle();
    expect(await store.load(),isNotNull);
    await tester.tap(find.byTooltip('Delete')); await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton,'Delete')); await tester.pumpAndSettle();
    expect(await store.load(),isNull);
    expect(find.byType(TextField),findsNWidgets(3));
  });

  testWidgets('empty card is rejected without leaving editor', (tester) async {
    await tester.pumpWidget(const MaterialApp(home:TravelDietaryCardScreen())); await tester.pumpAndSettle();
    await tester.tap(find.text('Show card')); await tester.pump();
    expect(find.text('Staff-facing text cannot be empty.'),findsOneWidget);
    expect(find.byType(TextField),findsNWidgets(3));
  });
}
