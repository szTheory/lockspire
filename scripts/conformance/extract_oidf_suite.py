#!/usr/bin/env python3
"""Safely extract the checksum-verified OIDF source archive."""

import argparse
import re
import shutil
import sys
import tarfile
from pathlib import Path, PurePosixPath

MAX_EXTRACTED_BYTES = 1_000_000_000


def fail(message):
    raise ValueError(message)


def extract(archive_path, commit, output_path):
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        fail("invalid suite commit")

    output = Path(output_path).resolve()
    if output == Path("/") or output.exists():
        fail("suite extraction requires a new non-root output directory")

    expected_root = f"conformance-suite-{commit}"
    total_size = 0
    output.mkdir(mode=0o700, parents=True)

    try:
        with tarfile.open(archive_path, mode="r:gz") as archive:
            for member in archive.getmembers():
                path = PurePosixPath(member.name)
                if path.is_absolute() or ".." in path.parts or not path.parts:
                    fail("unsafe suite archive path")
                if path.parts[0] != expected_root:
                    fail("unexpected suite archive root")
                if member.issym() or member.islnk() or member.isdev():
                    fail("unsupported suite archive entry")

                relative = PurePosixPath(*path.parts[1:])
                if not relative.parts:
                    continue
                target = output.joinpath(*relative.parts)
                if member.isdir():
                    target.mkdir(mode=0o700, parents=True, exist_ok=True)
                    continue
                if not member.isfile():
                    fail("unsupported suite archive entry")

                total_size += member.size
                if total_size > MAX_EXTRACTED_BYTES:
                    fail("suite archive exceeds extraction limit")
                source = archive.extractfile(member)
                if source is None:
                    fail("suite archive file could not be read")
                target.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
                with source, target.open("xb") as destination:
                    shutil.copyfileobj(source, destination)
    except Exception:
        shutil.rmtree(output, ignore_errors=True)
        raise


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    try:
        extract(args.archive, args.commit, args.output)
    except (OSError, tarfile.TarError, ValueError) as error:
        print(f"OIDF suite extraction failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
