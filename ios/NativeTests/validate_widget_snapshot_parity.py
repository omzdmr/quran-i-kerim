#!/usr/bin/env python3
from pathlib import Path

runner = Path("ios/Runner/WidgetSnapshotStore.swift").read_text()
widget = Path("ios/PrayerWidget/PrayerWidget.swift").read_text()

checks = {
    "schema version": ("static let schemaVersion = 1", runner, widget),
    "snapshot key": ('static let snapshotKey = "widget.prayer.snapshot.v1"', runner, None),
    "extension snapshot key": ('static let payloadKey = "widget.prayer.snapshot.v1"', widget, None),
    "generated before expiry": ("generatedAt < validUntil", runner, widget),
    "timezone identifier validity": ("TimeZone(identifier: timeZoneIdentifier) != nil", runner, widget),
    "nonblank policy fingerprint": ("!calculationFingerprint.trimmingCharacters", runner, widget),
    "paired prayer id/time": ("hasPrayerID == hasPrayerTime", runner, widget),
    "prayer after generation": ("$0 > generatedAt", runner, widget),
    "prayer within validity": ("$0 <= validUntil", runner, widget),
    "future generation rejection": ("generatedAt <=", runner, widget),
    "expiry rejection": ("validUntil", runner, widget),
    "timezone drift rejection": ("timeZoneIdentifier ==", runner, widget),
    "prayer boundary rejection": ("nextPrayerAt <=", runner, widget),
}

failed = []
for name, (needle, first, second) in checks.items():
    if needle not in first or (second is not None and needle not in second):
        failed.append(f"{name}: missing {needle!r}")

for needle in (
    "result.freshness != nil",
    "5 * 60",
    "freshness == .fresh ? snapshot : nil",
    'privacyMode == "standard" || privacyMode == "redacted"',
):
    if needle not in widget:
        failed.append(f"extension retry/fail-closed contract missing {needle!r}")

for needle in (
    ".accessoryInline",
    "private func inline(id: String, at: Double)",
    'Text("\\(localizedPrayerName(id)) · \\(time(at))")',
    'family == .accessoryInline',
    'Image(systemName: "lock.fill")',
    'Image(systemName: "arrow.clockwise")',
    "private var isAccessoryFamily: Bool",
):
    if needle not in widget:
        failed.append(f"Lock Screen accessory contract missing {needle!r}")

if failed:
    raise SystemExit("Widget snapshot parity validation failed:\n- " + "\n- ".join(failed))

print("Widget snapshot parity validation passed")
