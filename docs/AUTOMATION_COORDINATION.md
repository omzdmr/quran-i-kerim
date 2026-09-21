# Automation Coordination

This file is the coordination contract for all scheduled work on `feature/localization-v01`.

## Current status: manual development

All scheduled Quran automations were paused on 2026-09-20. This document keeps
their ownership and handoff rules for possible future reactivation, but no
automation should be assumed active. Current contributors must read
`docs/PROJECT_HANDOFF.md` and the latest repository/CI state before working.

## Active Feature Development handoff — Essential Reader

- Draft PR #3 on `automation/feature-roadmap` implements the adopted P1
  Essential/Senior Reader slice: reversible persisted preference, user-owned
  backup/restore, larger interface and Reader typography/spacing, bounded line
  measure, simplified first-layer Reader/search/selection controls, plus
  session-safe focus reading controls for true fullscreen (including app
  chrome), dimming, line focus/reading ruler, screen wake lock and resumable
  three-speed auto-scroll. The selected speed persists and participates in
  user-owned backup/restore; manual scrolling pauses auto-scroll. Navigation
  visibility handling releases all platform state when leaving either the Quran
  tab or its Read section, while lifecycle handling safely releases/reapplies
  state around backgrounding. Settings search deep-links to the focus controls.
- The slice is not landed on `feature/localization-v01` yet. The integration
  workflow only runs for the feature branch; run #560 was cancelled during
  analysis after two hours, without reaching tests or APK build. Do not
  duplicate or merge this implementation without Flutter analyzer/tests/APK
  validation, including the new `wakelock_plus` platform dependency.
- After validation, land PR #3 (or reapply it onto a newer feature HEAD without
  force-updating either branch). Validate the added `wakelock_plus` dependency,
  fullscreen system UI restoration, tab/Read-section cleanup, auto-scroll at all
  three speeds and 200%+ text on physical Android/iOS devices.

## Active Feature Development handoff — Atomic offline audio packs

- The same draft PR #3 now also contains the adopted P1 offline-audio
  reliability slice. A surah pack is marked offline-ready only after every ayah
  payload is present, SHA-256 verified, and an atomic versioned manifest has
  been published. Partial, changed and corrupt packs remain playable per
  available ayah but are surfaced as pending/repair-required, never as complete.
- Download intent is persisted separately from reproducible media bytes and is
  included in user-owned backup schema v8. Restore therefore remembers which
  reciter/quality/surah packs the user selected, while audio payloads remain
  excluded from backup; Downloads shows the re-download state and links back to
  the exact surah in Reader. Delete removes both payload and intent.
- Existing pre-manifest downloads upgrade in place after a successful integrity
  pass. Interrupted work retains resumable partials, while cancel/delete removes
  the selection. Validate pause/resume, checksum repair, legacy upgrade,
  backup/restore and large-surah performance before landing. Full Flutter and
  platform CI are still unavailable for the staging branch, so PR #3 remains
  draft.

## Active Feature Development handoff — Private qada fasting ledger

- Draft PR #3 also contains the adopted private qada-fasting ledger. Users can
  append a known or estimated debt with an optional source Ramadan year and
  private note, explicitly record completed fasts, and correct the current
  balance without rewriting history. The remaining balance and source-Ramadan
  groups are derived locally; the app does not infer religious rulings.
- The append-only ledger fails closed on malformed, duplicate, overdrawn or
  future-format records. Its local preference participates in user-owned backup
  schema v9; restoring schema v8 or older preserves newer qada data rather than
  deleting it. The UI states clearly that a user-created backup includes it.
- The ledger also has a date calendar with previous/next recorded-day
  navigation and a user-owned CSV export. Export excludes private notes by
  default; notes require explicit opt-in and formula-like user text is escaped
  before spreadsheet use. Domain, file, persistence, six-locale parity, backup
  compatibility and widget-flow tests are present, but Flutter tests/analyzer
  have not run in this worker. Keep the PR draft until full validation, then
  land without force-updating the feature branch.

## Shared source of truth
Every automation must read these before acting:
1. `docs/PRODUCT_MASTER_SPEC.md` — product requirements and non-negotiable decisions.
2. `docs/AUTOMATION_COORDINATION.md` — ownership, branch and handoff rules.
3. `docs/PRODUCT_RESEARCH_LOG.md` — research evidence and adopted/rejected ideas, when present.
4. Relevant domain docs such as `HIFZ_SYSTEM.md`, Reader and localization docs.

No automation may treat its chat memory as more authoritative than the current repository state.

## Roles

### Product Research
Purpose: discover real unmet needs, complaints, reliability risks, source/license opportunities and emerging platform expectations.
- Documentation only.
- May update PRODUCT_MASTER_SPEC and PRODUCT_RESEARCH_LOG.
- Must use `[skip ci]` in documentation-only commit messages.
- Must not change application code, tests, CI workflows or feature branches.
- Must not invent a finding just to have something to report.

