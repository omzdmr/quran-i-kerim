#!/usr/bin/env python3
import pathlib, plistlib, re, sys

project = pathlib.Path('ios/Runner.xcodeproj/project.pbxproj')
s = project.read_text()
ids = set(re.findall(r'^\s*([A-Za-z0-9]{24})\s+/\*', s, re.M))
bad = sorted(x for x in ids if not re.fullmatch(r'[0-9A-F]{24}', x))
errors = []
if bad:
    errors.append('non-hex PBX object IDs: ' + ', '.join(bad))

for required in ['PrayerWidget.swift in Sources', 'PrayerWidget.appex in Embed App Extensions', 'PrayerWidget/PrayerWidget.entitlements']:
    if required not in s:
        errors.append('missing project graph contract: ' + required)

if s.count('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;') < 3:
    errors.append('Runner entitlements must be wired for Debug, Release and Profile')
if s.count('CODE_SIGN_ENTITLEMENTS = PrayerWidget/PrayerWidget.entitlements;') < 3:
    errors.append('PrayerWidget entitlements must be wired for Debug, Release and Profile')

widget_privacy = pathlib.Path('ios/PrayerWidget/PrivacyInfo.xcprivacy')
if widget_privacy.exists() and 'PrivacyInfo.xcprivacy in Resources' not in s:
    errors.append('PrayerWidget PrivacyInfo.xcprivacy is not referenced by the widget Resources phase')

app_group = 'group.app.quranikerim.shared'
for entitlement_path in ['ios/Runner/Runner.entitlements', 'ios/PrayerWidget/PrayerWidget.entitlements']:
    path = pathlib.Path(entitlement_path)
    try:
        payload = plistlib.loads(path.read_bytes())
        groups = payload.get('com.apple.security.application-groups', [])
        if app_group not in groups:
            errors.append(f'{entitlement_path} is missing shared App Group {app_group}')
    except Exception as exc:
        errors.append(f'cannot parse {entitlement_path}: {exc}')

if errors:
    print('\n'.join('ERROR: ' + e for e in errors), file=sys.stderr)
    raise SystemExit(1)
print('Xcode project graph validation passed')
