import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/travel_dietary_card_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('dietary editor survives large accessibility text', (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)), child: child!),
      home: const TravelDietaryCardScreen(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Dietary communication card'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('staff card exposes one combined semantics label and hides private note', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TravelDietaryCardScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'No pork, trusted user text');
    await tester.enterText(find.byType(TextField).at(2), 'private detail');
    await tester.tap(find.text('Show card'));
    await tester.pumpAndSettle();
    expect(find.text('private detail'), findsNothing);
    expect(find.bySemanticsLabel('Text shown to staff: No pork, trusted user text'), findsOneWidget);
  });
}
