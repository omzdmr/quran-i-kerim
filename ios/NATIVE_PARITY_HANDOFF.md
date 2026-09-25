# Native iOS parity handoff

Shared Flutter/Dart remains read-only on `automation/ios-parity`.

## Widget snapshot (`app.quranikerim/native_widget_snapshot`)
`publish` expects `generatedAtMs`, `validUntilMs`, `timeZone`, `calculationFingerprint`, optional paired `nextPrayerId`/`nextPrayerAtMs`, `displayName`, and `privacyMode`. Native storage rejects expired, already-passed, future-generated, malformed or otherwise stale snapshots. A standard snapshot must contain a next-prayer ID/time pair; a privacy-redacted snapshot may intentionally omit that pair. This prevents native status from claiming “fresh” while the widget can only render “unavailable”.

The widget independently re-validates the same persisted contract before rendering: schema, generated-before-expiry ordering, supported privacy mode, real timezone identifier, nonblank calculation fingerprint, prayer pair/policy, prayer time inside the snapshot validity window, current timezone, expiry and prayer-boundary state must all agree. A present-but-invalid payload fails closed and asks WidgetKit for a near-term retry rather than silently displaying an old prayer time. Time-zone drift, expired/prayer-boundary data and malformed/future data produce distinct localized refresh explanations instead of one misleading generic state. `validate_widget_snapshot_parity.py` prevents Runner and WidgetKit freshness rules from quietly drifting apart.

The widget inserts an explicit timeline refresh at the next-prayer boundary and snapshot expiry. Shared code must republish after prayer-policy, timezone, schedule or privacy changes. Prayer calculation remains shared-layer owned. `calculationFingerprint` should be deterministic over every shared setting that can alter the projected schedule (calculation method, Asr rule, high-latitude rule and manual offsets); native code deliberately does not infer or invent those religious settings.

Persisted App Group payloads pass a validated read before they are exposed to the app. Undecodable, unsupported-schema and structurally impossible snapshots are quarantined instead of being retried forever. A quarantine is reported as a state change so WidgetKit reloads immediately. `status`, `purgeIfStale` and `invalidatePolicy` expose codec-safe diagnostics; invalidation reasons distinguish `expired`, `timeZoneChanged`, `prayerBoundaryPassed`, `generatedInFuture`, `policyChanged`, `corruptPayload` and explicit clear. A healthy republish clears the previous diagnostic.

The native channel revalidates on significant system-clock changes, time-zone changes and foreground activation. `PrayerWidget` shares the App Group and supports small/medium/large/iPad extra-large plus Lock Screen accessory inline/circular/rectangular families, Dynamic Type/VoiceOver-friendly states and EN/TR/AR/AZ/RU/FR. Accessory families use compact native chrome rather than Home Screen padding/background treatment. Inline/rectangular prayer name and time use separate SwiftUI elements so RTL layout can reorder naturally without punctuation corrupting Arabic reading order. Privacy-redacted Lock Screen states suppress prayer details. `validate_widget_localizations.py` enforces equal key coverage across all six native widget locales.

Widget prayer-name fallback is native and locale-safe for canonical schedule IDs. If shared code omits/blank-sends `displayName`, common `fajr/imsak`, sunrise/shuruq, dhuhr/zuhr, asr, maghrib and isha aliases resolve to six-locale native labels instead of leaking raw internal IDs onto Home/Lock Screen. Unknown IDs deliberately fall back to the localized generic “Prayer” label; native code still does not invent prayer times or religious schedule data. `validate_widget_prayer_names.py` gates both locale coverage and alias/fallback behavior in native CI.

## Widget deep link (`app.quranikerim/native_deep_link`)
Runner registers `quranikerim`; widget taps use `quranikerim://prayer`. AppDelegate buffers cold/warm private-scheme ingress without bypassing FlutterAppDelegate. Only `prayer`, `reader`, and `hifz` hosts are accepted. `universalLink` remains false until an owned domain and Associated Domains entitlement exist. Shared router should consume `consumePendingLinks`, listen for `linkReceived`, and deduplicate normalized URLs against Flutter's own incoming-link callback.

