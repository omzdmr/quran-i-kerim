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

Completed-plan off-device credit provenance is preserved and exposed:

- A completed app reading plan now retains the immutable
  `OffDevicePlanCreditEvent` snapshots that contributed to its progress.
- Provenance is carried into the completed archive whether the plan finishes via
  a normal next-day/through-day completion or the final explicit off-device
  credit action.
- The completed archive shows a read-only source breakdown:
  in-app completed plan days versus explicitly credited off-device plan days.
- A read-only source-details sheet exposes credited date, source reading date,
  Mushaf page span and canonical ayah range for each retained credit event.
- Editing or deleting the original off-device reading log still does not rewrite
  already confirmed plan progress or archived provenance.
- Legacy completed-plan rows without provenance remain valid and load with an
  empty credit list.
- Malformed provenance rows are sanitized independently instead of discarding
  the completed khatm record.
- Existing `reading_plan_state_v1` remains the persistence/backup unit; no new
  backend, account or preference key was introduced.
- Turkish, English, Arabic, Azerbaijani and Russian provenance copy remains in
  localization key parity.
- The strict credit rule is unchanged: partial overlaps stay informational and
  already-completed days cannot receive duplicate credit.

Focused completed-provenance validation run `35527406849` passed:
- bundled content setup, dependency resolution and localization generation;
- formatter on all changed source/test files;
- `reading_plan_store_test.dart`, including normal-finish, final-credit,
  legacy-row and malformed-provenance cases;
- `reading_plan_test.dart`;
- `plan_strings_test.dart` localization key parity.

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

The explicit-credit integration head before this provenance slice was
`84d45530ef966c3d95f0328f97e71f4fdd18eabf`.
Android APK run #550 for that head completed setup/content/dependency/l10n steps
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

Start the required full French application locale as a dedicated localization
workstream, without mixing partial French into unrelated feature commits:

- Before editing, inspect any existing localization-language branch/work and the
  current locale resolver/picker so already-completed French work is not
  duplicated or overwritten.
- Add `fr` as a supported application locale independently from Quran meaning
  language selection.
- Extend ARB/gen-l10n and every typed/feature string layer; remove hidden
  five-locale assumptions.
- Cover the full UI surface: onboarding, Home, Quran/Reader, Learn/Hifz, Plans,
  Discover, Profile/Settings, prayer/Qibla, notifications, downloads,
  backup/privacy, errors, permissions, help and accessibility labels.
- Update parity/regression tests so French is required wherever the existing
  core UI locales are required.
- Keep production French human-reviewed/natural for Quran/Islamic product
  terminology; do not ship raw machine-only translation.
- Validate offline behavior, date/time/plural formatting and long-string layout.
- Keep French Quran meaning/audio editions as separate content-catalog assets
  subject to normal source/license gates.



Do not restart already completed recovery, notification diagnostics,
recent-reading, Home quick-actions, khatm archive or page-session work unless a
real regression is demonstrated.
