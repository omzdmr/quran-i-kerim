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

Structured physical-Mushaf/off-device reading input now supports all planned
coverage entry modes in this slice:

- Plans → My Plans keeps the same user-reported off-device reading card.
- A reading can be entered as Madinah Mushaf pages, juz 1–30, Hizb 1–60, or a
  canonical surah/ayah range.
- Every accepted input is normalized to canonical start/end ayah coverage while
  retaining derived page coverage for existing plan/page logic.
- Existing page-only persisted records remain backward compatible; missing
  input metadata defaults to page mode and canonical ayah coverage is derived
  on load.
- Hizb boundaries come from verified Tanzil Quran Metadata. The bundled
  `quran_partition_metadata.dart` retains Tanzil attribution and the upstream
  CC BY 3.0 license notice. The 60 Hizb starts are derived from the source's
  240 quarter boundaries; no Hizb boundary was guessed.
- Hizb 1 is normalized to 1:1–2:74, Hizb 60 to 87:1–114:6, and each intermediate
  Hizb ends immediately before the next verified Hizb start.
- Users can edit a record and switch input type without losing the reading
  date/private note.
- Invalid page, juz, Hizb, surah/ayah and reversed ranges are rejected. Invalid
  persisted Hizb rows are skipped without discarding the rest of the snapshot.
- Off-device records remain explicitly user-reported and never advance, finish
  or rewrite an active reading plan automatically.
- The UI states that overlap with digital reading is not inferred.
- Storage remains inside `reading_plan_state_v1`; no new backend, account or
  backup preference key was introduced.
- Turkish, English, Arabic, Azerbaijani and Russian Plans copy remains in key
  parity for all four entry modes.

Focused Hizb validation run `35520996296`:
- bundled content generation/validation passed;
- formatter check passed on the six changed source/test files;
- `reading_plan_store_test.dart`: 41/41 tests passed;
- `plan_strings_test.dart`: localization key parity passed;
- a focused `dart analyze` emitted no diagnostic but hit its explicit
  120-second timeout (exit 124), matching the repository's existing analyzer
  stall. Do not classify that timeout as an app regression without a concrete
  analyzer/compiler diagnostic.
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

The structured-input integration head before the sourced-Hizb slice was
`2fffffed84906f44a07d41c3f5240fb878f56398`.
Android APK run #547 for that head reached `Analyze app code` after content,
dependency and localization setup succeeded, then remained subject to the same
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

Build on canonical off-device coverage without silently changing plan progress:

- Add a read-only impact preview that can compare a logged off-device record
  with the current plan's remaining coverage.
- Show exactly which planned day/page span would be affected and surface
  overlap/duplicate uncertainty instead of guessing.
- Any future "credit this reading to my plan" action must require an explicit
  confirmation after that preview; logging alone must never advance the plan.
- Keep the original off-device record independent so correcting/deleting a log
  does not silently rewrite previously confirmed plan progress.
- Hizb input is now complete for this slice; do not replace its sourced Tanzil
  boundaries with inferred or hand-authored values.
- Keep the full French UI localization requirement as its separate localization
  workstream rather than scattering partial French strings through feature
  commits.

Do not restart already completed recovery, notification diagnostics,
recent-reading, Home quick-actions, khatm archive or page-session work unless a
real regression is demonstrated.
