import 'package:flutter/material.dart';
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
            title: 'Kur’an-ı Kerim',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            home: const AppShell(),
          ),
        );
      },
    );
  }
}
