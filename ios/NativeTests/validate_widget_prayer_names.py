#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
widget = (root / "PrayerWidget" / "PrayerWidget.swift").read_text(encoding="utf-8")
store = (root / "Runner" / "WidgetSnapshotStore.swift").read_text(encoding="utf-8")
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

# Producer and WidgetKit consumer must read the same App Group key and schema fields.
store_key = re.search(r'snapshotKey\s*=\s*"([^"]+)"', store)
widget_key = re.search(r'payloadKey\s*=\s*"([^"]+)"', widget)
if not store_key or not widget_key or store_key.group(1) != widget_key.group(1):
    raise SystemExit("Runner/WidgetKit snapshot keys diverged")
for field in ("version", "generatedAt", "validUntil", "timeZoneIdentifier", "calculationFingerprint", "nextPrayerID", "nextPrayerAt", "displayName", "privacyMode"):
    if re.search(rf'\blet\s+{field}\s*:', widget) is None:
        raise SystemExit(f"WidgetKit snapshot decoder missing producer field: {field}")
if 'dateEncodingStrategy = .millisecondsSince1970' not in store:
    raise SystemExit("Runner snapshot date encoding contract changed")
if 'let generatedAt: Double' not in widget or 'let validUntil: Double' not in widget or 'let nextPrayerAt: Double?' not in widget:
    raise SystemExit("WidgetKit must decode persisted millisecond dates as numeric values")
if 'timeZoneIdentifier == currentTimeZone.identifier' not in widget or 'currentTimeZone: TimeZone = .autoupdatingCurrent' not in widget:
    raise SystemExit("WidgetKit must reject snapshots from another time zone while keeping freshness testable")
if 'snapshot.isRedacted' not in widget:
    raise SystemExit("WidgetKit must honor the persisted privacy redaction mode")

print("Widget canonical prayer-name and persisted snapshot bridge contract OK")
