#!/usr/bin/env python3
import pathlib, re, sys

root = pathlib.Path('ios/PrayerWidget')
locales = ['en', 'tr', 'ar', 'az', 'ru', 'fr']
pattern = re.compile(r'^\s*"((?:\\.|[^"\\])*)"\s*=\s*"((?:\\.|[^"\\])*)"\s*;\s*$', re.M)
required = {
    'Prayer', 'Prayer Times', 'Shows the next prayer from your on-device schedule.',
    'Time remaining', 'Prayer times hidden', 'Prayer times hidden for privacy',
    'Open app to refresh', 'Prayer information needs to be refreshed in the app',
    'Location changed', 'Prayer times need refresh after a time zone change',
    'Prayer times need refresh', 'Prayer information is out of date. Open the app to refresh',
    'Prayer information cannot be shown safely. Open the app to refresh',
}

errors = []
parsed = {}
for locale in locales:
    path = root / f'{locale}.lproj' / 'Localizable.strings'
    if not path.exists():
        errors.append(f'{locale}: Localizable.strings missing')
        continue
    text = path.read_text(encoding='utf-8')
    pairs = pattern.findall(text)
    values = {}
    for key, value in pairs:
        if key in values:
            errors.append(f'{locale}: duplicate key {key!r}')
        values[key] = value
        if not value.strip():
            errors.append(f'{locale}: empty value for {key!r}')
    parsed[locale] = values

if 'en' in parsed:
    canonical = set(parsed['en'])
    missing_required = required - canonical
    if missing_required:
        errors.append('en: required widget keys missing: ' + ', '.join(sorted(missing_required)))
    for locale, values in parsed.items():
        missing = canonical - set(values)
        extra = set(values) - canonical
        if missing:
            errors.append(f'{locale}: missing keys: ' + ', '.join(sorted(missing)))
        if extra:
            errors.append(f'{locale}: unexpected keys: ' + ', '.join(sorted(extra)))

if errors:
    print('\n'.join('ERROR: ' + item for item in errors), file=sys.stderr)
    raise SystemExit(1)
print('Widget localization parity validation passed for ' + ', '.join(locales))
