#!/usr/bin/env python3
import pathlib, re, sys

locales = ['en', 'tr', 'ar', 'az', 'ru', 'fr']
pattern = re.compile(r'^\s*"((?:\\.|[^"\\])*)"\s*=\s*"((?:\\.|[^"\\])*)"\s*;\s*$', re.M)
errors = []


def validate_table(root: pathlib.Path, filename: str, label: str, required: set[str]) -> None:
    parsed = {}
    for locale in locales:
        path = root / f'{locale}.lproj' / filename
        if not path.exists():
            errors.append(f'{label}/{locale}: {filename} missing')
            continue
        pairs = pattern.findall(path.read_text(encoding='utf-8'))
        values = {}
        for key, value in pairs:
            if key in values:
                errors.append(f'{label}/{locale}: duplicate key {key!r}')
            values[key] = value
            if not value.strip():
                errors.append(f'{label}/{locale}: empty value for {key!r}')
        parsed[locale] = values

    if 'en' not in parsed:
        return
    canonical = set(parsed['en'])
    missing_required = required - canonical
    if missing_required:
        errors.append(f'{label}/en: required keys missing: ' + ', '.join(sorted(missing_required)))
    for locale, values in parsed.items():
        missing = canonical - set(values)
        extra = set(values) - canonical
        if missing:
            errors.append(f'{label}/{locale}: missing keys: ' + ', '.join(sorted(missing)))
        if extra:
            errors.append(f'{label}/{locale}: unexpected keys: ' + ', '.join(sorted(extra)))


validate_table(
    pathlib.Path('ios/PrayerWidget'), 'Localizable.strings', 'widget',
    {
        'Prayer', 'Prayer Times', 'Shows the next prayer from your on-device schedule.',
        'Time remaining', 'Prayer times hidden', 'Prayer times hidden for privacy',
        'Open app to refresh', 'Prayer information needs to be refreshed in the app',
        'Location changed', 'Prayer times need refresh after a time zone change',
        'Prayer times need refresh', 'Prayer information is out of date. Open the app to refresh',
        'Prayer information cannot be shown safely. Open the app to refresh',
    },
)
validate_table(
    pathlib.Path('ios/Runner'), 'InfoPlist.strings', 'runner',
    {
        'CFBundleDisplayName', 'NSLocationWhenInUseUsageDescription', 'NSMicrophoneUsageDescription',
        'NotificationSelfTestTitle', 'NotificationSelfTestBody',
    },
)

if errors:
    print('\n'.join('ERROR: ' + item for item in errors), file=sys.stderr)
    raise SystemExit(1)
print('Native localization parity validation passed for ' + ', '.join(locales))
