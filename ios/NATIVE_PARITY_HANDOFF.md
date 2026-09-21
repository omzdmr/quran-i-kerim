# Native iOS parity handoff

This file describes the native contracts exposed by `automation/ios-parity`. Shared Flutter/Dart remains read-only on this branch.

## Widget snapshot (`app.quranikerim/native_widget_snapshot`)

`publish` expects `generatedAtMs`, `validUntilMs`, `timeZone`, `calculationFingerprint`, optional `nextPrayerId`, `nextPrayerAtMs`, `displayName`, and `privacyMode` (`standard` or `redacted`). The native store rejects already-expired/invalid snapshots, persists only a compact projection in `group.app.quranikerim.shared`, and asks WidgetKit to reload. The widget refuses stale, wrong-time-zone, expired-next-prayer, or redacted detail. Shared code must republish whenever prayer calculation policy, timezone, relevant location-derived schedule, or privacy choice changes.

Do not calculate prayer times inside the extension. The widget is a consumer of the shared layer's already-approved schedule.

The `PrayerWidget` target is embedded by Runner and has the same App Group entitlement. Its source supports system small, system medium and accessory rectangular families, Dynamic Type, VoiceOver-friendly states, privacy redaction, six native locales, and a validity-bound timeline refresh. The app remains iOS 15+, while this first widget target is iOS 17+ because it uses the modern widget container background API.

## Lifecycle restore (`app.quranikerim/native_lifecycle_state`)

- `snapshot`: launch count, launch time, prior clean-termination flag, last background/foreground timestamps and background gap.
- `acknowledgeRestore`: clears the consumed background marker.
- Event: `lifecycleChanged` with `active`, `inactive`, `background`, or `foreground`.

Use this to decide whether a shared reader/audio state needs restoration. Native code does not choose the Quran position itself.

## Recitation recording (`app.quranikerim/native_recording`)

- `permissionStatus`, `requestPermission`
- `startRecording({recordingId?})`
- `recordingStatus`
- `stopRecording`, `cancelRecording`
- `listRecordings`
- `deleteRecording({recordingId})`

Files are AAC `.m4a` under Application Support `UserRecitations`. They are user-created data and therefore are not marked as reproducible/backup-excluded. The directory uses iOS file protection. The shared layer owns labels, verse associations and deletion confirmation UX. No tajwid scoring or speech judgement is performed natively.

## Native share (`app.quranikerim/native_share`)

- `shareText({text})`
- `shareFile({path})`
- completion result: `completed`, `cancelled`, or `dismissed`

The presenter is popover-safe on iPad. Shared code owns the rendered text and must not ask native code to invent or transform religious content.

## Notification diagnostics (`com.omzdmr.quran_i_kerim/notification_permission`)

In addition to permission request/status, native code exposes `getNotificationDiagnostics`, `scheduleNotificationSelfTest`, and `cancelNotificationSelfTest`. The self-test schedules a local notification three seconds later only when authorization can deliver notifications. This is intended for a user-invoked troubleshooting screen, not an automatic background probe.

## Privacy manifests

Runner declares Apple's required-reason API categories for app-owned/shared `UserDefaults` (`CA92.1`, `1C8F.1`) and app-container file metadata (`C617.1`). The widget has its own privacy manifest declaring App Group `UserDefaults` use (`1C8F.1`), because it is a separate executable. Before App Store landing, ensure `PrayerWidget/PrivacyInfo.xcprivacy` has target membership and verify it exists inside the built `.appex`; the file is committed but that resource-membership gate is intentionally left explicit until CI validates the new target graph.

## Deep link draft

`DeepLinkChannel.swift` is intentionally **not wired into AppDelegate or the Xcode Sources phase yet**. It implements a bounded cold-start-safe queue and URL normalization, but enabling it must be coordinated with the shared router so Flutter's existing deep-link handling is not duplicated. Integrate it only after the shared route ownership decision is explicit.
