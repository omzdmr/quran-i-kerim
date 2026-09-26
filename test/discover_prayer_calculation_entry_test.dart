import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/discover_screen.dart';

void main() {
  testWidgets('Discover exposes prayer calculation transparency entry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: DiscoverScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Calculation method'), findsOneWidget);
    expect(find.byIcon(Icons.calculate_outlined), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Calculation method'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.ancestor(
        of: find.text('Calculation method'),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
  });
}
