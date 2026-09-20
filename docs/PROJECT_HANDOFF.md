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

Completed-plan archive now retains off-device credit provenance:

- `CompletedReadingPlan` carries immutable off-device credit event snapshots
  when a reading plan finishes after one or more explicitly confirmed manual
  credits.
- Provenance survives all three plan-completion paths: a credit that completes
  the plan, normal final-day completion, and catch-up/complete-through
  completion after earlier credits.
- The completed archive persists credit date, source reading date/input type,
  source page/canonical coverage and credited plan-day numbers inside the
  existing `reading_plan_state_v1` payload.
- Editing or deleting the original off-device reading does not invalidate or
  erase archived credit provenance.
- Legacy completed-plan rows without provenance remain valid and load with an
  empty credit history.
- Malformed archived credit rows are skipped without dropping the completed
  khatm record.
- Completed-plan cards show a compact read-only summary: number of plan days
  credited from off-device reading, number of explicit confirmations and the
  input types involved.
- Manual/off-device completed-khatm records remain separate from app reading
  plans and do not inherit reading-plan credit provenance.
- Existing strict credit rules are unchanged: only canonical full-day coverage
  can be credited, partial overlap remains informational and already-completed
  days are never credited twice.
- Turkish, English, Arabic, Azerbaijani and Russian archive-provenance copy
  remains in localization key parity.

Focused completed-provenance validation run `35522976274`:
- bundled content setup, dependencies and localization generation passed;
- formatter completed and its output was persisted to the feature branch;
- `reading_plan_store_test.dart` passed, including credit-completes-plan,
  normal-completion-after-credit, source-log-deletion and legacy/malformed
  archive migration scenarios;
- `reading_plan_test.dart` passed;
- `plan_strings_test.dart` localization key parity passed;
- the focused analyzer remains a non-gating probe because analyzer/import
  tooling repeatedly stalls in this repository without a diagnostic.

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

The explicit-credit integration head before completed-plan provenance was
`84d45530ef966c3d95f0328f97e71f4fdd18eabf`.
Android APK run #550 for that head started normally; newer full Android runs
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

Finish the provenance UX as a read-only detail view, then leave the Plans slice
alone unless a regression appears:

- Allow a completed reading-plan archive item with off-device credits to open a
  read-only provenance detail sheet.
- Show each confirmation date, source reading date/input type, credited plan
  day numbers and source coverage without requiring the original reading log.
- Keep the detail view non-editable; changing historical provenance must not
  silently rewrite completed plan progress.
- Do not introduce partial-day credit while implementing the detail view.
- After that vertical slice, return to another open product requirement instead
  of endlessly deepening Plans. The full French UI localization requirement
  remains a high-priority separate workstream and should be resumed from a
  dedicated localization branch after inspecting current localization state.
- Preserve local-first storage and existing backup compatibility.


Do not restart already completed recovery, notification diagnostics,
recent-reading, Home quick-actions, khatm archive or page-session work unless a
real regression is demonstrated.
