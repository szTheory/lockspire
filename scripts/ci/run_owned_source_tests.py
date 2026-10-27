#!/usr/bin/env python3
"""Run explicit source tests (or canonical CI) on a newly owned local database.

Child output is private, in-memory evidence. Only fixed outcomes, hashes, counts,
and verified resource identities are written to the mode-0600 manifest. An
uncertain create or changed database identity deliberately leaves storage alone.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass, field
from datetime import datetime, timezone
import hashlib
import ipaddress
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from types import MappingProxyType
from typing import Callable, Mapping, Sequence
import uuid

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
from clean_room.package_input import stop_process_group  # noqa: E402

REPO = "Lockspire.TestRepo"
DB_PATTERN = re.compile(r"lockspire_owned_[0-9a-f]{32}\Z")
MARKER = "LOCKSPIRE_OWNED_PREFLIGHT="
CREATED = b"The database for Lockspire.TestRepo has been created"
ALREADY_CREATED = b"The database for Lockspire.TestRepo has already been created"
STAGES = frozenset({"source", "preflight", "catalog", "identity", "create", "migrate", "test", "ci", "drop"})

# Repo.config() performs Ecto's runtime URL/config merge, but starts no repo/app.
# Credentials are compared inside the child; neither value is rendered.
PREFLIGHT = r'''
config = Lockspire.TestRepo.config()
payload = %{
  env: Atom.to_string(Mix.env()),
  repo: inspect(Application.get_env(:lockspire, :repo)),
  ecto_repos: Enum.map(Application.get_env(:lockspire, :ecto_repos, []), &inspect/1),
  database: Keyword.get(config, :database),
  hostname: Keyword.get(config, :hostname),
  port: Keyword.get(config, :port, 5432),
  credentials_match:
    Keyword.get(config, :username) == System.fetch_env!("LOCKSPIRE_TEST_DB_USER") and
    Keyword.get(config, :password, "") == System.fetch_env!("LOCKSPIRE_TEST_DB_PASSWORD")
}
IO.puts("LOCKSPIRE_OWNED_PREFLIGHT=" <> Jason.encode!(payload))
'''


class GuardFailure(RuntimeError):
    """Only locally selected fixed stage/reason strings may cross this boundary."""

    def __init__(self, stage: str, reason: str):
        self.stage, self.reason = stage, reason
        super().__init__(f"owned source test runner: {stage}/{reason}; child diagnostics withheld")


@dataclass(frozen=True)
class Target:
    database: str
    hostname: str
    port: int


@dataclass(frozen=True)
class Result:
    returncode: int
    stdout: bytes = field(default=b"", repr=False)
    stderr: bytes = field(default=b"", repr=False)
    process_group_stopped: bool = True


class ProcessFailure(Exception):
    def __init__(self, reason: str, stopped: bool):
        self.reason, self.stopped = reason, stopped
        super().__init__(reason)


class PrivateProcessRunner:
    """Own a bounded session and stop descendants even after a normal leader exit."""

    def __call__(self, command: Sequence[str], *, env: Mapping[str, str], cwd: Path,
                 timeout: int, started: Callable[[int], None]) -> Result:
        process = subprocess.Popen(
            command, cwd=cwd, env=dict(env), stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True,
        )
        try:
            started(process.pid)
            stdout, stderr = process.communicate(timeout=timeout)
        except BaseException as error:
            stopped = stop_process_group(process)
            reason = "interrupted" if isinstance(error, KeyboardInterrupt) else (
                "timeout" if isinstance(error, subprocess.TimeoutExpired) else "command_unavailable")
            raise ProcessFailure(reason, stopped) from None
        stopped = stop_process_group(process)
        return Result(process.returncode, stdout, stderr, stopped)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalized_environment(inherited: Mapping[str, str], database: str) -> tuple[Mapping[str, str], Target]:
    if not DB_PATTERN.fullmatch(database) or len(database) > 63:
        raise GuardFailure("arguments", "invalid_generated_database")
    host = (inherited.get("LOCKSPIRE_TEST_DB_HOST") or inherited.get("LOCKSPIRE_DB_HOST")
            or inherited.get("PGHOST") or "127.0.0.1")
    if host not in {"localhost", "127.0.0.1", "::1"}:
        raise GuardFailure("arguments", "nonlocal_database_host")
    host = "127.0.0.1" if host == "localhost" else host
    raw_port = (inherited.get("LOCKSPIRE_TEST_DB_PORT") or inherited.get("LOCKSPIRE_DB_PORT")
                or inherited.get("PGPORT") or "5432")
    if not re.fullmatch(r"[0-9]{1,5}", raw_port) or not 1 <= int(raw_port) <= 65535:
        raise GuardFailure("arguments", "invalid_database_port")
    def first_defined(keys, default):
        return next((inherited[key] for key in keys if key in inherited), default)

    user = first_defined(("LOCKSPIRE_TEST_DB_USER", "LOCKSPIRE_DB_USER", "PGUSER", "USER"), "postgres")
    password = first_defined(("LOCKSPIRE_TEST_DB_PASSWORD", "LOCKSPIRE_DB_PASSWORD", "PGPASSWORD"), "")
    env = {key: value for key, value in inherited.items()
           if not key.startswith("PG") and not key.startswith("LOCKSPIRE_TEST_DB_")
           and not key.startswith("LOCKSPIRE_DB_")
           and key not in {"DATABASE_URL", "ECTO_DATABASE_URL", "LOCKSPIRE_DATABASE_URL", "MIX_EXS"}}
    env.update({
        "MIX_ENV": "test", "LOCKSPIRE_TEST_DB_NAME": database, "LOCKSPIRE_DB_NAME": database,
        "LOCKSPIRE_TEST_DB_HOST": host, "LOCKSPIRE_DB_HOST": host,
        "LOCKSPIRE_TEST_DB_PORT": raw_port, "LOCKSPIRE_DB_PORT": raw_port,
        "LOCKSPIRE_TEST_DB_USER": user, "LOCKSPIRE_DB_USER": user,
        "LOCKSPIRE_TEST_DB_PASSWORD": password, "LOCKSPIRE_DB_PASSWORD": password,
        "PGHOST": host, "PGPORT": raw_port, "PGUSER": user, "PGPASSWORD": password,
        "PGDATABASE": database, "PGCONNECT_TIMEOUT": "10", "PGSSLMODE": "disable",
        "PGAPPNAME": "lockspire-owned-source-tests",
    })
    return MappingProxyType(env), Target(database, host, int(raw_port))


def test_paths(paths: Sequence[str], root: Path) -> list[str]:
    selected = []
    for value in paths:
        path = Path(value)
        if (path.is_absolute() or value.startswith("-") or ":" in value
                or path.suffix != ".exs" or not path.name.endswith("_test.exs")):
            raise GuardFailure("arguments", "invalid_test_path")
        resolved = (root / path).resolve()
        if not resolved.is_relative_to((root / "test").resolve()) or not resolved.is_file():
            raise GuardFailure("arguments", "invalid_test_path")
        selected.append(str(resolved.relative_to(root)))
    return selected


class OwnedSourceTests:
    def __init__(self, paths: Sequence[str], *, include_integration: bool = False,
                 ci: bool = False, root: Path = ROOT, inherited: Mapping[str, str] | None = None,
                 process_runner=None):
        self.root = root.resolve()
        self.paths = test_paths(paths, self.root)
        if (ci and (self.paths or include_integration)) or (not ci and not self.paths):
            raise GuardFailure("arguments", "select_tests_or_ci")
        self.ci, self.include_integration = ci, include_integration
        self.env, self.target = normalized_environment(
            dict(os.environ if inherited is None else inherited), "lockspire_owned_" + uuid.uuid4().hex,
        )
        self.process_runner = process_runner or PrivateProcessRunner()
        self.directory = Path(tempfile.mkdtemp(prefix="lockspire-owned-source-tests-"))
        self.directory.chmod(0o700)
        self.manifest_path = self.directory / "manifest.json"
        self.manifest = {
            "schema": "lockspire-owned-source-tests-v1", "created_at": utc_now(),
            "database": self.target.database, "hostname": self.target.hostname,
            "port": self.target.port, "repo": REPO, "mix_env": "test",
            "mode": "ci" if ci else "tests", "test_paths": self.paths,
            "state": "initialized", "create_witness": False, "owned_oid": None,
            "cleanup": "not_owned", "commands": [],
        }
        self.owned_oid = None
        self.process_cleanup_confirmed = True
        self._save()

    def _save(self) -> None:
        temporary = self.directory / "manifest.next"
        fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w") as output:
            json.dump(self.manifest, output, sort_keys=True)
            output.write("\n")
            output.flush()
            os.fsync(output.fileno())
        temporary.replace(self.manifest_path)
        directory_fd = os.open(self.directory, os.O_RDONLY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)

    def _invoke(self, stage: str, command: Sequence[str], timeout: int = 120) -> Result:
        if stage not in STAGES:
            raise GuardFailure("runner", "invalid_stage")
        entry = {"stage": stage, "started_at": utc_now(), "state": "starting"}
        self.manifest["commands"].append(entry)
        self._save()  # Persist intent before launching any possible mutation.

        def started(pid: int) -> None:
            entry.update(pid=pid, process_group=pid, state="running")
            self._save()

        try:
            child_env = dict(self.env)
            if stage in {"catalog", "identity"}:
                child_env["PGOPTIONS"] = "-c default_transaction_read_only=on"
            result = self.process_runner(
                tuple(command), env=child_env, cwd=self.root, timeout=timeout, started=started,
            )
        except BaseException as error:
            reason = error.reason if isinstance(error, ProcessFailure) else (
                "interrupted" if isinstance(error, KeyboardInterrupt) else (
                    "timeout" if isinstance(error, subprocess.TimeoutExpired) else "command_unavailable"))
            stopped = error.stopped if isinstance(error, ProcessFailure) else "pid" not in entry
            self.process_cleanup_confirmed &= stopped
            entry.update(state=reason, finished_at=utc_now(), process_group_stopped=stopped)
            self._save()
            raise GuardFailure(stage, reason) from None
        counts = [
            {"tests": int(tests), "failures": int(failures), "properties": int(properties or 0)}
            for properties, tests, failures in re.findall(
                rb"(?m)^\s*(?:(\d+) properties?,\s*)?(\d+) tests?, (\d+) failures?\b", result.stdout,
            )
            if int(tests) > 0
        ]
        entry.update(
            state="finished", finished_at=utc_now(), exit_code=result.returncode,
            stdout_bytes=len(result.stdout), stdout_sha256=hashlib.sha256(result.stdout).hexdigest(),
            stderr_bytes=len(result.stderr), stderr_sha256=hashlib.sha256(result.stderr).hexdigest(),
            exunit_counts=counts, process_group_stopped=result.process_group_stopped,
        )
        self._save()
        if not result.process_group_stopped:
            self.process_cleanup_confirmed = False
            raise GuardFailure(stage, "process_group_cleanup_unconfirmed")
        return result

    def _preflight(self) -> None:
        result = self._invoke("preflight", ["mix", "run", "--no-start", "-e", PREFLIGHT])
        try:
            lines = [line[len(MARKER):] for line in result.stdout.decode("utf-8").splitlines()
                     if line.startswith(MARKER)]
            payload = json.loads(lines[0]) if len(lines) == 1 else None
            expected = {
                "env": "test", "repo": REPO, "ecto_repos": [REPO],
                "database": self.target.database, "hostname": self.target.hostname,
                "port": self.target.port, "credentials_match": True,
            }
            valid = (result.returncode == 0 and payload == expected and type(payload["port"]) is int
                     and payload["credentials_match"] is True)
        except (ValueError, UnicodeError, TypeError, KeyError, IndexError):
            valid = False
        if not valid:
            raise GuardFailure("preflight", "effective_config_mismatch")

    def _psql(self, stage: str, database: str, sql: str) -> Result:
        command = [
            "psql", "-X", "-A", "-t", "--no-password", "-v", "ON_ERROR_STOP=1",
            "-h", self.target.hostname, "-p", str(self.target.port), "-U", self.env["PGUSER"],
            "-d", database, "-c", sql,
        ]
        result = self._invoke(stage, command)
        if result.returncode != 0:
            raise GuardFailure(stage, "readonly_identity_query_failed")
        return result

    def _catalog_oid(self) -> int | None:
        # Database is internally generated and strictly identifier-validated.
        output = self._psql("catalog", "postgres",
                            f"SELECT oid::text FROM pg_catalog.pg_database WHERE datname = '{self.target.database}';").stdout
        if not output.strip():
            return None
        if not re.fullmatch(rb"[0-9]+\s*", output) or int(output) <= 0:
            raise GuardFailure("catalog", "invalid_catalog_identity")
        return int(output)

    def _connected_oid(self) -> int:
        result = self._psql("identity", self.target.database, """
