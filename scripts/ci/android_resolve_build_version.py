#!/usr/bin/env python3
"""Resolve Android marketing version and next versionCode for Google Play.

Marketing version (build-name) comes from pubspec.yaml.
versionCode is max existing versionCode across all Play Store tracks + 1,
so it stays ahead even if someone manually uploads a build via the Play Console.

Falls back to pubspec build number + 1 when no builds exist on Play Store yet.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import urllib.error
import urllib.request
from pathlib import Path


def _parse_pubspec(path: Path) -> tuple[str, int]:
    text = path.read_text(encoding="utf-8")
    m = re.search(r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)", text, re.M)
    if not m:
        raise SystemExit(
            f"{path} must contain version: major.minor.patch+build (e.g. 1.3.4+18)"
        )
    return m.group(1), int(m.group(2))


def _api(method: str, url: str, token: str, data: bytes | None = None) -> dict:
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}
    if data is not None:
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, method=method, headers=headers, data=data)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            body = resp.read()
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        raise SystemExit(f"Play API {e.code} {method} {url}: {body}")


def _max_version_code(token: str, package_name: str) -> int | None:
    """Max versionCode across all Play Store tracks, or None if none found.

    Creates a temporary edit (read-only; deleted without committing) to query
    the tracks endpoint, which is only accessible via the edits API.
    """
    base = (
        "https://androidpublisher.googleapis.com/androidpublisher/v3"
        f"/applications/{package_name}"
    )
    edit_data = _api("POST", f"{base}/edits", token, b"{}")
    edit_id = edit_data["id"]
    try:
        tracks_data = _api("GET", f"{base}/edits/{edit_id}/tracks", token)
        max_vc: int | None = None
        for track in tracks_data.get("tracks") or []:
            for release in track.get("releases") or []:
                for vc in release.get("versionCodes") or []:
                    try:
                        n = int(str(vc).strip())
                        max_vc = n if max_vc is None else max(max_vc, n)
                    except ValueError:
                        continue
        return max_vc
    finally:
        try:
            _api("DELETE", f"{base}/edits/{edit_id}", token)
        except SystemExit:
            pass  # best-effort cleanup; orphaned edits expire automatically


def _write_github_output(name: str, code: int) -> None:
    out_path = os.environ.get("GITHUB_OUTPUT")
    if not out_path:
        return
    with open(out_path, "a", encoding="utf-8") as f:
        f.write(f"name={name}\n")
        f.write(f"code={code}\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pubspec", default="pubspec.yaml", type=Path)
    parser.add_argument("--package-name", default="app.halalscan")
    parser.add_argument(
        "--tag-version",
        default="",
        help="Version from git tag (e.g. 1.3.4) — validated against pubspec",
    )
    args = parser.parse_args()

    pubspec_name, pubspec_build = _parse_pubspec(args.pubspec)
    tag = (args.tag_version or "").strip().lstrip("v")
    if tag and tag != pubspec_name:
        raise SystemExit(
            f"Tag version {tag!r} does not match pubspec marketing version {pubspec_name!r}"
        )

    name = pubspec_name
    token = os.environ.get("PLAY_ACCESS_TOKEN", "")

    play_max: int | None = None
    if token:
        play_max = _max_version_code(token, args.package_name)

    if play_max is not None:
        next_code = play_max + 1
        source = f"Play Store max {play_max} + 1"
    else:
        next_code = pubspec_build + 1
        source = f"no Play Store builds found; pubspec {pubspec_build} + 1"

    print(f"Marketing version: {name}")
    print(f"Pubspec build:     {pubspec_build}")
    if play_max is not None:
        print(f"Play Store max VC: {play_max}")
    print(f"Next versionCode:  {next_code} ({source})")

    _write_github_output(name, next_code)


if __name__ == "__main__":
    main()
