import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/travel_packing_screen.dart';
import 'package:quran_i_kerim/src/features/discover/travel_packing_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('user can add, pack and remove a travel item', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TravelPackingScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Passport');
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Passport'), findsOneWidget);
    expect(find.text('Ready: 0 / 1'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('Ready: 1 / 1'), findsOneWidget);

    var saved = await const TravelPackingStore().load();
    expect(saved.single.label, 'Passport');
    expect(saved.single.packed, isTrue);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Passport'), findsNothing);
    expect(find.text('Ready: 0 / 0'), findsOneWidget);
    saved = await const TravelPackingStore().load();
    expect(saved, isEmpty);
  });
}