# Qur'an App — Master Product Specification

This file is the product source of truth. The hourly automation must read it before choosing work. Never implement one feature in isolation if it breaks the system below.

## Product identity
- Bottom navigation stays: Ana Sayfa / Kur’an / Planlar / Keşfedin / Siz. No sixth tab.
- Kur’an: Oku / Öğren / İlerlemem. Öğren: Dersler / Ezberle / Makaleler-Referans.
- Journey: Oku → Dinle → Anla → Öğren → Ezberle → Tekrar et.
- Local-first/offline-first. Core Quran reading must not require a backend.
- UI language and content/meal language are independent.
- No TTS for Quran, spoken meal or tafsir. Human recordings only when rights are verified.
- No AI fatwa/chatbot, no model-invented religious content, no automatic recitation/tajwid religious correctness scoring.
- No public leaderboard, open social feed or marketplace.
- Core Quran reading, prayer times, last-read, basic search/bookmark remain usable without subscription.

## UX constitution
The app must feel modern, elegant and calm, closer to YouVersion/Bible App hierarchy than a crowded utility grid.
- Features are visible and discoverable, but not all equal in visual weight.
- Reader is text-first. Ayah/word selection reveals contextual actions.
- Common actions: Dinle, Not, Kaydet, Vurgula, Karşılaştır, Paylaş.
- Advanced Study, roots, morphology, phrase study, tafsir, hadith, qiraat remain easy to reach in a second layer.
- One mini-player expands into a full player; advanced audio controls live there.
- Keşfedin is the utility/library/atlas/Hajj-Umrah/Qaida hub.
- Siz is settings/downloads/storage/backup/privacy/source-license/profiles.
- Universal search/command finds both content and features.
- No dead cards. Unsupported/unlicensed capabilities do not appear.
- Phone, tablet and desktop use different information density.
- Existing visual system is preserved unless explicit design reference/decision exists.

## Home dashboard
Home is a living personal dashboard, not an empty page and not a promo feed.
First viewport:
1. Greeting/date/search/profile.
2. Large Kaldığın yer / Okumaya devam et card with surah/ayah/page, last session, progress and correct Reader/meal/audio state restore.
3. Bugünkü hedeflerin with only active goals: pages, minutes, listening, review, hifz.
4. Compact next prayer + countdown.
5. 4–6 customizable quick actions.
Below:
- Sourced/deterministic Günün Ayeti.
- Active plan/khatm.
- Öğrenmeye Devam Et using current Qaida/vocabulary/lesson/hifz state.
- Weekly activity strip/summary.
- 2–3 real discovery cards.
Home adapts for new user, active reader, hafiz, Ramadan and travel. No XP/hasanat/public competition.

## Quran Reader & Mushaf
- Verse list + authentic fixed Mushaf page modes.
- Hafs first; Warsh/Qalun/etc only as separate verified text/layout/audio datasets. Never simulate riwayat with a font.
- Uthmani/Madani/QCF, IndoPak 15/16 line, Tajweed and other licensed layout/script packs.
- Navigation: surah, ayah, page, juz, hizb, rub, ruku, manzil, sajdah, maqra when metadata supports it.
- Direct reference search such as 2:255; typo-tolerant Arabic/Latin search; page/juz navigation.
- Search Arabic, transliteration, translations, root, phrase, diacritics and pause marks where safe.
- Crash-safe last-read/recent/history/khatm.
- Arabic/transliteration/meal layers.
- Translation-only book mode, clearly labeled as meaning/translation.
- Multi-translation comparison and history.
- Pin different ayahs side by side.
- Notes, highlights, bookmarks, collections, tags, backlinks, rich notes, audio notes and private mnemonic notes.
- Partial word/ayah-range copy/share when source rights allow.
- Word-by-word and phrase-by-phrase study.
- Root, lemma, POS, morphology, same-root occurrences.
- Gharib al-Quran learning mode from verified lexicon.
- Verified waqf/ibtida learning and per-ayah Tajweed rule sheets.
- Learning-aware Reader may show user-derived vocabulary status.
- Word/range audio selection and loop only with trustworthy timing data.
- Focus mode, auto-scroll, keep-awake, reading ruler/line focus, E-Ink/low-motion.
- Pinch on flow Reader changes actual text size; fixed Mushaf zoom remains separate.
- Camera/screenshot page identifier resolves to canonical ayah IDs. OCR never becomes canonical text.
- System print, study PDF, stylus/Pencil anchored notes, Study Canvas and multi-Mushaf/workspace tabs.
- Page-continuation cue only where source/layout supports it.

## Advanced Study
Separate workspace for heavy tools:
- Meal, Words, Tafsir, Hadith, I'rab, Asbab al-Nuzul, Related Verses, Qiraat.
- Multiple sourced surah introductions and sourced juz summaries when commercial-safe.
- Thematic surah maps.
- Quran Atlas: people, places, nations, events, geography/Seerah routes with certainty labels.
- Scholarly nazm/ring/parallel structure views with explicit attribution; competing analyses may be side by side.
- Revelation chronology, Quran sciences, historical Mushaf/rasm/dabt as separate academic mode.
- Qiraat comparison only with verified scholarly datasets and compatible audio.
- Curated topic taxonomy allowed. Semantic retrieval may rank canonical/source-backed results, never become generative tafsir.

## Audio
- Verified human reciters and human spoken translations only.
- Background/lock-screen/Control Center; proper call/headphone/Bluetooth handling.
- Previous/next, metadata, verse follow/highlight.
- Arabic recitation → optional spoken meaning chain when licensed.
- Speed, silence between ayahs, A-B/range repeat, sleep/end-of-ayah/surah/juz, playback profiles.
- Playlists and audio-khatm.
- Reciter filters: Murattal, Mujawwad, Muallim, qiraat, bitrate, offline.
- Reciter A/B comparison: same ayah/range alternated between selected reciters, learning aid only.
- Reciter + surah + ayah recognition from external audio with confidence.
- AirPlay/Chromecast/system routes, CarPlay/Android Auto safe controls, Watch controls, headset/keyboard commands.
- Whole-reciter/surah downloads, bitrate/source quality metadata and offline fallback.

## Learn
- Elifba/Noorani Qaida: letters, harakat, sukun, shadda, joining, human pronunciation.
- Mahreç/sıfat lab with licensed diagrams and human examples; user record-and-compare, no automatic religious grading.
- Vocabulary: frequency tiers, themes, POS, root, bidirectional quizzes, harakat, session size and spaced review.
- Sourced lesson flow: intro → ayah → meal → sourced explanation → verified hadith/context if applicable → quiz → summary → return Reader.
- Articles/reference and licensed human tafsir audio.

## Hifz
HIFZ_SYSTEM.md remains algorithm source of truth:
- Review-first 7/14/30, missed-day recovery, adaptive load, due reviews suppress new material.
- Optional Sabaq/Sabqi/Manzil terminology.
- Hide/hint/first-letter/blur/tap/swipe reveal.
- Random page/ayah, next ayah, preceding ayah, transition and fill-gap tests.
- Personal manual mistake ledger at ayah/word level.
- Mutashabihat Lab: aligned similar passages, word-order/add/remove/ending differences, before/after tests.
- Sourced dawabit where licensed plus clearly labeled private user cues.
- Own voice recording/playback, study recipes, two-rakah preparation, prayer-surah study sets, backup/restore.

## Plans & Progress
- Reading/listening/hifz/study goals.
- Daily/weekly/monthly metrics, heatmap, streak recovery, real activity.
- Flexible khatm by page/juz/time/date with missed-day redistribution.
- Reverse/custom order.
- Manual/off-platform sessions marked manual.
- Invite-only family/friends khatm with auto page/juz/hizb assignment and rebalancing.
- Prayer-anchored personal routine planner later.

## Prayer, Qibla & Fasting
- Multiple verified regional methods, madhab/Asr, custom angles, high-latitude rules, per-prayer offsets, DST/timezone tests.
- Manual city, saved places, opt-in location.
- Separate calculated adhan time from mosque iqamah/Jumuah/Eid.
- Authorized/public mosque timetable sources and safe manual/photo/CSV override.
- Mosque metadata may include women’s prayer space, wudu, accessibility, parking/family facilities only from trustworthy sources.
- Qibla calibration, declination, accuracy state, haptic lock; AR later opt-in.
- Per-prayer notification profiles and advance reminders.
- Notification diagnostics for permissions, Focus/DND, exact alarm, battery and next scheduled notification.
- Islamic midnight + last third of night and optional Tahajjud/Qiyam reminders.
- Optional Duha reminder from sourced timing rule.
- Ramadan/qada fasting, private menstrual pause, Monday/Thursday and White Days reminders/tracking.
- Hijri offset and sourced moonsighting alternative.
- Prayer calendar ICS export.
- Optional local calendar-aware prayer-window helper with explicit permission; never upload meeting titles/content.
- Optional mosque geofence silent-mode reminder, opt-in only.
- Optional solar/prayer timeline.

