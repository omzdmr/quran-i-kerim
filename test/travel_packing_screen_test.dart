import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/travel_packing_screen.dart';
import 'package:quran_i_kerim/src/features/discover/travel_packing_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('user can add, pack, copy, reset and remove a travel item', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TravelPackingScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Passport');
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Ready: 0 / 1'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('Ready: 1 / 1'), findsOneWidget);
    await tester.tap(find.text('Copy list'));
    await tester.pumpAndSettle();
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    expect(clipboard?.text, contains('☑ Passport'));
    await tester.tap(find.text('Reset checks'));
    await tester.pumpAndSettle();
    expect(find.text('Ready: 0 / 1'), findsOneWidget);
    var saved = await const TravelPackingStore().load();
    expect(saved.single.packed, isFalse);
    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    saved = await const TravelPackingStore().load();
    expect(saved, isEmpty);
  });

  testWidgets('packing input is bounded before persistence', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TravelPackingScreen()));
    await tester.pumpAndSettle();
    final oversized = List<String>.filled(TravelPackingItem.maxLabelLength + 50, 'x').join();
    await tester.enterText(find.byType(TextField), oversized);
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, TravelPackingItem.maxLabelLength);
  });
}