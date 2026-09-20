import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/translation_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/app_settings.dart';
import '../profile/downloads_screen.dart';
import 'backup_settings_screen.dart';
import 'quran_translation_catalog_screen.dart';

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
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              showSearch<void>(
                context: context,
                delegate: _SettingsSearchDelegate(
                  settings: settings,
                  l10n: l10n,
                  rootContext: context,
                ),
              );
            },
            icon: const Icon(Icons.search_rounded),
            tooltip: l10n.settings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _SectionHeader(
            title: l10n.appearance,
            description: l10n.appearanceDescription,
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
          _SectionHeader(
            title: l10n.language,
            description: l10n.languageDescription,
          ),
          const SizedBox(height: 18),
          _ChoiceTile(
            title: l10n.useDeviceLanguage,
            subtitle: l10n.useDeviceLanguageDescription,
            icon: Icons.language_rounded,
            selected: settings.locale == null,
            onTap: () {
              HapticFeedback.selectionClick();
              settings.setLocale(null);
            },
          ),
          _LanguageChoiceTile(
            code: 'TR',
            title: l10n.turkish,
            subtitle: l10n.turkishDescription,
            selected: settings.locale?.languageCode == 'tr',
            onTap: () => settings.setLocale(const Locale('tr')),
          ),
          _LanguageChoiceTile(
            code: 'EN',
            title: l10n.english,
            subtitle: l10n.englishDescription,
            selected: settings.locale?.languageCode == 'en',
            onTap: () => settings.setLocale(const Locale('en')),
          ),
          _LanguageChoiceTile(
            code: 'AR',
            title: l10n.arabic,
            subtitle: l10n.arabicDescription,
            selected: settings.locale?.languageCode == 'ar',
            onTap: () => settings.setLocale(const Locale('ar')),
          ),
          _LanguageChoiceTile(
            code: 'AZ',
            title: l10n.azerbaijani,
            subtitle: l10n.azerbaijaniDescription,
            selected: settings.locale?.languageCode == 'az',
            onTap: () => settings.setLocale(const Locale('az')),
          ),
          _LanguageChoiceTile(
            code: 'RU',
            title: l10n.russian,
            subtitle: l10n.russianDescription,
            selected: settings.locale?.languageCode == 'ru',
            onTap: () => settings.setLocale(const Locale('ru')),
          ),
          const SizedBox(height: 30),
          _SectionHeader(
            title: l10n.quranLanguage,
            description: l10n.quranLanguageDescription,
          ),
          const SizedBox(height: 18),
          _ChoiceTile(
            title: l10n.turkishMeal,
            subtitle: l10n.turkishMealDescription,
            icon: Icons.translate_rounded,
            trailingLabel: 'RWD',
            selected:
                settings.selectedQuranSourceId == bundledTurkishTranslationId,
            onTap: () {
              HapticFeedback.selectionClick();
              settings.setSelectedQuranSource(bundledTurkishTranslationId);
            },
          ),
          _ChoiceTile(
            title: l10n.arabicOriginal,
            subtitle: l10n.arabicOriginalDescription,
            icon: Icons.menu_book_rounded,
            trailingLabel: 'AR',
            selected: settings.selectedQuranSourceId == arabicOriginalSourceId,
            onTap: () {
              HapticFeedback.selectionClick();
              settings.setSelectedQuranSource(arabicOriginalSourceId);
            },
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.download_for_offline_outlined,
                  color: scheme.primary,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    l10n.moreTranslationsSoon,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const QuranTranslationCatalogScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.travel_explore_rounded),
              label: Text(l10n.languageAndTranslation),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DownloadsScreen(),
                ),
              ),
              icon: const Icon(Icons.download_done_rounded),
              label: Text(l10n.downloads),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BackupSettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.cloud_sync_outlined),
              label: Text(l10n.text('backupTitle')),
            ),
          ),
          const SizedBox(height: 30),
          _SectionHeader(title: l10n.reading),
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
}

class _SettingsSearchEntry {
  const _SettingsSearchEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.keywords = const <String>[],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final List<String> keywords;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return <String>[title, subtitle, ...keywords]
        .any((value) => value.toLowerCase().contains(normalized));
  }
}

class _SettingsSearchDelegate extends SearchDelegate<void> {
  _SettingsSearchDelegate({
    required this.settings,
    required this.l10n,
    required this.rootContext,
  }) : super(searchFieldLabel: l10n.settings);

  final AppSettings settings;
  final AppLocalizations l10n;
  final BuildContext rootContext;

