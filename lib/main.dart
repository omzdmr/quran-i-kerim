import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/features/audio/application/quran_audio_service.dart';
import 'src/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();
  await QuranAudioService.instance.initialize();
  runApp(QuranModernApp(settings: settings));
}
