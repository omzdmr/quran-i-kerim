import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('user can record debt and an explicit completed fast', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: QadaFastingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Remaining: 0 days'), findsOneWidget);
    expect(
      find.text(
        'This ledger is stored locally and is included only when you create a backup.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Add debt'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Number of days'),
      '3',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Remaining: 3 days'), findsOneWidget);
    expect(find.text('Recorded by Ramadan'), findsOneWidget);
    expect(find.textContaining('Year unknown / estimated · 3 days'), findsOneWidget);

    await tester.tap(find.text('I completed a fast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Remaining: 2 days'), findsOneWidget);
    expect(find.text('Qada fast completed'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: QadaFastingScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Remaining: 2 days'), findsOneWidget);
  });
}
