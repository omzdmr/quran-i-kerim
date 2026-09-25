# Agent Coordination

This file coordinates scheduled ChatGPT tasks, long-running Work/Codex sessions, and human contributors. Repository state is authoritative. A chat's memory must never override the current branch, tests, or the source-of-truth docs.

## Source-of-truth order
1. `docs/PRODUCT_MASTER_SPEC.md`
2. `docs/PROJECT_HANDOFF.md`
3. `docs/AGENT_COORDINATION.md`
4. `docs/AUTOMATION_COORDINATION.md`
5. Relevant domain docs such as `HIFZ_SYSTEM.md`, `READER_INTERACTIONS.md`, `LOCALIZATION*.md`, `GOOGLE_DRIVE_BACKUP.md`
6. Current code, tests, and CI

## Work lanes
### Hourly core development
- Integration: `feature/localization-v01`
- Staging: `automation/feature-roadmap`
- Owns shared Flutter/Dart product feature slices.
- Must not overwrite active native-iOS work.

### Hourly iOS parity
- Branch: `automation/ios-parity`
- Owns native Apple/Xcode/Swift adapters, entitlements, platform tests, and iOS parity.
- Shared Flutter/Dart is read-only by default; shared API needs become handoffs.

### Long Work/Codex session
- Use a dedicated branch with prefix `work/quran-`.
- Never write directly over another agent's active staging branch.
- Before starting, fetch the latest integration HEAD and inspect recent coordination comments/issues and `PROJECT_HANDOFF.md`.
- Pick a non-overlapping vertical slice. If an hourly agent is already touching the same module/data model, choose another slice unless the owner explicitly assigns a takeover.

## Coordination protocol
Before meaningful work:
1. Record base SHA, branch, chosen vertical slice, and expected modules/files in the relevant GitHub coordination issue.
2. Read the latest handoff and current HEAD again.
3. Do not duplicate work already integrated or actively owned elsewhere.

During work:
- Commit coherent slices with descriptive messages.
- Re-check upstream HEAD before each commit/landing decision.
- Keep persistent user-data features aligned with the shared backup contract: persistence + migration + backup registry/serialization + restore validation + tests.
- Cache/re-downloadable content and secrets/tokens stay outside user backup.
- Do not change product requirements merely to avoid a blocker.

At every meaningful handoff:
- Update `docs/PROJECT_HANDOFF.md` with what is complete, exact blockers, validation status, and the next concrete step.
- Leave a concise GitHub coordination comment with commit SHA(s), tests/CI, files/modules touched, and ownership status.
- A new agent must be able to continue from GitHub alone.

## Pause / quota / interruption rule
If a long Work/Codex session is stopped by usage limits, approval, network/tooling failure, or user interruption:
1. Do not claim completion.
2. Preserve coherent work in its dedicated branch when safe.
3. Update `PROJECT_HANDOFF.md` with the exact partial state and next executable step.
4. Mark the coordination entry as PAUSED, not DONE.
5. On resume, re-fetch current HEAD and re-read this file and the handoff before changing anything. Never resume blindly from stale chat context.

## Conflict rule
If two agents overlap, the newer integrated repository state wins. No force-push/force-update. Rebase/reapply or abandon stale work. If a safe merge is unclear, leave a handoff and move to a non-overlapping backlog item.

## Completion rule
A sub-feature is not the project finish. Continue until the applicable `PRODUCT_MASTER_SPEC.md` completion criteria are satisfied, including backup/restore coverage for persistent data, reliability/offline/migration/license gates, Android release verification, mandatory iOS parity, and real signed release artifacts where required.
