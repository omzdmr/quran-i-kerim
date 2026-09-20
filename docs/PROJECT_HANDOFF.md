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

Explicit off-device → active-plan credit is implemented on top of the
read-only impact preview:

- Logging or previewing an off-device record never changes plan progress.
- The preview now identifies which unfinished plan days are fully covered and
  which are only partially covered.
- Full-day eligibility is checked against canonical Quran start/end references,
  not merely page overlap. An ayah-range entry that touches a plan page without
  covering the complete plan day cannot be credited.
- Already-completed plan days are excluded from credit, so overlapping manual
  and digital reading is never counted twice.
- A user must first choose the credit action in the impact preview and then
  confirm a second dialog before any plan day is marked complete.
- Paused plans cannot receive off-device credit until resumed.
- Each confirmed credit creates an independent
  `OffDevicePlanCreditEvent` snapshot inside active `reading_plan_state_v1`,
  including source date/input/page/canonical coverage and credited day numbers.
- Editing or deleting the original off-device reading after confirmation does
  not undo credited progress or its active-plan credit event.
- A deleted/changed source record cannot be newly credited through a stale UI
  reference because the store verifies that the source record still exists.
- Credit can complete the reading plan; normal completed-plan archive behavior
  then takes over.
- Credit-event audit detail currently belongs to the active plan. When a plan is
  fully completed, the existing completed-plan archive keeps the completion but
  not the per-credit event list. Preserve/extend that provenance deliberately
  before presenting long-term credit history.
- Turkish, English, Arabic, Azerbaijani and Russian credit-flow copy remains in
  localization key parity.

Focused plan-credit validation run `35522662840`:
- bundled content setup, dependency resolution and localization generation
  passed;
- formatter completed and its output was persisted to the feature branch;
- `reading_plan_store_test.dart` passed, including full-day, partial-edge,
  partial-ayah, duplicate-completed, paused-plan, deleted-source and
  source-deletion-after-credit cases;
- `reading_plan_test.dart` passed;
- `plan_strings_test.dart` localization key parity passed;
- the focused analyzer remains a non-gating probe because this repository
  repeatedly stalls in analyzer/import tooling without diagnostics.

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

The impact-preview integration head before the explicit-credit slice was
`7bbcdfdd7e027bdc15e4d9d170733bc82aec2759`.
Android APK run #549 for that head started normally; newer full Android runs
continue to be evaluated separately from focused feature validation because the
main analyzer step has repeatedly stalled without a diagnostic. Inspect the
newest integrated Actions run before calling the full Android pipeline green.

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

Preserve and expose off-device credit provenance without changing its strict
credit rule:

- Extend completed-plan archive data so a khatm finished with confirmed
  off-device credits can retain a compact summary/provenance after the active
  plan is cleared.
- Keep the detailed source reading independent; do not make completed archive
  validity depend on the original off-device log still existing.
- Surface a read-only source breakdown/history where useful, but do not add
  undo-by-edit semantics that silently rewrite already confirmed progress.
- Keep partial overlaps informational. Do not invent partial-day progress until
  a separate explicit partial-progress model and UX exist.
- Keep completed-day overlap non-creditable.
- Preserve local-first storage and backup compatibility; migrate older
  completed archive rows without provenance as valid legacy records.
- Keep the full French UI localization requirement as a separate localization
  workstream rather than scattering partial French strings through feature
  commits.


Do not restart already completed recovery, notification diagnostics,
recent-reading, Home quick-actions, khatm archive or page-session work unless a
real regression is demonstrated.
