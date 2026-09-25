from pathlib import Path

runner_attrs = Path("ios/Runner/PrayerActivityAttributes.swift").read_text()
widget_attrs = Path("ios/PrayerWidget/PrayerActivityAttributes.swift").read_text()
channel = Path("ios/Runner/PrayerLiveActivityChannel.swift").read_text()
widget = Path("ios/PrayerWidget/PrayerWidget.swift").read_text()
project = Path("ios/Runner.xcodeproj/project.pbxproj").read_text()
info = Path("ios/Runner/Info.plist").read_text()

assert runner_attrs == widget_attrs, "Runner and widget ActivityAttributes drifted"
required_channel = ['native_prayer_live_activity','ActivityAuthorizationInfo().areActivitiesEnabled','Activity<PrayerActivityAttributes>.request','case "start"','case "update"','case "end"','case "endAll"','calculationFingerprint','isRedacted','dynamicIslandConfiguration','lockScreen','ActivityContent(state: state, staleDate:','if #available(iOS 16.2, *)','authorizationChanged','end(using: activity.contentState','alreadyActive','activeCount','expiredAutoCleanup','purgeExpiredActivities','contentState.prayerAtMilliseconds','UIApplication.willEnterForegroundNotification']
required_widget = ['ActivityConfiguration(for: PrayerActivityAttributes.self)','DynamicIsland {','PrayerLiveActivityWidget()','quranikerim://prayer','.privacySensitive()','prayerActivityIsStale','if #available(iOS 16.2, *) { return context.isStale }','isStale: stale']
missing = [x for x in required_channel if x not in channel] + [x for x in required_widget if x not in widget]
if "NSSupportsLiveActivities" not in info: missing.append("NSSupportsLiveActivities")
if project.count("PrayerActivityAttributes.swift in Sources") < 2: missing.append("attributes target membership")
if "PrayerLiveActivityChannel.swift in Sources" not in project: missing.append("channel target membership")
if missing: raise SystemExit("Prayer Live Activity foundation failed: " + ", ".join(missing))
assert '"dynamicIsland": true' not in channel, "Capability must not claim device has Dynamic Island"
assert "pushType: nil" in channel, "Prayer Live Activity must remain local-only"
for forbidden in ["UserDefaults", "FileManager.default", "write(to:", "URLSession", "pushType: .token"]:
    assert forbidden not in channel, "Live Activity bridge must remain ephemeral: " + forbidden
assert widget.count('.accessibilityLabel(') >= 4, "Dynamic Island accessibility labels missing"
print("Prayer Live Activity foundation contract OK")
