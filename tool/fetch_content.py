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
    if len(data) != 6236:
        raise SystemExit(f"6236 kayıt bekleniyordu, {len(data)} bulundu.")

    for key in ("1:1", "2:255", "114:6"):
        value = data.get(key)
        if not isinstance(value, str) or not value.strip():
            raise SystemExit(f"Eksik/geçersiz ayet: {key}")


def main() -> None:
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    print("Türkçe meal paketi indiriliyor…")
    urllib.request.urlretrieve(SOURCE, TARGET)
    validate(TARGET)
    print(f"Hazır: {TARGET.relative_to(ROOT)} ({TARGET.stat().st_size} bayt)")


if __name__ == "__main__":
    main()
