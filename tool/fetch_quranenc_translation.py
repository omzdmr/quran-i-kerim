#!/usr/bin/env python3
"""Build a validated offline QuranEnc translation pack.

This tool is intentionally not run during normal app builds. It is a release/content
pipeline utility for translations that will later be uploaded to our static content
host. It keeps source provenance and footnotes in the generated package.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

BASE_URL = "https://quranenc.com/api/v1"
USER_AGENT = "quran-i-kerim-content-builder/1.0"


def _get_json(url: str) -> Any:
    request = urllib.request.Request(
        url,
        headers={"User-Agent": USER_AGENT, "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            raw = response.read()
    except urllib.error.URLError as exc:
        raise RuntimeError(f"QuranEnc request failed: {url}: {exc}") from exc
    try:
        return json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"QuranEnc returned invalid JSON: {url}") from exc


def _translation_list(language: str) -> list[dict[str, Any]]:
    language_q = urllib.parse.quote(language)
    url = f"{BASE_URL}/translations/list/{language_q}?localization=en"
    payload = _get_json(url)
    if isinstance(payload, dict) and isinstance(payload.get("result"), list):
        payload = payload["result"]
    if not isinstance(payload, list):
        raise RuntimeError("Unexpected translations/list response shape")
    return [item for item in payload if isinstance(item, dict)]


def _sura_items(source_key: str, sura: int) -> list[dict[str, Any]]:
    key_q = urllib.parse.quote(source_key)
    url = f"{BASE_URL}/translation/sura/{key_q}/{sura}"
    payload = _get_json(url)
    if isinstance(payload, dict) and isinstance(payload.get("result"), list):
        payload = payload["result"]
    if not isinstance(payload, list):
        raise RuntimeError(f"Unexpected sura response for {source_key} sura {sura}")
    result: list[dict[str, Any]] = []
    for item in payload:
        if not isinstance(item, dict):
            raise RuntimeError(f"Invalid item in sura {sura}")
        result.append(item)
    return result


def _find_catalog_entry(
    entries: list[dict[str, Any]], source_key: str
) -> dict[str, Any]:
    for entry in entries:
        if str(entry.get("key", "")) == source_key:
            return entry
    raise RuntimeError(
        f"Translation key {source_key!r} was not returned by QuranEnc for this language"
    )


def build_pack(
    *,
    source_key: str,
    language: str,
    expected_version: str | None,
    output: Path,
) -> None:
    catalog_entry = _find_catalog_entry(_translation_list(language), source_key)
    upstream_version = str(catalog_entry.get("version", "")).strip()
    if expected_version and upstream_version and upstream_version != expected_version:
        raise RuntimeError(
            "QuranEnc version changed: "
            f"expected {expected_version}, upstream reports {upstream_version}. "
            "Review the update before publishing a new pack."
        )

    items: list[dict[str, Any]] = []
    seen: set[tuple[int, int]] = set()
    seen_suras: set[int] = set()

    for sura in range(1, 115):
        sura_items = _sura_items(source_key, sura)
        if not sura_items:
            raise RuntimeError(f"No verses returned for sura {sura}")
        for raw in sura_items:
            try:
                raw_sura = int(raw["sura"])
                raw_aya = int(raw["aya"])
            except (KeyError, TypeError, ValueError) as exc:
                raise RuntimeError(f"Invalid sura/aya metadata in sura {sura}") from exc
            translation = raw.get("translation")
            if raw_sura != sura or raw_aya < 1:
                raise RuntimeError(
                    f"Unexpected verse identity in sura {sura}: {raw_sura}:{raw_aya}"
                )
            if not isinstance(translation, str) or not translation.strip():
                raise RuntimeError(f"Empty translation at {raw_sura}:{raw_aya}")
            key = (raw_sura, raw_aya)
            if key in seen:
                raise RuntimeError(f"Duplicate verse {raw_sura}:{raw_aya}")
            seen.add(key)
            seen_suras.add(raw_sura)

            # Keep the upstream fields intact. We only normalize JSON container
            # structure and never alter translation or footnote text.
            items.append(dict(raw))

    if seen_suras != set(range(1, 115)):
        missing = sorted(set(range(1, 115)) - seen_suras)
        raise RuntimeError(f"Missing suras: {missing}")
    if len(items) < 6000:
        raise RuntimeError(f"Suspiciously small translation: {len(items)} verses")

    package = {
        "schema_version": 1,
        "source": "QuranEnc.com",
        "source_key": source_key,
        "language_iso_code": language,
        "version": upstream_version or expected_version or "unknown",
        "last_update": catalog_entry.get("last_update"),
        "title": catalog_entry.get("title"),
        "description": catalog_entry.get("description"),
        "terms": {
            "no_modification": True,
            "publisher_and_source_required": True,
            "version_required": True,
            "keep_transcript_information": True,
            "update_to_latest_required": True,
            "no_inappropriate_ads_with_translation": True,
        },
        "items": items,
    }

    encoded = json.dumps(
        package,
        ensure_ascii=False,
        separators=(",", ":"),
    ).encode("utf-8")
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("wb") as raw_output:
        with gzip.GzipFile(
            filename="",
            mode="wb",
            fileobj=raw_output,
            compresslevel=9,
            mtime=0,
        ) as handle:
            handle.write(encoded)

    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    print(f"Ready: {output} ({output.stat().st_size} bytes)")
    print(f"Verses: {len(items)}")
    print(f"Version: {package['version']}")
    print(f"SHA256: {digest}")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--key", required=True, dest="source_key")
    parser.add_argument("--language", required=True)
    parser.add_argument("--version", dest="expected_version")
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        build_pack(
            source_key=args.source_key,
            language=args.language,
            expected_version=args.expected_version,
            output=args.output,
        )
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
