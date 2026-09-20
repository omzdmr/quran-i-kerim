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

### 2026-09-20 — Hadith references need edition-aware identity, aliases and numbering crosswalks
- **Class:** CONTENT/SOURCE/LICENSE + UX/IA + RELIABILITY/BUG CLASS
- **Decision:** ADOPT
- **Signal:** Independent 2026 Hadith products and developer reports expose the same structural problem: a bare collection + number is not always a stable identity across editions/reference systems. A developer preparing a Hadith corpus reports missing/inconsistent numbering and mismatched English/international references; Deen2u explicitly warns that its Sahih Muslim running numbers do not correspond to standard/sunnah.com numbers; Hadith-Viz explains numbering ambiguity instead of guessing; HadithPal deliberately pins its numbering to a named external scheme and exposes source/translator identity.
- **Sources:** https://www.reddit.com/r/MuslimDevelopers/comments/1uarn7t/building_kitably_taught_me_that_preparing/ ; https://deen2u.com/hadith/browse/ ; https://hadith-viz.com/howto.html ; https://clearstackapps.com/apps/hadithpal/ ; https://hadith-hub-go.com/
- **Finding:** The master spec requires Hadith collection/book/chapter navigation, grading/source metadata and reference search, but it does not explicitly define canonical record identity versus edition-specific citation aliases. This can create a serious trust bug: a user pastes “Muslim 1234” from another app/book and the app confidently opens a different narration because the same number belongs to a different numbering scheme. Counts also differ when chains/variants are split or merged. The problem is data-model/reliability, not merely search polish.
- **Product decision:** Hadith records should use an internal stable canonical ID independent of display numbering. Each record may carry one or more explicit reference aliases/crosswalk entries with collection, book/chapter where available, numbering/edition scheme, number including suffixes such as `2564b`, source/version and verification status. Reference search must resolve known aliases, show the scheme/source used, and surface ambiguity when multiple records are plausible instead of silently guessing. Imported bookmarks/deep links should preserve the original citation string and resolved canonical ID. Cross-edition mappings must be sourced/verified data, never inferred solely from matching numbers. Exact corpus/text/translation/grading rights remain under the normal GREEN/YELLOW/BLOCKED gate.
- **Master spec:** Should be added under `V13 — Islamic library and long-form learning / Hadith scholarly navigation later` as an explicit edition-aware reference-identity requirement. The connector write surface only supports whole-file replacement and the current master spec is too large to safely reconstruct from a truncated read in this run, so the source-of-truth edit is intentionally deferred rather than risking truncating the document.
- **Notes:** High confidence. This is supported by a developer data-preparation report plus multiple independent products that either warn about numbering divergence or deliberately name/pin their numbering scheme. It also improves multilingual/global-library interoperability because translations/editions can point to the same canonical narration while retaining their own source reference.

### 2026-09-20 — Muslim travel needs offline, staff-facing dietary communication cards
- **Class:** NEW FEATURE + UX/IA + PLATFORM + PRIVACY/TRUST
- **Decision:** ADOPT
- **Signal:** Multiple independent 2026 travel products converge on the same practical gap: finding a supposedly halal place is not enough when the traveler and restaurant staff do not share a language. Halal Yalla explicitly ships multilingual dietary cards for Muslim travelers and says language barriers were a founding problem; Zouba ships chef-facing communication cards; DineNote independently uses prioritized staff-facing cards for dietary/religious restrictions; current China travel discussions still tell Muslim travelers to save large local-language phrases on their phones because hidden lard/broth and communication failures remain common.
- **Sources:** https://www.halalyalla.app/ ; https://zouba.ai/ ; https://www.dinenote.app/ ; https://www.reddit.com/r/traveltochinamainland/comments/1td2noj/vegetarian_and_halal_survival_guide_for_china/ ; https://www.reddit.com/r/AskAChinese/comments/1txsdei/zhangjiajie_muslim_trip/ ; https://chinamuslimkit.com/
- **Finding:** The master spec has halal/travel discovery, offline travel packs and global-language infrastructure, but it does not explicitly give the traveler a reliable, non-conversational way to communicate dietary requirements to restaurant/shop staff. This is especially valuable in China/Japan/Korea and other destinations where English is unreliable and the relevant risk may be hidden ingredients such as pork/lard, alcohol or meat stock rather than an obvious meat dish. A static, large-text card is also more dependable than live cloud translation in a basement restaurant, aircraft/roaming dead zone or behind restricted connectivity.
- **Product decision:** Add an optional offline `Dietary communication card` inside the travel pack. It should show professionally/human-reviewed local-language phrases in large staff-facing text, with the user's chosen constraints assembled from a controlled vocabulary (at minimum halal requirement, no pork/lard, no alcohol, and explicit ask/confirm wording). Keep religious/dietary requirements separate from medical allergy severity; if allergy phrases are ever supported, label them distinctly and require stronger translation/medical QA. Cards should work without account/network, support saved destination languages and optionally export/share as an image for offline use. Never use generative AI at display time to invent a safety-critical translation. The card communicates requirements; it must not certify the restaurant or claim a dish is halal.
- **Master spec:** Add under `Worship & Discover` / Hajj-Umrah and general Muslim travel tooling, with linkage to `Global-language Bible-App vision` for human-reviewed phrase packs. Source-of-truth edit is deferred in this run because the connector returned the very large master spec as truncated content; replacing the whole file would risk deleting unseen sections.
- **Notes:** High confidence in the user problem and product pattern: three independent products implement staff-facing cards, while current traveler discussions independently describe the language/hidden-ingredient problem. This is compatible with local-first/offline-first and does not require a halal-verdict engine. Phrase-pack licensing/provenance should be tracked if translations come from an external publisher; first-party human-reviewed translations can be versioned like localization assets.