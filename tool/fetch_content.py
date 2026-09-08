#!/usr/bin/env python3
"""Fetch and validate small bundled content used by local development/builds."""

from __future__ import annotations

import gzip
import json
import pathlib
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
PINNED_CONTENT_COMMIT = "6c0a1571bcac95eaaf0d167d15e558ec3c2bb8e2"
BASE = (
    "https://raw.githubusercontent.com/Yi-Developer/Qurb-content/"
    f"{PINNED_CONTENT_COMMIT}/quran/translations"
)

BUNDLED = (
    (
        "Türkçe",
        ROOT / "assets/data/translations/tr_rwwad.json.gz",
        f"{BASE}/t_turkish_rwwad.json.gz",
    ),
    (
        "English",
        ROOT / "assets/data/translations/en_rwwad.json.gz",
        f"{BASE}/t_english_rwwad.json.gz",
    ),
)


def validate(path: pathlib.Path) -> None:
    with gzip.open(path, "rt", encoding="utf-8") as handle:
        data = json.load(handle)

    if not isinstance(data, dict):
        raise SystemExit(f"{path.name}: translation package is not a JSON object.")

    # Ayet sayım gelenekleri farklılaşabildiği için 6236 gibi tek bir toplamı
    # evrensel gerçek kabul etmiyoruz. Bunun yerine paket yapısını ve 114 surenin
    # tamamının temsil edildiğini doğruluyoruz.
    seen_surahs: set[int] = set()
    valid_entries = 0

    for key, value in data.items():
        if not isinstance(key, str) or ":" not in key:
            raise SystemExit(f"{path.name}: invalid verse key: {key!r}")

        surah_text, ayah_text = key.split(":", 1)
        try:
            surah = int(surah_text)
            ayah = int(ayah_text)
        except ValueError as exc:
            raise SystemExit(f"{path.name}: non-numeric verse key: {key}") from exc

        if not 1 <= surah <= 114 or ayah < 1:
            raise SystemExit(f"{path.name}: verse key out of range: {key}")
        if not isinstance(value, str) or not value.strip():
            raise SystemExit(f"{path.name}: empty translation text: {key}")

        seen_surahs.add(surah)
        valid_entries += 1

    if seen_surahs != set(range(1, 115)):
        missing = sorted(set(range(1, 115)) - seen_surahs)
        raise SystemExit(f"{path.name}: missing surahs: {missing}")

    if valid_entries < 6000:
        raise SystemExit(
            f"{path.name}: package looks unexpectedly small: {valid_entries} records"
        )

    for key in ("1:1", "2:255", "114:6"):
        if key not in data:
            raise SystemExit(f"{path.name}: sanity-check verse is missing: {key}")


def main() -> None:
    for label, target, source in BUNDLED:
        target.parent.mkdir(parents=True, exist_ok=True)
        print(f"{label} translation package downloading…")
        urllib.request.urlretrieve(source, target)
        validate(target)
        print(f"Ready: {target.relative_to(ROOT)} ({target.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