## Files / portable backup (`app.quranikerim/native_document_handoff`)
Import is copy-on-import and security-scoped. Directories are rejected and portable backups are capped at 64 MiB before and after copy. Export staging now rechecks actual copied bytes as well as the source size, so a source that changes while being copied cannot bypass the portable-backup ceiling. Imported/export-staging copies use iOS file protection and remain excluded from automatic device backup. `deleteImportedFile` lets the shared restore flow explicitly remove its private imported copy after success/cancel; only handoff-created paths are accepted. On iPad, the Files picker resolves the active presented/navigation/tab/split controller before presentation. Shared code still owns backup parsing, preview, merge/replace and rollback policy.

## Qibla / heading (`com.omzdmr.quran_i_kerim/location_heading`)
Native heading follows iPhone/iPad rotation via `headingOrientation`. While heading is active and foreground location is authorized, native location updates remain active even when the shared UI does not request location streaming, allowing Core Location to provide true-north heading; location samples are not forwarded unless shared location streaming is explicitly on. Capabilities expose `orientationAwareHeading` and `trueNorthWhenAuthorized`. Qibla bearing math remains shared-owned.

## Quran audio / Now Playing (`com.omzdmr.quran_i_kerim/now_playing`)
Lock Screen/Control Center metadata clamps elapsed time to known duration, marks content as audio, sets default playback rate, and hides seeking when duration is unknown. `updateNowPlaying` accepts optional `canGoNext` / `canGoPrevious` so the shared queue can disable impossible remote controls at queue boundaries. The native coordinator stays dormant until this channel actually publishes metadata, so merely registering it does not disable or clear the existing `audio_service` remote-command surface. Once native ownership is adopted, shared code should avoid dual-owning Now Playing through two stacks. Remote commands still return to the shared player; native code does not advance Quran content itself.

## Recitation recording (`app.quranikerim/native_recording`)
AAC `.m4a` user recordings live under Application Support `UserRecitations` with required iOS file protection and remain backup-eligible as user-created data. Recording policy keeps Bluetooth HFP microphones eligible alongside A2DP playback; start/status/route events expose active input identity. If recorder preparation/start fails, the candidate file is removed and the normal Quran audio policy is restored instead of leaving an orphan `.m4a`. Interruptions and microphone-route changes finalize a recoverable partial recording rather than secretly continuing on another microphone. No tajwid scoring is performed.

## Notification diagnostics
`getNotificationDiagnostics`, `scheduleNotificationSelfTest`, and `cancelNotificationSelfTest` complement permission status/request. The self-test is explicitly presented with banner+sound while the app is foreground, while every non-test notification continues through FlutterAppDelegate's normal notification path.

## Lifecycle / protected data (`app.quranikerim/native_lifecycle_state`)
Lifecycle restore exposes prior-session/background markers without calling first install a crash. It reports `protectedDataAvailable`, remembers the last protected-data availability time and emits availability/unavailability events. After reboot or while the device is locked, native prayer-projection reconciliation will not pretend protected storage is readable; reconciliation resumes when iOS announces protected data is available.

A probable background-eviction restore is one-shot within the launch. After shared Flutter consumes the recovery state it should call `acknowledgeRestore`; subsequent `snapshot` calls report `likelyBackgroundEviction: false` and `restoreAcknowledged: true`, and the old background timestamp is removed. This prevents rebuilds/navigation from repeatedly replaying the same restore decision. Shared Flutter should use this as a restore/readiness signal, not as a second persistence engine.

Native share walks the active navigation/tab/split/presented hierarchy before presenting `UIActivityViewController`, keeping iPad popovers usable when Flutter is nested in native presentation containers. Shared Flutter owns actual Reader/audio restore decisions and rendered religious text.

