import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../navigation/app_navigation.dart';
import '../../settings/app_settings.dart';
import '../discover/dhikr_counter_screen.dart';
import '../prayer/presentation/prayer_screen.dart';
import '../prayer/presentation/qibla_launcher_screen.dart';
import '../profile/downloads_screen.dart';
import '../settings/settings_screen.dart';

class HomeQuickActionsSection extends StatelessWidget {
  const HomeQuickActionsSection({super.key});

  String _labelFor(BuildContext context, HomeQuickAction action) {
    final l10n = context.l10n;
    return switch (action) {
      HomeQuickAction.quran => l10n.navQuran,
      HomeQuickAction.prayer => l10n.prayerTimes,
      HomeQuickAction.qibla => l10n.text('qibla'),
      HomeQuickAction.dhikr => l10n.text('dhikrCounter'),
      HomeQuickAction.plans => l10n.navPlans,
      HomeQuickAction.downloads => l10n.downloads,
      HomeQuickAction.discover => l10n.navDiscover,
      HomeQuickAction.settings => l10n.settings,
    };
  }

  IconData _iconFor(HomeQuickAction action) => switch (action) {
    HomeQuickAction.quran => Icons.menu_book_rounded,
    HomeQuickAction.prayer => Icons.schedule_rounded,
    HomeQuickAction.qibla => Icons.explore_rounded,
    HomeQuickAction.dhikr => Icons.touch_app_rounded,
    HomeQuickAction.plans => Icons.library_add_check_rounded,
    HomeQuickAction.downloads => Icons.download_done_rounded,
    HomeQuickAction.discover => Icons.search_rounded,
    HomeQuickAction.settings => Icons.settings_rounded,
  };

  void _activate(BuildContext context, HomeQuickAction action) {
    HapticFeedback.selectionClick();
    switch (action) {
      case HomeQuickAction.quran:
        AppNavigation.instance.openQuran();
      case HomeQuickAction.prayer:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PrayerScreen()),
        );
      case HomeQuickAction.qibla:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const QiblaLauncherScreen()),
        );
      case HomeQuickAction.dhikr:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DhikrCounterScreen()),
        );
      case HomeQuickAction.plans:
        AppNavigation.instance.openPlans();
      case HomeQuickAction.downloads:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DownloadsScreen()),
        );
      case HomeQuickAction.discover:
        AppNavigation.instance.openDiscover();
      case HomeQuickAction.settings:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
        );
    }
  }

  Future<void> _edit(BuildContext context, AppSettings settings) async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _QuickActionEditor(settings: settings),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.text('homeQuickActionsTitle'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.text('homeQuickActionsSubtitle'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _edit(context, settings),
              icon: const Icon(Icons.tune_rounded, size: 19),
              label: Text(l10n.text('homeQuickActionsEdit')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final columns = largeText ? 2 : 3;
            final width =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final action in settings.homeQuickActions)
                  SizedBox(
                    width: width,
                    child: _QuickActionTile(
                      icon: _iconFor(action),
                      label: _labelFor(context, action),
                      onTap: () => _activate(context, action),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 94),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: scheme.primary, size: 28),
                  const SizedBox(height: 9),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionEditor extends StatefulWidget {
  const _QuickActionEditor({required this.settings});

  final AppSettings settings;

  @override
  State<_QuickActionEditor> createState() => _QuickActionEditorState();
}

class _QuickActionEditorState extends State<_QuickActionEditor> {
  late final List<HomeQuickAction> _selected;
  bool _saving = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.settings.homeQuickActions.toList(growable: true);
  }

  String _labelFor(HomeQuickAction action) {
    final l10n = context.l10n;
    return switch (action) {
      HomeQuickAction.quran => l10n.navQuran,
      HomeQuickAction.prayer => l10n.prayerTimes,
      HomeQuickAction.qibla => l10n.text('qibla'),
      HomeQuickAction.dhikr => l10n.text('dhikrCounter'),
      HomeQuickAction.plans => l10n.navPlans,
      HomeQuickAction.downloads => l10n.downloads,
      HomeQuickAction.discover => l10n.navDiscover,
      HomeQuickAction.settings => l10n.settings,
    };
  }

  IconData _iconFor(HomeQuickAction action) => switch (action) {
    HomeQuickAction.quran => Icons.menu_book_rounded,
    HomeQuickAction.prayer => Icons.schedule_rounded,
    HomeQuickAction.qibla => Icons.explore_rounded,
    HomeQuickAction.dhikr => Icons.touch_app_rounded,
    HomeQuickAction.plans => Icons.library_add_check_rounded,
    HomeQuickAction.downloads => Icons.download_done_rounded,
    HomeQuickAction.discover => Icons.search_rounded,
    HomeQuickAction.settings => Icons.settings_rounded,
  };

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    final saved = await widget.settings.setHomeQuickActions(_selected);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _saveFailed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text('homeQuickActionsCustomizeTitle'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.text('homeQuickActionsCustomizeBody'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n
                .text('homeQuickActionsSelectedCount')
                .replaceAll('{count}', '${_selected.length}'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final action in HomeQuickAction.values)
                  Builder(
                    builder: (context) {
                      final selected = _selected.contains(action);
                      final canToggle = selected
                          ? _selected.length > minHomeQuickActions
                          : _selected.length < maxHomeQuickActions;
                      return CheckboxListTile(
                        value: selected,
                        onChanged: canToggle
                            ? (checked) {
                                setState(() {
                                  _saveFailed = false;
                                  if (checked == true) {
                                    _selected.add(action);
                                  } else {
                                    _selected.remove(action);
                                  }
                                });
                              }
                            : null,
                        secondary: Icon(_iconFor(action)),
                        title: Text(_labelFor(action)),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  ),
              ],
            ),
          ),
          if (_saveFailed) ...[
            const SizedBox(height: 6),
            Text(
              l10n.text('homeQuickActionsSaveFailed'),
              style: TextStyle(color: scheme.error),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.text('homeQuickActionsCancel')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.text('homeQuickActionsSave')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