## Worship & Discover
- Zikirmatik, sourced morning/evening adhkar, duas, Esma.
- Favorites plus user-created private dhikr/dua lists and reminders, visually distinct from sourced canonical material.
- Verified guides: wudu, ghusl, tayammum, salah, Jumuah, Eid, Tarawih, Witr, Tahajjud, Duha, Istikhara, Janazah, Sajdah; jurisprudential variants attributed.
- Ruqyah only as sourced ayah/dua, no medical cure claims.
- Zakat later; verified charity directory only if current/legal/public data exists.
- Hajj/Umrah travel pack: Tawaf/Sa'i counters, haptic, offline map/meeting point, hotel/camp, packing, emergency/group itinerary.
- Seerah timeline/maps with uncertainty labels.
- Independent Hadith Library only with commercial-safe licensed collections and grading/source metadata.

## Family, teacher & private community
- Local multi-learner profiles.
- Child-safe mode: simplified UI, content allowlist, parent/settings/purchase PIN, external-link guard, no ads.
- Teacher/school local or user-owned workspace: roster, attendance, assignments, manual correction markers, rubrics and progress reports.
- QR/file/Drive assignment packages, student recording/progress export, teacher feedback import.
- Nearby/private Halaqa via QR/local network; leader page follow and optional pointer/drawing.
- Closed study sharing only. No public feed/discovery/leaderboard.

## Khutbah/live language later
- Private Jumuah/khutbah notes and recordings.
- Live khutbah transcription/translation may be explored, but must be clearly labeled machine transcript / machine translation and never become religious Q&A, summary, fiqh or tafsir.
- Prefer on-device speech. Cloud requires explicit opt-in, privacy and cost disclosure.
- Never create a dependency for core Quran/prayer functionality.

## Platforms
- Widgets, lock-screen, Live Activities, Siri/App Intents/Shortcuts, Android shortcuts/voice actions.
- Optional Home Assistant.
- TV/home/mosque kiosk with trusted prayer/iqamah/current ayah/audio and offline cache.
- Tablet/landscape split and two-page layouts, Stage Manager, hardware keyboard.
- Desktop Windows/macOS/Linux after mobile core if architecture supports.
- Web/PWA companion for share bundles.
- visionOS/spatial later, non-blocking.

## Accessibility
- Truly large persistent Arabic/translation text, Dynamic Type, pinch-resize, line spacing, large touch targets.
- Offer an optional persistent Essential/Senior/Low-vision preset over the same Reader and user data: enlarge Arabic, translation, interface text and touch targets together; keep a bounded readable line measure/reflow at maximum sizes; reduce the first control layer to Continue, Surah/Juz navigation, bookmark, play/pause and optional meaning, with advanced actions under a clearly labeled secondary action; expose full-screen, dimming, keep-awake and simple auto-scroll. The preset is reversible without data reset, is never inferred from age, and must pass maximum-text phone/tablet plus TalkBack/VoiceOver and representative older-device QA.
- High contrast and color-blind-safe Tajweed palette.
- Screen reader semantics, RTL/mixed-script correctness.
- Reading ruler/line focus, Reduce Motion/E-Ink.
- Braille/refreshable Braille only with verified data/platform support.
- Sign-language Quran meaning/tafsir video only when licensed.

## Offline, storage & reliability contract
These are release requirements:
- Airplane-mode Reader/search/bookmarks and downloaded content work.
- App updates/migrations never silently delete downloads.
- Background audio survives normal lock/app-switch/Bluetooth/CarPlay.
- Last-read, bookmarks, notes, hifz, plans, streaks and download state are crash-safe and migration-tested.
- Core local mode starts when network/catalog/backend is unavailable.
- User controls download scope, Wi-Fi-only/low-data, size/free-space.
- HTTP range/resume/checksum/integrity for large downloads.
- Arabic shaping, harakat, waqf, QCF/Uthmani rendering have reference/golden integrity tests.
- Canonical Quran text is never mutated by normalization.
- Arabic search debounces/batches; heavy per-keystroke work must not break typing.

## Global-language Bible-App vision
Goal: legally verified every available Quran meaning language, not a fake marketing count.
Catalog stores BCP-47/ISO, native name, script/direction, text editions, spoken editions, compatible recitations, fonts, offline size, source/version/checksum/attribution/license.
- Text/audio are independent packs.
- Signed manifests may expand catalog without app update.
- No human spoken translation → Arabic recitation + written meaning, never TTS.
- Multiple editions per language with clear translator/publisher/version.
- Dynamic fonts and mixed-direction tests.
- Publisher/NGO/official import pipeline requires permission evidence, checksum and review.
- UI localization may grow through human-reviewed community workflow.
- Sign-language/Braille variants may be first-class catalog entries.

## Licensing, content QA & ads
This product is ad-supported. Free online access does not imply commercial redistribution permission.
Every external asset requires machine-readable provenance: ID/type, language/edition, source URL, rights holder, license, commercial/ads/redistribution/offline/modification flags, attribution, cache/update requirements, permission evidence, version/checksum and GREEN/YELLOW/BLOCKED status.
Only GREEN ships. CI runs license/content-SBOM audit. Keep LICENSES, ATTRIBUTION and machine-readable content-license manifest. New source versions require staging diff/QA. Support takedown/revocation kill switch.

Conservative policy:
- Tanzil Arabic text only under exact license conditions.
- Tanzil translations NC unless separate commercial permission.
- Quran Foundation content follows current Developer/Content Sync/cache/attribution/ad-profile restrictions.
- QuranEnc/KFGQPC remain YELLOW when ad-supported commercial rights are not explicit.
- AlQuran.cloud reciters are not GREEN without explicit commercial rights.
- Aggregator repository code license never clears content copyright.
- Quranic Arabic Corpus NC content is BLOCKED without commercial permission.
- Diyanet/community assets require upstream rights.

Ads:
- Never interrupt Reader, ayah/surah transitions, prayer/qibla, adhan/iftar/sahur, audio, study or hifz with fullscreen/interstitial/rewarded ads.
- Prefer tasteful Home/Discover placements.
- No ads in child mode.
- Never use Quran reading, prayer, madhab/riwayat, dua, precise location, fasting/menstruation, hifz or journal/reflection for ad targeting.

## Community complaints become quality tests
- Wrong prayer time / DST / mosque mismatch → transparent method + override + regression tests.
- Adhan did not fire → diagnostics.
- Downloads disappeared after update → release blocker.
- Background audio cuts → release blocker.
- Last-read/bookmark/streak/progress resets → release blocker.
- Tiny text / elderly-unfriendly flows → real large text/simple flows.
- Tablet forced portrait → responsive parity.
- Search supports typo/transliteration/direct reference.
- Translation/source identity always visible.
- Onboarding short/resumable/revisitable; in-app help remains.
- Feedback/report from exact screen includes non-sensitive diagnostics only.
- Performance/battery: no continuous GPS/unnecessary wakeups.

## Latest approved market findings
- Reciter A/B comparison.
- Islamic midnight/last-third/Tahajjud reminders/widgets.
- Monday/Thursday and White Days fasting calendar.
- Mosque amenities metadata.
- True pinch-to-resize flow text.
- Sourced juz summaries.
- User-created private adhkar/dua lists.
- Live khutbah transcription/translation later with strict machine labels/privacy.
- Calendar-aware prayer-window helper.
- Optional mosque geofence silent reminder.
- Optional sun-position/prayer timeline.
- Partial ayah/range copy.
- Search debounce/input-flow tests.
- Color-coded bookmarks/stars may complement labels/collections without clutter.
- Reciter catalog expands via rights-cleared manifests, never a tiny hardcoded list.

## Completion
Android/common complete only after all applicable items are implemented or explicitly BLOCKED for source/license/visual reasons, tree is clean, analyzer/tests/license audit/migration/offline/restore/notification tests pass, signed ARM64 APK is verified and uploaded to Drive with metadata/size/checksum.

Then move to mandatory iOS parity: native config, permissions, background audio, downloads, notifications, location/qibla, Drive and optional iCloud adapter, mic/recording, sharing/deep links/state restore, WidgetKit/Live Activities/CarPlay/Watch, Pencil/stylus, RTL/Dynamic Type/accessibility and all relevant reliability cases.

Never fake a distributable IPA. Only real signing/provision/export. If signing is unavailable, finish parity/build and record exact blocker without repeating identical failure every hour.

Final completion requires Drive-verified Android APK, complete Android/common scope, iOS parity, green iOS archive/release, real Drive-verified signed IPA, green license/content QA and reliability tests, clean tree and only intentional source/license/visual blockers. Then report final SHA/CI/tests/license summary/Drive files and disable the existing hourly automation. Never create a duplicate automation.

