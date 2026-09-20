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
