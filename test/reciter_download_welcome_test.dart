import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/onboarding/presentation/reciter_download_welcome.dart';

void main() {
  Widget buildSubject({
    required VoidCallback onDownload,
    String? laterLabel,
    VoidCallback? onLater,
  }) {
    return MaterialApp(
      home: ReciterDownloadWelcome(
        title: 'Listen offline',
        reciterName: 'Test reciter',
        languageLabel: 'Arabic',
        body: 'Download an optional recitation package.',
        downloadLabel: 'Download',
        downloadMeta: 'Optional · offline',
        onDownload: onDownload,
        laterLabel: laterLabel,
        onLater: onLater,
      ),
    );
  }

  testWidgets('download action remains available without a later action', (
    tester,
  ) async {
    var downloads = 0;

    await tester.pumpWidget(
      buildSubject(onDownload: () => downloads += 1),
    );

    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Later'), findsNothing);

    await tester.tap(find.text('Download'));
    await tester.pump();

    expect(downloads, 1);
  });

  testWidgets('later action is shown only when label and callback are supplied', (
    tester,
  ) async {
    var laterTaps = 0;

    await tester.pumpWidget(
      buildSubject(
        onDownload: () {},
        laterLabel: 'Later',
        onLater: () => laterTaps += 1,
      ),
    );

    expect(find.text('Later'), findsOneWidget);

    await tester.tap(find.text('Later'));
    await tester.pump();

    expect(laterTaps, 1);
  });
}