### CI & Regression
Purpose: keep the integration/release path healthy.
- Owns failing tests, real regressions, build/workflow problems and concrete release blockers.
- Must classify failures as runtime bug, stale test expectation, CI/build config, infrastructure, or policy/release gate.
- Must not spend green cycles inventing speculative hardening.
- Must not implement roadmap features.

### Feature Development
Purpose: implement missing capabilities from PRODUCT_MASTER_SPEC.
- Owns `automation/feature-roadmap` staging when feature HEAD is not ready for direct work.
- Spends most of its cycle on real vertical feature slices.
- Does not perform market research.
- Does not take over CI/regression work except to observe blockers.
- Before landing anything, re-check current feature HEAD and CI state.

### Language & Localization
Purpose: own full-app locale expansion and multilingual infrastructure without competing with general feature work.
- Owns `automation/localization-language`.
- Primary write scope: `lib/src/l10n/`, localization resolver/picker, locale metadata, localization tests, localization docs, script/font/BCP-47 language metadata and language-coverage QA.
- French (`fr`) full-app locale is the immediate priority.
- May update shared UI strings only to route existing user-visible copy through localization; it must not redesign feature behavior or layouts.
- Quran meaning/audio content remains subject to GREEN/YELLOW/BLOCKED rights gates; this role may wire catalog metadata/gates but must not invent rights.
- If a locale change requires broader feature behavior changes, leave a handoff for Feature Development instead of editing unrelated feature logic.
- Before landing, re-check feature HEAD and CI state.

### iOS Parity
Purpose: continuously build and verify the native iOS side without competing with shared Flutter feature work.
- Owns `automation/ios-parity`.
- Primary write scope is `ios/`, iOS-specific CI/configuration, Apple platform metadata/entitlements, native adapters and iOS-specific tests.
- Shared Dart/lib code is read-only by default. If iOS parity needs a shared API/interface change, document the exact required contract/handoff for Feature Development instead of independently editing the same shared area.
- Because the repository may not yet contain a committed `ios/` scaffold, initial scaffold generation must happen only on `automation/ios-parity`, followed by a diff audit so generated unrelated files are not blindly landed.
- Must preserve Android/common behavior and rebase/compare against current feature HEAD before any handoff.
- May advance even while Android/shared feature CI is busy, as long as changes stay isolated.
- Real signing/provisioning blockers are documented; never fake a distributable IPA.

## Branch ownership
- Integration/product branch: `feature/localization-v01`.
- Feature staging: `automation/feature-roadmap`.
- Language/localization staging: `automation/localization-language`.
- iOS parity staging: `automation/ios-parity`.
- CI/regression staging if needed: `automation/ci-regression-fix`.
- Research should normally commit docs directly to feature with `[skip ci]`, after re-reading current HEAD.
- Never reuse another role's staging branch for unrelated work.

## Safe handoff protocol
Before any code commit is moved to the feature branch:
1. Fetch the current feature HEAD.
2. Compare staging base against current feature HEAD.
3. Rebase/reapply if feature moved.
4. Ensure the corresponding CI/regression blocker is resolved or unrelated.
5. Run the narrow relevant tests locally/through available CI.
6. Land the smallest coherent commit.
7. Let normal CI validate the integrated state.

If the feature branch moved during the run, do not force-push or overwrite newer work.

## What counts as a bug
A red test is not automatically a user-facing bug.
- Runtime/state/data/navigation behavior is wrong -> real app bug.
- Intentional new key/feature exists but expected-set test is stale -> test expectation drift.
- Workflow/scaffold/signing/resource issue -> CI/build bug.
- Runner/network/billing outage -> infrastructure, no code change.
- Rights/signing/source rule blocks release -> policy/release gate.

Report the class explicitly so product work is not swallowed by maintenance.

## Documentation discipline
PRODUCT_MASTER_SPEC answers **what the product must become**.
PRODUCT_RESEARCH_LOG answers **why a new requirement was added or rejected**.
AUTOMATION_COORDINATION answers **who is allowed to change what and how work is handed off**.
Domain docs answer detailed implementation/algorithm questions.

Avoid duplicating entire requirements across all documents. Link to the authoritative section instead.

## Global-language vision is non-negotiable
The language goal is a first-class product pillar, not a later polish item:
- UI language is independent of Quran meaning/translation language.
- Target every legally verified Quran meaning language that can be shipped under the product's commercial/ad-supported license constraints.
- Support multiple editions per language with explicit translator/publisher/version/source.
- Support human spoken translations where rights-cleared recordings exist; never substitute TTS.
- Use downloadable text/audio/font packs and signed catalog manifests so language coverage can expand without app releases.
- Handle BCP-47, script, direction, native names, mixed RTL/LTR and dynamic font packs correctly.
- Human-reviewed UI localization can expand beyond the initial locales.
- Language coverage must be measurable in CI/catalog QA: text coverage, audio coverage, fonts, license state and offline-pack integrity.
- No production UI should advertise a language whose required content is YELLOW/BLOCKED or incomplete.