## Super-app daily life layer
The long-term product vision is a Muslim super-app: broad enough that a user rarely needs a separate Islamic utility app, but designed with modern YouVersion/Instagram/Duolingo-level information hierarchy rather than WeChat-style visual clutter. New modules must live in the existing five-tab architecture, mostly under Keşfedin, Home context cards and Siz management surfaces. Breadth must never compromise the calm Reader or core worship reliability.

### Unified Scan
One camera entry point should intelligently route among:
- UPC/EAN barcode -> product identity and product-data lookup.
- Recognized official halal-certificate QR/domain -> certificate verification flow.
- Ingredient-label text -> OCR ingredient extraction for evidence-based analysis.
- Printed Mushaf page -> canonical ayah/page identification.
- Supported boarding pass/flight details later -> travel/flight setup.
Do not expose five redundant scanner buttons when one modern scanner can detect the input type. Always show what was detected and let the user override when confidence is low.

### Halal product evidence model
A barcode itself never means halal. It is only a product identifier.
Use layered evidence and never collapse ingredient analysis into official certification:
1. VERIFIED CERTIFIED HALAL — current certificate matched to a recognized/approved authority source.
2. INGREDIENTS APPEAR COMPATIBLE — no problematic ingredient found, but no certification was verified.
3. NEEDS VERIFICATION / MUSBOOH — source-dependent or ambiguous ingredient/additive, uncertain processing or missing manufacturer detail.
4. EXPLICITLY INCOMPATIBLE INGREDIENT FOUND — only when a source explicitly identifies a prohibited ingredient; do not over-generalize derivative/process rulings.
5. INSUFFICIENT DATA — product, certification or ingredients cannot be verified.
Each result explains why, shows evidence/source, certificate authority, certificate/expiry where allowed, last verification time and confidence/coverage. Never present crowd-sourced data as a religious authority.

### Halal product data sources and licensing
- Open Food Facts / Halal Open Food Facts can be considered for barcode/product/ingredients/labels under their current ODbL and attribution/share-alike requirements; verify current terms before implementation.
- Product databases provide product facts, not a binding halal ruling.
- Maintain a HalalAuthorityRegistry per country/region: authority name, official domain, recognized foreign bodies if published, public lookup/API/QR support, terms, commercial reuse rights, update method and trust status.
- Official certification lookup is preferred. If an authority has no permitted API/data reuse path, deep-link to the official checker or mark verification unavailable; do not silently scrape prohibited data.
- Distinguish halal-certified, Muslim-owned, community-recommended, ingredient-compatible and unknown. Never merge these labels.
- Keep certificate revocation/expiry/update logic. Cached certificates must have expiry/last-checked metadata.
- Ingredient OCR is evidence extraction only. OCR text must be user-reviewable before analysis.
- Additive/ingredient rules require a sourced knowledge base with jurisdiction/scholarly-source metadata and uncertainty; no generative halal fatwa engine.

### Halal places and local directory
Under Keşfedin / Yakınımda, support when trustworthy data exists:
- Mosques, musallas/prayer rooms.
- Halal-certified restaurants, groceries, butchers.
- Islamic schools/centres/classes.
- Muslim-owned businesses as a separate non-halal-certification label.
- Optional doctors/dentists/bookstores/travel agencies only as directory metadata, never quality/religious endorsement.
Filters may include certification authority, last verified date, cuisine, women’s prayer space, wudu, accessibility, parking/family facilities and distance.
User-submitted changes require verification workflow; stale/unverified listings must be visibly dated or hidden.

## Travel & flight mode
General Muslim travel is a first-class Discover module, not limited to Hajj/Umrah.
Travel workspace may combine:
- Saved destination/city, prayer method and offline prayer schedule.
- Nearby prayer spaces/mosques and halal-certified places.
- Offline Quran/audio/meal readiness before departure.
- Saved hotel/meeting point and travel duas from verified sources.
- Time-zone change handling and travel-mode state.

### In-flight prayer mode
Support a dedicated Flight Mode when technically reliable:
- Flight number lookup and/or manual origin/destination/departure/arrival input.
- Optional boarding-pass scan only as input convenience; parsed data must be reviewable.
- Approximate flight path, changing local solar position, prayer windows during the flight and Qibla relative to aircraft heading/seat where technically possible.
- Save all required data before departure so the schedule/map works in airplane mode.
- Clearly label estimates and assumptions; never claim exact aircraft position without live data.
- Verified travel-prayer fiqh guides may be linked as sourced references, but the calculation engine must not invent jurisprudential rulings.
- Refresh-flight-data reminder before departure.
- Handle International Date Line/time-zone crossings and very long polar/high-latitude flights with explicit tested rules and uncertainty.

## Ramadan seasonal experience
Ramadan Mode is a seasonal dashboard/context, not a separate cluttered app:
- Suhoor/iftar timing based on the same trusted prayer engine.
- Fasting log and optional qada tracking.
- Tarawih/Qiyam tracking only if user wants it.
- Last 10 Nights planner with optional reminders and sourced Laylat al-Qadr educational material without asserting an unknown exact night.
- Quran/khatm plan and missed-day redistribution.
- Personal dua/dhikr/reflection goals.
- Optional hydration and meal planning between iftar/suhoor as general wellness logging only, with no medical claims.
- Optional nearby/community iftar/suhoor events only from verified mosque/community sources or clearly labeled user-submitted events.
- Archive past Ramadan progress by year so history does not disappear when Ramadan ends.
- Ramadan Home cards appear seasonally and disappear cleanly afterward.

## Mosque/community connection layer
A user should not need separate mosque apps for basic community information, but this must remain a trusted directory/notification layer rather than an uncontrolled social network.
Where a mosque/admin or trusted public source exists:
- Exact iqamah/Jumuah/Eid times distinct from calculated prayer times.
- Announcements, safety/closure alerts, classes, halaqas, events and registration links.
- Mosque audio/lecture archive or live-stream links if rights/official source allow.
- Facilities/accessibility metadata.
- Optional follow/subscribe per mosque with granular notification controls.
- Event RSVP may be local/deep-link based initially.
- Donations initially prefer verified external mosque payment/donation links. Do not custody funds or build payment processing without the required legal/security/compliance work.
- Mosque-claim/admin update architecture can be considered later, with strong verification and audit history.
- Avoid community messaging/public feed by default; announcements are publisher-to-subscriber.

### Verified scholar/class directory
Where official registries exist, optionally expose:
- Verified teachers/asatizah/imams.
- Islamic education centres/classes.
- Certification/registration body and current status.
No popularity ranking, theological scoring or model-generated religious credentials.

## Janazah community utility
Beyond the offline Janazah guide, an optional local Janazah-announcement layer may exist only with privacy safeguards:
- Mosque/authorized organizer posts prayer time, mosque/public venue and directions.
- User subscribes to selected mosques/areas.
- Never expose private-home addresses or sensitive deceased/family data unless explicitly public and necessary.
- Clear source/organizer identity and timestamp.
- Opt-in notifications and easy mute.
This is a community notice utility, not a social feed.

## Zakat, sadaqah and household finance
Expand the existing future Zakat module into a careful personal finance workspace:
- Multi-method/madhab-aware Zakat calculator only from verified rules.
- Gold/silver nisab basis, current price source and timestamp when live pricing is used.
- Hawl/lunar-year tracking.
- Amount due / paid / remaining and private payment log.
- Sadaqah log, categories/tags and receipt attachment.
- Optional Riya/privacy mode that hides totals/streak-like giving metrics from normal Home surfaces.
- Family/household contributions with explicit ownership.
- Never imply a logged donation is religiously accepted; this is accounting only.
- Bank linking, investing, stock screening and live financial advice are NOT core until regulatory/data/licensing and methodology requirements are separately approved.

### Faraid / inheritance education tool
Potential later deterministic calculator:
- Estate value, debts, funeral expenses, wasiyyah inputs and heir relationships.
- Madhab/rule-set explicitly selected when applicable.
- Exact fractions and transparent step-by-step calculation, including relevant awl/radd/hajb logic only from verified jurisprudential specification.
- No generative legal/religious reasoning.
- Prominent disclaimer: educational/preliminary calculation, verify final distribution with a qualified scholar/legal professional in the applicable jurisdiction.
- Jurisdiction-specific civil-law effects are outside the generic engine unless separately implemented from authoritative legal sources.

### Private estate organizer / Islamic will preparation
Local-first, biometric/encrypted:
- Asset/debt inventory, important documents, emergency contacts, funeral wishes, personal instructions and export.
- Do not present a generic generated document as legally valid in every country.
- Country-specific legal will templates require separate authoritative legal review.
- Sharing/export is explicit and user-controlled.

