import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:quran_i_kerim/src/l10n/strings/home_quick_action_strings.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Home quick actions default to six useful destinations', () async {
    final settings = AppSettings();
    await settings.load();

    expect(settings.homeQuickActions, defaultHomeQuickActions);
    expect(settings.homeQuickActions.length, 6);
  });

  test('Home quick actions persist a valid four-to-six selection', () async {
    final settings = AppSettings();
    await settings.load();

    const selection = <HomeQuickAction>[
      HomeQuickAction.quran,
      HomeQuickAction.prayer,
      HomeQuickAction.plans,
      HomeQuickAction.settings,
    ];

    expect(await settings.setHomeQuickActions(selection), isTrue);
    expect(settings.homeQuickActions, selection);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('home_quick_actions_v1'),
      selection.map((action) => action.name).toList(),
    );

    final reloaded = AppSettings();
    await reloaded.load();
    expect(reloaded.homeQuickActions, selection);
  });

  test('invalid persisted quick actions fall back to the safe default', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'home_quick_actions_v1': <String>[
        'quran',
        'quran',
        'not-real',
        'prayer',
      ],
    });

    final settings = AppSettings();
    await settings.load();

    expect(settings.homeQuickActions, defaultHomeQuickActions);
  });

  test('setter rejects selections outside the four-to-six contract', () async {
    final settings = AppSettings();
    await settings.load();

    final before = settings.homeQuickActions.toList();

    expect(
      await settings.setHomeQuickActions(const <HomeQuickAction>[
        HomeQuickAction.quran,
        HomeQuickAction.prayer,
        HomeQuickAction.plans,
      ]),
      isFalse,
    );
    expect(settings.homeQuickActions, before);

    expect(
      await settings.setHomeQuickActions(HomeQuickAction.values),
      isFalse,
    );
    expect(settings.homeQuickActions, before);
  });

  test('Home quick actions survive sectioned backup and restore', () async {
    const selection = <String>[
      'quran',
      'qibla',
      'dhikr',
      'plans',
      'discover',
    ];
    SharedPreferences.setMockInitialValues(<String, Object>{
      'home_quick_actions_v1': selection,
    });

    const adapter = SharedPreferencesBackupAdapter();
    final sections = await adapter.captureSections();

    expect(
      (sections['preferences'] as Map)['home_quick_actions_v1'],
      selection,
    );

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await adapter.restoreSections(sections);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('home_quick_actions_v1'), selection);
  });

  test('Home quick-action strings have parity in every core locale', () {
    final expected = homeQuickActionStrings['tr']!.keys.toSet();

    expect(
      homeQuickActionStrings.keys,
      containsAll(<String>['tr', 'en', 'ar', 'az', 'ru']),
    );

    for (final entry in homeQuickActionStrings.entries) {
      expect(entry.value.keys.toSet(), expected, reason: entry.key);
      for (final value in entry.value.values) {
        expect(value.trim(), isNotEmpty, reason: entry.key);
      }
    }
  });
}