## Privacy / landing gates
Runner and PrayerWidget both use `group.app.quranikerim.shared`; `Runner/Runner.entitlements` and `PrayerWidget/PrayerWidget.entitlements` are wired in Debug/Release/Profile build settings. Runner declares required-reason APIs for app/shared `UserDefaults` and app-container file metadata; the widget privacy manifest declares its App Group UserDefaults reason and is in the widget Resources phase. The App Group still must exist in the Apple Developer team/provisioning profiles for a signed-device build.

`.github/workflows/ios-native-contract.yml` gates PBX/entitlements/privacy, iPhone+iPad device-family settings, six-locale native key parity, canonical prayer-name fallback parity, Runner/WidgetKit snapshot-freshness parity, Lock Screen accessory/RTL/fail-closed states, lifecycle restore acknowledgement, portable document staging, recitation recording storage lifecycle, standalone WidgetKit build/package inspection, MediaPlayer type-check, backup-exclusion execution and snapshot integrity/quarantine tests. Do not merge the widget slice to integration unless native-contract and the full simulator build are green.


## iCloud backup Apple foundation (`app.quranikerim/native_icloud_foundation`)
This is foundation only, not the final iCloud provider. Runner declares Cloud Documents container `iCloud.com.omzdmr.quranIKerim` and exposes native account/container readiness while shared backup serialization and restore semantics stay shared-owned. `capabilities.finalProvider` remains false until the persistent registry is mature and archive upload/list/download/restore is implemented end to end.

`CloudBackupFoundation` distinguishes no-account, unavailable-container and available states and reports account identity changes. `CloudBackupFileOperator` provides file-protected, device-backup-excluded temporary staging and atomic destination replacement so partial copies are never presented as complete archives. Cache and re-downloadable data remain outside this foundation.

Shared handoff: Feature Development can consume `status` for readiness UI. The final provider must later consume one complete shared archive and prove restore/round-trip for every registered persistent type. Signed-device verification remains mandatory because simulator CI cannot prove Apple account/container provisioning.


### Shared archive follow-up
The integration backup manifest currently leaves Hifz voice-recording files outside portable/cloud archives, while the product Hifz requirements include recording backup/restore. Native recording files are treated as user-created data, but final iCloud round-trip must follow one shared registry. Feature Development must define the archive policy and migration for those recordings before the native iCloud provider is finalized; native code must not create a parallel list of user data.


### Audio route/recovery follow-up
Native audio lifecycle marks an unavailable previous output with `shouldPause: true`, so the shared player can stop immediately when a wired or routed output disappears. Media-services reset emits `mediaServicesReset` with configuration status and `republishNowPlaying: true`; shared playback should rebuild current Now Playing metadata after receiving it. Native code still does not choose or advance Quran content.


## 2026-09-26 native media + iPad lifecycle slice
Now Playing ownership is now non-destructive across multiple playback stacks. Before the native Quran channel takes ownership it snapshots existing MediaPlayer metadata, playback state and command enabled states. On clear/detach it restores that prior state only when the process-global Now Playing payload is still the exact payload last published by this native coordinator. If another stack replaced metadata in the meantime, native cleanup removes only its own command targets and leaves the newer global state untouched. This closes the prior failure mode where clearing Quran metadata could blank or disable another playback stack.

Lifecycle restore is now scene-aware for iPad/Stage Manager diagnostics. Background persistence is only committed when there are no foreground-active or foreground-inactive connected scenes; otherwise the channel emits a sceneBackgrounded event without classifying the whole app as backgrounded. Snapshots expose foregroundSceneCount/connectedSceneCount and capabilities advertise multiSceneAwareBackground. This prevents a single-window transition from poisoning later background-eviction restore decisions.

Executable contract gates: validate_audio_ownership.py and validate_multiscene_lifecycle.py are wired into ios-native-contract.yml alongside the existing MediaPlayer type-check. Shared Flutter/Dart remains unchanged. No new persistent user data was introduced, so the shared backup registry/iCloud archive contract is unchanged.

Next native work: verify the new contract on macOS CI, then continue iPad keyboard/Stage Manager presentation and release/archive parity. Real signed-device behavior still requires Apple provisioning; simulator CI cannot prove multi-window scene transitions or Control Center coexistence on physical hardware.