## Private accountability and family OS
The app may support one-to-one/family coordination without becoming social media:
- Ibadet Arkadaşım: invite one trusted person or a small private group; user chooses exactly which high-level status categories are shared.
- Prayer/Quran/hifz/fasting/notes default private; each category separately opt-in. Notes/journal never shared by default.
- Family dashboard can coordinate Quran lessons, child Qaida, household routines and prayer-anchored tasks.
- Prayer-relative tasks such as “after Maghrib” are supported in addition to clock time.
- Adult UI remains calm; children may have simplified learning UI but no manipulative coin/pet/leaderboard requirement.
- Closed family calendar, assignments and reminders can reuse local/user-owned sync.
- No stranger matching/public accountability feed.

## Unified community/service taxonomy
When directory modules expand, preserve clear entity types and evidence:
- mosque
- prayer_space
- halal_certified_business
- muslim_owned_business
- islamic_school_or_centre
- verified_teacher
- community_event
- janazah_notice
Every entity stores source, verification status, last-updated time, location provenance and allowed fields. Never infer one status from another.

## New market findings — community and seasonal utilities
- Mosque platforms increasingly combine prayer/iqamah, announcements, classes/events, safety alerts, donation links and TV displays; our user-facing app can follow verified mosques without recreating a public social network.
- Ramadan products increasingly support past-year archives, Last 10 Nights planning, hydration/meal planning and community iftar discovery. Adopt only the pieces that fit the local-first, calm-design philosophy.
- Optional mosque event/class registration and reminders are useful Discover features.
- Optional iftar/suhoor community-event finder may exist only with trustworthy organizer/source and date/location freshness.
- Local scholar/teacher directories are acceptable only from official/verified registries; do not crowdsource religious credentials.
- Janazah nearby notifications are a real standalone use case but require strict privacy and mosque/organizer verification.
- Do not add generic Islamic news as a core feature: it creates editorial/political/moderation complexity and does not serve the product’s core daily Muslim life utility + Quran learning advantage.

## V11 — community infrastructure and real-world continuity
These are approved only when they preserve the calm, non-social-feed product philosophy.

### Follow a mosque
A user may follow selected verified mosques/centres and receive:
- Official iqamah/Jumuah/Eid timetable changes.
- Closures, emergency/safety notices and important announcements.
- Classes, halaqas, youth/family programmes and special events.
- Event reminders and deep-link/RSVP when a trustworthy registration source exists.
- Official lecture/video/audio links where rights allow.
Notifications are granular per mosque and category. No algorithmic feed, engagement ranking or public comments.

### Community events
Keşfedin may show nearby verified community events:
- Halaqas, Quran/Arabic classes, family/youth programmes, iftar/suhoor, Eid events, seminars and community service.
- Every event must have organizer/source, freshness timestamp, venue and cancellation/update path.
- User-submitted events remain clearly labeled and need verification/moderation before broad distribution.
- Calendar add/export and reminders are allowed.

### Volunteering opportunities
Where mosques/registered charities publish trustworthy opportunities, show an opt-in volunteer board:
- Event logistics, food distribution, teaching support, mosque operations, charity/community-service roles.
- Role source, organizer, time/location, requirements and safeguarding checks when relevant.
- Applications should initially deep-link to the official organizer. Do not become an employment/identity-verification platform by accident.
- Never imply religious merit scoring or public volunteer leaderboards.

### Mosque admin interoperability, not mandatory backend
Long term, verified mosque admins may claim/update profiles, but the consumer app must also consume public/authorized sources and remain useful without our own universal mosque backend.
Any admin system needs:
- Strong mosque identity verification.
- Role-based access and audit history.
- Draft/publish, duplicate detection, expiry, cancellation and rollback for time-sensitive announcements/events.
- Data export and clear ownership.
Core Quran/prayer remains independent.

### Donations and fundraising
Mosque/community donation campaigns can be surfaced only from verified official sources.
- Prefer verified external links/payment providers initially.
- Show organizer/campaign identity and destination.
- No custody of user funds, recurring billing, Gift Aid/tax processing or donor CRM until separately approved for legal/security/compliance.
- Do not rank mosques/charities by donations or turn giving into competition.

### Ramadan continuity
Keep a year-scoped Ramadan archive:
- Fasts logged, Quran/khatm progress, personal goals, private reflections, Tarawih/Qiyam if tracked, and user-owned statistics.
- New Ramadan starts a new period without deleting prior years.
- Historical Ramadan data stays local/private and never feeds ad profiling.
- Last 10 Nights mode is time-limited seasonal UI, not permanent Home clutter.

### Local service discovery boundaries
The super-app may reduce the need for separate directories, but labels must stay semantically correct:
- A mosque/event/teacher being verified does not imply endorsement of every religious opinion.
- A business being Muslim-owned does not imply halal certification.
- A restaurant being community-recommended does not imply official certification.
- A certification being valid does not imply nutritional/health quality.
Display the exact evidence type and source.

### Community content deliberately excluded by default
- Generic Islamic news feed.
- Public posts/comments/follower graph.
- Stranger direct messaging.
- Viral/recommendation engagement algorithms.
- Public worship streaks or charity leaderboards.
These create moderation, privacy, political/editorial and distraction problems that conflict with the product identity.

## V12 — life-stage modes without fragmenting the app

### New Muslim / Foundations mode
Do not force a new Muslim to understand the entire super-app on day one. Provide an optional guided path that reuses existing verified modules in a sane order:
- What to do after Shahadah / foundations, only from scholar-reviewed licensed content.
- Wudu step by step.
- Salah step by step: positions, what is said, transliteration, verified human audio, what is essential vs optional only when sourced and jurisprudentially labeled.
- Prayer times and Qibla.
- Short surahs and prayer duas with memorization aids.
- Quran for beginners: Arabic/transliteration/meaning, how surah/ayah references work, how to use audio.
- Basic Islamic calendar, fasting, halal-living and mosque-visit orientation.
- Arabic/Qaida starter track.
- Gentle 30/90/365-day learning path assembled from existing lessons; no shame, public streaks or paywall on basic worship learning.
- User can choose “new to Islam”, “returning/relearning”, or normal experience. This changes guidance/order, not religious content.
- In-app glossary for common Arabic/Islamic terms.
- Progress can be hidden/reset without deleting the user’s Quran data.

Optional community support:
- Show verified local new-Muslim classes/centres when a trustworthy source exists.
- A future mentor/imam connection must use verified organizations and explicit privacy controls; never random stranger matching.
- No AI religious Q&A as a substitute for qualified people.

### Private Muslimah worship/cycle mode
Optional, never assumed from gender, and designed as sensitive data:
- Period/bleeding/purity dates and user-entered notes.
- Prayer/fasting status display based only on a clearly selected sourced jurisprudential rule set; do not silently guess madhab or issue rulings.
- Ramadan missed-fast/qada list and scheduling.
- Optional ghusl reminder/status.
- Optional Umrah/Hajj travel planning dates from user-entered cycle data; no medical prediction claims.
- If general cycle prediction/symptom logging is offered, label it health-estimate only and never medical advice.
Privacy requirements:
- Entire module can be disabled and removed.
- Local-only by default, encrypted/biometric lock option.
- No ads inside this module.
- No analytics/ad SDK events containing cycle, purity, prayer eligibility or fasting status.
- Backup is category-opt-in, encrypted where possible, with clear restore/delete controls.
- No sharing to family/accountability contacts unless user explicitly exports a specific item.
- App Home must not reveal sensitive cycle state on lock-screen-like surfaces unless user opted into that exact card/widget.

### Experience presets, not separate apps
The same codebase can offer optional experience presets:
- Standard
- Essential / Senior / Low-vision
- New Muslim / Foundations
- Hifz-focused
- Study-focused
- Family/parent
- Travel/Ramadan seasonal contexts
Presets adjust Home cards, quick actions, onboarding and suggested paths only. They must not create incompatible data silos or hide core navigation. The Essential/Senior/Low-vision preset additionally simplifies Reader control density and applies the accessibility contract above, while preserving the same last-read, bookmarks, downloads, notes and backup identity.

## V13 — Islamic library and long-form learning

### General Islamic Library
Keşfedin / Kütüphane may grow beyond Quran/Hadith into a rights-cleared structured Islamic library:
- Tafsir, Hadith, Seerah, Fiqh/usul, Aqidah, Islamic history, biographies and other scholarly categories only when source/licensing is appropriate for the ad-supported product.
- Prefer structured text/EPUB-like content with real chapters, sections, footnotes and source metadata over image-only PDFs.
- Book metadata: title, author, editor/translator, publisher/source, edition/version, language, school/tradition/context when relevant, rights/license and checksum.
- Browse by title, author, category, language and publication/author metadata.
- Full-text search in one book, selected books, an author, category or the whole installed corpus.
- Search results always quote/link to the actual source location; no AI-generated paraphrase presented as the book.
- Bookmarks, highlights, notes, tags and cross-links to Quran ayahs/Hadith records where a verified mapping exists.
- Offline book packs and storage controls.
- Reading progress and continue-reading Home cards without turning long-form reading into public competition.

