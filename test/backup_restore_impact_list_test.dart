import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_import_plan.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/features/settings/backup_restore_impact_list.dart';

void main() {
  const plan = BackupImportPlan(
    incomingRecords: 3,
    localRecords: 3,
    conflictingRecords: 1,
    incomingOnlyRecords: 1,
    localOnlyRecords: 1,
    sectionImpacts: <BackupSectionImpact>[
      BackupSectionImpact(section: 'bookmarks', incomingRecords: 1, localRecords: 2, conflictingRecords: 0, incomingOnlyRecords: 0, localOnlyRecords: 1),
      BackupSectionImpact(section: 'notes', incomingRecords: 2, localRecords: 1, conflictingRecords: 1, incomingOnlyRecords: 1, localOnlyRecords: 0),
    ],
  );

  testWidgets('shows changed sections and destructive device-only count', (tester) async {
    await tester.pumpWidget(const MaterialApp(locale: Locale('en'), home: Scaffold(body: BackupRestoreImpactList(plan: plan))));
    expect(find.text('Changes by section'), findsOneWidget);
    expect(find.text('Bookmarks'), findsOneWidget);
    expect(find.text('Device only: 1'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Conflicts: 1 · From backup: 1'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('localizes section labels in French', (tester) async {
    await tester.pumpWidget(const MaterialApp(locale: Locale('fr'), home: Scaffold(body: BackupRestoreImpactList(plan: plan))));
    expect(find.text('Modifications par section'), findsOneWidget);
    expect(find.text('Signets'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });

  testWidgets('exposes a single accessible summary for each impact row', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(locale: Locale('tr'), home: Scaffold(body: BackupRestoreImpactList(plan: plan))));
    expect(find.bySemanticsLabel('Yer imleri. Yalnız cihazda: 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Notlar. Çakışan: 1 · Yedekten gelecek: 1'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('announces when backup produces no record changes', (tester) async {
    final handle = tester.ensureSemantics();
    const unchanged = BackupImportPlan(
      incomingRecords: 1,
      localRecords: 1,
      conflictingRecords: 0,
      incomingOnlyRecords: 0,
      localOnlyRecords: 0,
      sectionImpacts: <BackupSectionImpact>[
        BackupSectionImpact(section: 'reading', incomingRecords: 1, localRecords: 1, conflictingRecords: 0, incomingOnlyRecords: 0, localOnlyRecords: 0),
      ],
    );
    await tester.pumpWidget(const MaterialApp(locale: Locale('en'), home: Scaffold(body: BackupRestoreImpactList(plan: unchanged))));
    expect(find.bySemanticsLabel('This backup does not change records on this device.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('every portable manifest section has a human-readable English label', (tester) async {
    final impacts = <BackupSectionImpact>[
      for (final section in BackupManifest.includedSections)
        BackupSectionImpact(section: section, incomingRecords: 1, localRecords: 0, conflictingRecords: 0, incomingOnlyRecords: 1, localOnlyRecords: 0),
    ];
    final allSections = BackupImportPlan(
      incomingRecords: impacts.length,
      localRecords: 0,
      conflictingRecords: 0,
      incomingOnlyRecords: impacts.length,
      localOnlyRecords: 0,
      sectionImpacts: impacts,
    );
    await tester.pumpWidget(MaterialApp(locale: const Locale('en'), home: Scaffold(body: SingleChildScrollView(child: BackupRestoreImpactList(plan: allSections)))));

    for (final section in BackupManifest.includedSections) {
      expect(find.text(section), findsNothing, reason: 'Raw backup key leaked to UI: $section');
    }
    expect(find.text('Reading and last position'), findsOneWidget);
    expect(find.text('Hifz review history'), findsOneWidget);
    expect(find.text('Prayer preferences'), findsOneWidget);
    expect(find.text('Fasting records'), findsOneWidget);
  });
}
