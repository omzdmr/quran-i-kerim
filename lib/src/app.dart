import 'package:flutter/material.dart';
import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

class QuranModernApp extends StatelessWidget {
  const QuranModernApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kur’an-ı Kerim',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const AppShell(),
    );
  }
}
