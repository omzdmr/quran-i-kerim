# Native iOS parity handoff

Shared Flutter/Dart remains read-only on `automation/ios-parity`.

## Widget snapshot (`app.quranikerim/native_widget_snapshot`)
`publish` expects `generatedAtMs`, `validUntilMs`, `timeZone`, `calculationFingerprint`, optional paired `nextPrayerId`/`nextPrayerAtMs`, `displayName`, and `privacyMode`. Native storage rejects expired, malformed or implausible snapshots. The widget refuses wrong-time-zone/redacted/stale data and inserts an explicit timeline entry at the next-prayer boundary so a countdown cannot remain at 00:00. Shared code must republish after prayer-policy, timezone, schedule or privacy changes. Prayer calculation remains shared-layer owned.

The native channel also revalidates the projection on significant system-clock changes, time-zone changes and foreground activation. A stale projection is purged from the App Group; clock/time-zone changes force WidgetKit timeline reevaluation even if the projection remains valid. Capabilities expose `systemTimeInvalidation`, `timeZoneInvalidation` and `foregroundRevalidation` so the shared layer can feature-detect this behavior.

`PrayerWidget` shares the App Group, supports small/medium/accessory inline/circular/rectangular families, Dynamic Type/VoiceOver-friendly states and EN/TR/AR/AZ/RU/FR. Medium/iPad layouts separate absolute prayer time from the live countdown. The extension validates the prayer-id/time pair and policy/time-zone metadata again before display, so malformed App Group bytes fail closed. The first target is iOS 17+ because it uses the modern widget container background API.

## Widget deep link (`app.quranikerim/native_deep_link`)
Runner registers the private `quranikerim` URL scheme. Widget taps use `quranikerim://prayer`. AppDelegate forwards cold-start and warm custom-scheme ingress into a bounded native queue and still calls FlutterAppDelegate so existing plugin routing is not bypassed. The native boundary accepts only the private scheme and only `prayer`, `reader`, and `hifz` hosts. `universalLink` capability is intentionally `false`; do not advertise universal links until an owned domain plus Associated Domains entitlement exists.

Shared-router handoff: consume `consumePendingLinks` after router readiness and listen for `linkReceived`. Deduplicate against Flutter's own incoming-link callback by normalized URL before navigation. Until that shared integration lands, a widget tap is guaranteed to open the app, while exact in-app destination parity remains a shared-layer task.

## Files / portable backup (`app.quranikerim/native_document_handoff`)
Files/iCloud Drive import remains copy-on-import and security-scoped. The native boundary now rejects directories and caps a selected portable backup at 64 MiB before copying, then verifies copied size again. `capabilities.maxImportBytes` exposes the limit so shared UI can explain it. Imported temporary handoff files remain excluded from automatic device backup; the portable backup's content/merge semantics stay shared-owned.

## Qibla / heading (`com.omzdmr.quran_i_kerim/location_heading`)
Native heading tracks physical iPhone/iPad orientation and updates `CLLocationManager.headingOrientation` when the device rotates. This prevents a landscape iPad or rotated iPhone from feeding a portrait-relative compass heading to the shared Qibla UI. `getCapabilityStatus` exposes `orientationAwareHeading: true`; Qibla bearing calculation itself remains shared-layer owned.

## Lifecycle restore (`app.quranikerim/native_lifecycle_state`)
`snapshot` exposes launch count/time, `hadPreviousSession`, prior clean-termination state, background/foreground timestamps and background gap. First install is not mislabeled as a crash. `acknowledgeRestore` consumes the background marker. Shared code owns the actual Reader/audio restore decision.

## Recitation recording (`app.quranikerim/native_recording`)
Methods: `permissionStatus`, `requestPermission`, `startRecording`, `recordingStatus`, `stopRecording`, `cancelRecording`, `listRecordings`, `deleteRecording`. AAC `.m4a` files live under Application Support `UserRecitations`, use iOS file protection, and are deliberately not backup-excluded because they are user-created data. Recording audio policy now keeps Bluetooth HFP microphones eligible in addition to A2DP playback; start/status/route events expose the active input name/type so UI can tell users which microphone is actually recording. Unexpected recorder termination emits `recordingInterrupted` with recoverable file metadata and restores playback audio policy. No tajwid scoring is performed.

## Native share (`app.quranikerim/native_share`)
`shareText` and `shareFile` use `UIActivityViewController`, return completion status, and are popover-safe on iPad. Shared code owns rendered religious text.

## Notification diagnostics
`getNotificationDiagnostics`, `scheduleNotificationSelfTest`, and `cancelNotificationSelfTest` complement permission status/request. The user-invoked test schedules a localized local notification after three seconds only when authorization permits delivery.

## Privacy / landing gates
Runner declares required-reason APIs for app-owned/shared `UserDefaults` (`CA92.1`, `1C8F.1`) and app-container file metadata (`C617.1`). Widget manifest declares App Group `UserDefaults` reason `1C8F.1`. The App Group ID `group.app.quranikerim.shared` must also be registered to the Apple team and authorized by both provisioning profiles.

The widget Xcode graph uses 24-character hexadecimal PBX object IDs and `PrayerWidget/PrivacyInfo.xcprivacy` is part of the widget Resources phase. `.github/workflows/ios-native-contract.yml` independently gates the graph, privacy manifests, widget Swift type-check, snapshot persistence, private deep-link, Files import, rotation-aware heading and Bluetooth-recording contracts. Do not merge the widget target to integration unless both this native contract and the full simulator build remain green.
