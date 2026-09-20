# Project Handoff

Last updated: 2026-09-20 (Asia/Shanghai)

This is the first file a new ChatGPT, Claude, Codex or human contributor should
read. Repository state is authoritative; do not rely on an earlier chat's
memory when it conflicts with the current branch.

## Current operating mode

### Active handoff: off-device page sessions

The owner closed the other ChatGPT session. Continue on
`manual/off-device-sessions-complete`, based on `f1a6ca6` (the prior model-only
off-device session commit). Do not reimplement Home quick actions.

This branch adds Plans → Paper reading log: date, inclusive pages 1–604,
optional private note, history and confirmed deletion. Entries are explicitly
self-reported and use the 604-page Mushaf convention. They do not advance the
active plan, yearly khatm totals or goals; repeated readings are separate.

Sessions are stored inside `reading_plan_state_v1` and travel through the
existing backup unit. Plan mutation paths preserve them. Tests cover range/date
validation, persistence, backup round-trip, plan isolation, malformed entries,
localization and large-text RTL form layout.

Validation is pending in `Off-device reading checks`, scoped to this branch
with a 15-minute limit. No APK was requested or launched for this slice. Do not
call it fully validated or merge it until the targeted checks pass. Do not
restart long analyzer/APK jobs to fill waiting time.

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

The newest Plans work is now integrated:

- Commit `767c864` added full khatm archive retention, year filtering and a
  private yearly target.
- Commit `5c4b3b9` added manual/off-device completed-khatm records.
- Archive records now carry source metadata. Old records without a source
  migrate as app reading-plan records.
- Manual records may contain an optional start date, completion date and
  private note, and are clearly labelled user-reported/off-device.
- Manual records can be corrected or deleted. App-generated completion records
  cannot be rewritten through the manual editor.
- Yearly totals include both sources while also exposing an app-plan/manual
  breakdown.
- Existing `reading_plan_state_v1` remains the local-first persistence and
  backup unit; no backend/account dependency was introduced.
- Turkish, English, Arabic, Azerbaijani and Russian Plans copy remains
  key-parity checked.

## Latest completed feature slice

Manual/off-device khatm archive support is complete as one vertical slice:

- Plans → Completed exposes “Add manual khatm”.
- Completion date is required; start date and private note are optional.
- Future completion dates and start-after-completion ranges are rejected.
- Notes are limited to 300 characters for new input.
- Legacy/corrupt overlong stored notes are migration-tolerant and truncated
  rather than causing the whole reading-plan snapshot to be discarded.
- Archive cards distinguish app reading plans from manual/off-device records.
- Manual records expose edit/delete; app-generated records expose delete only.
- The yearly target card shows total progress plus source breakdown.
- Old archive JSON remains backward compatible.

Validation branch run `35516412798` passed:
- `reading_plan_store_test.dart`: 24/24 tests.
- `plan_strings_test.dart`: localization key parity passed.
- Formatter completed successfully on all changed files.

## Validation status

The last known fully green full Android workflow is run `35498316886` for
code-bearing head `1ac4908`: analysis, all tests, ARM64 APK build,
signer/application identity verification and artifact upload all passed.

Recent full Android validation has a repeatable tooling problem:
- Run `35502558063` for the Home quick-actions era was cancelled after
  `flutter analyze lib --no-fatal-infos` ran until the 120-minute timeout.
- Run `35510883618` for khatm archive head `767c864` showed the same
  analyzer-hang pattern and remained in the analyze step when superseded.
- Treat this as CI/analyzer tooling unless a concrete analyzer diagnostic or
  failing test says otherwise. Do not relabel a timeout as an app regression.

Current code-bearing head: `5c4b3b94cdfcc365f1b68d2646b4157e0b09b61c`.
Android APK run `35516558965` (#545) started for this head. Inspect its exact
step/result before calling the full Android pipeline green.

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

Continue the V17 physical Mushaf/off-device reading integration as the next
separate vertical slice:

- Add explicit manual reading sessions by page range first, then extend to
  juz/hizb/canonical ayah ranges when the data contracts are ready.
- Mark every such session as user-reported/off-device.
- Never advance an active khatm/goal automatically; advancement must be an
  explicit user action.
- Preserve source breakdown and avoid claiming certainty about duplicate
  digital/manual coverage.
- Keep the flow local-first and backup-compatible.
- A later quick-entry shortcut may support “I read pages X–Y on paper”.

Do not restart already completed recovery, notification-diagnostics,
recent-reading, Home quick-actions or completed-khatm archive work unless a
real regression is demonstrated.
