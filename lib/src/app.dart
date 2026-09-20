import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/onboarding/presentation/onboarding_app_root.dart';
import 'l10n/app_localizations.dart';
import 'l10n/generated/generated_app_localizations.dart';
import 'settings/app_settings.dart';
import 'theme/app_theme.dart';

class QuranModernApp extends StatelessWidget {
  const QuranModernApp({required this.settings, super.key});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return AppSettingsScope(
          settings: settings,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) =>
                GeneratedAppLocalizations.of(context)!.appTitle,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localeListResolutionCallback: (deviceLocales, supportedLocales) {
              if (settings.locale != null) return settings.locale;
              for (final deviceLocale in deviceLocales ?? const <Locale>[]) {
                for (final supported in supportedLocales) {
                  if (supported.languageCode == deviceLocale.languageCode) {
                    return supported;
                  }
                }
              }
              return const Locale('en');
            },
            localizationsDelegates: const [
              GeneratedAppLocalizations.delegate,
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: OnboardingAppRoot(settings: settings),
          ),
        );
      },
    );
  }
}
