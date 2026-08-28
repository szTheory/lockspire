#!/usr/bin/env python3
"""Validate and normalize the immutable OIDF conformance-suite input lock."""

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

COMMIT = "16ad152b1b2c0baacd3d2519128340d95deb2b8c"
TAG = "release-v5.1.43"
HEX = re.compile(r"^[0-9a-f]{64}$")
DIGEST = re.compile(r"^sha256:[0-9a-f]{64}$")
RAW_BASE = f"https://gitlab.com/openid/conformance-suite/-/raw/{COMMIT}/"
ARCHIVE_URL = f"https://gitlab.com/openid/conformance-suite/-/archive/{COMMIT}/conformance-suite-{COMMIT}.tar.gz"
HELPERS = {
    "docker-compose-prebuilt.yml",
    "scripts/run-test-plan.py",
    "scripts/conformance.py",
    "scripts/test_plan_parser.py",
}
IMAGES = {
    "server": "registry.gitlab.com/openid/conformance-suite",
    "nginx": "registry.gitlab.com/openid/conformance-suite/nginx",
    "mongodb": "mongo",
}
UPSTREAM_IMAGES = {
    "mongodb": "${MONGODB_IMAGE:-mongo:6.0.13}",
    "nginx": "registry.gitlab.com/openid/conformance-suite/nginx:${IMAGE_TAG:-latest}",
    "server": "registry.gitlab.com/openid/conformance-suite:${IMAGE_TAG:-latest}",
}


def fail(message):
    raise ValueError(message)


def no_duplicates(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            fail("duplicate key")
        result[key] = value
    return result


def load_lock(path):
    try:
        with Path(path).open(encoding="utf-8") as handle:
            return json.load(handle, object_pairs_hook=no_duplicates)
    except (OSError, json.JSONDecodeError, ValueError) as error:
        fail(f"invalid lock: {error}")


def require_keys(value, keys, label):
    if not isinstance(value, dict) or set(value) != set(keys):
        fail(f"invalid {label} schema")


def valid_hash(value, digest=False):
    return isinstance(value, str) and (DIGEST if digest else HEX).match(value)


def validate_lock(lock):
    require_keys(lock, {"schema_version", "suite", "helpers", "images"}, "lock")
    if lock["schema_version"] != 1:
        fail("unsupported schema version")

    suite = lock["suite"]
    require_keys(suite, {"tag", "commit", "archive"}, "suite")
    if suite["tag"] != TAG or suite["commit"] != COMMIT:
        fail("mutable reference")
    require_keys(suite["archive"], {"url", "sha256"}, "archive")
    if suite["archive"]["url"] != ARCHIVE_URL or not valid_hash(suite["archive"]["sha256"]):
        fail("invalid archive identity")

    helpers = lock["helpers"]
    if set(helpers) != HELPERS:
        fail("missing helper input")
    for name, item in helpers.items():
        require_keys(item, {"url", "sha256"}, "helper")
        if item["url"] != RAW_BASE + name or not valid_hash(item["sha256"]):
            fail("mutable reference")

    images = lock["images"]
    if set(images) != set(IMAGES):
        fail("missing image input")
    for name, repository in IMAGES.items():
        item = images[name]
        require_keys(item, {"repository", "digest"}, "image")
        if item["repository"] != repository or not valid_hash(item["digest"], digest=True):
            fail("invalid image identity")


def verify_downloads(lock, directory):
    root = Path(directory).resolve()
    archive = (root / "conformance-suite.tar.gz").resolve()
    if root not in archive.parents or not archive.is_file():
        fail("download path escape")
    if hashlib.sha256(archive.read_bytes()).hexdigest() != lock["suite"]["archive"]["sha256"]:
        fail("checksum mismatch")

    for name, item in lock["helpers"].items():
        target = (root / name).resolve()
        if root not in target.parents or not target.is_file():
            fail("download path escape")
        actual = hashlib.sha256(target.read_bytes()).hexdigest()
        if actual != item["sha256"]:
            fail("checksum mismatch")


def normalize_compose(lock, source, destination):
    source_path = Path(source).resolve()
    destination_path = Path(destination).resolve()
    content = source_path.read_text(encoding="utf-8")

    for image in UPSTREAM_IMAGES.values():
        if f"image: {image}" not in content:
            fail("unexpected compose image")

    image_lines = re.findall(r"^\s*image:\s*(.+?)\s*$", content, flags=re.MULTILINE)
    if set(image_lines) != set(UPSTREAM_IMAGES.values()):
        fail("unexpected compose image")

    for name, upstream in UPSTREAM_IMAGES.items():
        locked = f"{lock['images'][name]['repository']}@{lock['images'][name]['digest']}"
        content = content.replace(f"image: {upstream}", f"image: {locked}")

    server_image = f"  server:\n    image: {lock['images']['server']['repository']}@{lock['images']['server']['digest']}"
    if content.count(server_image) != 1:
        fail("unexpected server service")
    content = content.replace(
        server_image,
        server_image
        + '\n    extra_hosts:\n     - "host.docker.internal:host-gateway"',
    )

    if "latest" in content or "master" in content or "${IMAGE_TAG" in content:
        fail("mutable reference")
    destination_path.parent.mkdir(parents=True, exist_ok=True)
    destination_path.write_text(content, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--lock", required=True)
    parser.add_argument("--validate-only", action="store_true")
    parser.add_argument("--verify-downloads")
    parser.add_argument("--normalize-compose", nargs=2, metavar=("SOURCE", "DESTINATION"))
    args = parser.parse_args()

    try:
        lock = load_lock(args.lock)
        validate_lock(lock)
        if args.verify_downloads:
            verify_downloads(lock, args.verify_downloads)
        if args.normalize_compose:
            normalize_compose(lock, *args.normalize_compose)
    except ValueError as error:
        print(f"OIDF input validation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
