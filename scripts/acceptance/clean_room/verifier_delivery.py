"""Semantic delivery checks for bounded Phase 178 evidence artifacts."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
from typing import Any

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))

from package_input import PackageInputError, package_tree_digest, sha256, unpack_hex_tarball  # noqa: E402
from build_provider import PROOF_PAIR_LOCKS  # noqa: E402
from verifier_receipts import (  # noqa: E402
    REQUIRED_MATRIX, ReceiptError, _unique_object, expected_case_ids, validate_complete_matrix,
)

ROOT = HERE.parents[2]
PHASE_NAME = "178-packaged-upgrade-proof-delivery-handoff"
PHASE_DEFAULT = ROOT / ".planning" / "phases" / PHASE_NAME
ARTIFACT_DEFAULT = ROOT / ".artifacts" / "phase178"
REVISION = re.compile(r"[0-9a-f]{40,64}\Z")
SHA = re.compile(r"[0-9a-f]{64}\Z")
LATER_OWNER_FINDINGS = frozenset({"T-178-31", "T-178-32", "T-178-35", "T-178-36"})
CANONICAL_CI_JOBS = (
    "Dialyzer", "Release Hygiene Drift", "Fast Checks",
    "Minimum Supported Elixir/OTP", "Integration Checks",
    "Complete Coverage Evidence", "Adoption Demo Smoke",
)
PHASE175_FROZEN_INPUTS = (
    ("test/integration/client_secret_jwt_legacy_age_test.exs", "9cc57a31ebc5ed189a1fe41618aaa122447c8332758a96c5f7a58087b94f91c6"),
    ("test/lockspire/security/client_secret_verifier_compatibility_test.exs", "b409d40d4e1a1a88f9b8e18ab3023c278ae4d29e39fa26282dc0634b7029216d"),
    ("test/lockspire/security/client_secret_verifier_contract_test.exs", "b04ba0b562983122a835500162238cc66f83077926024ef956828f042e2b32fb"),
    ("test/support/client_secret_verifier_fixtures.ex", "4015e36c1a8ca87c066c5b4ddbbcb5193e29edaa5726d35409c80a5d7d36d524"),
    (".planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-BASELINE.json", "55ef5cc2b33556b87eddc8390ee671ab381f07f1e48d6fc54be88e702ed5f045"),
    (".planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-MAIN-ACCEPTANCE.json", "fa9f0914eced166115a2fb300a3f406e68739393e9f0e1970ca44aa1ddb394ab"),
    (".planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-QUALIFICATION.json", "e4f6f0fcc03a33309e02f4519a6ae1d1a54fd77c633108b4e168bd1f0e163788"),
    (".planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-COMPATIBILITY.json", "7eb178b8cbd41fb5e6f4cb5124e12a58502f414a5e2ef5f646df792546156ec3"),
    (".planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CONTRACT.md", "0a8fc84d6963c9a2019ab8faefbd9f29971f1cff2591d4dcaf7e0c60fbefa860"),
    (".planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-POLICY-REVISION.md", "3916510fcf8e9c7d56b3f433785a704eebc9dfca2d5b354b5e11fe55a5bb408f"),
    (".planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CONTEXT.md", "ec28d54304910291a8e278e49a6582d74e350c8d00f2ced3208474b10623efa2"),
    (".planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-03-PLAN.md", "8e93d17dbd303fcecec20f9de366d966b0b48b7c949ce096b2668c50e8e5095f"),
    (".planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-02-SUMMARY.md", "94187b75b50bf5661f2422645f93ffc400d3e12bce8c55b43d28e3b9416988cc"),
)

# Explicitly bounded. Do not replace this with a whole-repository history scan.
COVERED_INPUTS = (
    "mix.exs",
    "mix.lock",
    "config/config.exs",
    "config/test.exs",
    "lib/lockspire/admin/client_verifier_maintenance.ex",
    "lib/lockspire/security/client_secret_verifier.ex",
    "lib/lockspire/security/client_secret_verifier/context.ex",
    "lib/lockspire/security/client_secret_verifier/legacy.ex",
    "lib/lockspire/security/client_secret_verifier/operation_context.ex",
    "lib/lockspire/storage/client_lifetime.ex",
    "lib/lockspire/storage/client_store.ex",
    "lib/lockspire/storage/client_verifier_maintenance.ex",
    "lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex",
    "scripts/acceptance/clean_room/admin_receipts.py",
    "scripts/acceptance/clean_room/build_client.py",
    "scripts/acceptance/clean_room/build_provider.py",
    "scripts/acceptance/clean_room/client_lifetime_upgrade.py",
    "scripts/acceptance/clean_room/lifetime_receipts.py",
    "scripts/acceptance/clean_room/processes.py",
    "scripts/acceptance/clean_room/redaction.py",
    "scripts/acceptance/clean_room/selected_receipts.py",
    "scripts/acceptance/clean_room/verifier_recovery.py",
    "scripts/acceptance/clean_room/verifier_delivery.py",
    "scripts/acceptance/clean_room_admin_journey.py",
    "scripts/acceptance/clean_room_saas_journey.py",
    "scripts/acceptance/clean_room/verifier_receipts.py",
    "scripts/acceptance/clean_room/verifier_transactions.py",
    "scripts/acceptance/clean_room/verifier_core.py",
    "scripts/acceptance/clean_room/verifier_disclosure.py",
    "scripts/acceptance/clean_room/verifier_endpoints.py",
    "scripts/acceptance/clean_room/verifier_rollout.py",
    "scripts/acceptance/clean_room/package_input.py",
    "scripts/acceptance/clean_room_verifier_upgrade.py",
    "scripts/ci/run_verifier_upgrade_proof.sh",
    "scripts/ci/run_owned_source_tests.py",
    "scripts/ci/lint_workflows.sh",
    "test/acceptance/client_verifier_delivery_test.py",
    "test/acceptance/client_verifier_disclosure_test.py",
    "test/acceptance/client_verifier_receipts_test.py",
    "test/acceptance/client_verifier_core_test.py",
    "test/acceptance/client_verifier_endpoints_test.py",
    "test/acceptance/client_verifier_rollout_test.py",
    "test/acceptance/client_verifier_process_supervision_test.py",
    "test/acceptance/client_verifier_transactions_test.py",
    "test/acceptance/owned_source_tests_test.py",
    "test/integration/client_secret_verifier_configuration_test.exs",
    "test/integration/client_secret_verifier_maintenance_concurrency_test.exs",
    "test/integration/client_secret_verifier_maintenance_disclosure_test.exs",
    "test/integration/client_secret_verifier_maintenance_issuance_test.exs",
    "test/integration/client_secret_verifier_maintenance_recovery_test.exs",
    "test/integration/client_secret_verifier_maintenance_test.exs",
    "test/integration/client_secret_verifier_rotation_test.exs",
    "test/integration/client_secret_verifier_tracer_test.exs",
    "test/lockspire/admin/client_verifier_maintenance_test.exs",
    "test/lockspire/config_client_secret_verifier_test.exs",
    "test/lockspire/security/client_secret_verifier_age_test.exs",
    "test/lockspire/security/client_secret_verifier_inspection_test.exs",
    "test/lockspire/security/client_secret_verifier_maintenance_test.exs",
    "test/lockspire/security/client_secret_verifier_rollout_test.exs",
    "test/lockspire/security/client_secret_verifier_test.exs",
    "test/lockspire/storage/client_verifier_maintenance_test.exs",
    "test/support/client_verifier_maintenance_concurrency.ex",
    "test/clean_room/provider_host/mix.exs",
    "test/clean_room/provider_host/mix.lock",
    "test/clean_room/provider_host/lib/clean_room_provider/verifier_transactions.ex",
    "test/clean_room/provider_host/admin_proof.exs",
    "test/clean_room/provider_host/admin_proof_live_view.js",
    "test/clean_room/provider_host/lib/clean_room_provider/accounts.ex",
    "test/clean_room/provider_host/lib/clean_room_provider/bootstrap.ex",
    "test/clean_room/provider_host/lib/clean_room_provider/lockspire/account_resolver.ex",
    "test/clean_room/provider_host/lib/clean_room_provider/lockspire/interaction_handler.ex",
    "test/clean_room/provider_host/lib/clean_room_provider/verifier_disclosure.ex",
    "test/clean_room/provider_host/lib/clean_room_provider/verifier_recovery.ex",
    "test/clean_room/provider_host/lib/clean_room_provider_web/controllers/billing_controller.ex",
    "test/clean_room/provider_host/lib/clean_room_provider_web/controllers/session_controller.ex",
    "test/clean_room/provider_host/lib/clean_room_provider_web/operator_authorization.ex",
    "test/clean_room/provider_host/lib/clean_room_provider_web/router_patch.exs",
    "test/clean_room/confidential_client/config/config.exs",
    "test/clean_room/confidential_client/lib/clean_room_client/application.ex",
    "test/clean_room/confidential_client/lib/clean_room_client/dpop.ex",
    "test/clean_room/confidential_client/lib/clean_room_client/dpop_session.ex",
    "test/clean_room/confidential_client/lib/clean_room_client/oauth_http.ex",
    "test/clean_room/confidential_client/lib/clean_room_client/oauth_transaction.ex",
    "test/clean_room/confidential_client/lib/clean_room_client/oidc_verifier.ex",
    "test/clean_room/confidential_client/lib/clean_room_client/repo.ex",
    "test/clean_room/confidential_client/lib/clean_room_client/transactions.ex",
    "test/clean_room/confidential_client/lib/clean_room_client_web/controllers/journey_controller.ex",
    "test/clean_room/confidential_client/lib/clean_room_client_web/controllers/oauth_controller.ex",
    "test/clean_room/confidential_client/lib/clean_room_client_web/endpoint.ex",
    "test/clean_room/confidential_client/lib/clean_room_client_web/error_html.ex",
    "test/clean_room/confidential_client/lib/clean_room_client_web/router.ex",
    "test/clean_room/confidential_client/mix.exs",
    "test/clean_room/confidential_client/mix.lock",
    "test/clean_room/confidential_client/priv/repo/migrations/20260827000000_create_oauth_transactions.exs",
    "test/clean_room/confidential_client/test/dpop_client_test.exs",
    "test/clean_room/confidential_client/test/oauth_transaction_test.exs",
    "test/clean_room/confidential_client/test/test_helper.exs",
    "compatibility/phoenix_1_8_live_view_1_1/lib/lockspire_compatibility_fixture.ex",
    "compatibility/phoenix_1_8_live_view_1_1/mix.exs",
    "compatibility/phoenix_1_8_live_view_1_1/mix.lock",
    "compatibility/phoenix_1_8_live_view_1_1/test/admin_host_runtime_test.exs",
    "compatibility/phoenix_1_8_live_view_1_1/test/test_helper.exs",
    "test/clean_room/provider_host/lib/clean_room_provider/lifetime_client_store.ex",
    "docs/client-secret-verifier-configuration.md",
    "docs/client-secret-jwt-host-guide.md",
    "docs/install-and-onboard.md",
    "docs/getting-started.md",
    "docs/supported-surface.md",
    "docs/maintainer-release.md",
    ".github/workflows/ci.yml",
    ".planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-10-PLAN.md",
    ".planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-CONTEXT.md",
    ".planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-RESEARCH.md",
    ".planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-PATTERNS.md",
    ".planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-VALIDATION.md",
    ".planning/phases/177-safe-verifier-maintenance-recovery/177-VERIFICATION.md",
    ".planning/phases/177-safe-verifier-maintenance-recovery/177-SECURITY.md",
    ".planning/phases/177-safe-verifier-maintenance-recovery/177-SOURCE-ACCEPTANCE.json",
    ".planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-FINAL-SOURCE.json",
    *(path for path, _digest in PHASE175_FROZEN_INPUTS),
)


class DeliveryError(ValueError):
    """A finite delivery evidence contract failed."""


def _read_json(path: Path, label: str) -> dict[str, Any]:
    if path.is_symlink() or not path.is_file():
        raise DeliveryError(f"{label} is unavailable or unsafe")
    try:
        result = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    except (OSError, UnicodeError, ValueError):
        raise DeliveryError(f"{label} is malformed") from None
    if not isinstance(result, dict):
        raise DeliveryError(f"{label} is malformed")
    return result


def _git(*args: str, cwd: Path = ROOT) -> str:
    result = subprocess.run(("git", *args), cwd=cwd, stdin=subprocess.DEVNULL,
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                            check=False, timeout=20)
    if result.returncode:
        raise DeliveryError("required source identity is unavailable")
    return result.stdout.decode("ascii", errors="strict").strip()


def _safe_repo_file(value: str) -> Path:
    path = Path(value)
    if path.is_absolute() or ".." in path.parts or not value:
        raise DeliveryError("covered input path is unsafe")
    full = ROOT
    for part in path.parts:
        full = full / part
        if full.is_symlink():
            raise DeliveryError("covered input is missing or unsafe")
    if not full.is_file():
        raise DeliveryError("covered input is missing or unsafe")
    return full


def verify_phase175_frozen_inputs() -> None:
    """Rehash every immutable Phase 175 input against the retained owner pins."""
    for relative, expected in PHASE175_FROZEN_INPUTS:
        path = _safe_repo_file(relative)
        if sha256(path) != expected:
            raise DeliveryError("an immutable Phase 175 source input changed")


def _file_manifest(package_root: Path) -> list[dict[str, str]]:
    rows = []
    for path in sorted(package_root.rglob("*")):
        if path.is_symlink():
            raise DeliveryError("candidate package contains a symbolic link")
        if path.is_file():
            rows.append({"path": path.relative_to(package_root).as_posix(), "sha256": sha256(path)})
    if not rows:
        raise DeliveryError("candidate package tree is empty")
    return rows


def _verify_owner_source(owner: dict[str, Any], package_root: Path) -> None:
    revision = owner.get("source_revision")
    if not isinstance(revision, str) or not REVISION.fullmatch(revision):
        raise DeliveryError("candidate source owner revision is invalid")
    if _git("rev-parse", f"{revision}^{{tree}}") != owner.get("source_tree"):
        raise DeliveryError("candidate source tree identity is stale")
    files = owner.get("package_files")
    observed = _file_manifest(package_root)
    if files != observed:
        raise DeliveryError("candidate archive tree does not match its bounded file manifest")
    for row in observed:
        if row["path"] == "hex_metadata.config":
            # Mix generates this archive metadata from the checked source; it
            # is independently reproduced by _rebuild_source_package below.
            continue
        result = subprocess.run(("git", "show", f"{revision}:{row['path']}"), cwd=ROOT,
                                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, check=False, timeout=10)
        if result.returncode or hashlib.sha256(result.stdout).hexdigest() != row["sha256"]:
            raise DeliveryError("candidate archive file is not owned by the selected source commit")


def _rebuild_source_package(revision: str) -> tuple[str, dict[str, Any]]:
    """Rebuild and unpack a local archive from a detached Git source export."""
    with tempfile.TemporaryDirectory(prefix="lockspire-frozen-source-build-") as temporary:
        root = Path(temporary)
        source = root / "source"
        source.mkdir(mode=0o700)
        source_archive = root / "source.tar"
        package_archive = root / "lockspire.tar"
        result = subprocess.run(
            ("git", "archive", "--format=tar", "--output", str(source_archive), revision),
            cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, check=False, timeout=60,
        )
        if result.returncode:
            raise DeliveryError("frozen source export failed")
        result = subprocess.run(("tar", "-xf", str(source_archive), "-C", str(source)),
                                cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, check=False, timeout=60)
        if result.returncode:
            raise DeliveryError("frozen source export could not be unpacked")
        built = subprocess.run(("mix", "hex.build", "--output", str(package_archive)),
                               cwd=source, env=os.environ.copy(), stdin=subprocess.DEVNULL,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               check=False, timeout=180)
        if built.returncode or not package_archive.is_file():
            raise DeliveryError("frozen source package build failed")
        extracted = root / "extracted"
        try:
            unpack_hex_tarball(package_archive, extracted)
            tree_digest = package_tree_digest(extracted)
        except PackageInputError:
            raise DeliveryError("frozen source package could not be inspected") from None
        return tree_digest, {
            "command": "git archive <source-revision>; mix hex.build --output <owned-temporary>/lockspire.tar",
            "cwd": "<owned-temporary>/source (git archive of source_revision)",
            "git_archive_exit_code": 0, "package_build_exit_code": 0,
            "package_stdout_bytes": len(built.stdout),
            "package_stdout_sha256": hashlib.sha256(built.stdout).hexdigest(),
            "package_stderr_bytes": len(built.stderr),
            "package_stderr_sha256": hashlib.sha256(built.stderr).hexdigest(),
            "rebuilt_archive_sha256": sha256(package_archive),
            "rebuilt_tree_sha256": tree_digest,
        }


def frozen_owner_document(
    archive: Path, package_root: Path, *, expected_runner: str,
    expected_candidate_source: str, expected_archive_sha256: str, expected_tree_sha256: str,
) -> dict[str, Any]:
    """Build a source-bound owner from an already produced local Hex archive."""
    artifact_root = (ROOT / ".artifacts" / "phase178").resolve(strict=True)
    if archive.is_symlink() or not archive.is_file():
        raise DeliveryError("candidate archive is unavailable or unsafe")
    archive = archive.resolve(strict=True)
    if archive == artifact_root or artifact_root not in archive.parents:
        raise DeliveryError("candidate archive must be inside the owned Phase 178 artifact root")
    if package_root.is_symlink() or not package_root.is_dir():
        raise DeliveryError("candidate extracted tree is unavailable or unsafe")
    package_root = package_root.resolve(strict=True)
    if package_root == artifact_root or artifact_root not in package_root.parents:
        raise DeliveryError("candidate extracted tree must be inside the owned Phase 178 artifact root")
    revision = _git("rev-parse", "HEAD")
    if revision != expected_runner:
        raise DeliveryError("freeze runner differs from its independent caller pin")
    source_tree_digest, source_build = _rebuild_source_package(expected_candidate_source)
    candidate_tree_digest = package_tree_digest(package_root)
    if (sha256(archive) != expected_archive_sha256
            or candidate_tree_digest != expected_tree_sha256
            or source_tree_digest != expected_tree_sha256
            or source_tree_digest != candidate_tree_digest):
        raise DeliveryError("frozen candidate tree differs from package built from its source commit")
    owner: dict[str, Any] = {
        "schema": "lockspire-frozen-candidate-owner-v1",
        "source_revision": expected_candidate_source,
        "source_tree": _git("rev-parse", f"{expected_candidate_source}^{{tree}}"),
        "archive_path": archive.relative_to(ROOT).as_posix(),
        "archive_sha256": sha256(archive),
        "extracted_tree_path": package_root.relative_to(ROOT).as_posix(),
        "tree_sha256": candidate_tree_digest,
        "package_files": _file_manifest(package_root),
        "source_build": source_build,
    }
    _verify_owner_source(owner, package_root)
    owner["owner_sha256"] = hashlib.sha256(
        json.dumps(owner, sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()
    return owner


def create_frozen_manifest(
    phase_dir: Path, archive: Path, package_root: Path, *, expected_runner: str,
    expected_candidate_source: str, expected_archive_sha256: str, expected_tree_sha256: str,
) -> Path:
    verify_phase175_frozen_inputs()
    owner = frozen_owner_document(
        archive, package_root, expected_runner=expected_runner,
        expected_candidate_source=expected_candidate_source,
        expected_archive_sha256=expected_archive_sha256,
        expected_tree_sha256=expected_tree_sha256,
    )
    rows = []
    for relative in COVERED_INPUTS:
        source = _safe_repo_file(relative)
        if hashlib.sha256(subprocess.run(
                ("git", "show", f"HEAD:{relative}"), cwd=ROOT, stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False, timeout=10,
        ).stdout).hexdigest() != sha256(source):
            raise DeliveryError("covered inputs must be committed before freezing")
        rows.append({"path": relative, "sha256": sha256(source)})
    manifest = {
        "schema": "lockspire-phase178-frozen-inputs-v1",
        "frozen_at": datetime.now(timezone.utc).isoformat(),
        "runner_revision": _git("rev-parse", "HEAD"),
        "runner_tree": _git("rev-parse", "HEAD^{tree}"),
        "candidate_owner": owner,
        "covered_inputs": rows,
    }
    target = phase_dir / "178-FROZEN-INPUTS.json"
    if target.exists() or target.is_symlink():
        raise DeliveryError("frozen input manifest already exists")
    target.write_text(json.dumps(manifest, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    return target


def validate_frozen_manifest(phase_dir: Path, *, expected_runner: str,
                             expected_candidate_source: str, expected_archive_sha256: str,
                             expected_tree_sha256: str, expected_manifest_sha256: str) -> dict[str, Any]:
    verify_phase175_frozen_inputs()
    manifest_path = phase_dir / "178-FROZEN-INPUTS.json"
    if sha256(manifest_path) != expected_manifest_sha256:
        raise DeliveryError("frozen manifest bytes differ from their independent caller pin")
    manifest = _read_json(manifest_path, "frozen input manifest")
    if manifest.get("schema") != "lockspire-phase178-frozen-inputs-v1":
        raise DeliveryError("frozen input manifest schema is invalid")
    runner = manifest.get("runner_revision")
    if not isinstance(runner, str) or not REVISION.fullmatch(runner):
        raise DeliveryError("frozen runner identity is invalid")
    if runner != expected_runner:
        raise DeliveryError("frozen runner differs from its independent caller pin")
    if _git("rev-parse", f"{runner}^{{tree}}") != manifest.get("runner_tree"):
        raise DeliveryError("frozen runner tree does not match its commit")
    rows = manifest.get("covered_inputs")
    expected_paths = list(COVERED_INPUTS)
    if not isinstance(rows, list) or [row.get("path") for row in rows if isinstance(row, dict)] != expected_paths:
        raise DeliveryError("frozen input path set differs from the bounded contract")
    for row in rows:
        path = _safe_repo_file(row["path"])
        if not isinstance(row.get("sha256"), str) or sha256(path) != row["sha256"]:
            raise DeliveryError("covered input bytes changed after freeze")
        if hashlib.sha256(subprocess.run(
                ("git", "show", f"{runner}:{row['path']}"), cwd=ROOT, stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False, timeout=10,
        ).stdout).hexdigest() != row["sha256"]:
            raise DeliveryError("frozen input bytes are not owned by the tested runner commit")
    owner = manifest.get("candidate_owner")
    if not isinstance(owner, dict):
        raise DeliveryError("candidate source owner is missing")
    if (owner.get("source_revision") != expected_candidate_source
            or owner.get("archive_sha256") != expected_archive_sha256
            or owner.get("tree_sha256") != expected_tree_sha256):
        raise DeliveryError("frozen candidate differs from its independent caller pins")
    owner_digest = owner.get("owner_sha256")
    if not isinstance(owner_digest, str) or not SHA.fullmatch(owner_digest):
        raise DeliveryError("candidate source owner digest is invalid")
    claim = {key: value for key, value in owner.items() if key != "owner_sha256"}
    if hashlib.sha256(json.dumps(claim, sort_keys=True, separators=(",", ":")).encode()).hexdigest() != owner_digest:
        raise DeliveryError("candidate source owner digest is invalid")
    archive_relative = owner.get("archive_path")
    if not isinstance(archive_relative, str):
        raise DeliveryError("candidate archive path is invalid")
    archive = _safe_repo_file(archive_relative)
    if sha256(archive) != owner.get("archive_sha256"):
        raise DeliveryError("frozen candidate archive bytes changed")
    tree_relative = owner.get("extracted_tree_path")
    if not isinstance(tree_relative, str):
        raise DeliveryError("candidate extracted tree path is invalid")
    tree_relative_path = Path(tree_relative)
    if tree_relative_path.is_absolute() or ".." in tree_relative_path.parts:
        raise DeliveryError("candidate extracted tree path is unsafe")
    tree_root = ROOT
    for part in tree_relative_path.parts:
        tree_root = tree_root / part
        if tree_root.is_symlink():
            raise DeliveryError("candidate extracted tree contains a symbolic path")
    if (tree_root == ARTIFACT_DEFAULT.resolve(strict=True)
            or ARTIFACT_DEFAULT.resolve(strict=True) not in tree_root.resolve(strict=True).parents
            or not tree_root.is_dir()
            or package_tree_digest(tree_root) != owner.get("tree_sha256")):
        raise DeliveryError("frozen candidate extracted tree changed")
    _verify_owner_source(owner, tree_root)
    source_tree_digest, source_build = _rebuild_source_package(owner["source_revision"])
    recorded_build = owner.get("source_build")
    stable_build_fields = (
        "command", "cwd", "git_archive_exit_code", "package_build_exit_code",
        "rebuilt_tree_sha256",
    )
    if (source_tree_digest != owner.get("tree_sha256") or not isinstance(recorded_build, dict)
            or any(recorded_build.get(field) != source_build.get(field) for field in stable_build_fields)):
        raise DeliveryError("frozen archive tree differs from a fresh build of its source commit")
    with tempfile.TemporaryDirectory(prefix="lockspire-frozen-owner-check-") as temporary:
        extracted = Path(temporary) / "lockspire"
        try:
            unpack_hex_tarball(archive, extracted)
        except PackageInputError:
            raise DeliveryError("frozen candidate archive could not be inspected") from None
        if package_tree_digest(extracted) != owner.get("tree_sha256"):
            raise DeliveryError("frozen candidate archive does not produce its selected source tree")
    return manifest


def _receipt_path(root: Path, relative: Any) -> Path:
    if not isinstance(relative, str) or Path(relative).is_absolute() or ".." in Path(relative).parts:
        raise DeliveryError("package receipt origin path is unsafe")
    path = root / relative
    current = root
    for part in Path(relative).parts:
        current = current / part
        if current.is_symlink():
            raise DeliveryError("package receipt origin path contains a symbolic link")
    if not path.is_file():
        raise DeliveryError("package receipt origin bytes are missing")
    return path


def compose_pair_indexes(
    locked_root: Path, floor_root: Path, *, expected_runner: str,
    expected_candidate: tuple[str, str, str], expected_candidate_proof: str | None = None,
) -> dict[str, Any]:
    """Compose only the two fresh fixed-wrapper pair partitions into the closed matrix."""
    from verifier_receipts import validate_receipt, validate_rollout_receipt

    rows: list[dict[str, Any]] = []
    origins: list[dict[str, str]] = []
    for pair, root, expected_receipts, expected_cases in (
        ("locked", locked_root, 14, 33), ("floor", floor_root, 12, 31),
    ):
        if root.is_symlink():
            raise DeliveryError("package pair root is symbolic")
        root = root.resolve(strict=True)
        artifact_root = (ROOT / ".artifacts" / "phase178").resolve(strict=True)
        if root.is_symlink() or root == artifact_root or artifact_root not in root.parents:
            raise DeliveryError("package pair root is outside its owned artifact boundary")
        index_path = root / "validated" / "index.json"
        index = _read_json(index_path, f"{pair} pair index")
        if (index.get("schema") != "lockspire-installed-verifier-pair-v1"
                or index.get("pair") != pair or index.get("runner_revision") != expected_runner
                or index.get("required_receipts") != expected_receipts
                or index.get("executed_receipts") != expected_receipts
                or index.get("required_cases") != expected_cases
                or index.get("passed_cases") != expected_cases or index.get("failed_cases") != 0
                or index.get("candidate_source_archive_tree") != list(expected_candidate)):
            raise DeliveryError(f"{pair} pair index is incomplete or has a substituted identity")
        cells = index.get("cells")
        expected_keys = {key for key in REQUIRED_MATRIX if key[1] == pair}
        if not isinstance(cells, list) or len(cells) != expected_receipts:
            raise DeliveryError(f"{pair} pair index has an incomplete cell set")
        seen: set[tuple[str, str, str]] = set()
        for row in cells:
            if not isinstance(row, dict):
                raise DeliveryError("package cell is malformed")
            key = (row.get("scope"), row.get("pair"), row.get("store"))
            if key not in expected_keys or key in seen:
                raise DeliveryError("package pair contains an extra or duplicate cell")
            seen.add(key)
            path = _receipt_path(root, row.get("receipt_path"))
            raw = path.read_bytes()
            digest = hashlib.sha256(raw).hexdigest()
            if row.get("receipt_sha256") != digest:
                raise DeliveryError("package raw receipt digest does not match its origin bytes")
            try:
                receipt = json.loads(raw, object_pairs_hook=_unique_object)
            except (UnicodeError, ValueError):
                raise DeliveryError("package raw receipt is malformed") from None
            rollout_schema = isinstance(receipt, dict) and receipt.get("schema") == "lockspire-installed-verifier-rollout-v1"
            raw_cases_match = (
                receipt.get("executed_count") == 1 if rollout_schema else
                receipt.get("stable_case_ids") == expected_case_ids(key)
                and receipt.get("executed_count") == len(expected_case_ids(key))
            ) if isinstance(receipt, dict) else False
            if (not isinstance(receipt, dict) or receipt.get("scope") != key[0]
                    or receipt.get("pair") != pair or receipt.get("store") != key[2]
                    or not raw_cases_match
                    or receipt.get("run_id") != row.get("run_id")
                    or receipt.get("executed_count") != row.get("executed_count")
                    or row.get("outcome") != "pass"
                    or row.get("stable_case_ids") != expected_case_ids(key)
                    or row.get("candidate_source_archive_tree") != list(expected_candidate)
                    or row.get("runner_revision") != expected_runner):
                raise DeliveryError("package index summary is not bound to its receipt")
            if receipt.get("schema") == "lockspire-installed-verifier-rollout-v1":
                validate_rollout_receipt(receipt, expected_pair=pair, expected_store=key[2],
                                          expected_runner=expected_runner,
                                          expected_candidate_source=expected_candidate[0],
                                          expected_scope=key[0])
                candidate = receipt["candidate"]
            else:
                validate_receipt(receipt, expected_pair=pair, expected_store=key[2])
                if receipt.get("runner") != expected_runner:
                    raise DeliveryError("package receipt runner does not match frozen runner pin")
                candidate = receipt["candidate"]
            if (candidate.get("source_revision"), candidate.get("archive_sha256"),
                    candidate.get("tree_sha256")) != expected_candidate:
                raise DeliveryError("package receipt candidate identity differs from frozen owner")
            if expected_candidate_proof is not None and candidate.get("source_proof") != expected_candidate_proof:
                raise DeliveryError("package receipt does not carry the authenticated frozen owner")
            host = receipt.get("host", {})
            compiled = (receipt.get("processes", {}).get("candidate", {}).get("compiled_candidate_sha256")
                        if receipt.get("schema") == "lockspire-installed-verifier-rollout-v1"
                        else host.get("compiled_candidate_sha256"))
            if (host.get("lock_sha256") != row.get("host_lock_sha256")
                    or compiled != row.get("compiled_candidate_sha256")):
                raise DeliveryError("package host or compiled identity differs from the raw receipt")
            expected_lock = sha256(PROOF_PAIR_LOCKS[pair])
            if host.get("lock_sha256") != expected_lock:
                raise DeliveryError("package host lock does not match the selected dependency pair")
            if not isinstance(compiled, str) or not SHA.fullmatch(compiled):
                raise DeliveryError("package compiled candidate identity is invalid")
            rows.append(dict(row))
            origins.append({"pair": pair, "path": path.relative_to(root).as_posix(), "sha256": digest})
        if seen != expected_keys:
            raise DeliveryError(f"{pair} pair omits a required cell")
    matrix = validate_complete_matrix(rows, expected_runner=expected_runner)
    if len(matrix) != 26 or sum(len(row["stable_case_ids"]) for row in matrix) != 64:
        raise DeliveryError("composed package matrix is not the exact 26-cell/64-case contract")
    if {tuple(row["candidate_source_archive_tree"]) for row in matrix} != {expected_candidate}:
        raise DeliveryError("composed package matrix mixes candidate source/archive/tree owners")
    return {
        "schema": "lockspire-installed-verifier-composed-matrix-v1",
        "runner_revision": expected_runner,
        "candidate_source_archive_tree": list(expected_candidate),
        "required_receipt_count": 26, "executed_receipt_count": 26,
        "required_case_count": 64, "passed_case_count": 64, "failed_case_count": 0,
        "origins": origins, "cells": matrix,
    }


def _reviewed_revision_is_ancestor(reviewed: str, expected: str) -> bool:
    result = subprocess.run(("git", "merge-base", "--is-ancestor", reviewed, expected), cwd=ROOT,
                            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL, check=False, timeout=20)
    return result.returncode == 0


def _metadata_only_difference(older: str, newer: str) -> bool:
    result = subprocess.run(("git", "diff", "--name-only", "-z", older, newer), cwd=ROOT,
                            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=subprocess.DEVNULL, check=False, timeout=20)
    if result.returncode:
        return False
    allowed = (
        ".planning/STATE.md", ".planning/ROADMAP.md", ".planning/REQUIREMENTS.md",
        f".planning/phases/{PHASE_NAME}/178-REVIEW.md",
        f".planning/phases/{PHASE_NAME}/178-SECURITY.md",
        f".planning/phases/{PHASE_NAME}/178-INTEGRATION.md",
        f".planning/phases/{PHASE_NAME}/178-INDEPENDENT-REVIEWS.json",
    )
    paths = [item.decode("utf-8", errors="strict") for item in result.stdout.split(b"\0") if item]
    return all(path in allowed for path in paths)


def validate_reviews(phase_dir: Path, *, expected_revision: str | None = None) -> dict[str, Any]:
    """Accept independent reviews only from a structured, commit-bound decision record."""
    expected_revision = expected_revision or _git("rev-parse", "HEAD")
    if not REVISION.fullmatch(expected_revision):
        raise DeliveryError("review target revision is invalid")
    record = _read_json(phase_dir / "178-INDEPENDENT-REVIEWS.json", "independent review decision record")
    implementation_revision = record.get("implementation_revision")
    if (record.get("schema") != "lockspire-phase178-independent-reviews-v1"
            or implementation_revision != expected_revision):
        raise DeliveryError("independent reviews do not bind the selected implementation revision")
    lanes = record.get("lanes")
    expected_lanes = {"source", "security", "integration"}
    if not isinstance(lanes, dict) or set(lanes) != expected_lanes:
        raise DeliveryError("independent review lane set is incomplete")
    identities: set[str] = set()
    for lane_name in sorted(expected_lanes):
        lane = lanes[lane_name]
        if (not isinstance(lane, dict)
                or set(lane) != {"reviewer_identity", "reviewed_revision", "reviewed_at", "verdict",
                                 "report_path", "report_sha256", "reviewed_files", "findings"}):
            raise DeliveryError("review lane record is malformed")
        reviewed_revision = lane.get("reviewed_revision") if isinstance(lane, dict) else None
        if (not isinstance(reviewed_revision, str) or not REVISION.fullmatch(reviewed_revision)
                or not _reviewed_revision_is_ancestor(reviewed_revision, expected_revision)
                or not _metadata_only_difference(reviewed_revision, expected_revision)):
            raise DeliveryError("review lane does not bind the selected implementation revision")
        identity = lane.get("reviewer_identity")
        if not isinstance(identity, str) or len(identity) < 8 or identity in identities:
            raise DeliveryError("independent reviewer identities are missing or duplicated")
        identities.add(identity)
        if lane.get("verdict") != "accepted":
            raise DeliveryError("independent review did not accept the selected implementation")
        date = lane.get("reviewed_at")
        try:
            datetime.strptime(date, "%Y-%m-%d")
        except (TypeError, ValueError):
            raise DeliveryError("review observation date is invalid") from None
        report_path = lane.get("report_path")
        if not isinstance(report_path, str) or Path(report_path).name != report_path:
            raise DeliveryError("independent review report path is malformed")
        report = phase_dir / report_path
        if (report.is_symlink() or not report.is_file()
                or not isinstance(lane.get("report_sha256"), str)
                or not SHA.fullmatch(lane["report_sha256"])
                or sha256(report) != lane["report_sha256"]):
            raise DeliveryError("independent review report bytes changed")
        report_text = report.read_text(encoding="utf-8")
        reviewed_match = re.search(r"(?im)^reviewed commit:\s*([0-9a-f]{40,64})\s*$", report_text)
        reviewer_match = re.search(r"(?im)^reviewer:\s*(.+?)\s*$", report_text)
        if (not reviewed_match or reviewed_match.group(1) != reviewed_revision
                or not reviewer_match or reviewer_match.group(1) != identity):
            raise DeliveryError("review judgment identity does not match its preserved report")
        files = lane.get("reviewed_files")
        if not isinstance(files, list) or not files:
            raise DeliveryError("reviewed source file scope is missing")
        for item in files:
            if (not isinstance(item, dict) or set(item) != {"path", "sha256"}
                    or not isinstance(item["path"], str) or not SHA.fullmatch(str(item["sha256"]))):
                raise DeliveryError("reviewed source file binding is malformed")
            path = _safe_repo_file(item["path"])
            if sha256(path) != item["sha256"]:
                raise DeliveryError("reviewed source bytes changed after independent review")
            committed = subprocess.run(("git", "show", f"{reviewed_revision}:{item['path']}"), cwd=ROOT,
                                       stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                       stderr=subprocess.DEVNULL, check=False, timeout=10)
            if committed.returncode or hashlib.sha256(committed.stdout).hexdigest() != item["sha256"]:
                raise DeliveryError("reviewed source bytes are not present at the reviewed revision")
        findings = lane.get("findings")
        if not isinstance(findings, list):
            raise DeliveryError("review findings lack classified dispositions")
        for finding in findings:
            if (not isinstance(finding, dict)
                    or set(finding) != {"id", "severity", "status", "disposition", "evidence", "files"}
                    or not isinstance(finding.get("id"), str) or not finding["id"]
                    or finding.get("severity") not in {"critical", "high", "medium", "low", "info"}
                    or finding.get("status") not in {"open", "resolved", "deferred"}
                    or finding.get("disposition") not in {"fix-before-freeze", "rechecked-fixed", "later-owner"}
                    or not isinstance(finding.get("evidence"), str) or not finding["evidence"]
                    or not isinstance(finding.get("files"), list) or not finding["files"]):
                raise DeliveryError("review finding classification is malformed")
            if finding["status"] == "open":
                raise DeliveryError("independent review has an unresolved finding")
            if finding["severity"] in {"critical", "high"} and finding["disposition"] != "rechecked-fixed":
                if not (finding["id"] in LATER_OWNER_FINDINGS
                        and finding["status"] == "deferred"
                        and finding["disposition"] == "later-owner"):
                    raise DeliveryError("independent review has an unresolved high-impact finding")
            if finding["disposition"] == "later-owner" and finding["status"] != "deferred":
                raise DeliveryError("later-owner finding disposition is inconsistent")
    return record


def _check_frozen(phase_dir: Path, pins: dict[str, str]) -> dict[str, Any]:
    return validate_frozen_manifest(phase_dir, **pins)


def _check_package(phase_dir: Path, locked_root: Path, floor_root: Path,
                   pins: dict[str, str]) -> dict[str, Any]:
    frozen = validate_frozen_manifest(phase_dir, **pins)
    owner = frozen["candidate_owner"]
    matrix = compose_pair_indexes(
        locked_root, floor_root, expected_runner=frozen["runner_revision"],
        expected_candidate=(owner["source_revision"], owner["archive_sha256"], owner["tree_sha256"]),
        expected_candidate_proof=owner["owner_sha256"],
    )
    lines = [
        "# Phase 178 Package Acceptance",
        "",
        "This record composes the two successful fixed-wrapper partitions. It does not represent a third all-scope package producer or hosted CI.",
        "",
        f"- Tested runner: `{matrix['runner_revision']}`",
        f"- Candidate source: `{owner['source_revision']}`",
        f"- Candidate archive SHA-256: `{owner['archive_sha256']}`",
        f"- Candidate extracted tree SHA-256: `{owner['tree_sha256']}`",
        f"- Executed receipts: {matrix['executed_receipt_count']}/26",
        f"- Cases: {matrix['passed_case_count']}/64; failed: {matrix['failed_case_count']}",
        "",
        "| Pair | Scope | Store | Cases | Host lock SHA-256 | Compiled candidate SHA-256 | Origin | Receipt SHA-256 |",
        "|---|---|---|---:|---|---|---|---|",
    ]
    origin_by_key = {}
    for origin, row in zip(matrix["origins"], matrix["cells"], strict=True):
        origin_by_key[(row["scope"], row["pair"], row["store"])] = origin
    for row in matrix["cells"]:
        origin = origin_by_key[(row["scope"], row["pair"], row["store"])]
        lines.append(
            f"| {row['pair']} | {row['scope']} | {row['store']} | {len(row['stable_case_ids'])} | "
            f"`{row['host_lock_sha256']}` | `{row['compiled_candidate_sha256']}` | "
            f"`{origin['path']}` | `{origin['sha256']}` |"
        )
    content = "\n".join(lines) + "\n"
    report = phase_dir / "178-PACKAGE-ACCEPTANCE.md"
    if report.is_symlink():
        raise DeliveryError("package acceptance report path is symbolic")
    if report.exists() and report.read_text(encoding="utf-8") != content:
        raise DeliveryError("a different package acceptance report already exists; preserve the prior attempt")
    if not report.exists():
        report.write_text(content, encoding="utf-8")
    return matrix


def _owned_source_manifest(
    path: Path, expected_revision: str, *, require_temp_custody: bool = True,
) -> dict[str, Any]:
    try:
        resolved = path.resolve(strict=True)
        if (path.is_symlink() or not resolved.is_file()
                or (require_temp_custody and (
                    not resolved.parent.name.startswith("lockspire-owned-source-tests-")
                    or stat.S_IMODE(resolved.parent.stat().st_mode) != 0o700))
                or stat.S_IMODE(resolved.stat().st_mode) != 0o600):
            raise DeliveryError("owned source guard manifest custody is unsafe")
        manifest = _read_json(resolved, "owned source guard manifest")
    except OSError:
        raise DeliveryError("owned source guard manifest is unavailable") from None
    if (manifest.get("schema") != "lockspire-owned-source-tests-v1"
            or manifest.get("mode") != "ci" or manifest.get("repo") != "Lockspire.TestRepo"
            or manifest.get("mix_env") != "test" or manifest.get("state") != "passed"
            or manifest.get("source_sha") != expected_revision
            or manifest.get("source_sha_after") != expected_revision
            or manifest.get("checkout_clean_before") is not True
            or manifest.get("checkout_clean_after") is not True
            or not isinstance(manifest.get("checkout_status_sha256_before"), str)
            or not SHA.fullmatch(manifest["checkout_status_sha256_before"])
            or not isinstance(manifest.get("checkout_status_sha256_after"), str)
            or not SHA.fullmatch(manifest["checkout_status_sha256_after"])
            or manifest.get("create_witness") is not True
            or type(manifest.get("owned_oid")) is not int or manifest["owned_oid"] <= 0
            or manifest.get("cleanup") != "independently_absent"):
        raise DeliveryError("owned source guard did not prove exact checkout, owned target and cleanup")
    commands = manifest.get("commands")
    if not isinstance(commands, list) or not commands:
        raise DeliveryError("owned source guard command capture is missing")
    if any(not isinstance(item, dict) or item.get("state") != "finished"
           or item.get("process_group_stopped") is not True or item.get("exit_code") != 0
           for item in commands):
        raise DeliveryError("owned source guard has an incomplete command or process outcome")
    ci = [item for item in commands if item.get("stage") == "ci"]
    if len(ci) != 1:
        raise DeliveryError("owned source guard did not capture exactly one canonical CI command")
    counts = ci[0].get("exunit_counts")
    if not isinstance(counts, list) or len(counts) != 3:
        raise DeliveryError("owned source guard did not capture all three canonical CI suites")
    if any(not isinstance(row, dict) or type(row.get("tests")) is not int or row["tests"] <= 0
           or row.get("failures") != 0 or type(row.get("failures")) is not int
           or type(row.get("stdout_bytes")) is not int or row["stdout_bytes"] <= 0
           or not isinstance(row.get("stdout_sha256"), str) or not SHA.fullmatch(row["stdout_sha256"])
           for row in counts):
        raise DeliveryError("owned source guard suite observations are incomplete")
    for stage in ("create", "migrate", "ci", "drop"):
        if len([item for item in commands if item.get("stage") == stage]) != 1:
            raise DeliveryError("owned source guard omitted a required canonical stage")
    if commands[-1].get("stage") != "drop":
        raise DeliveryError("owned source guard cleanup was not the final captured command")
    return manifest


def record_source_acceptance(
    phase_dir: Path, guard_manifest_path: Path, locked_root: Path, floor_root: Path,
    pins: dict[str, str],
) -> dict[str, Any]:
    frozen = validate_frozen_manifest(phase_dir, **pins)
    manifest = _owned_source_manifest(guard_manifest_path, frozen["runner_revision"])
    package = _check_package(phase_dir, locked_root, floor_root, pins)
    source_manifest = phase_dir / "178-OWNED-SOURCE-MANIFEST.json"
    source_record = phase_dir / "178-SOURCE-ACCEPTANCE.json"
    if source_manifest.exists() or source_manifest.is_symlink() or source_record.exists() or source_record.is_symlink():
        raise DeliveryError("source acceptance evidence already exists; preserve the prior attempt")
    raw_manifest = guard_manifest_path.read_bytes()
    fd = os.open(source_manifest, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as output:
        output.write(raw_manifest)
        output.flush()
        os.fsync(output.fileno())
    ci = next(item for item in manifest["commands"] if item["stage"] == "ci")
    rows = ci["exunit_counts"]
    canonical = {
        "command": ("ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' "
                    "python3 scripts/ci/run_owned_source_tests.py --ci"),
        "exit_code": ci["exit_code"], "manifest_sha256": sha256(source_manifest),
        "stages": [
            {"name": name, "exit_code": ci["exit_code"], "tests": row["tests"],
             "failures": row["failures"], "properties": row["properties"],
             "stdout_bytes": row["stdout_bytes"], "stdout_sha256": row["stdout_sha256"]}
            for name, row in zip(("qa.architecture", "test.fast", "test.integration"), rows, strict=True)
        ],
    }
    record = {
        "schema": "lockspire-phase178-source-acceptance-v1",
        "tested_source_revision": frozen["runner_revision"],
        "candidate_source_revision": frozen["candidate_owner"]["source_revision"],
        "candidate_archive_sha256": frozen["candidate_owner"]["archive_sha256"],
        "candidate_tree_sha256": frozen["candidate_owner"]["tree_sha256"],
        "frozen_manifest_sha256": pins["expected_manifest_sha256"],
        "covered_inputs": frozen["covered_inputs"],
        "owned_source_manifest": source_manifest.name,
        "owned_source_manifest_sha256": sha256(source_manifest),
        "canonical_ci": canonical,
        "package_acceptance_sha256": sha256(phase_dir / "178-PACKAGE-ACCEPTANCE.md"),
        "package_receipt_count": package["executed_receipt_count"],
        "package_case_count": package["passed_case_count"],
    }
    fd = os.open(source_record, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as output:
        json.dump(record, output, sort_keys=True, indent=2)
        output.write("\n")
        output.flush()
        os.fsync(output.fileno())
    return record


def _check_source(phase_dir: Path, locked_root: Path, floor_root: Path,
                  pins: dict[str, str]) -> dict[str, Any]:
    frozen = validate_frozen_manifest(phase_dir, **pins)
    record = _read_json(phase_dir / "178-SOURCE-ACCEPTANCE.json", "source acceptance record")
    if record.get("schema") != "lockspire-phase178-source-acceptance-v1":
        raise DeliveryError("source acceptance record schema is invalid")
    if record.get("tested_source_revision") != frozen["runner_revision"]:
        raise DeliveryError("source acceptance tested revision differs from frozen runner")
    if record.get("covered_inputs") != frozen["covered_inputs"]:
        raise DeliveryError("source acceptance does not bind the frozen input bytes")
    ci = record.get("canonical_ci")
    if not isinstance(ci, dict) or ci.get("exit_code") != 0 or ci.get("command") != (
            "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' "
            "python3 scripts/ci/run_owned_source_tests.py --ci"):
        raise DeliveryError("canonical guarded source gate is missing or failed")
    stages = ci.get("stages")
    if not isinstance(stages, list) or [row.get("name") for row in stages if isinstance(row, dict)] != [
        "qa.architecture", "test.fast", "test.integration"
    ]:
        raise DeliveryError("canonical source gate does not contain the exact required stage set")
    for stage in stages:
        if (not isinstance(stage, dict) or stage.get("exit_code") != 0
                or type(stage.get("tests")) is not int or stage["tests"] <= 0
                or type(stage.get("failures")) is not int or stage["failures"] != 0
                or type(stage.get("stdout_bytes")) is not int or stage["stdout_bytes"] <= 0
                or not isinstance(stage.get("stdout_sha256"), str)
                or not SHA.fullmatch(stage["stdout_sha256"])):
            raise DeliveryError("canonical source stage is missing actual nonzero test evidence")
    manifest_name = record.get("owned_source_manifest")
    if manifest_name != "178-OWNED-SOURCE-MANIFEST.json":
        raise DeliveryError("source acceptance does not reference the owned guard manifest")
    manifest_path = phase_dir / manifest_name
    if (manifest_path.is_symlink() or not manifest_path.is_file()
            or sha256(manifest_path) != record.get("owned_source_manifest_sha256")
            or sha256(manifest_path) != ci.get("manifest_sha256")
            or stat.S_IMODE(manifest_path.stat().st_mode) != 0o600):
        raise DeliveryError("source acceptance guard manifest digest or custody is invalid")
    manifest = _owned_source_manifest(manifest_path, frozen["runner_revision"], require_temp_custody=False)
    guard_ci = next(item for item in manifest["commands"] if item["stage"] == "ci")
    if ci["exit_code"] != guard_ci["exit_code"] or [
            {field: stage[field] for field in ("tests", "failures", "properties", "stdout_bytes", "stdout_sha256")}
            for stage in stages] != guard_ci["exunit_counts"]:
        raise DeliveryError("source acceptance CI stage results differ from the live owned guard capture")
    if _check_package(phase_dir, locked_root, floor_root, pins)["executed_receipt_count"] != record.get("package_receipt_count"):
        raise DeliveryError("source acceptance package proof is absent or changed")
    if sha256(phase_dir / "178-PACKAGE-ACCEPTANCE.md") != record.get("package_acceptance_sha256"):
        raise DeliveryError("source acceptance package report bytes changed")
    return record


def _blob_sha(revision: str, relative: str) -> str:
    if not REVISION.fullmatch(revision):
        raise DeliveryError("candidate source revision is malformed")
    result = subprocess.run(("git", "show", f"{revision}:{relative}"), cwd=ROOT,
                            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=subprocess.DEVNULL, check=False, timeout=10)
    if result.returncode:
        raise DeliveryError("candidate covered input is unavailable")
    return hashlib.sha256(result.stdout).hexdigest()


def _commit_shape(revision: str) -> tuple[str, list[str]]:
    tree = _git("rev-parse", f"{revision}^{{tree}}")
    parents = _git("show", "-s", "--format=%P", revision).split()
    if any(not REVISION.fullmatch(parent) for parent in parents):
        raise DeliveryError("candidate checkout parent identity is malformed")
    return tree, parents


def _check_candidate_identity(phase_dir: Path) -> dict[str, Any]:
    candidate = _read_json(phase_dir / "178-CANDIDATE.json", "candidate identity")
    observation_path = phase_dir / "178-CANDIDATE-OBSERVATION.json"
    observation = _read_json(observation_path, "candidate raw observation")
    source = _read_json(phase_dir / "178-SOURCE-ACCEPTANCE.json", "source acceptance record")
    candidate_fields = {
        "schema", "reviewed_head_sha", "package_source_sha", "package_archive_sha256",
        "package_tree_sha256", "frozen_manifest_sha256", "runner_sha", "executed_checkout_sha",
        "checkout_tree", "checkout_parents", "covered_input_relation", "workflow_path", "event",
        "run_id", "run_attempt", "observed_at", "failed_attempts", "source_acceptance_sha256",
        "raw_observation_sha256",
    }
    if set(candidate) != candidate_fields or candidate.get("schema") != "lockspire-phase178-candidate-v1":
        raise DeliveryError("candidate identity schema is invalid")
    if source.get("schema") != "lockspire-phase178-source-acceptance-v1":
        raise DeliveryError("candidate source acceptance identity is unavailable")
    if candidate.get("source_acceptance_sha256") != sha256(phase_dir / "178-SOURCE-ACCEPTANCE.json"):
        raise DeliveryError("candidate does not bind the source acceptance bytes")
    if candidate.get("raw_observation_sha256") != sha256(observation_path):
        raise DeliveryError("candidate raw observation digest is stale")
    if observation.get("schema") != "lockspire-phase178-candidate-observation-v1":
        raise DeliveryError("candidate raw observation schema is invalid")
    if set(observation) != {"schema", "event", "run_id", "run_attempt", "pull_request_head_sha",
                           "executed_checkout_sha", "checkout_tree", "checkout_parents"}:
        raise DeliveryError("candidate raw observation contains unsupported fields")
    fields = ("event", "run_id", "run_attempt", "executed_checkout_sha", "checkout_tree", "checkout_parents")
    if (any(candidate.get(field) != observation.get(field) for field in fields)
            or candidate.get("reviewed_head_sha") != observation.get("pull_request_head_sha")):
        raise DeliveryError("candidate record differs from its raw workflow observation")
    if candidate.get("workflow_path") != ".github/workflows/ci.yml":
        raise DeliveryError("candidate workflow identity is unsupported")
    event = candidate.get("event")
    if event not in {"pull_request", "push"}:
        raise DeliveryError("candidate event cannot establish protected workflow identity")
    for key in ("reviewed_head_sha", "package_source_sha", "runner_sha", "executed_checkout_sha",
                "checkout_tree"):
        if not isinstance(candidate.get(key), str) or not REVISION.fullmatch(candidate[key]):
            raise DeliveryError("candidate source identity is malformed")
    if (not isinstance(candidate.get("run_id"), str) or not candidate["run_id"].isdigit()
            or not isinstance(candidate.get("run_attempt"), int) or candidate["run_attempt"] < 1):
        raise DeliveryError("candidate workflow run identity is malformed")
    try:
        datetime.fromisoformat(candidate["observed_at"].replace("Z", "+00:00"))
    except (TypeError, ValueError, AttributeError):
        raise DeliveryError("candidate observation time is malformed") from None
    if not isinstance(candidate["failed_attempts"], list):
        raise DeliveryError("candidate failed-attempt history is malformed")
    if candidate["runner_sha"] != source.get("tested_source_revision"):
        raise DeliveryError("candidate runner differs from source acceptance")
    if candidate["package_source_sha"] != source.get("candidate_source_revision"):
        raise DeliveryError("candidate package source differs from frozen source acceptance")
    if (candidate.get("package_archive_sha256") != source.get("candidate_archive_sha256")
            or candidate.get("package_tree_sha256") != source.get("candidate_tree_sha256")
            or candidate.get("frozen_manifest_sha256") != source.get("frozen_manifest_sha256")):
        raise DeliveryError("candidate package identity differs from frozen source acceptance")
    ci = source.get("canonical_ci")
    if (not isinstance(ci, dict) or ci.get("exit_code") != 0
            or source.get("package_receipt_count") != 26 or source.get("package_case_count") != 64):
        raise DeliveryError("candidate lacks complete successful local source/package acceptance")
    stages = ci.get("stages")
    if not isinstance(stages, list) or [row.get("name") for row in stages if isinstance(row, dict)] != [
            "qa.architecture", "test.fast", "test.integration"]:
        raise DeliveryError("candidate lacks the exact successful source CI stages")
    if any(not isinstance(row, dict) or row.get("exit_code") != 0
           or type(row.get("tests")) is not int or row["tests"] <= 0
           or type(row.get("failures")) is not int or row["failures"] != 0
           for row in stages):
        raise DeliveryError("candidate source CI contains a missing or failed stage")
    actual_tree, actual_parents = _commit_shape(candidate["executed_checkout_sha"])
    if candidate["checkout_tree"] != actual_tree or candidate["checkout_parents"] != actual_parents:
        raise DeliveryError("candidate checkout tree or parent relation differs from Git")
    if candidate["event"] == "pull_request":
        if (observation.get("pull_request_head_sha") != candidate["reviewed_head_sha"]
                or not actual_parents or actual_parents[-1] != candidate["reviewed_head_sha"]):
            raise DeliveryError("candidate PR head is not the observed synthetic checkout parent")
    elif candidate["reviewed_head_sha"] != candidate["executed_checkout_sha"]:
        raise DeliveryError("candidate push head differs from the executed checkout")
    try:
        relation = candidate["covered_input_relation"]
        source_rows = {row["path"]: row["sha256"] for row in source["covered_inputs"]}
    except (KeyError, TypeError):
        raise DeliveryError("candidate covered-input relation is unavailable") from None
    if not isinstance(relation, list) or {row.get("path") for row in relation if isinstance(row, dict)} != set(source_rows):
        raise DeliveryError("candidate covered-input relation is incomplete")
    for row in relation:
        if not isinstance(row, dict) or set(row) != {"path", "runner_sha256", "package_sha256"}:
            raise DeliveryError("candidate covered-input row is malformed")
        path = row["path"]
        if (row["runner_sha256"] != source_rows.get(path)
                or row["package_sha256"] != _blob_sha(candidate["package_source_sha"], path)
                or row["runner_sha256"] != row["package_sha256"]):
            raise DeliveryError("candidate package/source relationship differs across covered bytes")
    return candidate


def _check_candidate(phase_dir: Path) -> dict[str, Any]:
    identity = _check_candidate_identity(phase_dir)
    gates = _read_json(phase_dir / "178-CANDIDATE-GATES.json", "candidate hosted gates")
    gate_fields = {"schema", "workflow_path", "event", "run_id", "run_attempt",
                   "executed_checkout_sha", "runner_sha", "package_source_sha",
                   "source_acceptance_sha256", "status", "conclusion", "jobs",
                   "package_artifacts", "failed_attempts"}
    if set(gates) != gate_fields or gates.get("schema") != "lockspire-phase178-candidate-gates-v1":
        raise DeliveryError("candidate hosted gate schema is invalid")
    if (gates.get("workflow_path") != identity["workflow_path"]
            or gates.get("event") != identity["event"]
            or gates.get("run_id") != identity["run_id"]
            or gates.get("run_attempt") != identity["run_attempt"]
            or gates.get("executed_checkout_sha") != identity["executed_checkout_sha"]
            or gates.get("runner_sha") != identity["runner_sha"]
            or gates.get("package_source_sha") != identity["package_source_sha"]
            or gates.get("source_acceptance_sha256") != identity["source_acceptance_sha256"]
            or gates.get("status") != "completed" or gates.get("conclusion") != "success"):
        raise DeliveryError("candidate hosted graph identities are mixed or stale")
    jobs = gates.get("jobs")
    if not isinstance(jobs, list) or len(jobs) != len(CANONICAL_CI_JOBS):
        raise DeliveryError("candidate hosted job graph is incomplete")
    job_ids: set[int] = set()
    for name, job in zip(CANONICAL_CI_JOBS, jobs, strict=True):
        if (not isinstance(job, dict) or set(job) != {"name", "job_id", "run_id", "run_attempt",
                                                       "checkout_sha", "status", "conclusion"}
                or job.get("name") != name
                or job.get("run_id") != identity["run_id"]
                or job.get("run_attempt") != identity["run_attempt"]
                or job.get("checkout_sha") != identity["executed_checkout_sha"]
                or job.get("status") != "completed" or job.get("conclusion") != "success"
                or not isinstance(job.get("job_id"), int) or job["job_id"] <= 0):
            raise DeliveryError("candidate hosted job graph contains a missing, mixed, or failed job")
        if job["job_id"] in job_ids:
            raise DeliveryError("candidate hosted job graph repeats an observed job")
        job_ids.add(job["job_id"])
    artifacts = gates.get("package_artifacts")
    if (not isinstance(artifacts, list) or len(artifacts) != 2
            or {row.get("pair") for row in artifacts if isinstance(row, dict)} != {"locked", "floor"}
            or any(not isinstance(row, dict) or set(row) != {
                "pair", "name", "artifact_id", "sha256", "raw_index_sha256", "receipt_count", "case_count",
            } or row.get("name") != f"lockspire-verifier-upgrade-{identity['executed_checkout_sha']}-{row.get('pair')}"
                or not isinstance(row.get("artifact_id"), int) or row["artifact_id"] <= 0
                or not isinstance(row.get("sha256"), str) or not SHA.fullmatch(row["sha256"])
                or not isinstance(row.get("raw_index_sha256"), str) or not SHA.fullmatch(row["raw_index_sha256"])
                or row.get("receipt_count") != (14 if row.get("pair") == "locked" else 12)
                or row.get("case_count") != (33 if row.get("pair") == "locked" else 31)
                for row in artifacts)):
        raise DeliveryError("candidate hosted package artifacts are incomplete or unauthenticated")
    if not isinstance(gates.get("failed_attempts"), list):
        raise DeliveryError("candidate hosted failed-attempt history is malformed")
    return {"jobs": len(jobs), "run_id": identity["run_id"], "run_attempt": identity["run_attempt"]}


def _check_handoff(phase_dir: Path) -> dict[str, Any]:
    handoff = _read_json(phase_dir / "178-HANDOFF.json", "delivery handoff")
    if set(handoff) != {"schema", "integration_status", "accepted_main_status", "owner", "next_action",
                        "main_acceptance_path", "main_acceptance_sha256", "main_sha"} or handoff.get(
                            "schema") != "lockspire-phase178-handoff-v1":
        raise DeliveryError("delivery handoff schema is invalid")
    if (not isinstance(handoff.get("owner"), str) or not handoff["owner"].strip()
            or not isinstance(handoff.get("next_action"), str) or not handoff["next_action"].strip()):
        raise DeliveryError("delivery handoff owner or next action is missing")
    state = handoff.get("accepted_main_status")
    if state == "pending":
        if handoff.get("integration_status") not in {"pending", "blocked"}:
            raise DeliveryError("pending main handoff has an incompatible integration status")
        if (handoff.get("main_acceptance_path") is not None
                or handoff.get("main_acceptance_sha256") is not None or handoff.get("main_sha") is not None
                or (phase_dir / "178-MAIN-ACCEPTANCE.json").exists()):
            raise DeliveryError("pending main handoff contains accepted-main helper evidence")
        return {"accepted_main": False, "integration_status": handoff["integration_status"]}
    if state != "accepted" or handoff.get("integration_status") != "accepted":
        raise DeliveryError("delivery handoff state is unsupported")
    main_path = phase_dir / "178-MAIN-ACCEPTANCE.json"
    if handoff.get("main_acceptance_path") != main_path.name:
        raise DeliveryError("accepted-main helper receipt path is invalid")
    if handoff.get("main_acceptance_sha256") != sha256(main_path):
        raise DeliveryError("accepted-main helper receipt bytes differ from the declared digest")
    receipt = _read_json(main_path, "main acceptance helper receipt")
    main_sha = handoff.get("main_sha")
    if not isinstance(main_sha, str) or not REVISION.fullmatch(main_sha):
        raise DeliveryError("accepted-main revision is malformed")
    local_gate = receipt.get("local_gate")
    required_ci = receipt.get("required_ci")
    release = receipt.get("release_no_publish")
    if (receipt.get("schema") != "lockspire-phase-139-acceptance-v1"
            or receipt.get("baseline_sha") != main_sha
            or not isinstance(local_gate, dict) or local_gate.get("status") != "pass"
            or not isinstance(required_ci, dict) or required_ci.get("status") != "pass"
            or required_ci.get("event") != "push" or required_ci.get("conclusion") != "success"
            or not isinstance(release, dict) or release.get("status") != "pass"
            or release.get("outcome") != "no_publish"):
        raise DeliveryError("accepted-main helper receipt does not prove the required main gate")
    candidate = _check_candidate_identity(phase_dir)
    ancestor = subprocess.run(("git", "merge-base", "--is-ancestor", candidate["reviewed_head_sha"], main_sha),
                              cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL, check=False, timeout=20)
    if ancestor.returncode:
        raise DeliveryError("accepted main does not contain the reviewed candidate")
    return {"accepted_main": True, "main_sha": main_sha, "helper_sha256": handoff["main_acceptance_sha256"]}


def check(stage: str, phase_dir: Path, locked_root: Path, floor_root: Path,
          expected_runner: str | None = None,
          frozen_pins: dict[str, str] | None = None) -> dict[str, Any]:
    if stage == "reviews":
        if expected_runner is None:
            raise DeliveryError("review check requires an independent implementation revision pin")
        validate_reviews(phase_dir, expected_revision=expected_runner)
        return {"reviews": 3, "runtime_acceptance_inferred": False}
    if stage == "frozen":
        if frozen_pins is None:
            raise DeliveryError("frozen validation requires independent caller pins")
        return _check_frozen(phase_dir, frozen_pins)
    if stage == "package":
        if frozen_pins is None:
            raise DeliveryError("package validation requires independent frozen owner pins")
        return _check_package(phase_dir, locked_root, floor_root, frozen_pins)
    if stage == "source":
        if frozen_pins is None:
            raise DeliveryError("source validation requires independent frozen owner pins")
        return _check_source(phase_dir, locked_root, floor_root, frozen_pins)
    if stage == "candidate-identity":
        return _check_candidate_identity(phase_dir)
    if stage == "candidate":
        return _check_candidate(phase_dir)
    if stage == "handoff":
        return _check_handoff(phase_dir)
    raise DeliveryError("unknown delivery check")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", choices=("reviews", "frozen", "source", "package",
                                             "candidate-identity", "candidate", "handoff"))
    parser.add_argument("--freeze", action="store_true")
    parser.add_argument("--record-source", action="store_true")
    parser.add_argument("--guard-manifest", type=Path)
    parser.add_argument("--phase-dir", type=Path, default=PHASE_DEFAULT)
    parser.add_argument("--archive", type=Path)
    parser.add_argument("--extracted-tree", type=Path)
    parser.add_argument("--locked-root", type=Path, default=ARTIFACT_DEFAULT / "final-locked")
    parser.add_argument("--floor-root", type=Path, default=ARTIFACT_DEFAULT / "final-floor")
    parser.add_argument("--expected-runner")
    parser.add_argument("--expected-candidate-source")
    parser.add_argument("--expected-archive-sha256")
    parser.add_argument("--expected-tree-sha256")
    parser.add_argument("--expected-manifest-sha256")
    return parser.parse_args(argv)


def _frozen_pins(args: argparse.Namespace, *, require_manifest: bool) -> dict[str, str]:
    keys = {
        "expected_runner": args.expected_runner,
        "expected_candidate_source": args.expected_candidate_source,
        "expected_archive_sha256": args.expected_archive_sha256,
        "expected_tree_sha256": args.expected_tree_sha256,
        "expected_manifest_sha256": args.expected_manifest_sha256,
    }
    required = tuple(keys) if require_manifest else tuple(key for key in keys if key != "expected_manifest_sha256")
    if any(not isinstance(keys[key], str) or not keys[key] for key in required):
        raise DeliveryError("frozen validation requires explicit caller pins for runner, candidate, archive, tree and manifest")
    if (not REVISION.fullmatch(keys["expected_runner"])
            or not REVISION.fullmatch(keys["expected_candidate_source"])
            or any(not SHA.fullmatch(keys[key]) for key in ("expected_archive_sha256", "expected_tree_sha256"))
            or (require_manifest and not SHA.fullmatch(keys["expected_manifest_sha256"]))):
        raise DeliveryError("independent frozen caller pins are malformed")
    return {key: value for key, value in keys.items() if key in required}


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        if args.freeze:
            if args.archive is None or args.extracted_tree is None:
                raise DeliveryError("freeze requires an archive and extracted tree")
            pins = _frozen_pins(args, require_manifest=False)
            target = create_frozen_manifest(
                args.phase_dir.resolve(), args.archive.resolve(), args.extracted_tree.resolve(),
                **pins,
            )
            print(json.dumps({"frozen": True, "manifest": str(target.relative_to(ROOT)),
                              "manifest_sha256": sha256(target)}, sort_keys=True))
            return 0
        if args.record_source:
            if args.guard_manifest is None:
                raise DeliveryError("record-source requires a guarded source manifest")
            pins = _frozen_pins(args, require_manifest=True)
            result = record_source_acceptance(
                args.phase_dir.resolve(), args.guard_manifest,
                args.locked_root, args.floor_root, pins,
            )
            print(json.dumps({"source_acceptance_recorded": True,
                              "source_revision": result["tested_source_revision"],
                              "package_receipts": result["package_receipt_count"],
                              "package_cases": result["package_case_count"]}, sort_keys=True))
            return 0
        if not args.check:
            raise DeliveryError("a delivery check stage is required")
        result = check(args.check, args.phase_dir.resolve(), args.locked_root, args.floor_root,
                       expected_runner=args.expected_runner,
                       frozen_pins=(_frozen_pins(args, require_manifest=True)
                                    if args.check in {"frozen", "package", "source"} else None))
        print(json.dumps({"validated": args.check, "result": result}, sort_keys=True))
        return 0
    except (DeliveryError, PackageInputError, ReceiptError, OSError, ValueError, KeyError, TypeError):
        print("delivery evidence rejected; diagnostics withheld", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
