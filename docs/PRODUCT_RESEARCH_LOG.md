# Qur'an App — Product Research Log

This file is the evidence log for continuous product research. It complements `docs/PRODUCT_MASTER_SPEC.md`; it does not replace it.

## Rules
- The hourly product-research automation reads `PRODUCT_MASTER_SPEC.md` first to avoid rediscovering old ideas.
- Only genuinely new, useful findings are logged.
- No finding is added merely to make the hourly run look productive.
- Prefer repeated complaints, multiple independent sources, official changelogs/support pages, or concrete product behavior over a single anonymous opinion.
- Each entry should classify the finding as NEW FEATURE, UX/IA, RELIABILITY/BUG CLASS, PRIVACY/TRUST, CONTENT/SOURCE/LICENSE, PLATFORM, or REJECT.
- Decisions: ADOPT, INVESTIGATE, REJECT.
- ADOPT items that materially change the product must also be converted into a clear requirement in `PRODUCT_MASTER_SPEC.md`.
- REJECT items should be logged only when the rejection is strategically useful, not to create a graveyard of every bad idea on the internet.
- Code changes do not belong in this file.

## Entry template

### YYYY-MM-DD — Short finding title
- **Class:** UX/IA
- **Decision:** ADOPT
- **Signal:** Repeated App Store complaints / Reddit thread / official feature / etc.
- **Sources:** URLs or source identifiers
- **Finding:** What users are actually asking for or complaining about.
- **Product decision:** What we will do, avoid, or investigate.
- **Master spec:** Section changed, if any.
- **Notes:** Confidence, caveats, licensing/privacy concerns.

## Research rotation
1. Quran Reader / Mushaf / Advanced Study
2. Hifz / memorization / learning
3. Prayer / Qibla / notifications / widgets / Watch
4. Dua / Adhkar / Hadith / library
5. Halal scanner / places / travel / flight
6. Ramadan / Hajj / Umrah / fasting
7. Family / children / new Muslim / Muslimah / privacy
8. Mosque / community / events / volunteering
9. Accessibility / elderly / tablet / desktop / offline
10. Monetization / privacy / account / sync / data loss
11. “Why I deleted it” / “wish it had” review mining
12. Emerging apps, changelogs and 2026 platform capabilities

## Guardrails
- Product vision: WeChat breadth, YouVersion/Bible App clarity, Instagram-level modern polish, Duolingo-like guidance.
- Broad scope is acceptable; clutter, hidden paywalls, intrusive ads, public social-feed mechanics, mandatory accounts, AI fatwa/chatbot behavior and automatic tajwid correctness grading are not.
- Free/open-source code never automatically proves commercial redistribution rights for the underlying religious/content data.
- High-risk halal/legal/finance/health features require authoritative sources, transparent uncertainty and appropriate jurisdiction/privacy constraints.

### 2026-09-20 — Hifz review coverage needs an explicit “untouched/age” model
- **Class:** UX/IA + RELIABILITY/BUG CLASS
- **Decision:** INVESTIGATE
- **Signal:** Multiple independent 2026 Hifz discussions/products converge on the same problem: revision blind spots are hard to notice, page-level history matters, and losing review history during an update is especially damaging.
- **Sources:** https://www.reddit.com/r/Hifdh/comments/1s83uk7/spaced_repetition_app_recommendations/ ; https://www.reddit.com/r/Hifdh/comments/1ur1xq0/i_built_an_app_to_track_my_daughters_quran/ ; https://www.reddit.com/r/Hifdh/comments/1trm9w6/built_an_app_to_fix_my_own_quran_hifz_frustrations/ ; https://www.reddit.com/r/Hifdh/comments/1v7cwt0/i_made_a_free_app_for_hifz_revision_it_listens_to/
- **Finding:** Existing master-spec concepts cover revision freshness, adaptive scheduling, page-centric Hifz and migration safety, but the market signal is more specific: users need to see which memorized pages/ranges have gone untouched longest, not merely a generic weak/strong score. A parent managing multiple learners described the core burden as remembering what was tested last and what had not been touched for weeks; another Hifz product explicitly targets unseen review blind spots. Separately, a RetainQuran user reported an update deleting spaced-repetition memory, making review-history durability itself part of the feature's trust contract.
- **Product decision:** Investigate a page/range-level review-coverage ledger derived from local practice events: `lastReviewedAt`, review age/overdue state, recent review count and user/self-rated outcome, with a “longest untouched”/coverage view. It should complement, not replace, the existing review-first scheduler and visual-memory confidence. Multi-learner profiles should keep this ledger isolated per learner. Treat migration/restore loss of this ledger as a Hifz data-loss regression. Do not adopt a specific FSRS/SM-2 algorithm merely because competing apps use one; `HIFZ_SYSTEM.md` remains algorithm authority.
- **Master spec:** No change yet; current V14/Hifz requirements partially overlap. Promote to an explicit requirement only after confirming the gap against `HIFZ_SYSTEM.md`/implementation and preferably one more independent user signal.
- **Notes:** Medium-high confidence in the user problem, lower confidence that a new product requirement is needed rather than a clearer presentation of already-planned revision-freshness data. No religious-content or licensing dependency; all proposed state is user-generated/local.

### 2026-09-20 — Prayer notification diagnostics should include an immediate end-to-end self-test
- **Class:** RELIABILITY/BUG CLASS + UX/IA + PLATFORM
- **Decision:** INVESTIGATE
- **Signal:** Multiple independent prayer apps/support pages expose a test-notification path specifically because users otherwise discover broken notification/sound configuration only when an actual prayer alert fails. Pillars uses the test as part of its troubleshooting flow; Hayya and IslamOne expose dedicated test notifications; Muslim Pro documents multiple iOS permission/Focus/alarm failure modes.
- **Sources:** https://www.thepillarsapp.com/faqs ; https://apps.apple.com/no/app/hayya-prayer-times-qibla/id6772190577 ; https://islamoneapp.github.io/prayer-times-qibla-app.html ; https://helpdesk.muslimpro.com/help/en/articles/muslim-pro-alarm-not-working-fix-it-for-your-ios-device ; https://quanticapps.zendesk.com/hc/en-us/articles/115003671929-The-notification-for-the-Athan-doesn-t-fire
- **Finding:** The current master spec already requires notification diagnostics for permissions, Focus/DND, exact alarms, battery state and the next scheduled notification, but that is largely configuration/state inspection. Market implementations repeatedly add a user-triggered notification/adhan self-test so the user can verify the real delivery path and selected sound immediately instead of waiting until Fajr or another prayer. Hayya's July 2026 changelog also fixed notifications stopping after the app had not been opened for several days, reinforcing that scheduling health can fail independently of the visible preference state.
- **Product decision:** Investigate extending the existing notification-diagnostics requirement with an explicit end-to-end self-test: schedule a near-immediate local test using the currently selected notification profile/sound, tell the user what should happen, confirm whether the app observed the expected scheduling state, and route failures to platform-specific remediation (permission, Focus/DND/time-sensitive capability, Android battery/exact-alarm/OEM restrictions). The test must be clearly labeled as a test and must not alter prayer-completion history or worship metrics. Prefer local/on-device diagnostics; no account/backend dependency.
- **Master spec:** No change yet because `Prayer, Qibla & Fasting` already contains notification diagnostics. Promote the self-test to an explicit sub-requirement if implementation audit shows diagnostics currently lack a real delivery test.
- **Notes:** High confidence in the reliability problem and the usefulness of a self-test; medium confidence that this requires a distinct master-spec bullet rather than implementation detail under the existing diagnostics requirement. No religious-content or licensing dependency.