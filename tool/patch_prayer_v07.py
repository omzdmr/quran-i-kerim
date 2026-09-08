from pathlib import Path
import re

path = Path('lib/src/features/prayer/presentation/prayer_screen.dart')
text = path.read_text(encoding='utf-8')
original = text


def replace_once(old: str, new: str, label: str) -> None:
    global text
    if old not in text:
        raise SystemExit(f'{label}: source block not found')
    text = text.replace(old, new, 1)


replace_once(
    "import 'package:shared_preferences/shared_preferences.dart';\n",
    '',
    'remove direct shared preferences import',
)
replace_once(
    "import '../application/prayer_calculator.dart';\nimport '../domain/prayer_models.dart';\n",
    "import '../application/prayer_calculator.dart';\n"
    "import '../application/prayer_preferences_store.dart';\n"
    "import '../domain/prayer_city_catalog.dart';\n"
    "import '../domain/prayer_models.dart';\n"
    "import 'prayer_city_picker.dart';\n"
    "import 'prayer_settings_screen.dart';\n",
    'add prayer feature imports',
)
replace_once(
    "  static const _cityKey = 'prayer_city_id';\n\n"
    "  final PrayerCalculator _calculator = PrayerCalculator();\n"
    "  Timer? _timer;\n"
    "  _PrayerCity _city = _prayerCities.first;\n"
    "  bool _showTomorrow = false;\n",
    "  final PrayerCalculator _calculator = PrayerCalculator();\n"
    "  Timer? _timer;\n"
    "  PrayerCity _city = prayerCities.first;\n"
    "  PrayerSettingsSnapshot _prayerSettings = const PrayerSettingsSnapshot();\n"
    "  bool _showTomorrow = false;\n",
    'replace prayer state fields',
)
replace_once('    _restoreCity();\n', '    _restoreState();\n', 'restore state call')

restore_pattern = re.compile(
    r"  Future<void> _restoreCity\(\) async \{.*?\n  \}\n\n  PrayerDaySchedule _scheduleFor",
    re.S,
)
restore_replacement = """  Future<void> _restoreState() async {
    final cityId = await PrayerPreferencesStore.loadCityId();
    final settings = await PrayerPreferencesStore.load();
    if (!mounted) return;
    setState(() {
      _city = prayerCityById(cityId);
      _prayerSettings = settings;
    });
  }

  PrayerDaySchedule _scheduleFor"""
text, count = restore_pattern.subn(restore_replacement, text, count=1)
if count != 1:
    raise SystemExit('restore state method not patched')

replace_once(
    '      preferences: PrayerPreferences(calculationMethod: _city.method),\n',
    '      preferences: _prayerSettings.preferencesFor(_city.defaultMethod),\n',
    'main schedule preferences',
)

picker_pattern = re.compile(
    r"  Future<void> _pickCity\(\) async \{.*?\n  \}\n\n  @override\n  Widget build",
    re.S,
)
picker_replacement = """  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<PrayerCity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => PrayerCityPicker(selectedCityId: _city.id),
    );

    if (picked == null || !mounted) return;
    await PrayerPreferencesStore.saveCityId(picked.id);
    if (!mounted) return;
    setState(() {
      _city = picked;
      _showTomorrow = false;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _openPrayerSettings() async {
    final updated = await Navigator.of(context).push<PrayerSettingsSnapshot>(
      MaterialPageRoute(
        builder: (_) => PrayerSettingsScreen(
          city: _city,
          initial: _prayerSettings,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _prayerSettings = updated);
  }

  @override
  Widget build"""
text, count = picker_pattern.subn(picker_replacement, text, count=1)
if count != 1:
    raise SystemExit('city picker method not patched')

replace_once(
    "        actions: [\n          IconButton(\n            onPressed: _pickCity,",
    "        actions: [\n"
    "          IconButton(\n"
    "            onPressed: _openPrayerSettings,\n"
    "            icon: const Icon(Icons.tune_rounded),\n"
    "            tooltip: 'Namaz ayarları',\n"
    "          ),\n"
    "          IconButton(\n"
    "            onPressed: _pickCity,",
    'add settings app bar action',
)
text = text.replace('_city.region', '_city.country')
replace_once(
    'builder: (_) => MonthlyPrayerTimesScreen(city: _city),',
    'builder: (_) => MonthlyPrayerTimesScreen(\n'
    '                        city: _city,\n'
    '                        settings: _prayerSettings,\n'
    '                      ),',
    'monthly screen settings argument',
)
replace_once(
    "Vakitler cihazda hesaplanır; günlük internet bağlantısı gerekmez. Şehir ve hesaplama yöntemi sonraki ayarlarda daha ayrıntılı özelleştirilecek.",
    "Vakitler cihazda hesaplanır; günlük internet gerekmez. Hesaplama yöntemi, İkindi tercihi, yüksek enlem kuralı ve dakika düzeltmeleri ayarlardan değiştirilebilir.",
    'prayer info text',
)

