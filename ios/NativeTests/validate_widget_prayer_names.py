#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
widget = (root / "PrayerWidget" / "PrayerWidget.swift").read_text(encoding="utf-8")
locales = ("en", "tr", "ar", "az", "ru", "fr")
required = {"Prayer", "Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"}

for locale in locales:
    path = root / "PrayerWidget" / f"{locale}.lproj" / "Localizable.strings"
    text = path.read_text(encoding="utf-8")
    keys = set(re.findall(r'^\s*"((?:\\.|[^"\\])+)"\s*=', text, flags=re.MULTILINE))
    missing = sorted(required - keys)
    if missing:
        raise SystemExit(f"{locale}: missing canonical prayer keys: {', '.join(missing)}")

aliases = {
    "fajr": "Fajr", "imsak": "Fajr",
    "sunrise": "Sunrise", "shuruq": "Sunrise", "shurooq": "Sunrise",
    "dhuhr": "Dhuhr", "zuhr": "Dhuhr", "noon": "Dhuhr",
    "asr": "Asr",
    "maghrib": "Maghrib", "sunset": "Maghrib",
    "isha": "Isha", "ishaa": "Isha",
}
for alias, canonical in aliases.items():
    if f'"{alias}"' not in widget:
        raise SystemExit(f"widget resolver contract missing alias {alias}")
    if f'key = "{canonical}"' not in widget:
        raise SystemExit(f"widget resolver contract missing {alias} -> {canonical}")

if 'default: return String(localized: "Prayer", table: "Localizable")' not in widget:
    raise SystemExit("unknown prayer IDs must use a localized generic fallback, never raw IDs")
if 'String(localized: String.LocalizationValue(key), table: "Localizable")' not in widget:
    raise SystemExit("canonical prayer names must resolve through the native localization table")

print("Widget canonical prayer-name contract OK")