### Storage capacity bridge
Native channel `app.quranikerim/native_storage_capacity` reports Application Support volume capacity for important/opportunistic usage plus total capacity when iOS provides those values. It is read-only and persists nothing.

Shared handoff: Download Manager should compare its verified pack byte size and product headroom against `availableForImportantUsageBytes` before starting each queued pack. A missing field means unknown capacity. Shared code owns the policy; native code does not estimate pack sizes. Backup/iCloud scope is unchanged.


## 2026-09-26 iPad and release parity

Stage Manager presentation now uses one scene-aware resolver for document handoff and native sharing. It prefers the Flutter window's foreground scene, walks presented/navigation/tab/split containers, ignores hidden windows, and only falls back to another foreground scene when needed. Focused native contract tests cover this behavior.

Notification health now reports permission state plus pending/delivered counts and native self-test state, and can open the relevant iOS settings page. Shared code still owns prayer schedule identity and semantics; a raw pending count is diagnostic only.

CI now adds an unsigned Release iphoneos build and verifies arm64 Runner/PrayerWidget binaries, bundle IDs and privacy manifests. This is not a signed IPA. Signed-device and signed archive/export verification remain pending Apple provisioning and final product readiness.

No persistent user data was added, so backup registry and iCloud archive scope are unchanged. Next: close current CI, then continue hardware-keyboard/Pencil native foundations without inventing shared product semantics.


### iPad hardware keyboard and Pencil foundation
Runner now uses `NativeFlutterViewController`. Hardware shortcuts are opt-in and preserve Flutter's existing responder commands: after shared calls `app.quranikerim/native_keyboard.setEnabled(true)`, Command-F emits `search` and Command-1...5 emit zero-based `selectTab` actions matching the fixed five-tab product shell. Disabled is the default so native code does not steal shortcuts before shared routing adopts them.

The same controller exposes an opt-in `app.quranikerim/native_pencil` foundation. Apple Pencil double-tap is surfaced as a gesture event only after explicit enablement. Native code does not create note anchors, mutate Quran content or invent Pencil semantics; shared Reader/Study Canvas remains owner of anchored notes. Squeeze is explicitly reported unsupported in this foundation rather than being faked.

Both adapters are non-persistent and do not change backup/iCloud scope. Shared handoff: wire these channels only when the corresponding shared navigation/Reader actions are ready, then add end-to-end iPad interaction tests. Physical keyboard/Pencil behavior still needs signed-device verification.


### Prayer Live Activity / Dynamic Island foundation
Prayer Live Activity now has a native ActivityKit foundation without moving prayer calculation into Swift. Shared code supplies the canonical prayer ID/display label, future prayer timestamp, timezone, locale, calculation fingerprint and explicit privacy-redaction state. Runner validates that payload before requesting/updating ActivityKit. The Widget extension renders Lock Screen and Dynamic Island surfaces and deep-links to `quranikerim://prayer`.

Native lifecycle prevents duplicate future prayer activities and prunes expired prayer activities on foreground. On iOS 16.2+ ActivityContent also sets staleDate to the prayer boundary, while iOS 16.1 keeps the compatible contentState path. Returning to foreground emits current ActivityKit authorization so shared UI can refresh settings state. Redacted state never renders the prayer label/time. The app declares Live Activity support and Runner/Widget compile the same `PrayerActivityAttributes` contract; CI asserts the two copies remain byte-identical.

Shared handoff: use `app.quranikerim/native_prayer_live_activity` only after shared prayer schedule/privacy state is ready. Methods are `capabilities`, `status`, `start`, `update`, `end`, `endAll`. Shared remains owner of schedule changes (timezone/DST/location/method/offset) and must update or end/restart the activity when its calculation fingerprint changes. Native code does not calculate prayer times. This foundation is local-only (pushType nil): it does not create ActivityKit push tokens or add a server dependency.

This is not signed-device completion. ActivityKit authorization, Dynamic Island behavior, lock-screen privacy and deep-link behavior still require physical signed-device verification.
