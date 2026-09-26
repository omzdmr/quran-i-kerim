# Project Handoff

Last updated: 2026-09-20 (Asia/Shanghai)

This is the first file a new ChatGPT, Claude, Codex or human contributor should
read. Repository state is authoritative; do not rely on an earlier chat's
memory when it conflicts with the current branch.

## Current operating mode

- All scheduled Quran development automations are paused.
- Development is manual and collaborative until the owner explicitly enables
  an automation again.
- Integration branch: `feature/localization-v01`.
- Do not assume an automation is working in the background or owns a pending
  change.
- Before editing, fetch the current integration branch and inspect its latest
  Android/iOS Actions result. Never overwrite a moved branch.

## Source-of-truth order

1. `docs/PRODUCT_MASTER_SPEC.md` — complete product requirements.
2. `docs/PROJECT_HANDOFF.md` — current mode, progress and next work.
3. `docs/AUTOMATION_COORDINATION.md` — branch/ownership rules if automation is
   ever re-enabled.
4. Domain documents such as `HIFZ_SYSTEM.md`, `READER_INTERACTIONS.md`,
   `LOCALIZATION.md`, `LOCALIZATION_ARCHITECTURE.md` and
   `GOOGLE_DRIVE_BACKUP.md`.
5. Current code, tests and CI logs.

## Non-negotiable product decisions

- Five bottom tabs remain: Home, Quran, Plans, Discover and Profile.
- Quran opens the Reader. Quran contains Read / Learn / Progress; Learn contains
  Lessons / Memorize / Articles.
- Local-first and offline-first. Core Quran reading must not depend on a custom
  backend or mandatory account.
- UI language and Quran meaning/translation language remain independent.
- Do not use TTS for Quran or spoken translations.
- Do not invent Quran explanations, hadith, surah information, source names or
  religious rulings. Religious/translation content needs a verified source and
  usable rights/license.
- No automatic recitation/tajwid correctness score, AI fatwa/chatbot, public
  social feed or worship leaderboard.
- Preserve existing visual shells unless the owner supplies a visual decision
  or a verified bug requires a change.

## Integrated progress at this handoff

Earlier completed slices remain integrated, including missed-day plan recovery,
Settings search, prayer notification diagnostics, Home prayer accessibility,
recent-reading shortcuts and customizable Home quick actions.

Recent Plans work:

- Commit `767c864` added full khatm archive retention, year filtering and a
  private yearly khatm target.
- Commit `5c4b3b9` added manual/off-device completed-khatm records with
  optional start date/private note and clear source labels.
- Commit `9995ee6` added physical-Mushaf/off-device page reading sessions.
- The structured-input slice extends those sessions with
  page/juz/Hizb/ayah-range entry and canonical ayah coverage while preserving
  the same local storage.
- Old khatm archive records without source metadata migrate as app reading-plan
  records.
- Manual khatm records and off-device page sessions live inside
  `reading_plan_state_v1`; existing backup coverage therefore remains intact
  without a new backend or preference key.
- Turkish, English, Arabic, Azerbaijani and Russian Plans copy remains
  key-parity checked.

## Latest completed feature slice

French full feature-string parity is now integrated on top of the French core
application-locale wiring, without merging stale localization branches wholesale.

Integrated French feature-string work:
- Commit `3aac833` added French Home quick actions, recent-reading and Home verse/activity copy plus parity tests.
- Commit `0c97cce` added French Reader navigation/audio/media/note copy, prayer notification copy and Learn catalog progress copy plus parity tests.
- Commit `100af6a` added French prayer-notification diagnostics, Learn lesson copy and Learn reference/source copy plus parity tests.
- `feature_strings.dart` currently has exact 137/137 EN↔FR key parity and its test already requires all six core locales.
- `plan_strings.dart` currently has exact 141/141 EN↔FR key parity and its test already requires all six core locales.
- Backup strings already include French parity from `fe6ddc6`.
- French remains `humanReviewRequired: true`; AI-assisted draft copy must not be represented as production human-reviewed French.
- French UI availability remains independent from French Quran meaning/audio catalog rights.

French core application-locale wiring was implemented on the current integration
foundation without merging the stale localization automation branch wholesale:

- Existing French work from `automation/localization-language` was audited and
  selectively reused instead of merging a branch that is dozens of commits
  behind current Plans work.
- `fr` is now a declared `AppLocalizations.supportedLocales` application
  locale and resolves independently from Quran meaning/translation selection.
- Device/system locale resolution can select French; an explicitly stored
  French app locale overrides the device locale like the other supported
  languages.
- Settings and Settings search expose a real `FR / Français` application
  language choice.
- The French ARB has exact 118-key parity with the current English ARB and
  `flutter gen-l10n` generates it successfully.
- The core French Dart dictionary has exact 150-key parity with TR/EN/AR/AZ/RU.
- All existing core language dictionaries now include localized labels and
  descriptions for choosing French.
