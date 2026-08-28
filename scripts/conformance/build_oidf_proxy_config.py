#!/usr/bin/env python3
"""Derive an OIDF nginx config that TLS-terminates the throwaway provider."""

import argparse
from pathlib import Path
import sys


DEFAULT_LOCATION = """        location / {
            proxy_pass http://server:8080;
"""

PROVIDER_LOCATION = """        # Keep provider traffic on the suite's disposable TLS boundary while
        # preserving all /test routes for the conformance server itself.
        location ~ ^/(?:lockspire(?:/|$)|login$|api/billing/summary$) {
            proxy_pass http://host.docker.internal:4100;
            proxy_set_header Host $http_host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port 8443;
            proxy_redirect off;
        }

"""


def build(source: Path, destination: Path) -> None:
    source = source.resolve()
    destination = destination.resolve()

    if not source.is_file():
        raise ValueError("upstream nginx configuration is missing")

    content = source.read_text(encoding="utf-8")
    if content.count(DEFAULT_LOCATION) != 3:
        raise ValueError("unexpected upstream nginx configuration")
    if "host.docker.internal" in content:
        raise ValueError("upstream nginx configuration already defines a host bridge")

    content = content.replace(DEFAULT_LOCATION, PROVIDER_LOCATION + DEFAULT_LOCATION, 1)
    destination.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    destination.write_text(content, encoding="utf-8")
    destination.chmod(0o600)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    try:
        build(Path(args.source), Path(args.output))
    except ValueError as error:
        print(f"OIDF proxy configuration failed: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