SELECT json_build_object('database', current_database(), 'oid',
  (SELECT oid::bigint FROM pg_catalog.pg_database WHERE datname = current_database()),
  'server_address', host(inet_server_addr()), 'server_port', inet_server_port())::text;
""")
        try:
            payload = json.loads(result.stdout)
            valid = (set(payload) == {"database", "oid", "server_address", "server_port"}
                     and payload["database"] == self.target.database
                     and type(payload["oid"]) is int and payload["oid"] > 0
                     and type(payload["server_port"]) is int and payload["server_port"] == self.target.port
                     and ipaddress.ip_address(payload["server_address"]).is_loopback)
        except (ValueError, TypeError, KeyError):
            valid = False
        if not valid:
            raise GuardFailure("identity", "connected_database_mismatch")
        return payload["oid"]

    def _guard_owned(self) -> None:
        self._preflight()
        if (not self.manifest["create_witness"] or self.owned_oid is None
                or self._catalog_oid() != self.owned_oid or self._connected_oid() != self.owned_oid):
            raise GuardFailure("identity", "ownership_unconfirmed")

    def _cleanup(self) -> None:
        if not self.process_cleanup_confirmed:
            raise GuardFailure("drop", "owned_process_cleanup_unconfirmed")
        if self.owned_oid is None:
            self.manifest["cleanup"] = "not_owned_or_uncertain_create"
            self._save()
            return
        self.manifest["cleanup"] = "verifying_ownership"
        self._save()
        self._guard_owned()
        self.manifest["state"] = "drop_intent"
        self._save()
        result = self._invoke("drop", ["mix", "ecto.drop", "-r", REPO])
        if result.returncode != 0:
            raise GuardFailure("drop", "drop_failed")
        self._preflight()
        if self._catalog_oid() is not None:
            raise GuardFailure("drop", "absence_unconfirmed")
        self.manifest["cleanup"] = "independently_absent"
        self._save()

    def run(self) -> int:
        failure = None
        try:
            source = self._invoke("source", ["git", "rev-parse", "HEAD"])
            if source.returncode != 0 or not re.fullmatch(rb"[0-9a-f]{40}\n?", source.stdout):
                raise GuardFailure("source", "source_identity_unconfirmed")
            self.manifest["source_sha"] = source.stdout.decode("ascii").strip()
            checkout = self._invoke("source", ["git", "status", "--porcelain=v1", "--untracked-files=all"])
            if checkout.returncode != 0:
                raise GuardFailure("source", "checkout_identity_unconfirmed")
            self.manifest["checkout_clean_before"] = not checkout.stdout
            self.manifest["checkout_status_sha256_before"] = hashlib.sha256(checkout.stdout).hexdigest()
            self._save()
            self._preflight()
            if self._catalog_oid() is not None:
                raise GuardFailure("create", "database_already_exists")
            self.manifest["state"] = "create_intent"
            self._save()
            result = self._invoke("create", ["mix", "ecto.create", "-r", REPO])
            lines = result.stdout.splitlines()
            if result.returncode != 0 or lines.count(CREATED) != 1 or ALREADY_CREATED in lines:
                raise GuardFailure("create", "new_storage_creation_unconfirmed")
            self.manifest["create_witness"] = True
            self._save()
            self._preflight()
            catalog_oid, connected_oid = self._catalog_oid(), self._connected_oid()
            if catalog_oid is None or catalog_oid != connected_oid:
                raise GuardFailure("identity", "created_database_mismatch")
            self.owned_oid = catalog_oid
            self.manifest.update(owned_oid=catalog_oid, state="owned")
            self._save()
            self._guard_owned()
            result = self._invoke("migrate", ["mix", "ecto.migrate", "-r", REPO], timeout=300)
            if result.returncode != 0:
                raise GuardFailure("migrate", "migration_failed")
            self._guard_owned()
            command = ["mix", "ci"] if self.ci else ["mix", "test"] + (
                ["--include", "integration"] if self.include_integration else []
            ) + self.paths
            stage = "ci" if self.ci else "test"
            result = self._invoke(stage, command, timeout=7200 if self.ci else 1800)
            counts = self.manifest["commands"][-1]["exunit_counts"]
            if result.returncode != 0:
                raise GuardFailure(stage, "tests_failed")
            # Canonical ci owns qa.architecture, test.fast and test.integration.
            if not counts or (self.ci and len(counts) < 3) or any(row["failures"] for row in counts):
                raise GuardFailure(stage, "nonzero_test_evidence_missing")
        except GuardFailure as error:
            failure = error
        except BaseException as error:
            failure = GuardFailure("runner", "interrupted" if isinstance(error, KeyboardInterrupt) else "internal_failure")
        finally:
            try:
                self._cleanup()
            except BaseException as error:
                self.manifest["cleanup"] = "refused_or_unconfirmed"
                failure = failure or (error if isinstance(error, GuardFailure)
                                      else GuardFailure("drop", "cleanup_unconfirmed"))
            self.manifest.update(
                state="failed" if failure else "passed", finished_at=utc_now(),
                failure=None if failure is None else {"stage": failure.stage, "reason": failure.reason},
            )
            self._save()
        return 1 if failure else 0


class PrivateArgumentParser(argparse.ArgumentParser):
    def error(self, _message):
        raise GuardFailure("arguments", "invalid_arguments")


def main(argv: Sequence[str] | None = None) -> int:
    parser = PrivateArgumentParser(description=__doc__)
    parser.add_argument("--ci", action="store_true", help="run the unchanged canonical mix ci alias")
    parser.add_argument("--include", choices=["integration"])
    parser.add_argument("tests", nargs="*", help="explicit existing test/*_test.exs paths")
    runner = None
    try:
        args = parser.parse_args(argv)
        runner = OwnedSourceTests(args.tests, include_integration=args.include is not None, ci=args.ci)
        code = runner.run()
        print(json.dumps({
            "status": "pass" if code == 0 else "failed", "manifest": str(runner.manifest_path),
            "failure": runner.manifest["failure"], "cleanup": runner.manifest["cleanup"],
        }, sort_keys=True))
        return code
    except BaseException as error:
        if isinstance(error, SystemExit) and error.code == 0:
            return 0
        failure = error if isinstance(error, GuardFailure) else GuardFailure("runner", "internal_failure")
        print(json.dumps({"status": "failed", "failure": {"stage": failure.stage, "reason": failure.reason}}))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