- `locale_metadata.dart` records French as a Latin/LTR full application locale
  while explicitly keeping `humanReviewRequired: true`. Do not represent the
  current AI-assisted draft copy as production human-reviewed French.
- French UI support remains separate from French Quran meaning/audio assets and
  does not enable any unverified content source.

Focused French-core validation:
- Run `35528291231` passed bundled-content setup, dependency resolution,
  `flutter gen-l10n`, 6-locale ARB parity, 6-locale core-string parity,
  resolver/Settings wiring checks and the human-review gate.
- Direct `flutter test` run `35527989225` loaded no test case and timed out
  after 180 seconds at `app_locale_resolver_test.dart`; this is the same class
  of repository Flutter loader stall seen in other focused screens/analyzer
  runs, not a test assertion failure.
- Keep the Flutter tests in the repository; retry them when the loader issue is
  repaired rather than deleting coverage to make CI look green.

## Validation status

The last known fully green full Android workflow is run `35498316886` for
code-bearing head `1ac4908`: analysis, all tests, ARM64 APK build,
signer/application identity verification and artifact upload all passed.

Recent full Android validation has a repeatable tooling problem:
- Run `35502558063` was cancelled after `flutter analyze lib --no-fatal-infos`
  ran until the 120-minute timeout.
- Runs for newer khatm slices have shown the same long analyzer behavior unless
  superseded by a newer push.
- Treat this as CI/analyzer tooling unless a concrete analyzer diagnostic or
  failing test says otherwise. Do not relabel a timeout as an app regression.

The completed-credit provenance integration head before French core work was
`98b6212801414b4ed10fb59137c9b2cd5da479c3`.
Android APK run #551 for that head completed setup/content/dependency/l10n steps
and remains in `Analyze app code`, matching the repository's repeated analyzer
stall. Inspect the newest integrated Actions run before calling the full Android
pipeline green.

## Safe continuation checklist

1. Fetch `feature/localization-v01` and read the latest commits/diff.
2. Check the latest GitHub Actions run and exact failing step, if any.
3. Finish or repair the current vertical slice before selecting another one.
4. Choose one user-visible requirement from `PRODUCT_MASTER_SPEC.md` and carry
   it through state/data, UI navigation, accessibility and tests where
   applicable. A model, adapter, documentation sync or test alone is not a
   finished feature.
5. Run formatter/relevant tests. Let Android CI validate the integrated branch;
   classify infrastructure/tooling failures separately from code failures.
6. Update this file whenever the active feature, blocker or next concrete step
   changes.

## Latest prayer-notification profile slice

Manual notification-profile foundation V1 is implemented in commit `b55535b`:
- Prayer Settings exposes explicit full-sound and discreet/vibration profiles.
- Android uses distinct versioned notification channels so sound policy can actually differ by profile.
- iOS maps the profile to `presentSound` while preserving alerts.
- The selected profile persists locally and is included in safe prayer-preference backup/restore.
- Unknown future/stale stored profile values fall back to full sound.
- This is intentionally only the manual profile foundation. Schedule/geofence/travel/mosque activation and temporary non-essential-reminder pause remain later V18 slices.
- Android CI #560 for `b55535b` is running; do not mark this slice fully green until that run reaches analyzer/tests/build successfully or a newer equivalent head is verified.

## Immediate next step

French application/feature-string parity is complete at the repository level.
Do not restart the old `manual/french-*` branches unless a concrete regression
is found; they are historical staging branches and may be behind integration.

Next manual development should:
1. Re-check the newest Android CI result for the current integration head and
   classify any failure by its exact failing step.
2. Read the current `PRODUCT_MASTER_SPEC.md` and choose the next missing
   user-visible vertical slice rather than adding more localization scaffolding.
3. Preserve the completed Home, Reader, Plans, notification-diagnostics,
   khatm/page-session and French-parity work.
4. Keep French `humanReviewRequired: true` until an actual human language
   review is completed.
5. Continue to separate UI-locale availability from Quran
   meaning/audio/source-rights availability.


## Staging progress — offline audio recovery (2026-09-26)

Commits 1f9017d0 and a071e4b2 add central recovery for incomplete audio packs in
Profile > Downloads. Users can resume, repair and pause a pack there while the
screen reflects live downloading, paused, verifying and failed state. Existing
Wi-Fi-only and mobile confirmation preferences remain enforced.

Permanent audio files remain device-local re-downloadable data and are not
placed in portable backup. The existing offline-audio pack intent preference
keeps its established schema behavior; no audio bytes, cache or secrets were
added to backup.

Focused URL-resolution tests were added for both existing provider address
formats. This worker could not run Flutter locally, so keep the slice on staging
until formatter/analyzer and the focused audio download tests are green.

Next: central bulk queue/free-space controls for Downloads; do not rebuild the
per-surah recovery path.