  List<_SettingsSearchEntry> get _entries => <_SettingsSearchEntry>[
        _SettingsSearchEntry(
          title: l10n.useDeviceTheme,
          subtitle: l10n.useDeviceThemeDescription,
          icon: Icons.brightness_auto_rounded,
          selected: settings.themeMode == ThemeMode.system,
          keywords: <String>[l10n.appearance],
          onTap: () => settings.setThemeMode(ThemeMode.system),
        ),
        _SettingsSearchEntry(
          title: l10n.lightTheme,
          subtitle: l10n.lightThemeDescription,
          icon: Icons.light_mode_outlined,
          selected: settings.themeMode == ThemeMode.light,
          keywords: <String>[l10n.appearance],
          onTap: () => settings.setThemeMode(ThemeMode.light),
        ),
        _SettingsSearchEntry(
          title: l10n.darkTheme,
          subtitle: l10n.darkThemeDescription,
          icon: Icons.dark_mode_outlined,
          selected: settings.themeMode == ThemeMode.dark,
          keywords: <String>[l10n.appearance],
          onTap: () => settings.setThemeMode(ThemeMode.dark),
        ),
        _SettingsSearchEntry(
          title: l10n.useDeviceLanguage,
          subtitle: l10n.useDeviceLanguageDescription,
          icon: Icons.language_rounded,
          selected: settings.locale == null,
          keywords: <String>[l10n.language],
          onTap: () => settings.setLocale(null),
        ),
        _SettingsSearchEntry(
          title: l10n.turkish,
          subtitle: l10n.turkishDescription,
          icon: Icons.translate_rounded,
          selected: settings.locale?.languageCode == 'tr',
          keywords: <String>[l10n.language, 'TR'],
          onTap: () => settings.setLocale(const Locale('tr')),
        ),
        _SettingsSearchEntry(
          title: l10n.english,
          subtitle: l10n.englishDescription,
          icon: Icons.translate_rounded,
          selected: settings.locale?.languageCode == 'en',
          keywords: <String>[l10n.language, 'EN'],
          onTap: () => settings.setLocale(const Locale('en')),
        ),
        _SettingsSearchEntry(
          title: l10n.arabic,
          subtitle: l10n.arabicDescription,
          icon: Icons.translate_rounded,
          selected: settings.locale?.languageCode == 'ar',
          keywords: <String>[l10n.language, 'AR'],
          onTap: () => settings.setLocale(const Locale('ar')),
        ),
        _SettingsSearchEntry(
          title: l10n.azerbaijani,
          subtitle: l10n.azerbaijaniDescription,
          icon: Icons.translate_rounded,
          selected: settings.locale?.languageCode == 'az',
          keywords: <String>[l10n.language, 'AZ'],
          onTap: () => settings.setLocale(const Locale('az')),
        ),
        _SettingsSearchEntry(
          title: l10n.russian,
          subtitle: l10n.russianDescription,
          icon: Icons.translate_rounded,
          selected: settings.locale?.languageCode == 'ru',
          keywords: <String>[l10n.language, 'RU'],
          onTap: () => settings.setLocale(const Locale('ru')),
        ),
        _SettingsSearchEntry(
          title: l10n.turkishMeal,
          subtitle: l10n.turkishMealDescription,
          icon: Icons.menu_book_rounded,
          selected:
              settings.selectedQuranSourceId == bundledTurkishTranslationId,
          keywords: <String>[l10n.quranLanguage, l10n.languageAndTranslation],
          onTap: () =>
              settings.setSelectedQuranSource(bundledTurkishTranslationId),
        ),
        _SettingsSearchEntry(
          title: l10n.arabicOriginal,
          subtitle: l10n.arabicOriginalDescription,
          icon: Icons.menu_book_rounded,
          selected: settings.selectedQuranSourceId == arabicOriginalSourceId,
          keywords: <String>[l10n.quranLanguage, l10n.languageAndTranslation],
          onTap: () => settings.setSelectedQuranSource(arabicOriginalSourceId),
        ),
        _SettingsSearchEntry(
          title: l10n.languageAndTranslation,
          subtitle: l10n.quranLanguageDescription,
          icon: Icons.travel_explore_rounded,
          keywords: <String>[l10n.quranLanguage],
          onTap: () => Navigator.of(rootContext).push(
            MaterialPageRoute<void>(
              builder: (_) => const QuranTranslationCatalogScreen(),
            ),
          ),
        ),
        _SettingsSearchEntry(
          title: l10n.downloads,
          subtitle: l10n.downloadsDescription,
          icon: Icons.download_done_rounded,
          onTap: () => Navigator.of(rootContext).push(
            MaterialPageRoute<void>(
              builder: (_) => const DownloadsScreen(),
            ),
          ),
        ),
        _SettingsSearchEntry(
          title: l10n.text('backupTitle'),
          subtitle: l10n.text('backupDescription'),
          icon: Icons.cloud_sync_outlined,
          onTap: () => Navigator.of(rootContext).push(
            MaterialPageRoute<void>(
              builder: (_) => const BackupSettingsScreen(),
            ),
          ),
        ),
        _SettingsSearchEntry(
          title: l10n.rememberPosition,
          subtitle: l10n.rememberPositionDescription,
          icon: Icons.history_rounded,
          selected: true,
          keywords: <String>[l10n.reading],
          onTap: () {},
        ),
      ];

  @override
  List<Widget>? buildActions(BuildContext context) => <Widget>[
        if (query.isNotEmpty)
          IconButton(
            onPressed: () => query = '',
            icon: const Icon(Icons.close_rounded),
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        onPressed: () => close(context, null),
        icon: const BackButtonIcon(),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final matches = _entries.where((entry) => entry.matches(query)).toList();
    if (matches.isEmpty) {
      return Center(
        child: Icon(
          Icons.search_off_rounded,
          size: 44,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = matches[index];
        return ListTile(
          tileColor: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: Icon(entry.icon),
          title: Text(
            entry.title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(entry.subtitle),
          trailing: entry.selected
              ? Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              : const Icon(Icons.chevron_right_rounded),
          onTap: () {
            HapticFeedback.selectionClick();
            close(context, null);
            entry.onTap();
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description!,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
          ),
        ],
      ],
    );
  }
}

class _LanguageChoiceTile extends StatelessWidget {
  const _LanguageChoiceTile({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ChoiceTile(
      title: title,
      subtitle: subtitle,
      selected: selected,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      leading: _LanguageBadge(code: code, selected: selected),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({required this.code, required this.selected});

  final String code;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 42,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        code,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          color: selected ? scheme.onPrimary : scheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leading,
    this.trailingLabel,
  }) : assert(icon != null || leading != null);

  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;
  final String? trailingLabel;

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
                leading ?? Icon(icon, size: 27),
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
                if (trailingLabel != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      trailingLabel!,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
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