### Curated reading paths
Provide optional human-curated/source-reviewed paths such as:
- New Muslim foundations.
- Seerah introduction.
- Forty Hadith / selected Hadith study.
- Quran sciences basics.
- Arabic/Quran vocabulary.
Paths organize licensed books/chapters/lessons already in the library. Do not let a generative model silently create a religious curriculum.

### Islamic audiobook / lecture library
Where distribution rights are GREEN:
- Human-narrated audiobooks, lectures, khutbah archives and courses.
- Speaker/author/publisher/source metadata.
- Background playback, lock-screen controls, speed, sleep timer, chapters, bookmarks/timestamps, offline downloads and listening history.
- Optional follow/notify for verified publisher/scholar channels only when the source allows redistribution/notifications.
- Audio transcripts only when licensed or user-generated; machine transcript must be labeled.
- No synthetic narration for copyrighted/religious books without explicit rights.

### Hadith scholarly navigation later
If a licensed structured corpus supports it:
- Collection/book/chapter/hadith navigation.
- Translation/commentary/takhreej/grading metadata with exact source attribution.
- Narrator/rawi index and chain navigation as sourced data, not generated biography claims.
- Search across matn, narrator names and references.
- Cross-link Quran ayahs only from verified scholarly mappings.

### Library licensing warning
Open-source application code or a downloadable book file does not prove the underlying book/translation/audio is commercially redistributable. Every title/edition/audio follows the same GREEN/YELLOW/BLOCKED content-provenance gate as Quran content.

## V14 — complaint-driven polish and trust requirements

These requirements come from repeated App Store/Reddit complaints and expectations. They are not optional polish if the corresponding feature ships.

### Zero-friction core actions
The user must be able to reach the three most common tasks immediately:
- Check next/all prayer times.
- Continue Quran from exact last state.
- Open Qibla.
Home should surface prayer information and continue-reading prominently. Do not insert promotional/interstitial steps before these core actions.
Where supported, home-screen widgets, lock-screen surfaces and app shortcuts may expose the same fast paths.

### Notification sovereignty
Notification permission is a trust contract.
- Asking for prayer notifications does NOT imply permission for donation prompts, generic motivation, marketing, content recommendations or unrelated religious reminders.
- Every notification category is separately controllable: adhan, pre-prayer, mosque, plan, hifz review, Ramadan, fasting, daily ayah, learning, community event, app/service notices.
- Non-essential notification categories default OFF unless explicitly selected during onboarding.
- A notification inbox/history may show what the app scheduled/sent and why.
- Provide a single “quiet everything except prayer” preset.
- Seasonal modes such as Ramadan must not silently enable new notification categories.

### Widget and notification health
Widgets and prayer notifications are daily-critical surfaces and need diagnostics:
- Last successful widget refresh.
- Last prayer schedule generation.
- Next scheduled notification.
- Permission/Focus/DND/battery/exact-alarm status.
- Timezone/location/method used.
- Manual refresh/rebuild schedule action.
- Detect stale widget/prayer data after timezone/DST/location changes.
If a widget cannot refresh due to OS limits, show cached data with a stale indicator rather than blank content where safe.

### No-account-required core
Core Quran, prayer, Qibla, local plans, bookmarks and offline downloads must work without creating an account.
- Account/cloud sync is an enhancement, not an entry ticket.
- User can export local data before signing in.
- Signing in or out must never silently destroy local progress.
- Merge/restore choices are explicit.

### Seasonal UI must be opt-in friendly
Ramadan/seasonal Home adaptations are useful but must not hijack the product:
- User can dismiss/minimize seasonal cards.
- Do not replace the normal Home with a bloated Ramadan page.
- Prayer time and continue-reading remain prominent.
- Seasonal sponsorship/promo never outranks worship utility.

### Hifz visual-memory support
Serious hifz users often rely on the exact physical page layout.
Add optional page-centric revision metadata:
- Per-page repetition counter, manually incrementable or tied to completed practice loops.
- Separate “read while looking” vs “recited from memory” session markers.
- Page-specific private notes/mistake notes.
- Visual refresh schedule for pages whose oral recall is strong but page-image confidence is weak.
- Fixed-layout Mushaf identity must be preserved; page numbers/line layout may not silently change after an update.
- Allow user to choose the exact Mushaf layout used for hifz and keep it pinned.
- Hifz progress should distinguish memorized coverage from revision freshness and visual-memory confidence.

### Recording library and precise review
Own-voice recording must not become a pile of anonymous audio files.
- Dedicated recording library by date, surah/ayah/page/range/session.
- Rename/tag/favorite recordings.
- Manual teacher/user mistake markers can attach a timestamp/ayah/word.
- Tapping a marker replays a short local segment around the marker, not the entire recording from the beginning.
- Compare current recording with a prior recording or licensed reciter A/B without grading.
- Optional export/share of a selected recording with explicit user action.

### Practice simplicity mode
Some serious hifz users explicitly dislike gamification and feature-heavy practice screens.
Offer a stripped-down practice preset:
- Mushaf.
- Hide/reveal.
- Repeat counter.
- Record.
- Self-rate.
- Next review.
No XP, animations or unrelated cards. This is an experience preset, not a separate data model.

### Per-Mushaf state
When multiple Mushaf/riwayah/layout packs exist:
- Bookmarks, last page, notes, zoom/text settings and hifz page references must retain the Mushaf/layout identity they were created against.
- Switching Mushaf must never reinterpret a page-number bookmark against another layout.
- Downloads for multiple Mushafs can queue in background with pause/cancel/resume and clear progress.
- Content updates must preserve user anchors or migrate them by canonical ayah ID with an explicit compatibility check.

### Rotation and layout continuity
Repeated complaints show orientation changes can lose place or render the wrong page.
- Portrait ↔ landscape preserves exact canonical reading position.
- Font-size changes in flow Reader preserve semantic position.
- One-page ↔ two-page tablet mode preserves the focused ayah/page.
- Rotation/page-mode regression tests are release requirements.
- Right/left physical page identity is preserved in two-page Mushaf mode.

### Built-in manual/help is permanent
The onboarding tour is not the only documentation.
- “How this works” remains available from relevant screens and Help.
- Contextual explanations for prayer methods, notification icons, Mushaf/riwayah, download packs, hifz modes and privacy states.
- Searchable help.
- Reset/re-run onboarding or a specific tutorial without resetting user data.

### Performance budgets
The calm design promise includes speed and battery:
- Home/core local screens should render from local state immediately; remote catalog refresh is asynchronous.
- No continuous location polling for prayer times.
- Widgets, Live Activities and background tasks use conservative refresh schedules.
- Search indexing/download hashing runs off the critical UI path.
- Establish regression budgets for cold start, Home first meaningful paint, Reader open, memory growth during long audio and idle battery use.
- “More features” must not make the common prayer/Quran path feel heavier.

### Respectful monetization
Repeated reviews show users tolerate funding far better than interruption.
- Never use a forced-video-ad gate to reveal prayer times/Qibla/continue Quran.
- No ad after every settings/login action.
- Purchase/subscription state is cached/restored reliably; a paid/lifetime user is never repeatedly shown ads because restore temporarily failed.
- If ad-free premium exists, failure to validate entitlement should degrade gracefully and retry, not punish the user.
- Ad category filtering/reporting must be prominent enough to handle inappropriate creatives quickly.

### Feature feedback loop
Users value developers who actually implement sensible feedback.
- In-app feature request/feedback entry grouped by screen/module.
- Existing roadmap/known-issue status can be shown in simple terms where practical.
- Allow the user to attach screenshot/log diagnostics explicitly.
- Do not automatically attach religious activity history, notes, recordings or precise location.

## V15 — additional complaint-derived reliability and transparency requirements

### Notification deduplication and storm protection
Prayer notifications must be idempotent.
- Every scheduled notification has a stable logical key: prayer/date/place/profile/type.
- Rescheduling after location, timezone, DST, method or app-update changes must cancel/replace the old logical notification instead of stacking duplicates.
- Add a hard duplicate/storm guard so a bug cannot emit dozens of notifications for one prayer.
- Diagnostics should show duplicate suppression events and the active schedule.
- Regression tests cover app update, reboot, timezone change, DST change, location change and method change.

### Settings persistence is sacred
Users repeatedly report calculation methods or display choices reverting after updates.
Persist and migration-test:
- Prayer calculation method, Asr method, per-prayer offsets, high-latitude rule.
- Hijri offset/moonsighting preference.
- Quran script/font/layout/Mushaf identity.
- Translation(s), transliteration visibility and selected reciter/audio profile.
- Notification profile and Home customization.
- Accessibility text size/line spacing/contrast.
An app update may introduce a new default for new users but must not silently overwrite an existing user choice.

