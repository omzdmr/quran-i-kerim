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

Read-only off-device → active-plan impact preview is implemented on top of the
structured page/juz/Hizb/ayah-range records:

- When an active reading plan exists, each off-device record exposes a
  "preview plan impact" action. The action is hidden when there is no active
  plan.
- The preview intersects the record's normalized Mushaf page span with the
  active plan's day/page schedule without mutating plan state.
- It shows the exact touched plan days and the intersecting page span for each
  day, split into already-completed versus still-remaining plan days.
- The preview explicitly warns that it does not credit or advance the plan and
  that overlap with completed digital reading cannot be inferred as fact.
- For ayah-range entries, the UI now clarifies that page counts describe the
  Mushaf page span touched by the record, not necessarily a count of fully read
  pages.
- The calculation is input-type agnostic, so page, juz, sourced Hizb and
  canonical ayah-range records all use the same normalized impact path.
- The original off-device record remains independent; previewing it writes no
  state and creates no hidden linkage to plan progress.
- Turkish, English, Arabic, Azerbaijani and Russian impact-preview copy remains
  in localization key parity.

Focused impact validation:
- Run `35522014627` formatted the slice, then
  `reading_plan_test.dart` passed 9/9 and `plan_strings_test.dart` passed.
- Its direct `PlansScreen` widget probe reached only the test-loader phase and
  timed out after 180 seconds with no tests run and no compiler diagnostic,
  matching the repository's known PlansScreen/analyzer tooling stall.
- That hanging widget probe was removed from the final slice so it cannot block
  a future full `flutter test` run.
- Follow-up run `35522207601` passed formatting, the reading-plan model tests
  and localization parity on the cleaned slice. The focused analyzer remains a
  non-gating probe because this repository repeatedly stalls there without a
  diagnostic.

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

The sourced-Hizb integration head before the impact-preview slice was
`83a56ddf8a757fb1ddbd09effe6bbc4ea9b74100`.
Android APK run #548 for that head completed content, dependency and
localization setup and then remained in `Analyze app code`, matching the same
long analyzer behavior. Inspect the newest integrated Actions run before
calling the full Android pipeline green.

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

Build the explicit user-confirmed credit flow on top of the read-only preview:

- Never credit a plan merely because an off-device record exists or is
  previewed.
- From the preview, allow an explicit "credit this reading to my plan" action
  only after showing exactly which still-unfinished plan days would be affected.
- Do not silently complete a plan day from a partial overlap. Define a strict,
  testable rule for full-day coverage first; partial coverage must remain
  informational until a separate partial-progress model exists.
- Record any future credit as its own plan-progress event/reference so editing
  or deleting the original off-device log cannot silently rewrite already
  confirmed plan progress.
- Completed-day overlap must remain a warning only, never a second credit.
- Keep Hizb boundaries sourced from the retained Tanzil metadata.
- Keep the full French UI localization requirement as its separate localization
  workstream rather than scattering partial French strings through feature
  commits.


Do not restart already completed recovery, notification diagnostics,
recent-reading, Home quick-actions, khatm archive or page-session work unless a
real regression is demonstrated.
