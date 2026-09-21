# Native iOS parity handoff

Shared Flutter/Dart remains read-only on `automation/ios-parity`.

## Widget snapshot (`app.quranikerim/native_widget_snapshot`)
`publish` expects `generatedAtMs`, `validUntilMs`, `timeZone`, `calculationFingerprint`, optional paired `nextPrayerId`/`nextPrayerAtMs`, `displayName`, and `privacyMode`. Native storage rejects expired, malformed or implausible snapshots. The widget refuses wrong-time-zone/redacted/stale data and inserts an explicit timeline entry at the next-prayer boundary so a countdown cannot remain at 00:00. Shared code must republish after prayer-policy, timezone, schedule or privacy changes. Prayer calculation remains shared-layer owned.

The native channel revalidates on significant system-clock changes, time-zone changes and foreground activation. `PrayerWidget` shares the App Group, supports small/medium/accessory inline/circular/rectangular families, Dynamic Type/VoiceOver-friendly states and EN/TR/AR/AZ/RU/FR. Medium/iPad layouts separate absolute prayer time from live countdown. Privacy-redacted accessory widgets use compact lock states instead of leaking details or overflowing the Lock Screen. `validate_widget_localizations.py` enforces equal key coverage across all six native widget locales.

## Widget deep link (`app.quranikerim/native_deep_link`)
Runner registers `quranikerim`; widget taps use `quranikerim://prayer`. AppDelegate buffers cold/warm private-scheme ingress without bypassing FlutterAppDelegate. Only `prayer`, `reader`, and `hifz` hosts are accepted. `universalLink` remains false until an owned domain and Associated Domains entitlement exist. Shared router should consume `consumePendingLinks`, listen for `linkReceived`, and deduplicate normalized URLs against Flutter's own incoming-link callback.

## Files / portable backup (`app.quranikerim/native_document_handoff`)
Import is copy-on-import and security-scoped. Directories are rejected and portable backups are capped at 64 MiB before and after copy. Imported/export-staging copies use iOS file protection and remain excluded from automatic device backup. `deleteImportedFile` lets the shared restore flow explicitly remove its private imported copy after success/cancel; only handoff-created paths are accepted. Shared code still owns backup parsing, preview, merge/replace and rollback policy.

## Qibla / heading (`com.omzdmr.quran_i_kerim/location_heading`)
Native heading follows iPhone/iPad rotation via `headingOrientation`. While heading is active and foreground location is authorized, native location updates remain active even when the shared UI does not request location streaming, allowing Core Location to provide true-north heading; location samples are not forwarded unless shared location streaming is explicitly on. Capabilities expose `orientationAwareHeading` and `trueNorthWhenAuthorized`. Qibla bearing math remains shared-owned.

## Quran audio / Now Playing (`com.omzdmr.quran_i_kerim/now_playing`)
Lock Screen/Control Center metadata clamps elapsed time to known duration, marks content as audio, sets default playback rate, and hides seeking when duration is unknown. `updateNowPlaying` accepts optional `canGoNext` / `canGoPrevious` so the shared queue can disable impossible remote controls at queue boundaries. Remote commands still return to the shared player; native code does not advance Quran content itself.

## Recitation recording (`app.quranikerim/native_recording`)
AAC `.m4a` user recordings live under Application Support `UserRecitations` with iOS file protection and remain backup-eligible as user-created data. Recording policy keeps Bluetooth HFP microphones eligible alongside A2DP playback; start/status/route events expose active input name/type. Interruptions finalize a recoverable partial recording rather than secretly auto-resuming. No tajwid scoring is performed.

## Notification diagnostics
`getNotificationDiagnostics`, `scheduleNotificationSelfTest`, and `cancelNotificationSelfTest` complement permission status/request. The self-test is explicitly presented with banner+sound while the app is foreground, while every non-test notification continues through FlutterAppDelegate's normal notification path.

## Other native parity
Lifecycle restore exposes prior-session/background markers without calling first install a crash. Native share walks the active navigation/tab/split/presented hierarchy before presenting `UIActivityViewController`, keeping iPad popovers usable when Flutter is nested in native presentation containers. Shared Flutter owns actual Reader/audio restore decisions and rendered religious text.

## Privacy / landing gates
Runner and PrayerWidget both use `group.app.quranikerim.shared`; `Runner/Runner.entitlements` and `PrayerWidget/PrayerWidget.entitlements` are wired in Debug/Release/Profile build settings. Runner declares required-reason APIs for app/shared `UserDefaults` and app-container file metadata; the widget privacy manifest declares its App Group UserDefaults reason and is in the widget Resources phase. The App Group still must exist in the Apple Developer team/provisioning profiles for a signed-device build.

`.github/workflows/ios-native-contract.yml` independently gates PBX/entitlements/privacy, six-locale widget key parity, a standalone WidgetKit build with packaged privacy/localizations, MediaPlayer type-check and snapshot persistence. Do not merge the widget slice to integration unless native-contract and the full simulator build are green.
