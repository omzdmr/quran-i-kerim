#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
widget = (root / "PrayerWidget" / "PrayerWidget.swift").read_text(encoding="utf-8")
locales = ("en", "tr", "ar", "az", "ru", "fr")
required = {"Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"}

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
    needle = f'"{alias}"'
    if needle not in widget or f'key = "{canonical}"' not in widget:
        raise SystemExit(f"widget resolver contract missing {alias} -> {canonical}")

if "displayName?.trimmingCharacters" not in widget:
    raise SystemExit("widget must reject blank displayName before canonical fallback")
if 'default: return String(localized: "Prayer")' not in widget:
    raise SystemExit("unknown prayer IDs must use a localized generic fallback, never raw IDs")

print("Widget canonical prayer-name contract OK")
