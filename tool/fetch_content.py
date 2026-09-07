#!/usr/bin/env python3
"""Fetch and validate small bundled content used by local development/builds."""

from __future__ import annotations

import gzip
import json
import pathlib
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
TARGET = ROOT / "assets/data/translations/tr_rwwad.json.gz"
SOURCE = (
    "https://raw.githubusercontent.com/Yi-Developer/Qurb-content/"
    "6c0a1571bcac95eaaf0d167d15e558ec3c2bb8e2/"
    "quran/translations/t_turkish_rwwad.json.gz"
)


def validate(path: pathlib.Path) -> None:
    with gzip.open(path, "rt", encoding="utf-8") as handle:
        data = json.load(handle)

    if not isinstance(data, dict):
        raise SystemExit("Meal paketi JSON nesnesi değil.")

    # Ayet sayım gelenekleri farklılaşabildiği için 6236 gibi tek bir toplamı
    # evrensel gerçek kabul etmiyoruz. Bunun yerine paket yapısını ve 114 surenin
    # tamamının temsil edildiğini doğruluyoruz.
    seen_surahs: set[int] = set()
    valid_entries = 0

    for key, value in data.items():
        if not isinstance(key, str) or ":" not in key:
            raise SystemExit(f"Geçersiz ayet anahtarı: {key!r}")

        surah_text, ayah_text = key.split(":", 1)
        try:
            surah = int(surah_text)
            ayah = int(ayah_text)
        except ValueError as exc:
            raise SystemExit(f"Sayısal olmayan ayet anahtarı: {key}") from exc

        if not 1 <= surah <= 114 or ayah < 1:
            raise SystemExit(f"Aralık dışı ayet anahtarı: {key}")
        if not isinstance(value, str) or not value.strip():
            raise SystemExit(f"Boş/geçersiz meal metni: {key}")

        seen_surahs.add(surah)
        valid_entries += 1

    if seen_surahs != set(range(1, 115)):
        missing = sorted(set(range(1, 115)) - seen_surahs)
        raise SystemExit(f"Meal paketinde sureler eksik: {missing}")

    # Bozuk veya yanlış dosyayı erken yakalamak için kaba bir alt sınır.
    if valid_entries < 6000:
        raise SystemExit(
            f"Meal paketi beklenenden çok küçük görünüyor: {valid_entries} kayıt"
        )

    for key in ("1:1", "2:255", "114:6"):
        if key not in data:
            raise SystemExit(f"Temel doğrulama ayeti eksik: {key}")


def main() -> None:
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    print("Türkçe meal paketi indiriliyor…")
    urllib.request.urlretrieve(SOURCE, TARGET)
    validate(TARGET)
    print(f"Hazır: {TARGET.relative_to(ROOT)} ({TARGET.stat().st_size} bayt)")


if __name__ == "__main__":
    main()
