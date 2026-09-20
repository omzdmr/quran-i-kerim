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

French core application-locale wiring is implemented on the current integration
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

## Immediate next step

Continue French parity through the feature-string layers from a fresh branch
based on the integrated French-core head:

- Reuse the already-complete French blocks from the stale localization branch
  only when their key sets still match current code; do not replace newer files
  wholesale.
- Low-conflict reusable layers currently include Home verse, prayer
  notifications, Reader navigation/media/audio/note and Learn catalog.
- Add new French copy for layers created after the old localization branch:
  Home quick actions, recent reading, prayer-notification diagnostics and newer
  Learn/reference surfaces.
- Plans requires special care: the old French block covers only 30 of the
  current 141 keys. Translate the missing recovery, yearly-khatm,
  manual/off-device, impact/credit and completed-provenance keys against the
  current English semantics rather than copying the stale file.
- Add French to every feature-string parity test and eliminate silent English
  fallback on surfaces declared French-complete.
- Preserve `humanReviewRequired: true` until a human language review has
  actually happened.
- Do not couple French UI availability to French Quran meaning/audio catalog
  availability.



Do not restart already completed recovery, notification diagnostics,
recent-reading, Home quick-actions, khatm archive or page-session work unless a
real regression is demonstrated.
