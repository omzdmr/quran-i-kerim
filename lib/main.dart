import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();
  runApp(QuranModernApp(settings: settings));
}
