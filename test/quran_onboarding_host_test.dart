import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_controller.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_host_controller.dart';
import 'package:quran_i_kerim/src/features/onboarding/application/onboarding_selection_applier.dart';
import 'package:quran_i_kerim/src/features/onboarding/presentation/quran_onboarding_host.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<OnboardingHostController> createHost() async {
    final settings = AppSettings();
    await settings.load();
    return OnboardingHostController(
      applier: OnboardingSelectionApplier(settings: settings),
      flow: OnboardingController(),
    );
  }

  Widget appFor(OnboardingHostController host, {VoidCallback? onCompleted}) {
    return MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        GeneratedAppLocalizations.delegate,
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: QuranOnboardingHost(
        controller: host,
        onCompleted: onCompleted ?? () {},
      ),
    );
  }

  testWidgets('renders real language choices and advances to translation', (
    tester,
  ) async {
    final host = await createHost();
    addTearDown(host.dispose);

    await tester.pumpWidget(appFor(host));
    await tester.pumpAndSettle();

    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('Azərbaycanca'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);

    await tester.tap(find.text('Русский'));
    await tester.pump();
    expect(host.languageCode, 'ru');

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(host.flow.step, OnboardingStep.translation);
    expect(host.quranSourceId, isNotEmpty);
  });

  testWidgets('back button returns from translation to language', (
    tester,
  ) async {
    final host = await createHost();
    addTearDown(host.dispose);

    await tester.pumpWidget(appFor(host));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(host.flow.step, OnboardingStep.translation);

    expect(find.byType(TextButton), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(host.flow.step, OnboardingStep.language);
  });
}
