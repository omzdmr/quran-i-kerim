#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
widget = (root / "PrayerWidget" / "PrayerWidget.swift").read_text(encoding="utf-8")
locales = ("en", "tr", "ar", "az", "ru", "fr")
required = {
    "PrayerNameFajr", "PrayerNameSunrise", "PrayerNameDhuhr", "PrayerNameAsr",
    "PrayerNameMaghrib", "PrayerNameIsha", "PrayerNameImsak", "PrayerNameGeneric",
}

for locale in locales:
    path = root / "PrayerWidget" / f"{locale}.lproj" / "Localizable.strings"
    text = path.read_text(encoding="utf-8")
    keys = set(re.findall(r'^\s*"((?:\\.|[^"\\])+)"\s*=', text, flags=re.MULTILINE))
    missing = sorted(required - keys)
    if missing:
        raise SystemExit(f"{locale}: missing prayer-name keys: {', '.join(missing)}")

# Keep raw schedule identifiers out of the UI. The resolver deliberately maps aliases
# to localization keys and has a generic localized fallback for unknown identifiers.
aliases = {
    "fajr": "PrayerNameFajr",
    "sunrise": "PrayerNameSunrise", "shuruq": "PrayerNameSunrise",
    "dhuhr": "PrayerNameDhuhr", "zuhr": "PrayerNameDhuhr",
    "asr": "PrayerNameAsr",
    "maghrib": "PrayerNameMaghrib",
    "isha": "PrayerNameIsha",
    "imsak": "PrayerNameImsak",
}
for alias, key in aliases.items():
    if f'case "{alias}"' not in widget and f', "{alias}"' not in widget:
        raise SystemExit(f"widget resolver contract missing alias {alias}")
    if f'key = "{key}"' not in widget:
        raise SystemExit(f"widget resolver contract missing localization key {key}")

if 'default: key = "PrayerNameGeneric"' not in widget:
    raise SystemExit("unknown prayer IDs must use PrayerNameGeneric, never raw IDs")
if 'String(localized: String.LocalizationValue(key), table: "Localizable")' not in widget:
    raise SystemExit("prayer-name resolver must resolve through the native localization table")

print("Widget localized prayer-name contract OK")
