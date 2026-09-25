from pathlib import Path

runner_attrs = Path("ios/Runner/PrayerActivityAttributes.swift").read_text()
widget_attrs = Path("ios/PrayerWidget/PrayerActivityAttributes.swift").read_text()
channel = Path("ios/Runner/PrayerLiveActivityChannel.swift").read_text()
widget = Path("ios/PrayerWidget/PrayerWidget.swift").read_text()
project = Path("ios/Runner.xcodeproj/project.pbxproj").read_text()
info = Path("ios/Runner/Info.plist").read_text()

assert runner_attrs == widget_attrs, "Runner and widget ActivityAttributes drifted"
required_channel = ['native_prayer_live_activity','ActivityAuthorizationInfo().areActivitiesEnabled','Activity<PrayerActivityAttributes>.request','case "start"','case "update"','case "end"','case "endAll"','calculationFingerprint','isRedacted','alreadyActive','activeCount','expiredAutoCleanup','purgeExpiredActivities','contentState.prayerAtMilliseconds','UIApplication.willEnterForegroundNotification']
required_widget = ['ActivityConfiguration(for: PrayerActivityAttributes.self)','DynamicIsland {','PrayerLiveActivityWidget()','quranikerim://prayer']
missing = [x for x in required_channel if x not in channel] + [x for x in required_widget if x not in widget]
if "NSSupportsLiveActivities" not in info: missing.append("NSSupportsLiveActivities")
if project.count("PrayerActivityAttributes.swift in Sources") < 2: missing.append("attributes target membership")
if "PrayerLiveActivityChannel.swift in Sources" not in project: missing.append("channel target membership")
if missing: raise SystemExit("Prayer Live Activity foundation failed: " + ", ".join(missing))
print("Prayer Live Activity foundation contract OK")
