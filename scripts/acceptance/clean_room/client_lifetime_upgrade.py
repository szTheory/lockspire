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


OLD_VERSION = "1.6.1"
OLD_SHA256 = "629abdc1b6721620f3d9084dbbe78da1e254650da5c552d0cc0f5b0c00f1cc6d"
SCENARIOS = {"public": "public", "tenant_auth": "tenant_auth"}
DATES = ("nil", "creation", "past", "future", "stale_after_rotation")


def run_process(child: Path, env: dict[str, str], args: tuple[str, ...], timeout: int = 180) -> dict[str, object]:
    process = subprocess.Popen(
        ("mix", *args), cwd=child, env=env, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    try:
        output, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        process.kill()
        process.communicate()
        raise PackageInputError(f"child process timed out: {args[0]}")
    if process.returncode != 0:
        safe_lines = [re.sub(r"client_secret=\S*", "client_secret=[REDACTED]", line)
                      for line in output.decode(errors="replace").splitlines()]
        raise PackageInputError(f"child command failed ({process.returncode}): {' '.join(args)}: {' '.join(safe_lines[-12:])}")
    safe_output = re.sub(r"client_secret=\S*", "client_secret=[REDACTED]", output.decode(errors="replace"))
    return {"pid": process.pid, "command": args[0], "exit_code": process.returncode, "output": safe_output[-3000:]}


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
    candidate_identity: PackageIdentity,
) -> dict[str, object]:
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
        run_process(old_host, old_env, ("ecto.create",)),
        run_process(old_host, old_env, ("ecto.migrate",)),
    ]

    # The old package still reads and writes every row after expansion: its schema ignores
    # the additive columns and PostgreSQL supplies the constant v0 default.
    candidate_host = prepare_provider(
        candidate_root, database_url, package_root=candidate_package, storage_prefix=prefix,
        candidate_identity=candidate_identity,
    )
    candidate_env = mix_env(candidate_host, candidate_root, database_url, prefix)
    host_provenance = candidate_host_provenance(candidate_host)
    expansion = run_process(candidate_host, candidate_env, ("ecto.migrate",))

    client_ids = [f"lifetime-{prefix}-{label}" for label in DATES]
    for client_id in client_ids:
        kind = "confidential" if client_id.endswith("stale_after_rotation") else "public"
        create_args = (
            "lockspire.client.create", "--client-type", kind, "--client-id", client_id,
            "--redirect-uri", "https://client.example/callback", "--scope", "openid",
            "--grant-type", "authorization_code", "--name", "Upgrade proof",
        )
        old_processes.append(run_process(old_host, old_env, (
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
    old_rotation = run_process(old_host, old_env, ("run", "-e", seed_dates))
    old_processes.append(old_rotation)
    old_read = run_process(old_host, old_env, (
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
    legacy_observation = run_process(candidate_host, candidate_env, ("run", "-e", v0_probe))
    if "V0_LEGACY_ROWS_VERIFIED=5;LEGACY_DATE_KINDS=4;STALE_AFTER_ROTATION_OBSERVED=1" not in str(legacy_observation["output"]):
        raise PackageInputError("candidate did not observe five unlimited v0 rows and four historical date shapes")

    v1_id = f"lifetime-{prefix}-candidate-v1"
    v1_write = run_process(candidate_host, candidate_env, (
        "lockspire.client.create", "--client-type", "public", "--client-id", v1_id,
        "--redirect-uri", "https://client.example/callback", "--scope", "openid",
        "--grant-type", "authorization_code", "--name", "Candidate v1 proof",
    ))
    retained_probe = (
        'repo = Lockspire.Config.repo!(); '
        f'result = Ecto.Adapters.SQL.query!(repo, "SELECT lifetime_version FROM {qualified} WHERE client_id = $1", ["{v1_id}"]); '
        'unless result.rows == [[1]], do: raise("candidate v1 state was not retained"); IO.puts("V1_STATE_RETAINED=1")'
    )
    retained_observation = run_process(candidate_host, candidate_env, ("run", "-e", retained_probe))
    if "V1_STATE_RETAINED=1" not in str(retained_observation["output"]):
        raise PackageInputError("candidate did not observe retained authoritative v1 state")
    database_cleanup = run_process(candidate_host, candidate_env, ("ecto.drop",))

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
    expected_prefixes = expected_prefixes or set(SCENARIOS.values())
    rows = receipt.get("scenarios")
    if not isinstance(rows, list) or {row.get("prefix") for row in rows if isinstance(row, dict)} != expected_prefixes:
        raise PackageInputError("receipt is missing a requested prefix scenario")
    candidate_identities: set[tuple[object, ...]] = set()
    for row in rows:
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
        candidate = row.get("candidate_package")
        if not isinstance(candidate, dict):
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
            scenarios = [run_scenario(run_root, SCENARIOS[name], candidate_package, candidate_archive, candidate_identity) for name in selected]
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
                scenarios = [run_scenario(run_root, SCENARIOS[name], candidate_package, candidate_archive, candidate_identity) for name in selected]
                receipt = {"schema_version": 1, "scenarios": scenarios}
                validate_receipt(receipt)
                rendered = json.dumps(receipt, sort_keys=True, indent=2)
                if args.receipt:
                    args.receipt.parent.mkdir(parents=True, exist_ok=True)
                    args.receipt.write_text(rendered + "\n")
                print(rendered)
        return 0
    except (PackageInputError, OSError, ValueError) as error:
        print(f"lifetime upgrade failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
