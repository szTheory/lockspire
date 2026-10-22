#!/usr/bin/env python3
"""Exercise the supported pre-lifetime to authoritative maintenance cutover."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from urllib.request import urlopen

from build_provider import prepare_provider
from package_input import (
    candidate_host_provenance,
    PackageInputError,
    PackageIdentity,
    PackageSource,
    clean_room_database_url,
    prepare_package,
    verify_candidate_input,
)
from lifetime_receipts import validate_candidate_identity_agreement
from redaction import Redactor, SentinelSet, safe_failure_summary


OLD_VERSION = "1.6.1"
OLD_SHA256 = "629abdc1b6721620f3d9084dbbe78da1e254650da5c552d0cc0f5b0c00f1cc6d"
SCENARIOS = {"public": "public", "tenant_auth": "tenant_auth"}
DATES = ("nil", "creation", "past", "future", "stale_after_rotation")
UPGRADE_RECEIPT_FIELDS = frozenset({"schema_version", "scenarios"})
UPGRADE_SCENARIO_FIELDS = frozenset({
    "prefix", "old_package", "candidate_package", "historical_migration_checksums_preserved",
    "historical_migration_checksum_count", "historical_migration_checksums_sha256",
    "old_processes", "expansion_process", "old_writer_processes_stopped_before_v1",
    "old_read_write_count", "old_read_observation", "v0_legacy_rows_observation",
    "old_rotation_observation", "candidate_v1_write_process", "v1_state_retained_observation",
    "v1_state_retained", "database_cleanup_process", "old_binary_after_v1_traffic",
    "rollback_boundary",
})
PROCESS_FIELDS = frozenset({"pid", "command", "exit_code", "output"})
OLD_PACKAGE_FIELDS = frozenset({
    "schema_version", "source", "package", "version", "sha256", "archive_sha256",
    "tree_sha256", "source_revision",
})
SAFE_COMMANDS = frozenset({"ecto.create", "ecto.migrate", "run", "lockspire.client.create", "ecto.drop"})


SENSITIVE_OUTPUT = re.compile(
    r"(?i)(?:client_secret|registration_access_token|access_token|refresh_token|authorization_code|"
    r"pkce_verifier|verifier|private_key|cookie|secret|token|hash)\s*[:=]\s*[\"']?([^\s,;\"'}]+)"
)
SAFE_MARKER = re.compile(r"(?:[A-Z][A-Z0-9_]*=\d+)(?:;[A-Z][A-Z0-9_]*=\d+)*\Z")


def _register_output_material(redactor: Redactor, output: str) -> None:
    for match in SENSITIVE_OUTPUT.finditer(output):
        redactor.register_material(match.group(1))
    for line in output.splitlines():
        try:
            parsed = json.loads(line)
        except (json.JSONDecodeError, TypeError):
            continue
        _register_structured_material(redactor, parsed)


def _register_structured_material(redactor: Redactor, value: object, key: str = "") -> None:
    if isinstance(value, dict):
        for child_key, child_value in value.items():
            _register_structured_material(redactor, child_value, str(child_key))
    elif isinstance(value, (list, tuple)):
        for child_value in value:
            _register_structured_material(redactor, child_value, key)
    elif isinstance(value, str) and re.search(
        r"(?i)(secret|token|code|verifier|private.?key|cookie|hash)", key
    ):
        redactor.register_material(value)


def _safe_process_output(output: str) -> str:
    return "\n".join(line for line in output.splitlines() if SAFE_MARKER.fullmatch(line))[-3000:]


def run_process(
    child: Path, env: dict[str, str], args: tuple[str, ...], redactor: Redactor,
    *, stage: str, scenario: str, timeout: int = 180,
) -> dict[str, object]:
    try:
        redactor.assert_safe("\0".join(args))
    except RuntimeError:
        raise PackageInputError(str(safe_failure_summary(
            stage=stage, scenario=scenario, event="child_start", field="argv", count=1
        ))) from None
    try:
        process = subprocess.Popen(
            ("mix", *args), cwd=child, env=env, stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
    except OSError:
        raise PackageInputError(str(safe_failure_summary(
            stage=stage, scenario=scenario, event="child_start", field="exception", count=1
        ))) from None
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        process.kill()
        process.communicate()
        raise PackageInputError(str(safe_failure_summary(
            stage=stage, scenario=scenario, event="child_timeout", field="process", count=1
        ))) from None
    output = (stdout or b"").decode(errors="replace")
    error_output = (stderr or b"").decode(errors="replace")
    _register_output_material(redactor, output + "\n" + error_output)
    command = args[0] if args and args[0] in SAFE_COMMANDS else "child"
    if process.returncode != 0:
        summary = safe_failure_summary(
            stage=stage, scenario=scenario, event="child_exit", field="stdout_stderr",
            count=len(output.splitlines()) + len(error_output.splitlines()),
        )
        raise PackageInputError(str(summary))
    return {
        "pid": process.pid,
        "command": command,
        "exit_code": process.returncode,
        "output": _safe_process_output(output),
    }


def mix_env(child: Path, run_root: Path, database_url: str, storage_prefix: str) -> dict[str, str]:
    env = os.environ.copy()
    dependency_root = run_root / "deps-cache" / "provider" / "deps"
    hex_home = run_root / "hex-home"
    mix_home = run_root / "mix-home"
    dependency_root.mkdir(mode=0o700, parents=True, exist_ok=True)
    hex_home.mkdir(mode=0o700, parents=True, exist_ok=True)
    mix_home.mkdir(mode=0o700, parents=True, exist_ok=True)
    env.update({
        "MIX_ENV": "dev",
        "MIX_BUILD_PATH": str(child / "_build"),
        "MIX_DEPS_PATH": str(dependency_root),
        "HEX_HOME": str(hex_home),
        "MIX_HOME": str(mix_home),
        "DATABASE_URL": database_url,
        "LOCKSPIRE_STORAGE_PREFIX": storage_prefix,
        "LOCKSPIRE_KEY_ENCRYPTION_KEY": os.environ.get("LOCKSPIRE_KEY_ENCRYPTION_KEY", "") or "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
    })
    return env


def migration_checksums(root: Path) -> dict[str, str]:
    migration_root = root / "priv" / "repo" / "migrations"
    return {
        path.name: hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(migration_root.glob("*.exs"))
    }


def run_scenario(
    run_root: Path, prefix: str, candidate_package: Path, candidate_archive: Path,
    candidate_identity: PackageIdentity, redactor: Redactor,
) -> dict[str, object]:
    def run_child(host: Path, environment: dict[str, str], command: tuple[str, ...]) -> dict[str, object]:
        return run_process(
            host, environment, command, redactor, stage="legacy_upgrade", scenario=prefix
        )

    old_root = run_root / f"old-{prefix}"
    candidate_root = run_root / f"candidate-{prefix}"
    database_url = clean_room_database_url(f"life_{prefix}")
    downloads = old_root / "package" / "downloads"
    downloads.mkdir(mode=0o700, parents=True, exist_ok=True)
    old_tar = downloads / f"lockspire-{OLD_VERSION}.tar"
    if not old_tar.is_file():
        with urlopen(f"https://repo.hex.pm/tarballs/lockspire-{OLD_VERSION}.tar", timeout=30) as response:
            old_tar.write_bytes(response.read())
    digest = hashlib.sha256(old_tar.read_bytes()).hexdigest()
    if digest != OLD_SHA256:
        raise PackageInputError("public old package checksum did not match the pinned release")
    previous_root = os.environ.get("LOCKSPIRE_PACKAGE_ROOT")
    os.environ["LOCKSPIRE_PACKAGE_ROOT"] = str(downloads)
    try:
        old_package = old_root / "package" / "lockspire"
        old_package, old_entries, old_identity = prepare_package(
            old_root, PackageSource("tar", str(old_tar), OLD_SHA256)
        )
        verify_candidate_input(old_tar, old_package, old_identity)
    finally:
        if previous_root is None:
            os.environ.pop("LOCKSPIRE_PACKAGE_ROOT", None)
        else:
            os.environ["LOCKSPIRE_PACKAGE_ROOT"] = previous_root
    verify_candidate_input(candidate_archive, candidate_package, candidate_identity)
    if not (candidate_package / "priv/repo/migrations/20261021000000_add_client_lifetime_contract.exs").is_file():
        raise PackageInputError("candidate package lacks the lifetime expansion migration")
    if "priv/repo/migrations/20261021000000_add_client_lifetime_contract.exs" in old_entries:
        raise PackageInputError("pinned old package unexpectedly contains the lifetime expansion migration")
    old_checksums = migration_checksums(old_package)
    candidate_checksums = migration_checksums(candidate_package)
    if not old_checksums or any(candidate_checksums.get(name) != checksum for name, checksum in old_checksums.items()):
        raise PackageInputError("candidate package changed a shipped migration checksum")

    old_host = prepare_provider(old_root, database_url, package_root=old_package, storage_prefix=prefix, candidate_identity=old_identity)
    old_env = mix_env(old_host, old_root, database_url, prefix)
    old_processes = [
        run_child(old_host, old_env, ("ecto.create",)),
        run_child(old_host, old_env, ("ecto.migrate",)),
    ]

    # The old package still reads and writes every row after expansion: its schema ignores
    # the additive columns and PostgreSQL supplies the constant v0 default.
    candidate_host = prepare_provider(
        candidate_root, database_url, package_root=candidate_package, storage_prefix=prefix,
        candidate_identity=candidate_identity,
    )
    candidate_env = mix_env(candidate_host, candidate_root, database_url, prefix)
    host_provenance = candidate_host_provenance(candidate_host)
    expansion = run_child(candidate_host, candidate_env, ("ecto.migrate",))

    client_ids = [f"lifetime-{prefix}-{label}" for label in DATES]
    for client_id in client_ids:
        kind = "confidential" if client_id.endswith("stale_after_rotation") else "public"
        create_args = (
            "lockspire.client.create", "--client-type", kind, "--client-id", client_id,
            "--redirect-uri", "https://client.example/callback", "--scope", "openid",
            "--grant-type", "authorization_code", "--name", "Upgrade proof",
        )
        old_processes.append(run_child(old_host, old_env, (
            *create_args,
        )))

    qualified = f"{prefix}.lockspire_clients"
    date_updates = [
        f'Ecto.Adapters.SQL.query!(repo, "UPDATE {qualified} SET client_secret_expires_at = NULL WHERE client_id = $1", ["{client_ids[0]}"])',
        f'Ecto.Adapters.SQL.query!(repo, "UPDATE {qualified} SET client_secret_expires_at = created_at WHERE client_id = $1", ["{client_ids[1]}"])',
        f'Ecto.Adapters.SQL.query!(repo, "UPDATE {qualified} SET client_secret_expires_at = TIMESTAMPTZ \'2000-01-01 00:00:00+00\' WHERE client_id = $1", ["{client_ids[2]}"])',
        f'Ecto.Adapters.SQL.query!(repo, "UPDATE {qualified} SET client_secret_expires_at = TIMESTAMPTZ \'2099-01-01 00:00:00+00\' WHERE client_id = $1", ["{client_ids[3]}"])',
        f'Ecto.Adapters.SQL.query!(repo, "UPDATE {qualified} SET client_secret_expires_at = TIMESTAMPTZ \'2000-01-02 00:00:00+00\' WHERE client_id = $1", ["{client_ids[4]}"])',
    ]
    seed_dates = (
        'repo = Lockspire.Config.repo!(); ' + "; ".join(date_updates) + "; "
        f'{{:ok, _}} = Lockspire.Admin.Clients.rotate_client_secret("{client_ids[4]}", %{{rotated_at: DateTime.utc_now(), actor: %{{type: :operator, id: "upgrade-proof"}}}}); '
        'IO.puts("LEGACY_SECRET_DATES_SEEDED=5;STALE_DATE_SURVIVED_ROTATION=1")'
    )
    old_rotation = run_child(old_host, old_env, ("run", "-e", seed_dates))
    old_processes.append(old_rotation)
    old_read = run_child(old_host, old_env, (
        "run", "-e",
        'repo = Lockspire.Config.repo!(); '
        f'result = Ecto.Adapters.SQL.query!(repo, "SELECT count(*) FROM {qualified} WHERE client_id LIKE $1", ["lifetime-{prefix}-%"]); '
        'unless result.rows == [[5]], do: raise("old package could not read expanded rows"); IO.puts("OLD_EXPANDED_ROWS_READ=5")',
    ))
    old_processes.append(old_read)

    # All old child Mix processes have exited before the candidate's first v1 registration.
    old_stopped = all(item["exit_code"] == 0 for item in old_processes)
    if not old_stopped:
        raise PackageInputError("old writer process did not stop before cutover")

    id_sql = ",".join("'" + value.replace("'", "''") + "'" for value in client_ids)
    v0_probe = (
        'repo = Lockspire.Config.repo!(); '
        f'result = Ecto.Adapters.SQL.query!(repo, "SELECT client_id, lifetime_version, client_expires_at, CASE WHEN client_secret_expires_at IS NULL THEN \'nil\' WHEN client_secret_expires_at::date = created_at::date THEN \'creation\' WHEN client_secret_expires_at < NOW() THEN \'past\' WHEN client_secret_expires_at > NOW() THEN \'future\' ELSE \'other\' END FROM {qualified} WHERE client_id IN ({id_sql})", []); '
        'now = DateTime.utc_now() |> DateTime.truncate(:second); '
        'valid = length(result.rows) == 5 and Enum.all?(result.rows, fn [_id, version, deadline, _date_kind] -> '
        'Lockspire.Domain.Client.app_eligibility(%Lockspire.Domain.Client{active: true, lifetime_version: version, client_expires_at: deadline}, now, :upgrade_proof) == :ok end); '
        'date_kinds = result.rows |> Enum.map(&Enum.at(&1, 3)) |> MapSet.new(); '
        'expected = MapSet.new(["nil", "creation", "past", "future"]); '
        f'stale = Enum.any?(result.rows, fn [id, _version, _deadline, kind] -> id == "{client_ids[4]}" and kind == "past" end); '
        'unless valid and MapSet.subset?(expected, date_kinds) and stale, do: raise("v0 legacy rows or historical dates failed observation"); '
        'IO.puts("V0_LEGACY_ROWS_VERIFIED=#{length(result.rows)};LEGACY_DATE_KINDS=#{MapSet.size(date_kinds)};STALE_AFTER_ROTATION_OBSERVED=1")'
    )
    legacy_observation = run_child(candidate_host, candidate_env, ("run", "-e", v0_probe))
    if "V0_LEGACY_ROWS_VERIFIED=5;LEGACY_DATE_KINDS=4;STALE_AFTER_ROTATION_OBSERVED=1" not in str(legacy_observation["output"]):
        raise PackageInputError("candidate did not observe five unlimited v0 rows and four historical date shapes")

    v1_id = f"lifetime-{prefix}-candidate-v1"
    v1_write = run_child(candidate_host, candidate_env, (
        "lockspire.client.create", "--client-type", "public", "--client-id", v1_id,
        "--redirect-uri", "https://client.example/callback", "--scope", "openid",
        "--grant-type", "authorization_code", "--name", "Candidate v1 proof",
    ))
    retained_probe = (
        'repo = Lockspire.Config.repo!(); '
        f'result = Ecto.Adapters.SQL.query!(repo, "SELECT lifetime_version FROM {qualified} WHERE client_id = $1", ["{v1_id}"]); '
        'unless result.rows == [[1]], do: raise("candidate v1 state was not retained"); IO.puts("V1_STATE_RETAINED=1")'
    )
    retained_observation = run_child(candidate_host, candidate_env, ("run", "-e", retained_probe))
    if "V1_STATE_RETAINED=1" not in str(retained_observation["output"]):
        raise PackageInputError("candidate did not observe retained authoritative v1 state")
    database_cleanup = run_child(candidate_host, candidate_env, ("ecto.drop",))

    receipt = {
        "prefix": prefix,
        "old_package": old_identity.safe_receipt(),
        "candidate_package": {
            "kind": candidate_identity.kind,
            "version": candidate_identity.version,
            "archive_sha256": candidate_identity.archive_sha256,
            "tree_sha256": candidate_identity.tree_sha256,
            "source_revision": candidate_identity.source_revision,
            **host_provenance,
        },
        "historical_migration_checksums_preserved": True,
        "historical_migration_checksum_count": len(old_checksums),
        "historical_migration_checksums_sha256": hashlib.sha256(json.dumps(old_checksums, sort_keys=True).encode()).hexdigest(),
        "old_processes": old_processes,
        "expansion_process": expansion,
        "old_writer_processes_stopped_before_v1": old_stopped,
        "old_read_write_count": len(client_ids),
        "old_read_observation": old_read,
        "v0_legacy_rows_observation": legacy_observation,
        "old_rotation_observation": old_rotation,
        "candidate_v1_write_process": v1_write,
        "v1_state_retained_observation": retained_observation,
        "v1_state_retained": "V1_STATE_RETAINED=1" in str(retained_observation["output"]),
        "database_cleanup_process": database_cleanup,
        "old_binary_after_v1_traffic": False,
        "rollback_boundary": "retain schema and v1 state; fix forward or use lifetime-aware rollback",
    }
    return receipt


def validate_receipt(receipt: dict[str, object], expected_prefixes: set[str] | None = None) -> None:
    if not isinstance(receipt, dict) or set(receipt) != UPGRADE_RECEIPT_FIELDS or receipt.get("schema_version") != 1:
        raise PackageInputError("receipt fields are invalid")
    expected_prefixes = set(SCENARIOS.values()) if expected_prefixes is None else expected_prefixes
    rows = receipt.get("scenarios")
    if not isinstance(rows, list) or {row.get("prefix") for row in rows if isinstance(row, dict)} != expected_prefixes:
        raise PackageInputError("receipt is missing a requested prefix scenario")
    candidate_identities: set[tuple[object, ...]] = set()
    for row in rows:
        if not isinstance(row, dict) or set(row) != UPGRADE_SCENARIO_FIELDS:
            raise PackageInputError("receipt scenario fields are invalid")
        for name in ("old_processes",):
            processes = row.get(name)
            if not isinstance(processes, list) or any(not isinstance(item, dict) or set(item) != PROCESS_FIELDS for item in processes):
                raise PackageInputError("receipt process fields are invalid")
            if any(
                type(item.get("pid")) is not int
                or item.get("command") not in SAFE_COMMANDS
                or type(item.get("exit_code")) is not int
                for item in processes
            ):
                raise PackageInputError("receipt process identity is invalid")
        for name in (
            "expansion_process", "old_read_observation", "v0_legacy_rows_observation",
            "old_rotation_observation", "candidate_v1_write_process", "v1_state_retained_observation",
            "database_cleanup_process",
        ):
            process = row.get(name)
            if not isinstance(process, dict) or set(process) != PROCESS_FIELDS:
                raise PackageInputError("receipt process fields are invalid")
            if (
                type(process.get("pid")) is not int
                or process.get("command") not in SAFE_COMMANDS
                or type(process.get("exit_code")) is not int
            ):
                raise PackageInputError("receipt process identity is invalid")
            output = process.get("output")
            if not isinstance(output, str) or len(output) > 3000 or any(
                line and not SAFE_MARKER.fullmatch(line) for line in output.splitlines()
            ):
                raise PackageInputError("receipt process output is not an allowlisted observation")
        if not isinstance(row, dict) or row.get("old_read_write_count", 0) < len(DATES):
            raise PackageInputError("receipt has no observed old package writes")
        if "OLD_EXPANDED_ROWS_READ=5" not in str(row.get("old_read_observation", {}).get("output", "")):
            raise PackageInputError("receipt is missing the old package's post-expansion read")
        if "V0_LEGACY_ROWS_VERIFIED=5;LEGACY_DATE_KINDS=4;STALE_AFTER_ROTATION_OBSERVED=1" not in str(row.get("v0_legacy_rows_observation", {}).get("output", "")):
            raise PackageInputError("receipt is missing the candidate's observed v0-unlimited and historical-date results")
        if "STALE_DATE_SURVIVED_ROTATION=1" not in str(row.get("old_rotation_observation", {}).get("output", "")):
            raise PackageInputError("receipt is missing the old package secret-rotation observation")
        if not row.get("old_writer_processes_stopped_before_v1") or not row.get("v1_state_retained"):
            raise PackageInputError("receipt is missing the writer drain or retained-v1-state boundary")
        if row.get("database_cleanup_process", {}).get("exit_code") != 0:
            raise PackageInputError("receipt is missing isolated database cleanup")
        if not row.get("historical_migration_checksums_preserved") or row.get("historical_migration_checksum_count", 0) == 0:
            raise PackageInputError("receipt is missing byte-preserved historical migration checksums")
        if row.get("old_binary_after_v1_traffic") is not False:
            raise PackageInputError("receipt claims unsafe old-binary protocol rollback")
        if not isinstance(row.get("old_package"), dict) or set(row["old_package"]) != OLD_PACKAGE_FIELDS:
            raise PackageInputError("receipt old package identity fields are invalid")
        candidate = row.get("candidate_package")
        candidate_fields = frozenset({"kind", "version", "archive_sha256", "tree_sha256", "source_revision", "vendor_tree_sha256", "compiled_candidate_sha256", "resolved_dependency_verified"})
        if not isinstance(candidate, dict) or set(candidate) != candidate_fields:
            raise PackageInputError("receipt is missing candidate package identity")
        if not all(isinstance(candidate.get(key), str) for key in ("kind", "version", "archive_sha256", "tree_sha256", "source_revision", "vendor_tree_sha256", "compiled_candidate_sha256")):
            raise PackageInputError("receipt candidate package identity is incomplete")
        if any(not re.fullmatch(r"[0-9a-f]{64}", str(candidate[key])) for key in ("archive_sha256", "tree_sha256", "vendor_tree_sha256", "compiled_candidate_sha256")):
            raise PackageInputError("receipt candidate package digest is invalid")
        if not re.fullmatch(r"[0-9a-f]{40,64}", str(candidate["source_revision"])):
            raise PackageInputError("receipt candidate source revision is invalid")
        if candidate.get("resolved_dependency_verified") is not True or candidate["vendor_tree_sha256"] != candidate["tree_sha256"]:
            raise PackageInputError("receipt candidate host provenance is incomplete")
        candidate_identities.add(tuple(candidate[key] for key in ("kind", "version", "archive_sha256", "tree_sha256", "source_revision")))
    if len(candidate_identities) != 1:
        raise PackageInputError("prefix scenarios do not share one candidate identity")
    try:
        validate_candidate_identity_agreement(
            [{key: row["candidate_package"][key] for key in ("kind", "version", "archive_sha256", "tree_sha256")} for row in rows]
        )
    except (AssertionError, KeyError, TypeError):
        raise PackageInputError("prefix scenarios do not share one candidate identity") from None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scenario", choices=("all", *SCENARIOS), default="all")
    parser.add_argument("--receipt", type=Path)
    parser.add_argument("--check-receipt", type=Path)
    parser.add_argument("--work-root", type=Path, help="reuse isolated package and provider trees under this task-local directory")
    parser.add_argument("--package-tar", type=Path)
    parser.add_argument("--package-sha256")
    parser.add_argument("--source-revision")
    args = parser.parse_args()
    redactor = Redactor(SentinelSet.for_run())
    try:
        if args.check_receipt:
            validate_receipt(json.loads(args.check_receipt.read_text()))
            print("lifetime upgrade receipt verified")
            return 0
        selected = list(SCENARIOS) if args.scenario == "all" else [args.scenario]
        debug_root = str(args.work_root) if args.work_root else os.environ.get("LOCKSPIRE_UPGRADE_DEBUG_ROOT")
        if debug_root:
            run_root = Path(debug_root).resolve()
            run_root.mkdir(mode=0o700, parents=True, exist_ok=True)
            candidate_package, _entries, candidate_identity = prepare_package(
                run_root, PackageSource("tar", str(args.package_tar), args.package_sha256)
                if args.package_tar else None
            )
            candidate_archive = args.package_tar.resolve() if args.package_tar else run_root / "package" / f"lockspire-{candidate_identity.version}.tar"
            if args.source_revision:
                if not re.fullmatch(r"[0-9a-f]{40,64}", args.source_revision):
                    raise PackageInputError("candidate source revision is invalid")
                candidate_identity = PackageIdentity(
                    candidate_identity.kind, candidate_identity.version, candidate_identity.sha256,
                    candidate_identity.archive_sha256, candidate_identity.tree_sha256, args.source_revision,
                )
            scenarios = [run_scenario(run_root, SCENARIOS[name], candidate_package, candidate_archive, candidate_identity, redactor) for name in selected]
            receipt = {"schema_version": 1, "scenarios": scenarios}
            validate_receipt(receipt, {SCENARIOS[name] for name in selected})
            rendered = json.dumps(receipt, sort_keys=True, indent=2)
            if args.receipt:
                args.receipt.parent.mkdir(parents=True, exist_ok=True)
                args.receipt.write_text(rendered + "\n")
            print(rendered)
        else:
            with tempfile.TemporaryDirectory(prefix="lockspire-lifetime-upgrade-") as temporary:
                run_root = Path(temporary)
                candidate_package, _entries, candidate_identity = prepare_package(
                    run_root, PackageSource("tar", str(args.package_tar), args.package_sha256)
                    if args.package_tar else None
                )
                candidate_archive = args.package_tar.resolve() if args.package_tar else run_root / "package" / f"lockspire-{candidate_identity.version}.tar"
                if args.source_revision:
                    if not re.fullmatch(r"[0-9a-f]{40,64}", args.source_revision):
                        raise PackageInputError("candidate source revision is invalid")
                    candidate_identity = PackageIdentity(
                        candidate_identity.kind, candidate_identity.version, candidate_identity.sha256,
                        candidate_identity.archive_sha256, candidate_identity.tree_sha256, args.source_revision,
                    )
                scenarios = [run_scenario(run_root, SCENARIOS[name], candidate_package, candidate_archive, candidate_identity, redactor) for name in selected]
                receipt = {"schema_version": 1, "scenarios": scenarios}
                validate_receipt(receipt)
                rendered = json.dumps(receipt, sort_keys=True, indent=2)
                if args.receipt:
                    args.receipt.parent.mkdir(parents=True, exist_ok=True)
                    args.receipt.write_text(rendered + "\n")
                print(rendered)
        return 0
    except (PackageInputError, OSError, ValueError) as error:
        summary = safe_failure_summary(
            stage="legacy_upgrade", scenario="selected", event="runner_failure",
            field=type(error).__name__, count=1,
        )
        print(str(summary), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
