# Third-party data

## Tanzil Quran text

The Arabic Quran text exposed through the `quran` package is sourced from the Tanzil Project. The package documents its current Quran script as the Tanzil **Simple (Plain)** text.

- Source: Tanzil Project
- License: Creative Commons Attribution 3.0 (CC BY 3.0)
- Project: https://tanzil.net/
- Upstream text download: https://tanzil.net/download/

Tanzil permits verbatim redistribution but does not permit changing the Quran text. The app therefore treats the Arabic text as immutable source data. Reader surfaces identify Tanzil and provide a link back to the project so users can follow upstream changes.

## English transliteration

Learn lessons bundle the `en.transliteration` edition delivered by the Al Quran Cloud API and preserve every transliteration string verbatim. The edition is validated at build time for the expected identifier, all 114 surahs, and exactly 6,236 verse records before it is compressed into the offline asset.

- Delivery source: Al Quran Cloud / Islamic Network
- Edition: `en.transliteration`
- API: https://api.alquran.cloud/v1/quran/en.transliteration
- API terms: https://alquran.cloud/terms-and-conditions
- Upstream translation catalogue: https://tanzil.net/trans/

Tanzil lists **English Transliteration** in its translations catalogue. Tanzil translation resources are currently provided for non-commercial use unless any additional permission required by the translator or publisher is obtained. The current app model is free/no-backend; any future paid or commercial distribution must re-check the transliteration licence before release.

The transliteration is source data, not machine-generated pronunciation. Learn verse cards show the source edition alongside the Arabic verse.

## QuranEnc translations

Supported QuranEnc translations are downloaded or bundled as source-bound translation packs. Translation text and provider-authored footnotes are preserved verbatim.

- Source: QuranEnc.com
- Project: https://quranenc.com/
- API: https://quranenc.com/en/home/api
- Terms: https://quranenc.com/en/home/about/terms-and-conditions

QuranEnc requires republished translations to remain unmodified and to identify the publisher, QuranEnc as the source, and the translation version. Translation packs therefore retain source, publisher and version metadata, and Learn explanation surfaces only expose provider-authored footnotes when the installed source contains them.

## GeoNames

The offline worldwide city search is built from the GeoNames `cities5000` dump and `countryInfo.txt`.

- Source: GeoNames geographical database
- License: Creative Commons Attribution 4.0 (CC BY 4.0)
- Project: https://www.geonames.org/

The build process keeps only the fields needed for local city lookup, prayer-time coordinates and timezone selection. The raw GeoNames dump is not shipped unchanged.

## OpenStreetMap / Nominatim

The optional **Search online** fallback uses the public OpenStreetMap Nominatim service only after an explicit user action. Requests are rate-limited, identify the application with a User-Agent, and repeated identical queries are cached in memory for the app session.

Search results are attributed to OpenStreetMap contributors in the city picker UI.
