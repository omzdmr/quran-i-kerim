#!/usr/bin/env python3
"""Fetch and validate bundled local-first content used by builds."""

from __future__ import annotations

import gzip
import io
import json
import pathlib
import unicodedata
import urllib.request
import zipfile

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

GEONAMES_CITIES_URL = "https://download.geonames.org/export/dump/cities5000.zip"
GEONAMES_COUNTRY_INFO_URL = "https://download.geonames.org/export/dump/countryInfo.txt"
GEONAMES_TARGET = ROOT / "assets/data/locations/cities5000.json.gz"
USER_AGENT = "Quran-i-Kerim-build/0.5 (GeoNames offline city bundle)"


def _request_bytes(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def validate_translation(path: pathlib.Path) -> None:
    with gzip.open(path, "rt", encoding="utf-8") as handle:
        data = json.load(handle)

    if not isinstance(data, dict):
        raise SystemExit(f"{path.name}: translation package is not a JSON object.")

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


def _fold_ascii(value: str) -> str:
    value = value.replace("ı", "i").replace("İ", "I").replace("ə", "e")
    normalized = unicodedata.normalize("NFKD", value)
    return "".join(ch for ch in normalized if not unicodedata.combining(ch)).lower()


def _country_names(raw: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in raw.splitlines():
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) >= 5:
            result[parts[0]] = parts[4]
    return result


def build_geonames_city_bundle() -> None:
    print("GeoNames cities5000 downloading…")
    countries_raw = _request_bytes(GEONAMES_COUNTRY_INFO_URL).decode("utf-8")
    countries = _country_names(countries_raw)
    archive = _request_bytes(GEONAMES_CITIES_URL)

    with zipfile.ZipFile(io.BytesIO(archive)) as zf:
        names = zf.namelist()
        city_name = next((name for name in names if name.endswith("cities5000.txt")), None)
        if city_name is None:
            raise SystemExit("cities5000.txt missing from GeoNames archive")
        raw = zf.read(city_name).decode("utf-8")

    records_with_population: list[tuple[int, list[object]]] = []
    seen_ids: set[int] = set()
    represented_countries: set[str] = set()

    for line in raw.splitlines():
        parts = line.split("\t")
        if len(parts) < 19:
            continue
        try:
            geoname_id = int(parts[0])
            latitude = float(parts[4])
            longitude = float(parts[5])
            population = int(parts[14] or "0")
        except ValueError:
            continue

        if geoname_id in seen_ids:
            continue
        name = parts[1].strip()
        ascii_name = parts[2].strip()
        country_code = parts[8].strip()
        timezone = parts[17].strip()
        if not name or not country_code or not timezone:
            continue

        aliases: list[str] = []
        for candidate in [name, ascii_name, *parts[3].split(",")]:
            candidate = candidate.strip()
            if not candidate or len(candidate) > 80 or candidate in aliases:
                continue
            aliases.append(candidate)
            if len(aliases) >= 24:
                break

        country = countries.get(country_code, country_code)
        raw_search = " ".join([*aliases, country, country_code]).lower()
        search = f"{raw_search} {_fold_ascii(raw_search)}"
        record: list[object] = [
            geoname_id,
            name,
            country,
            latitude,
            longitude,
            timezone,
            search,
        ]
        records_with_population.append((population, record))
        seen_ids.add(geoname_id)
        represented_countries.add(country_code)

    records_with_population.sort(key=lambda item: item[0], reverse=True)
    records = [record for _, record in records_with_population]

    if len(records) < 35000:
        raise SystemExit(f"GeoNames city bundle unexpectedly small: {len(records)}")
    if len(represented_countries) < 180:
        raise SystemExit(
            f"GeoNames country coverage unexpectedly small: {len(represented_countries)}"
        )

    GEONAMES_TARGET.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(records, ensure_ascii=False, separators=(",", ":")).encode(
        "utf-8"
    )
    with gzip.open(GEONAMES_TARGET, "wb", compresslevel=9) as handle:
        handle.write(payload)

    print(
        "Ready: "
        f"{GEONAMES_TARGET.relative_to(ROOT)} "
        f"({GEONAMES_TARGET.stat().st_size} bytes, "
        f"{len(records)} cities, {len(represented_countries)} countries)"
    )


def main() -> None:
    for label, target, source in BUNDLED:
        target.parent.mkdir(parents=True, exist_ok=True)
        print(f"{label} translation package downloading…")
        urllib.request.urlretrieve(source, target)
        validate_translation(target)
        print(f"Ready: {target.relative_to(ROOT)} ({target.stat().st_size} bytes)")

    build_geonames_city_bundle()


if __name__ == "__main__":
    main()
