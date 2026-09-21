#!/usr/bin/env python3
import pathlib, re, sys
p=pathlib.Path('ios/Runner.xcodeproj/project.pbxproj')
s=p.read_text()
ids=set(re.findall(r'^\s*([A-Za-z0-9]{24})\s+/\*',s,re.M))
bad=sorted(x for x in ids if not re.fullmatch(r'[0-9A-F]{24}',x))
errors=[]
if bad: errors.append('non-hex PBX object IDs: '+', '.join(bad))
for required in ['PrayerWidget.swift in Sources','PrayerWidget.appex in Embed App Extensions','PrayerWidget/PrayerWidget.entitlements']:
    if required not in s: errors.append('missing project graph contract: '+required)
# PrivacyInfo.xcprivacy must be a widget target resource before App Store landing.
widget_privacy=pathlib.Path('ios/PrayerWidget/PrivacyInfo.xcprivacy')
if widget_privacy.exists() and 'PrayerWidget/PrivacyInfo.xcprivacy' not in s and 'PrivacyInfo.xcprivacy in Resources' not in s:
    errors.append('PrayerWidget PrivacyInfo.xcprivacy is not referenced by the Xcode graph')
if errors:
    print('\n'.join('ERROR: '+e for e in errors), file=sys.stderr)
    raise SystemExit(1)
print('Xcode project graph validation passed')
