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

## Integrated progress immediately before this handoff

- Missed-day reading-plan recovery is connected to the user flow and persists
  the chosen recovery strategy.
- Settings search opens real settings destinations.
- Prayer notification diagnostics shows permission, exact-alarm availability
  and scheduled prayer-notification count. Commit `29470ca` fixes its analyzer
  failure; confirm the latest CI result rather than assuming it is green.
- The earlier feature staging branch contains a screen-reader improvement for
  the Home prayer card. This handoff's current feature slice reapplies it on
  top of the latest integration branch.

## Current feature slice in this commit

Home now exposes up to three useful recent Quran-reading contexts beneath the
primary Continue card:

- Consecutive ayahs from the same surah/source do not flood the list.
- The current reading context is not repeated.
- Tapping a recent item returns to its exact surah and ayah.
- Its saved Quran source is restored only when that offline source is still
  installed; otherwise the current source remains active.
- History changes notify Home immediately.
- Turkish, English, Arabic, Azerbaijani and Russian labels plus repository and
  selection tests are included.

## Safe continuation checklist

1. Fetch `feature/localization-v01` and read the latest commits/diff.
2. Check the latest GitHub Actions run and exact failing step, if any.
3. Finish or repair the current vertical slice before selecting another one.
4. Choose one user-visible requirement from `PRODUCT_MASTER_SPEC.md` and carry
   it through state/data, UI navigation, accessibility and tests where
   applicable. A model, adapter, documentation sync or test alone is not a
   finished feature.
5. Run formatter/analyzer/relevant tests. Let Android CI validate the integrated
   branch; classify infrastructure failures separately from code failures.
6. Update this file whenever the active feature, blocker or next concrete step
   changes.

## Immediate next step

Validate this Home recent-reading slice in CI, fix only evidence-backed errors,
then select the next visible roadmap feature. Do not restart Reading Plan
Recovery or notification diagnostics unless a real regression is present.
