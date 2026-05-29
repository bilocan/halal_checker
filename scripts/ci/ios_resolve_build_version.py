#!/usr/bin/env python3
"""Resolve iOS marketing version (pubspec) and next CFBundleVersion (App Store Connect).

Marketing version (build-name) comes from pubspec.yaml. When ``--update-pubspec``
is set (TestFlight workflow), the patch version is bumped if App Store Connect has
closed that version's pre-release train (e.g. after App Store release).

Build number (build-number) is max existing ASC build for the resolved version + 1,
so it stays ahead of TestFlight (e.g. 160 -> 161) even when pubspec still says +18.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
import time
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


def _make_jwt() -> str:
    try:
        from cryptography.hazmat.primitives import hashes, serialization
        from cryptography.hazmat.primitives.asymmetric import ec
        from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
    except ImportError:
        raise SystemExit("cryptography package required (pip install cryptography)")

    key_id = os.environ["APP_STORE_CONNECT_KEY_ID"]
    issuer_id = os.environ["APP_STORE_CONNECT_ISSUER_ID"]
    key_b64 = os.environ["APP_STORE_CONNECT_KEY_BASE64"]
    key_pem = base64.b64decode(key_b64)

    pk = serialization.load_pem_private_key(key_pem, password=None)
    now = int(time.time())

    def b64u(data: bytes | str) -> str:
        raw = data if isinstance(data, bytes) else data.encode()
        return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()

    header = b64u(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"}, separators=(",", ":")))
    payload = b64u(
        json.dumps(
            {"iss": issuer_id, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
            separators=(",", ":"),
        )
    )
    message = f"{header}.{payload}".encode()
    r, s = decode_dss_signature(pk.sign(message, ec.ECDSA(hashes.SHA256())))
    sig = b64u(r.to_bytes(32, "big") + s.to_bytes(32, "big"))
    return f"{header}.{payload}.{sig}"


def _api_get(url: str, jwt: str) -> dict:
    req = urllib.request.Request(
        url,
        headers={"Authorization": f"Bearer {jwt}", "Accept": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def _app_id(jwt: str, bundle_id: str) -> str:
    url = (
        "https://api.appstoreconnect.apple.com/v1/apps"
        f"?filter[bundleId]={bundle_id}"
    )
    data = _api_get(url, jwt)
    apps = data.get("data") or []
    if not apps:
        raise SystemExit(f"No App Store Connect app for bundle id {bundle_id}")
    return apps[0]["id"]


# App Store states where ASC no longer accepts new builds for that version train.
_CLOSED_TRAIN_STATES = frozenset({
    "READY_FOR_SALE",
    "REPLACED_WITH_NEW_VERSION",
    "PENDING_DEVELOPER_RELEASE",
    "PENDING_APPLE_RELEASE",
    "PROCESSING_FOR_APP_STORE",
})


def _bump_patch(version: str) -> str:
    m = re.match(r"^(\d+)\.(\d+)\.(\d+)$", version)
    if not m:
        raise SystemExit(f"Cannot bump patch for version {version!r}")
    major, minor, patch = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
    return f"{major}.{minor}.{patch + 1}"


def _app_store_version_state(jwt: str, app_id: str, marketing_version: str) -> str | None:
    url = (
        f"https://api.appstoreconnect.apple.com/v1/apps/{app_id}/appStoreVersions"
        f"?filter[platform]=IOS"
        f"&filter[versionString]={marketing_version}"
        "&limit=1"
    )
    data = _api_get(url, jwt)
    items = data.get("data") or []
    if not items:
        return None
    return (items[0].get("attributes") or {}).get("appStoreState")


def _is_train_closed(jwt: str, app_id: str, marketing_version: str) -> bool:
    state = _app_store_version_state(jwt, app_id, marketing_version)
    return state in _CLOSED_TRAIN_STATES if state else False


def _resolve_marketing_version(
    jwt: str, app_id: str, name: str, *, bump_if_closed: bool
) -> tuple[str, bool]:
    if not bump_if_closed:
        return name, False
    current = name
    bumped = False
    while _is_train_closed(jwt, app_id, current):
        next_name = _bump_patch(current)
        print(
            f"Pre-release train {current} is closed on App Store Connect; "
            f"bumping marketing version to {next_name}"
        )
        current = next_name
        bumped = True
    return current, bumped


def _max_build_for_version(jwt: str, app_id: str, marketing_version: str) -> int | None:
    """Largest CFBundleVersion uploaded for [marketing_version], or None."""
    base = (
        "https://api.appstoreconnect.apple.com/v1/builds"
        f"?filter[app]={app_id}"
        f"&filter[preReleaseVersion.version]={marketing_version}"
        "&limit=200"
        "&sort=-version"
    )
    return _max_build_from_builds_url(jwt, base)


def _max_build_for_app(jwt: str, app_id: str) -> int | None:
    """Largest CFBundleVersion uploaded for the app (any marketing version), or None."""
    base = (
        "https://api.appstoreconnect.apple.com/v1/builds"
        f"?filter[app]={app_id}"
        "&limit=200"
        "&sort=-version"
    )
    return _max_build_from_builds_url(jwt, base)


def _max_build_from_builds_url(jwt: str, base: str) -> int | None:
    max_build: int | None = None
    url: str | None = base
    while url:
        data = _api_get(url, jwt)
        for item in data.get("data") or []:
            raw = (item.get("attributes") or {}).get("version")
            if raw is None:
                continue
            try:
                n = int(str(raw).strip())
            except ValueError:
                continue
            max_build = n if max_build is None else max(max_build, n)
        url = (data.get("links") or {}).get("next")
    return max_build


def _write_github_output(
    name: str,
    code: int,
    full: str,
    asc_max: int | None,
    pubspec_build: int,
    *,
    pubspec_name: str,
    version_bumped: bool,
) -> None:
    out_path = os.environ.get("GITHUB_OUTPUT")
    if not out_path:
        return
    with open(out_path, "a", encoding="utf-8") as f:
        f.write(f"name={name}\n")
        f.write(f"code={code}\n")
        f.write(f"full={full}\n")
        f.write(f"pubspec_build={pubspec_build}\n")
        f.write(f"pubspec_name={pubspec_name}\n")
        f.write(f"version_bumped={'true' if version_bumped else 'false'}\n")
        if asc_max is not None:
            f.write(f"asc_max_build={asc_max}\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pubspec", default="pubspec.yaml", type=Path)
    parser.add_argument("--bundle-id", default="app.halalscan")
    parser.add_argument(
        "--tag-version",
        default="",
        help="Optional tag or input version to verify matches pubspec (e.g. 1.3.4)",
    )
    parser.add_argument(
        "--update-pubspec",
        action="store_true",
        help="Write resolved version line back to pubspec.yaml",
    )
    args = parser.parse_args()

    pubspec_name, pubspec_build = _parse_pubspec(args.pubspec)
    tag = (args.tag_version or os.environ.get("TAG_VERSION", "")).strip().lstrip("v")
    if tag and tag != pubspec_name:
        raise SystemExit(
            f"Tag/input version {tag!r} does not match pubspec marketing version {pubspec_name!r}"
        )

    name = pubspec_name
    version_bumped = False
    asc_max: int | None = None
    asc_app_max: int | None = None
    if all(os.environ.get(k) for k in (
        "APP_STORE_CONNECT_KEY_ID",
        "APP_STORE_CONNECT_ISSUER_ID",
        "APP_STORE_CONNECT_KEY_BASE64",
    )):
        jwt = _make_jwt()
        app_id = _app_id(jwt, args.bundle_id)
        bump_if_closed = args.update_pubspec and not tag
        name, version_bumped = _resolve_marketing_version(
            jwt, app_id, pubspec_name, bump_if_closed=bump_if_closed
        )
        asc_max = _max_build_for_version(jwt, app_id, name)
        asc_app_max = _max_build_for_app(jwt, app_id)

    asc_effective_max = asc_max
    if asc_app_max is not None:
        asc_effective_max = (
            asc_app_max if asc_effective_max is None else max(asc_effective_max, asc_app_max)
        )

    if asc_effective_max is not None:
        next_build = asc_effective_max + 1
        if asc_max is not None and asc_max == asc_effective_max:
            source = f"App Store Connect max {asc_effective_max} + 1"
        elif asc_max is not None:
            source = (
                f"App Store Connect app max {asc_app_max} + 1 "
                f"(version {name} max {asc_max})"
            )
        else:
            source = f"App Store Connect app max {asc_app_max} + 1 (new version train)"
    else:
        next_build = pubspec_build + 1
        source = f"no ASC builds for {name}; pubspec {pubspec_build} + 1"

    if asc_effective_max is not None and next_build <= asc_effective_max:
        next_build = asc_effective_max + 1

    full = f"{name}+{next_build}"
    if args.update_pubspec:
        text = args.pubspec.read_text(encoding="utf-8")
        args.pubspec.write_text(
            re.sub(r"^version:.*$", f"version: {full}", text, count=1, flags=re.M),
            encoding="utf-8",
        )
        print(f"Updated {args.pubspec} to {full}")

    if version_bumped:
        print(f"Marketing version: {name} (pubspec was {pubspec_name}; train closed)")
    else:
        print(f"Marketing version: {name} (from pubspec)")
    print(f"Pubspec build:     {pubspec_build}")
    if asc_max is not None:
        print(f"ASC max build:     {asc_max} (version {name})")
    if asc_app_max is not None and asc_app_max != asc_max:
        print(f"ASC app max build: {asc_app_max} (all versions)")
    print(f"Next build number: {next_build} ({source})")
    print(f"Full:              {full}")

    _write_github_output(
        name,
        next_build,
        full,
        asc_effective_max,
        pubspec_build,
        pubspec_name=pubspec_name,
        version_bumped=version_bumped,
    )


if __name__ == "__main__":
    main()
