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