### Qibla confidence, calibration and fallback
A compass sensor can be wrong even when the great-circle Qibla calculation is correct. Never present raw sensor heading as unquestionable truth.
- Separate computed Qibla bearing from live magnetic-device heading.
- Show sensor accuracy/calibration state and warn when magnetometer data is unreliable.
- Provide a simple calibration help flow.
- Cross-check with map-line/static bearing view that does not depend on live compass orientation.
- Manual location selection works without sensor access.
- If heading jumps by a large implausible amount while location is stable, show low-confidence state rather than silently rotating 180 degrees.
- Qibla screen can expose North/East/West reference markers without clutter.
- Release tests include known-coordinate bearing fixtures; hardware heading itself is treated as sensor input, not religious certainty.

### Hijri calendar transparency
Hijri dates can differ by observation authority/region.
- Always expose selected Hijri source/method and manual offset.
- Do not silently change the user’s offset after an update.
- Ramadan/Eid/White Days features use the same selected calendar source consistently.
- When an official regional sighting source is available, label it by authority and last update.
- If sources disagree, show the difference instead of pretending there is one universal observed date.

### Content/source continuity across updates
A new app/content update must not make a user’s chosen translation, Mushaf or reciter mysteriously disappear.
- If a source is removed for rights, safety or upstream reasons, show a clear migration notice explaining that the edition is unavailable and offer rights-cleared alternatives.
- Preserve the user’s preference metadata even when a pack is unavailable so it can be restored if rights/source return, unless legal deletion is required.
- Never silently substitute one translator/edition/reciter for another.
- Installed GREEN content can update only through versioned manifests/checksums and compatibility validation.
- User notes/bookmarks remain anchored to canonical ayah IDs when an edition changes.

### Religious text correction pipeline
Reported Quran/translation/tafsir metadata errors require a high-trust correction workflow.
- “Report content issue” attaches exact source/edition/version/surah/ayah/field.
- Canonical Quran text changes are never accepted from ordinary crowd edits.
- Corrections require verified upstream/source evidence and review.
- Maintain signed/versioned content patches and change logs.
- Translation corrections show edition/version history when possible.
- Emergency bad-pack kill switch may disable download/use, but user receives a transparent notice.
- Regression test verse counts, IDs, required fields and source checksums after every content update.

### Playback-control ergonomics
Accidental previous/next-ayah jumps are a real complaint.
- Play/pause hit target must be clearly separated from previous/next.
- Landscape, compact-player, large-text and accessibility layouts must preserve safe hit targets.
- Destructive/navigation audio actions require deliberate taps; no overlapping invisible gesture zones.
- Media controls include haptic/visual feedback where appropriate.
- UI tests cover compact iPhone sizes, landscape and Dynamic Type.

### Halal scanner market/factory awareness
A product name or brand is not globally identical.
- Evidence should key primarily by barcode/SKU plus market/country/manufacturer/factory/packaging data where available, never by fuzzy product name alone.
- If identical branding has halal and non-halal regional variants, show the market/factory distinction prominently.
- Do not merge conflicting barcode/database/OCR results into a single green badge.
- If barcode evidence says certified but OCR ingredients conflict, downgrade to NEEDS VERIFICATION and show both sources.
- Duplicate/conflicting community records are surfaced to QA, not randomly selected.
- Show country/market and last-seen package version when known.
- Let the user report “my package differs” and attach a product-label photo explicitly.

### Halal scanner privacy and honesty
Scanner trust requires restraint.
- Barcode lookup should not require an account.
- Ingredient images are processed on-device when feasible; cloud OCR requires explicit disclosure/consent and retention policy.
- Do not collect identity/location merely to classify a grocery product.
- Never market the scanner as “100% accurate”, “#1” or “scholar-approved” without evidence.
- Explain the evidence tier and limitations on every result.
- Search history/favorites remain local by default and can be cleared/exported.

### Subscription and trial anti-dark-pattern rules
Repeated complaints target apps that appear free but block the core function behind an immediate trial.
- Never force a trial/payment screen before prayer times, Qibla or Quran.
- Price, billing period, trial length and renewal terms are visible before purchase.
- No deceptive close button, countdown or accidental purchase flow.
- Restore purchase is prominent and reliable.
- Subscription cancellation/help links are easy to find.
- If a paid extra is unavailable, core free utility remains functional.

### Simple-mode coexistence
Some users want a super-app but only use two functions.
Provide a user-selectable “Sade görünüm” preset:
- Home emphasizes Continue Quran, prayer times and Qibla plus chosen quick actions.
- Keşfedin still contains the broader super-app modules.
- It changes presentation, not feature entitlement or data.
- User can switch back instantly without losing state.

### Progress resume must be one tap
A recurring Hifz complaint is having to reselect surah/ayah every session.
- Home/Learn/Hifz surfaces provide a true “continue current memorization/revision session” state.
- Persist exact program, Mushaf layout, range, repetition stage, review queue and audio choices.
- Session restore is migration-tested and works offline.

## V16 — routine integrity, qada planning and source transparency

### Prayer tracker states must be semantically distinct
Do not collapse different user-entered states into one color/status.
Support clear, user-controlled distinctions such as:
- prayed/completed
- completed later / qada
- pending/missed
- not tracked / user-chosen exemption state when appropriate
The app does not issue a religious verdict about the user. It records the state the user selects.
- History/calendar views must visually distinguish states without relying on color alone.
- Accessibility labels must speak the state.
- Stats explain exactly what each metric counts.
- Editing historical status is easy and auditable locally.

### Qada debt planning for large histories
A user with months/years of qada should not have to create thousands of entries one by one.
When the user explicitly chooses to use qada tracking:
- Allow estimated/bulk initialization by date range or user-entered totals.
- Batch-complete/edit periods or counts.
- Show per-prayer totals and an overall total.
- Adjustable private daily/weekly qada goal.
- Deterministic projected completion date based on the user’s chosen pace.
- Manual corrections and import/export.
- Distinguish estimated historical totals from individually logged records.
- Optional app-icon/widget remaining-count badge only with explicit opt-in because it may expose sensitive worship information.
- No shame language, public comparison or hasanat scoring.

### Arabic display profile across modules
A user’s Arabic reading preferences should feel coherent across Quran, Dua, Adhkar, Hadith and guides where technically valid:
- Arabic font/script preference when the content supports that script.
- Text size, line spacing, diacritic visibility and theme.
- Transliteration display preference.
- Do not pretend a non-Quran Arabic text is a Quranic Mushaf script when that rendering is not semantically appropriate.
- Module-specific override remains possible.
- Update/migration must not reset these preferences.

### Adhkar/dua routine integrity
Users build muscle memory around routine order. Updates must not casually break it.
- Canonical sourced morning/evening/routine packs are versioned.
- If upstream source content/order changes, show a changelog rather than silently deleting/reordering items.
- Preserve a user-pinned/custom order separately from canonical source order.
- Missing/withdrawn content receives a transparent source notice.
- Users can save their own private routine assembled from GREEN sourced items plus clearly labeled personal additions.
- Continue/resume position within a routine may be restored locally.
- Audio failure in one dua must not block navigating to the next item.
- Offline routine content remains usable after app update.

### Source and tradition transparency for religious library content
Do not disguise provenance to look universally agreed when it is not.
For Hadith, dua, fiqh guides, tafsir, seerah and similar sourced material, metadata should expose as applicable:
- Original collection/source.
- Hadith reference and grading/source of grading.
- Scholar/editor/translator/commentator.
- Madhab/school/tradition/context when materially relevant.
- Edition/version and publisher.
- Language/translation identity.
The app may provide filters but must not algorithmically rank theological traditions or imply one is superior.
No anonymous “daily hadith” or religious quote where the source cannot be inspected.

### Basic source verification remains accessible
If the app includes a Hadith/source lookup feature:
- Basic exact-reference/source lookup should not be blocked by an immediate trial wall if the underlying licensed corpus is available locally.
- Premium may fund advanced library tooling or additional licensed collections, but source identity/authenticity metadata for displayed content remains visible.
- Never use a paid AI answer as the only way to inspect the source of religious content.

### Cross-module Arabic rendering integrity
The Arabic shaping integrity contract applies beyond canonical Quran text:
- Lam-alif and common ligatures must not be broken by font/update regressions.
- Diacritics cannot collide/disappear due to line-height clipping.
- RTL punctuation/numerals/reference markers should remain readable.
- Golden/reference rendering tests cover representative Quran, dua, adhkar and Hadith samples for supported fonts/scripts.

