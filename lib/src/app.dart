import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'settings/app_settings.dart';
import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

class QuranModernApp extends StatelessWidget {
  const QuranModernApp({
    required this.settings,
    super.key,
  });

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
            onGenerateTitle: (context) => context.l10n.appTitle,
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
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AppShell(),
          ),
        );
      },
    );
  }
}