replace_once(
    "class MonthlyPrayerTimesScreen extends StatefulWidget {\n"
    "  const MonthlyPrayerTimesScreen({required this.city, super.key});\n\n"
    "  final _PrayerCity city;\n",
    "class MonthlyPrayerTimesScreen extends StatefulWidget {\n"
    "  const MonthlyPrayerTimesScreen({\n"
    "    required this.city,\n"
    "    required this.settings,\n"
    "    super.key,\n"
    "  });\n\n"
    "  final PrayerCity city;\n"
    "  final PrayerSettingsSnapshot settings;\n",
    'monthly public city type and settings',
)
replace_once(
    "class _MonthlyPrayerTimesScreenState extends State<MonthlyPrayerTimesScreen> {\n"
    "  final PrayerCalculator _calculator = PrayerCalculator();\n"
    "  late DateTime _month;\n",
    "class _MonthlyPrayerTimesScreenState extends State<MonthlyPrayerTimesScreen> {\n"
    "  final PrayerCalculator _calculator = PrayerCalculator();\n"
    "  late DateTime _month;\n"
    "  String _filter = 'all';\n",
    'monthly filter state',
)
replace_once(
    "          preferences: PrayerPreferences(\n"
    "            calculationMethod: widget.city.method,\n"
    "          ),\n",
    "          preferences: widget.settings.preferencesFor(\n"
    "            widget.city.defaultMethod,\n"
    "          ),\n",
    'monthly calculation preferences',
)

replace_once(
    "          const Divider(height: 1),\n"
    "          Expanded(\n"
    "            child: ListView.separated(\n",
    "          const Divider(height: 1),\n"
    "          SizedBox(\n"
    "            height: 52,\n"
    "            child: ListView(\n"
    "              scrollDirection: Axis.horizontal,\n"
    "              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),\n"
    "              children: [\n"
    "                for (final option in const [\n"
    "                  ('all', 'Tümü'),\n"
    "                  ('fajr', 'İmsak'),\n"
    "                  ('sunrise', 'Güneş'),\n"
    "                  ('dhuhr', 'Öğle'),\n"
    "                  ('asr', 'İkindi'),\n"
    "                  ('maghrib', 'Akşam'),\n"
    "                  ('isha', 'Yatsı'),\n"
    "                ]) ...[\n"
    "                  ChoiceChip(\n"
    "                    label: Text(option.$2),\n"
    "                    selected: _filter == option.$1,\n"
    "                    onSelected: (_) {\n"
    "                      setState(() => _filter = option.$1);\n"
    "                      HapticFeedback.selectionClick();\n"
    "                    },\n"
    "                  ),\n"
    "                  const SizedBox(width: 7),\n"
    "                ],\n"
    "              ],\n"
    "            ),\n"
    "          ),\n"
    "          const Divider(height: 1),\n"
    "          Expanded(\n"
    "            child: ListView.separated(\n",
    'monthly filter chips',
)
replace_once(
    'return _MonthlyDayCard(schedule: schedule);',
    'return _MonthlyDayCard(schedule: schedule, filter: _filter);',
    'monthly card filter argument',
)
replace_once(
    "class QiblaInfoScreen extends StatelessWidget {\n"
    "  const QiblaInfoScreen({\n"
    "    required this.city,\n"
    "    required this.qiblaDegrees,\n"
    "    super.key,\n"
    "  });\n\n"
    "  final _PrayerCity city;\n",
    "class QiblaInfoScreen extends StatelessWidget {\n"
    "  const QiblaInfoScreen({\n"
    "    required this.city,\n"
    "    required this.qiblaDegrees,\n"
    "    super.key,\n"
    "  });\n\n"
    "  final PrayerCity city;\n",
    'qibla city public type',
)
replace_once(
    "class _MonthlyDayCard extends StatelessWidget {\n"
    "  const _MonthlyDayCard({required this.schedule});\n\n"
    "  final PrayerDaySchedule schedule;\n",
    "class _MonthlyDayCard extends StatelessWidget {\n"
    "  const _MonthlyDayCard({required this.schedule, required this.filter});\n\n"
    "  final PrayerDaySchedule schedule;\n"
    "  final String filter;\n",
    'monthly card filter field',
)
replace_once(
    '    final rows = schedule.rows;\n',
    "    final rows = filter == 'all'\n"
    "        ? schedule.rows\n"
    "        : schedule.rows.where((row) => row.id == filter).toList();\n",
    'monthly row filter logic',
)

private_catalog_pattern = re.compile(
    r"\nclass _PrayerCity \{.*?\nconst _months = <String>\[",
    re.S,
)
text, count = private_catalog_pattern.subn("\nconst _months = <String>[", text, count=1)
if count != 1:
    raise SystemExit('private city catalog not removed')

if text == original:
    raise SystemExit('no prayer screen changes made')
path.write_text(text, encoding='utf-8')
print('Prayer screen patched for regional cities, settings and monthly filters.')