### Update stability over novelty
Repeated app-store complaints show redesigns often break long-established routines.
Before replacing a widely used screen/flow:
- Preserve the task path and stored user preferences.
- Run migration/state restoration tests.
- Prefer staged rollout/feature flag where practical.
- Document material behavior changes in release notes/in-app changelog.
- Do not remove a frequently used translation/script/routine merely because a new design has a different default.

## V17 — context-resume, khatm history, routines and focused-device integration

### Resume the exact task, not just the ayah
“Continue” must restore the user’s real context.
Persist recent work sessions with canonical position plus mode-specific state:
- Reader/Mushaf: layout, ayah/page, selected translation layers, text size/theme.
- Advanced Study: exact study tab/source/lesson/ayah, not a fallback jump to Mushaf.
- Hifz: range, repetition stage, review queue, Mushaf identity, audio settings.
- Audio: reciter, queue/range, playback position/profile.
- Learn: course/lesson/step/quiz state.
Home may show one primary Continue card plus a compact recent-history list (for example the last 3–5 distinct contexts) so study users do not lose their place when they switch between reading, listening and study.
Session restore must work offline and survive updates.

### Khatm archive and annual targets
Users explicitly ask to count completed khatms over a year.
- Store each completed khatm as a dated record with plan/source, start/end date, digital/manual coverage metadata and optional private note.
- Year/month filtering and yearly target such as “3 khatms this year”.
- Show current pace and remaining amount without public competition or hasanat scoring.
- Never infer completion from fast scrolling alone.
- User can correct/archive/delete records.
- Ramadan khatm can be categorized separately without fragmenting the general archive.

### Physical Mushaf / off-device reading integration
A user may read on paper and still want one coherent plan.
- Manual log by page, juz, hizb or canonical ayah range.
- Clearly mark these entries as user-reported/off-device.
- Manual reading can advance a chosen khatm/goal only when the user explicitly adds it.
- Avoid double counting if the same range was read digitally and manually; show source breakdown rather than pretending perfect certainty.
- Optional quick-entry shortcut/widget for “I read pages X–Y on paper”.

### Custom Quran reading/routine lists
Collections can become ordered reading routines when the user chooses:
- Arbitrary ayah ranges across different surahs.
- Whole surahs.
- User-defined order.
- Optional repeat/audio profile per item.
- Examples may include personal daily wird, revision set, selected salah surahs or sourced ruqyah set, but the app must clearly distinguish a user-created list from a canonical/source-curated routine.
- Resume within a list, mark complete, duplicate/edit/reorder/export.
- Curated religious routines require verified sources; arbitrary user lists are simply user organization, not religious endorsement.

### Bookmark/tag navigation integrity
Every tag/highlight/note/search result that references an ayah must navigate back to the exact canonical ayah and relevant saved context where possible.
- A tag is not merely a label; it remains a navigable reference.
- Deleted/migrated content cannot leave silent dead links.
- Cross-source notes anchor to canonical ayah IDs and show the original edition context.

### Hifz repetition is fully user-controlled
Do not force a memorization algorithm’s repetition count on every session.
- Repeat count includes 1 and user-defined values within safe UI limits.
- Modes: single ayah, ayah-by-ayah range, cumulative pattern, whole selected block, whole surah/juz where practical, no-repeat continuous listening.
- User can save practice presets.
- Reverse-order revision remains optional.
- A broken repeat state must never trap playback on one ayah; state-machine regression tests required.

### Goal pacing and target-date flexibility
For reading/hifz/study plans:
- Optional target date.
- Daily pace derived from remaining work and available days.
- Ahead/behind indicator with neutral language.
- Backdate a plan/start point and preserve already-completed work.
- Extend/continue a goal after its original target without erasing progress.
- Custom surah/range order.
- Progress weighting should use meaningful units such as ayah/page/time as appropriate rather than treating very short and very long surahs as equal by default.
- Missed-day redistribution remains user-controlled and transparent.

### Prayer-window visibility and last-call reminders
When the selected jurisprudential/calculation source supports it, prayer UI may expose:
- Start time.
- End/window boundary used by the app.
- Time remaining in the current prayer window.
- Optional “last call” reminder/alarm X minutes before the selected window ends.
The app must explain the source/rule used for boundaries and must not present disputed jurisprudential details as universal.
- Per-prayer last-call toggles.
- iOS uses system alarm capabilities such as AlarmKit only where officially supported and permitted; otherwise use the best documented notification path.
- Android uses platform-appropriate exact-alarm/notification capabilities under current OS policy.
- Respect user choice between notification, sound, full adhan and alarm where platform rules allow.

### Watch / wearable standalone essentials
A wearable should remain useful when the phone is unavailable.
Where platform permits:
- Cache/sync at least several days to one month of prayer schedules.
- Compute prayer times locally from a saved place/method if safe and tested.
- Next-prayer countdown and complications/widgets.
- Qibla bearing using the wearable’s sensors with the same accuracy/calibration warnings as phone.
- Dhikr counter and selected offline adhkar.
- Prayer tracker / qada quick marking.
- Audio remote controls; standalone Quran audio only if storage/battery/licensing make sense.
- Watch changes sync back to the user-owned data store when connectivity returns.
No dependency on a live server for basic wearable prayer times.

### Widget gallery and preview
Because widgets are highly requested but easy to make confusing:
- Provide an in-app Widget Gallery/preview using the user’s actual local prayer/Quran state where platform APIs permit.
- Categories: next prayer, full-day prayer schedule, countdown, Quran/ayah, continue reading, hifz review, dhikr/fasting seasonal where appropriate.
- Explain privacy visibility for lock-screen widgets before enabling sensitive states.
- Widget style/configuration should reuse app design tokens and not become a second inconsistent design system.

### Subscription family sharing
If paid extras/subscriptions exist:
- Support Apple/Google family-sharing mechanisms where the store/product type permits and terms are clear.
- Do not require each family member to buy the same entitlement if the selected plan is explicitly sold as family-shareable.
- Family entitlement is billing only; private Quran notes, prayer, fasting, cycle, hifz and journal data remain isolated unless separately shared.
- Restore-purchase logic must handle family entitlement changes gracefully.

### Optional Digital Focus / distraction control
A super-app may help users protect prayer/study time without turning Quran into punishment.
Possible opt-in tools, only with official OS APIs:
- Temporarily shield user-selected distracting apps during a scheduled Quran study session or chosen prayer window.
- “Mindful pause” before opening selected apps: user may choose a short breathing/Quran/dhikr prompt, but completing worship must not be gamified as a compulsory moral score.
- Easy/compassionate mode and emergency bypass to avoid hostile lock-in.
- No hidden monitoring of other-app content.
- Screen Time / FamilyControls / Digital Wellbeing permissions explained clearly.
- Child/family controls require parent authorization and must not leak religious activity.
This is optional focus infrastructure, never required for Quran/prayer functionality.

### Modern navigation expectations
User complaints about tapping through many pages imply:
- Every long surah/study corpus has direct ayah/page/juz/hizb navigation where the source supports it.
- Recent searches and recent study positions are available locally.
- Navigation actions respond immediately; blank intermediate pages/freezes are regressions.
- English/localized numerals may be optionally displayed alongside Arabic ayah numerals for users learning the script, without altering canonical text.

### Product principle reinforced
All-in-one breadth is acceptable only when the common path stays calm:
- A user who only wants Quran + prayer + Qibla can live almost entirely in Home, Quran and a compact prayer surface.
- A study-focused user can resume directly into Study without being bounced through Mushaf.
- Advanced modules remain discoverable in Keşfedin/search, not sprayed across every screen.

## V18 — weekly rhythm, context profiles and study-to-review bridges

### Friday / Jumuah context
Friday can have a lightweight weekly context without replacing the normal Home.
When the selected sources/rights permit:
- Local mosque Jumuah times and venue information are prominent.
- Optional sourced reminders for Surah al-Kahf, ghusl, salawat or other Friday practices only when exact source/context is inspectable.
- Al-Kahf reading progress can reset weekly while its long-term history remains available.
- User can resume exactly where they stopped in Al-Kahf.
- Jumuah preparation checklist is optional and user-configurable.
- Friday mosque visit/logbook may be private and local if the user wants it; never turned into a public streak.
- Friday cards can begin at the user’s selected/sourced Friday boundary and disappear after Friday, without permanently crowding Home.
- Never invent or overstate a single “golden hour” interpretation; if such timing is offered, source and scholarly interpretation must be explicit.

### Prayer-time explorer beyond the five starts
A useful prayer app may expose more than start timestamps, but these markers are jurisprudentially sensitive.
Optional sourced markers may include:
- Sunrise.
- Ishraq/Duha start/end where a selected rule set defines them.
- Solar noon / zenith / zawal interval.
- Current prayer end boundary.
- Islamic midnight / last third.
- Optional prohibited/disliked voluntary-prayer windows.
For every nontrivial marker:
- Show selected source/method/school/context.
- Explain that rules can differ.
- Never display a red “haram to pray now” universal verdict from astronomy alone.
- Allow the user to hide advanced timing markers entirely.

