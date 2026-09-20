# Translation catalog — initial verified candidates

This file tracks upstream translation candidates and release readiness. It does **not** mean a translation is already shipped in the app.

## Source policy

Primary candidate source: **QuranEnc.com**.

For republished translations we must keep the translation content unchanged, identify the publisher and QuranEnc.com as source, retain the version/transcript information, follow upstream updates, and avoid inappropriate advertising when the translation is displayed. A pack is not marked downloadable until its version and checksum have been validated by our content pipeline.

## Initial languages

| App language | QuranEnc key | Translation | Upstream version recorded | Current app state |
| --- | --- | --- | --- | --- |
| Turkish | `turkish_rwwad` | Rowad Turkish translation | `1.0.4` | Bundled / offline |
| English | `english_rwwad` | Rowwad Translation Center | `1.0.19` | Catalog candidate; pack not published yet |
| Azerbaijani | `azeri_musayev` | Əlixan Musayev | `1.0.4` | Catalog candidate; pack not published yet |
| Russian | `russian_rwwad` | Rowwad Translation Center | `1.0.1` | Catalog candidate; pack not published yet |
| Arabic | n/a | Original Quran text | Tanzil-based `quran` package | Bundled / offline |

Versions are release metadata, not eternal constants. `tool/fetch_quranenc_translation.py` deliberately fails when the upstream version differs from the expected version so a human can review the new revision before publishing it.

## Planned pack workflow

1. Read QuranEnc translation list for the language and verify the translation key/version.
2. Fetch all 114 surahs through the official QuranEnc API.
3. Validate non-empty content, unique ayah identities, all 114 surahs, and a sanity lower bound for total ayat.
4. Keep upstream translation and footnote fields intact inside the package.
5. Create deterministic gzip output and compute SHA-256.
6. Upload the pack to the static content host.
7. Publish/refresh a small manifest containing language, translation ID, version, size, SHA-256, URL, attribution and update policy.
8. The app downloads only the translations the user requests and verifies SHA-256 before activation.

## Example pack build

```bash
python3 tool/fetch_quranenc_translation.py \
  --key english_rwwad \
  --language en \
  --version 1.0.19 \
  --output build/content/en_rwwad_1.0.19.json.gz
```

The generated content pack is a distribution artifact and should not automatically be committed to the source repository.
