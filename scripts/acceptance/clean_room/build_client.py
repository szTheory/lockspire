#!/usr/bin/env python3
"""Build and test the isolated confidential-client acceptance fixture.

The checked-in source is a template; every invocation copies it and the
unpacked package to a fresh directory before touching Mix or PostgreSQL.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import sys
import tempfile
import uuid

from package_input import PackageInputError, build_package, copy_child_template, locked_environment, probe_environment, verify_child
from build_provider import patch_jose_record_extractors


def run_child(child: Path, environment: dict[str, str], *command: str) -> None:
    result = subprocess.run(("mix", *command), cwd=child, env=environment, stdin=subprocess.DEVNULL,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False)
    if result.returncode:
        details = result.stdout.decode(errors="replace").splitlines()[-20:]
        raise PackageInputError("client " + " ".join(command) + " failed: " + " ".join(details))


def exercise(test_name: str) -> None:
    probe_environment()
    with tempfile.TemporaryDirectory(prefix="lockspire-clean-room-client-") as temporary:
        root = Path(temporary)
        package, _ = build_package(root)
        child = copy_child_template("confidential_client", root, package)
        database = f"lockspire_clean_room_client_{uuid.uuid4().hex}"
        environment = locked_environment(child, "confidential_client", root / "deps-cache")
        environment.update({"DATABASE_URL": f"postgres://postgres:postgres@127.0.0.1/{database}"})
        verify_child("confidential_client", child, root / "deps-cache", {"DATABASE_URL": environment["DATABASE_URL"]})
        # The pinned clean-room graph uses JOSE 1.11.12.  Apply the same
        # fail-closed child-local Elixir 1.19 compatibility patch proven for
        # the provider; the checked-in lock remains untouched.
        patch_jose_record_extractors(child, environment)
        try:
            run_child(child, environment, "ecto.create")
            run_child(child, environment, "ecto.migrate", "--migrations-path", "priv/repo/migrations")
            test_file = "oauth_transaction" if test_name == "oauth_callback" else "dpop_client" if test_name in {"oidc_verifier", "dpop_client"} else test_name
            run_child(child, environment, "test", f"test/{test_file}_test.exs")
        finally:
            # Do not hide a test/build failure behind cleanup compilation.
            subprocess.run(("mix", "ecto.drop"), cwd=child, env=environment, stdin=subprocess.DEVNULL,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--test", choices=("oauth_transaction", "oauth_callback", "oidc_verifier", "dpop_client"), required=True)
    args = parser.parse_args(argv)
    try:
        exercise(args.test)
        print(f"client {args.test} verified")
        return 0
    except PackageInputError as error:
        print(f"clean-room client build failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