### Context-aware notification profiles
Users need different behavior at home, work, mosque, sleep and travel.
Allow explicit profiles such as:
- Home: chosen adhan/full sound.
- Work/school: vibration or discreet tone.
- Sleep/Fajr: alarm where platform supports it.
- Travel: temporary profile with destination schedule.
- Mosque: optionally suppress redundant adhan reminders while the user is at a saved mosque, only with opt-in geofence/location permission.
Profiles may activate by:
- Saved place/geofence, with clear permission.
- User schedule.
- Manual quick toggle.
- Travel mode.
A prominent temporary “pause non-essential reminders” action should support an expiry time so users do not forget to re-enable them.
No profile silently changes prayer calculation method or religious content.

### Settings search and control discoverability
Because the super-app has many preferences:
- Global search indexes settings as well as content/features.
- A dedicated Settings search may deep-link directly to calculation method, fonts, notifications, downloads, privacy, source licenses, backup etc.
- Search results show the current value where helpful.
- Changing a setting never resets unrelated settings.
- Advanced settings can remain nested without becoming undiscoverable.

### Study-to-review bridge
Anything learned in Study should be reusable in Learn without manual reconstruction.
Where source data permits:
- From a word/root/morphology/tafsir lesson, user can “Add to review”.
- Review item preserves backlink to canonical ayah, exact study source/lesson/section and edition/version.
- Vocabulary/root flashcards can show the original ayah context and return to the exact Study page.
- User can build a private review deck from selected roots, words, phrases or sourced concepts.
- Review cards do not contain model-invented religious explanations.
- If source edition is removed, preserve user-authored note and canonical ayah anchor while marking the missing source.
- Duplicate review items should merge or reference the same canonical concept rather than silently multiplying.

### Custom learning collections
Allow a user to combine study material into a focused learning set:
- Ayahs/ranges.
- Vocabulary/root items.
- User notes.
- Sourced tafsir/reference links.
- Audio ranges.
This becomes a private study set that can be reviewed, printed/exported or assigned by a teacher. It is not a new public-content publishing system.

### Real recent-history model
Recent history is not one global stack.
Maintain typed recent lists such as:
- Recent Quran reading positions.
- Recent audio queues/surahs.
- Recent Study pages/sources.
- Recent searches.
- Recent books/library positions.
User can clear each history category independently.
Sensitive histories such as cycle/private journal are excluded from generic recents.

### Habit/routine reminders remain source-aware
If the app offers recurring reminders for specific surahs/adhkar or weekly practices:
- Every canonical reminder explains its source.
- User can turn each one off independently.
- Personal routines can be scheduled without claiming religious virtue.
- Do not create a generic “Sunnah score” or compare users.

### OS-native alarm capability, carefully
Where current OS APIs permit true alarms (for example supported iOS AlarmKit or Android alarm APIs):
- Offer them as an explicit stronger reminder mode, especially for Fajr/suhoor or user-selected last-call reminders.
- Explain that system alarm behavior differs from normal notifications.
- Ask only the permissions/capabilities actually required.
- Fall back gracefully on unsupported OS versions.
- Never market alarms as mathematically guaranteeing a prayer will not be missed.

### Screen-time focus as a supportive tool
If Digital Focus ships, avoid coercive religious UX:
- User may schedule a distraction shield before/during a prayer window or Quran study block.
- Default behavior is a calm pause/intent prompt, not “worship or your phone stays locked”.
- Optional stricter modes are knowingly enabled by the user/parent.
- Reading a verse is never used as a monetized unlock currency.
- Emergency/bypass path is obvious.
- Focus state never modifies worship completion statistics unless user explicitly logs the activity.

## Global-language mission — non-negotiable product pillar
The multilingual vision is not optional polish and must not be postponed until the end. It is one of the product's defining differentiators.

### Core goal
Ship the broadest legally verified Quran meaning-language catalog realistically possible while preserving source integrity, licensing, offline use and modern UX.
- UI language and Quran meaning/translation language remain fully independent.
- A user may use the app UI in one language while reading one or several Quran meaning editions in other languages.
- Multiple translation/meaning editions per language are supported with explicit translator, publisher, source, version and license identity.
- Human spoken translations are supported when rights-cleared recordings exist. Never use TTS as a substitute for Quran/meal/tafsir audio.
- If no rights-cleared spoken translation exists, offer Arabic recitation + written meaning rather than synthesizing speech.

### Catalog architecture
Language coverage must be data-driven, not hardcoded into app releases.
Each catalog entry records at minimum:
- BCP-47/ISO language tag.
- Native name and English/Turkish discovery name.
- Script and text direction.
- Translation editions.
- Human spoken-translation editions.
- Compatible recitations if relevant.
- Required fonts/font packs.
- Offline package size.
- Source, rights holder, version, checksum, attribution and GREEN/YELLOW/BLOCKED rights state.
- Completeness/coverage status.
Signed manifests may add/update language packs without an app release after license/content QA.

### Production visibility
- Only GREEN content can be exposed in production.
- A language must not appear as fully available if its required edition is missing, incomplete or rights-blocked.
- YELLOW/BLOCKED sources can remain visible to developers/source admins but not masquerade as user-ready content.
- If an edition is withdrawn, do not silently replace it with another translator; explain the change and preserve user preference metadata where legally permitted.

### Offline-first multilingual behavior
- Text, spoken translation, recitation and font packs are independently downloadable.
- User chooses which languages/editions/audio to store.
- Reader/search/bookmarks for downloaded language packs work offline.
- Download manager shows size, version, source and integrity state.
- An offline pack is marked ready only when its payload and every required timing/index/manifest/font dependency are version-compatible and checksum-verified; media bytes alone never count as a successful install.
- Install/update is transactional: retain the last valid pack until the replacement passes verification, resume/retry partial work, and expose exact scope, size, network policy, progress, failure reason and repair action.
- Storage controls show per-pack/reciter/range size and allow deleting reproducible content without deleting bookmarks, notes, Hifz state, reading history or pack preference.
- Cloud backup includes user-created data and lightweight installed-pack intent/version metadata, but excludes reproducible Quran/translation/audio/font payload bytes. After restore or OS cache eviction, preserve selections and transparently offer/queue re-download; never claim a missing pack is offline-ready.
- Updates are resumable/checksummed and must not destroy already downloaded valid packs during app upgrades.

### Rendering/search quality
- Correct RTL/LTR/mixed-direction rendering is mandatory.
- Dynamic fonts must cover scripts such as Arabic, Cyrillic, Latin, CJK, Devanagari, Burmese, N'Ko and others as catalog coverage grows, subject to font rights.
- Search supports language-appropriate normalization/transliteration behavior without mutating canonical source content.
- Locale-specific punctuation, numerals, pluralization and line breaking are tested.
- Accessibility and large-text behavior must be validated per script, not only Latin/Arabic.

### UI localization growth
Initial ARB/gen-l10n locales remain centrally managed, but UI localization should be able to expand through a human-reviewed community workflow.
- Glossary/terminology rules for Quranic and Islamic product terms.
- Reviewer/approval flow.
- Screenshot/context support for translators.
- No AI-only production UI translation.
- Locale parity tests catch missing keys and stale translations.

### Coverage QA and roadmap priority
Maintain measurable coverage reporting:
- Number of GREEN written meaning languages.
- Number of GREEN spoken-translation languages.
- Number of available editions per language.
- Font/script readiness.
- Offline-pack integrity.
- Missing/blocked sources and exact reason.
The feature roadmap must regularly advance this catalog/source architecture alongside other product work. It must not be left as a final “localization phase”.

### French full-app locale — required
French (`fr`) is an approved full application locale, not only a Quran-meaning/content language.
The French experience must reach the same functional parity as the existing core UI locales:
- Add `fr` to the supported application locale resolver and locale picker.
- Complete ARB/gen-l10n coverage for all user-visible UI strings.
- Cover onboarding, Home, Quran/Reader, Learn, Hifz, Plans, Discover, Profile/Settings, prayer/Qibla, notifications, downloads, backup/privacy, errors, permissions, help and accessibility labels.
- Extend all typed/feature string layers and remove any hidden five-locale assumptions.
- Update localization parity/regression tests so French is required wherever core UI locale parity is expected.
- Use natural French terminology reviewed for Islamic/Quran product context; do not ship raw machine-only production translation.
- Validate French date/time, pluralization, punctuation, number formatting, search and Dynamic Type/long-string layout.
- UI French remains independent of Quran meaning editions. A French UI user may select any GREEN content language/edition.
- French Quran meaning editions and human spoken French translations are separate content-catalog assets and must pass the normal source/license GREEN gate.
- French support must work offline for bundled UI strings and for any downloaded GREEN content packs.
