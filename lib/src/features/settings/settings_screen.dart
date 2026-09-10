import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../settings/app_settings.dart';
import '../audio/application/audio_sleep_timer_input.dart';
import '../audio/application/quran_audio_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text(
            l10n.appearance,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appearanceDescription,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          _ChoiceTile(
            title: l10n.useDeviceTheme,
            subtitle: l10n.useDeviceThemeDescription,
            icon: Icons.brightness_auto_rounded,
            selected: settings.themeMode == ThemeMode.system,
            onTap: () => settings.setThemeMode(ThemeMode.system),
          ),
          _ChoiceTile(
            title: l10n.lightTheme,
            subtitle: l10n.lightThemeDescription,
            icon: Icons.light_mode_outlined,
            selected: settings.themeMode == ThemeMode.light,
            onTap: () => settings.setThemeMode(ThemeMode.light),
          ),
          _ChoiceTile(
            title: l10n.darkTheme,
            subtitle: l10n.darkThemeDescription,
            icon: Icons.dark_mode_outlined,
            selected: settings.themeMode == ThemeMode.dark,
            onTap: () => settings.setThemeMode(ThemeMode.dark),
          ),
          const SizedBox(height: 30),
          Text(
            l10n.language,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.languageDescription,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          _ChoiceTile(
            title: l10n.useDeviceLanguage,
            subtitle: l10n.useDeviceLanguageDescription,
            icon: Icons.language_rounded,
            selected: settings.locale == null,
            onTap: () => settings.setLocale(null),
          ),
          _ChoiceTile(
            title: l10n.turkish,
            subtitle: l10n.turkishDescription,
            icon: Icons.translate_rounded,
            selected: settings.locale?.languageCode == 'tr',
            onTap: () => settings.setLocale(const Locale('tr')),
          ),
          const SizedBox(height: 28),
          Text(
            'Sesli okuma',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              leading: const Icon(Icons.bedtime_outlined),
              title: const Text(
                'Uyku zamanlayıcısı',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Dakika veya saat olarak özel süre belirle'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showSleepTimer(context),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.reading,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(
                l10n.rememberPosition,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(l10n.rememberPositionDescription),
              trailing: const Icon(Icons.check_circle_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSleepTimer(BuildContext context) async {
    final handler = QuranAudioService.instance.handler;
    final controller = TextEditingController(text: '30');
    var unit = AudioSleepTimerUnit.minutes;
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final active = handler.isSleepTimerActive;
          final remaining = handler.sleepTimerRemaining;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Uyku zamanlayıcısı',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    active
                        ? 'Aktif · yaklaşık ${formatAudioSleepTimerRemaining(remaining)} kaldı'
                        : 'Süre dolunca ses arka planda veya ekran kilitliyken de duraklatılır.',
                    style: TextStyle(
                      color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Süre',
                      hintText: unit == AudioSleepTimerUnit.minutes ? '30' : '1',
                      errorText: errorText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<AudioSleepTimerUnit>(
                    segments: const [
                      ButtonSegment(
                        value: AudioSleepTimerUnit.minutes,
                        label: Text('Dakika'),
                        icon: Icon(Icons.timer_outlined),
                      ),
                      ButtonSegment(
                        value: AudioSleepTimerUnit.hours,
                        label: Text('Saat'),
                        icon: Icon(Icons.schedule_rounded),
                      ),
                    ],
                    selected: {unit},
                    onSelectionChanged: (selection) {
                      setSheetState(() {
                        unit = selection.single;
                        errorText = null;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () {
                      final duration = parseAudioSleepTimerDuration(
                        controller.text,
                        unit,
                      );
                      if (duration == null) {
                        setSheetState(() {
                          errorText = unit == AudioSleepTimerUnit.minutes
                              ? '1-1440 dakika arasında bir değer girin.'
                              : '1-24 saat arasında bir değer girin.';
                        });
                        return;
                      }
                      handler.startSleepTimer(duration);
                      HapticFeedback.selectionClick();
                      setSheetState(() => errorText = null);
                    },
                    icon: const Icon(Icons.bedtime_rounded),
                    label: Text(active ? 'Süreyi değiştir' : 'Zamanlayıcıyı başlat'),
                  ),
                  if (active) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        handler.cancelSleepTimer();
                        HapticFeedback.selectionClick();
                        setSheetState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Zamanlayıcıyı kapat'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );

    controller.dispose();
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 27),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
