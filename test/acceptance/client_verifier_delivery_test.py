"""Adversarial contracts for bounded verifier-delivery evidence."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import sys
import shutil
import tempfile
import unittest
import zipfile
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
CLEAN_ROOM = ROOT / "scripts" / "acceptance" / "clean_room"
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(CLEAN_ROOM))
sys.path.insert(0, str(ROOT / "scripts" / "ci"))

from package_input import PackageInputError, PackageSource, package_tree_digest, prepare_package  # noqa: E402
import clean_room_verifier_upgrade  # noqa: E402
import verifier_delivery  # noqa: E402
import verifier_receipts  # noqa: E402
import provision_verifier_candidate  # noqa: E402
import run_owned_source_tests as owned_source_guard  # noqa: E402


class CandidateProvisioningContracts(unittest.TestCase):
    def _git(self, repo: Path, *args: str) -> str:
        result = __import__("subprocess").run(("git", *args), cwd=repo, check=True,
                                             capture_output=True, text=True)
        return result.stdout.strip()

    def test_clean_job_source_pins_and_covered_bytes_accept_distinct_revisions(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)
            self._git(repo, "init", "-q")
            self._git(repo, "config", "user.email", "fixture@example.invalid")
            self._git(repo, "config", "user.name", "Fixture")
            (repo / "mix.exs").write_text("package bytes\n", encoding="utf-8")
            self._git(repo, "add", "mix.exs")
            self._git(repo, "commit", "-qm", "package source")
            package_source = self._git(repo, "rev-parse", "HEAD")
            (repo / "docs.md").write_text("runner-only observation metadata\n", encoding="utf-8")
            self._git(repo, "add", "docs.md")
            self._git(repo, "commit", "-qm", "runner metadata")
            runner = self._git(repo, "rev-parse", "HEAD")
            provision_verifier_candidate.validate_checkout_pins(repo, runner, package_source)
            rows = provision_verifier_candidate.covered_input_relation(
                repo, runner, package_source, ["mix.exs"],
            )
            self.assertEqual(rows[0]["runner_sha256"], rows[0]["package_sha256"])

    def test_clean_job_rejects_stale_checkout_and_changed_candidate_bytes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)
            self._git(repo, "init", "-q")
            self._git(repo, "config", "user.email", "fixture@example.invalid")
            self._git(repo, "config", "user.name", "Fixture")
            (repo / "mix.exs").write_text("package bytes\n", encoding="utf-8")
            self._git(repo, "add", "mix.exs")
            self._git(repo, "commit", "-qm", "package source")
            package_source = self._git(repo, "rev-parse", "HEAD")
            (repo / "mix.exs").write_text("changed package bytes\n", encoding="utf-8")
            self._git(repo, "commit", "-qam", "runner changed source")
            runner = self._git(repo, "rev-parse", "HEAD")
            with self.assertRaises(ValueError):
                provision_verifier_candidate.covered_input_relation(
                    repo, runner, package_source, ["mix.exs"],
                )
            with self.assertRaises(ValueError):
                provision_verifier_candidate.validate_checkout_pins(repo, package_source, package_source)


class FrozenSourceOwnerContracts(unittest.TestCase):
    def test_all_immutable_phase175_inputs_are_rehashed_and_pinned(self) -> None:
        self.assertEqual(len(verifier_delivery.PHASE175_FROZEN_INPUTS), 13)
        for relative, _digest in verifier_delivery.PHASE175_FROZEN_INPUTS:
            self.assertIn(relative, verifier_delivery.COVERED_INPUTS)
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for relative, _digest in verifier_delivery.PHASE175_FROZEN_INPUTS:
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b"pinned fixture")
            with patch.object(verifier_delivery, "ROOT", root), \
                 patch.object(verifier_delivery, "sha256", side_effect=lambda _path: "0" * 64):
                with self.assertRaisesRegex(verifier_delivery.DeliveryError, "immutable Phase 175"):
                    verifier_delivery.verify_phase175_frozen_inputs()

    def test_self_reported_source_hash_does_not_authenticate_external_archive(self) -> None:
        """A public digest over caller claims cannot prove source-to-archive ownership."""
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / "lockspire-1.6.1.tar"
            archive.write_bytes(b"archive bytes whose source is not established")
            package = root / "package" / "lockspire"
            package.mkdir(parents=True)
            (package / "mix.exs").write_text('version: "1.6.1"\n', encoding="utf-8")
            (package / "lib.ex").write_text("unowned candidate bytes\n", encoding="utf-8")
            revision = "d" * 40
            archive_sha = "a" * 64
            tree_sha = package_tree_digest(package)
            claim = json.dumps(
                {"archive_sha256": archive_sha, "source_revision": revision, "tree_sha256": tree_sha},
                sort_keys=True, separators=(",", ":"),
            ).encode()
            self_reported_proof = hashlib.sha256(claim).hexdigest()
            with patch("package_input.validate_local_tarball",
                       return_value=(archive, "1.6.1", archive_sha)), \
                 patch("package_input.verify_candidate_input"):
                with self.assertRaises(PackageInputError):
                    prepare_package(
                        root,
                        PackageSource(
                            "tar", str(archive), source_revision=revision,
                            source_proof=self_reported_proof,
                        ),
                    )


class OwnedSourceProducerConsumerContracts(unittest.TestCase):
    def test_actual_owned_source_runner_manifest_is_consumed_with_cleanup_order(self) -> None:
        """Only Git reads and a stateful DB/OS boundary fake are used; no DB is started."""
        import subprocess

        class Boundary:
            def __init__(self):
                self.owner = None
                self.exists = False
                self.oid = 412

            def __call__(self, command, *, env, cwd, timeout, started):
                owner = self.owner
                stage = owner.manifest["commands"][-1]["stage"]
                started(5500 + len(owner.manifest["commands"]))
                if stage == "source":
                    observed = subprocess.run(command, cwd=cwd, check=False,
                                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    return owned_source_guard.Result(observed.returncode, observed.stdout, observed.stderr)
                if stage == "preflight":
                    payload = {"env": "test", "repo": owned_source_guard.REPO,
                               "ecto_repos": [owned_source_guard.REPO],
                               "database": owner.target.database, "hostname": owner.target.hostname,
                               "port": owner.target.port, "credentials_match": True}
                    return owned_source_guard.Result(0, (owned_source_guard.MARKER
                        + json.dumps(payload) + "\n").encode())
                if stage == "catalog":
                    return owned_source_guard.Result(0, str(self.oid).encode() + b"\n"
                                                     if self.exists else b"")
                if stage == "identity":
                    return owned_source_guard.Result(0, json.dumps({
                        "database": owner.target.database, "oid": self.oid,
                        "server_address": "127.0.0.1", "server_port": owner.target.port,
                    }).encode())
                if stage == "create":
                    self.exists = True
                    return owned_source_guard.Result(0, owned_source_guard.CREATED + b"\n")
                if stage == "drop":
                    self.exists = False
                if stage == "ci":
                    return owned_source_guard.Result(0, b"15 tests, 0 failures\n2 properties, 2138 tests, 0 failures\n270 tests, 0 failures\n")
                return owned_source_guard.Result(0)

        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)
            subprocess.run(("git", "init", "-q"), cwd=repo, check=True)
            subprocess.run(("git", "config", "user.email", "fixture@example.invalid"), cwd=repo, check=True)
            subprocess.run(("git", "config", "user.name", "Fixture"), cwd=repo, check=True)
            (repo / "tracked.txt").write_text("owned fixture\n", encoding="utf-8")
            subprocess.run(("git", "add", "tracked.txt"), cwd=repo, check=True)
            subprocess.run(("git", "commit", "-qm", "fixture"), cwd=repo, check=True)
            source_revision = subprocess.run(("git", "rev-parse", "HEAD"), cwd=repo,
                                             check=True, capture_output=True, text=True).stdout.strip()
            boundary = Boundary()
            runner = owned_source_guard.OwnedSourceTests(
                [], ci=True, root=repo, inherited={}, process_runner=boundary,
            )
            boundary.owner = runner
            self.assertEqual(runner.run(), 0)
            consumed = verifier_delivery._owned_source_manifest(
                runner.manifest_path, source_revision,
            )
            stages = [row["stage"] for row in consumed["commands"]]
            intents = [row["command_intent"] for row in consumed["commands"]]
            drop = stages.index("drop")
            self.assertEqual(stages[drop + 1:], ["preflight", "catalog"])
            self.assertEqual(intents[drop - 3:drop], [
                "effective_repo_preflight", "database_catalog_identity", "connected_database_identity"])
            self.assertEqual(intents[drop:drop + 3], [
                "drop_owned_database", "effective_repo_preflight", "database_catalog_identity"])
            self.assertLess(stages.index("ci"), drop)
            self.assertEqual(consumed["cleanup"], "independently_absent")
            shutil.rmtree(runner.directory)


class HelperReceiptProducerContracts(unittest.TestCase):
    def test_actual_helper_emitter_preserves_refs_graphs_and_pending_authorization(self) -> None:
        helper = ROOT / "scripts/maintainer/repo_hygiene_check.sh"
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)
            helper_copy = repo / "scripts/maintainer/repo_hygiene_check.sh"
            helper_copy.parent.mkdir(parents=True)
            shutil.copy2(helper, helper_copy)
            subprocess = __import__("subprocess")
            subprocess.run(("git", "init", "--quiet", "--initial-branch=main"), cwd=repo, check=True)
            subprocess.run(("git", "config", "user.email", "fixture@example.invalid"), cwd=repo, check=True)
            subprocess.run(("git", "config", "user.name", "Fixture"), cwd=repo, check=True)
            subprocess.run(("git", "add", "scripts/maintainer/repo_hygiene_check.sh"), cwd=repo, check=True)
            subprocess.run(("git", "commit", "-qm", "helper emitter fixture"), cwd=repo, check=True)
            head = subprocess.run(("git", "rev-parse", "HEAD"), cwd=repo, check=True,
                                  capture_output=True, text=True).stdout.strip()
            subprocess.run(("git", "update-ref", "refs/remotes/origin/main", head), cwd=repo, check=True)
            jobs = [
                {"name": name, "id": index + 1, "run_id": 100, "run_attempt": 1,
                 "head_sha": head, "status": "completed", "conclusion": "success"}
                for index, name in enumerate(verifier_delivery.CANONICAL_CI_JOBS)
            ]
            release_jobs = [
                {"name": name, "id": index + 1, "run_id": 200, "run_attempt": 1,
                 "head_sha": head, "status": "completed",
                 "conclusion": "success" if index == 0 else "skipped"}
                for index, name in enumerate((
                    "Maintain Release Please PR", "Validate exact main head and CI evidence",
                    "Prove exact package before publication", "Publish verified release to Hex",
                    "Verify public install truth", "Record terminal release outcome",
                ))
            ]
            environment = dict(os.environ)
            environment.update({
                "HELPER": str(helper_copy), "REQUIRED_CI_RUN": json.dumps(
                    {"id": 100, "run_attempt": 1, "html_url": "https://github.com/szTheory/lockspire/actions/runs/100"}),
                "RELEASE_RUN": json.dumps(
                    {"id": 200, "run_attempt": 1, "html_url": "https://github.com/szTheory/lockspire/actions/runs/200"}),
                "LOCAL_TEST_COUNT": "240", "PASS_COUNT": "9", "WARN_COUNT": "0", "BLOCK_COUNT": "0",
                "REQUIRED_CI_JOBS": json.dumps(jobs), "RELEASE_JOBS": json.dumps(release_jobs),
                "REPOSITORY": "szTheory/lockspire", "REMOTE": "origin",
                "INTEGRATION_AUTHORIZATION_JSON":
                    '{"status":"pending","path":null,"sha256":null,"authorized_by":null,"authorized_at":null}',
                "WARN_DISPOSITIONS_JSON": "[]",
            })
            command = '''source <(sed -n '/^emit_acceptance_receipt() {/,/^}/p' "$HELPER"); emit_acceptance_receipt'''
            output = subprocess.run(("bash", "-c", command), cwd=repo, env=environment,
                                    check=True, capture_output=True, text=True).stdout
            receipt = json.loads(output)
            self.assertEqual(receipt["synchronized_refs"],
                             {"head": head, "local_main": head, "refreshed_origin_main": head})
            self.assertEqual(receipt["required_ci"]["jobs"], jobs)
            self.assertEqual(receipt["release_no_publish"]["jobs"], release_jobs)
            self.assertEqual(receipt["integration_authorization"]["status"], "pending")
            self.assertEqual(receipt["helper"]["sha256"], verifier_delivery.sha256(helper_copy))


class BoundedInputAndNestedFieldContracts(unittest.TestCase):
    def test_selected_evidence_producers_and_sources_are_covered(self) -> None:
        required = {
            "scripts/ci/provision_verifier_candidate.py",
            "scripts/maintainer/repo_hygiene_check.sh",
            "scripts/acceptance/clean_room/verifier_delivery.py",
            "scripts/acceptance/clean_room/verifier_receipts.py",
            "scripts/acceptance/clean_room/package_input.py",
            "scripts/ci/run_owned_source_tests.py",
            "test/clean_room/provider_host/verifier_endpoints.exs",
            "lib/lockspire/oban.ex",
            "lib/lockspire/protocol/client_auth/client_secret_jwt.ex",
        }
        self.assertTrue(required.issubset(verifier_delivery.COVERED_INPUTS),
                        "bounded frozen inputs omit a selected evidence producer or source")

    def test_unknown_fields_at_every_closed_json_object_path_fail_for_all_26_cells(self) -> None:
        fixture_root = ROOT / "test/fixtures/verifier-matrix-26"
        files = sorted((*fixture_root.rglob("receipt.json"), *fixture_root.rglob("failure-receipt.json")))
        self.assertEqual(len(files), 26, "expected full representative package matrix fixtures")

        def object_paths(value, path=()):
            if isinstance(value, dict):
                yield path
                for key, child in value.items():
                    yield from object_paths(child, path + (key,))
            elif isinstance(value, list):
                for index, child in enumerate(value):
                    yield from object_paths(child, path + (index,))

        def inject(value, path):
            node = value
            for part in path:
                node = node[part]
            node["unknown_sensitive_contract_marker"] = "must-not-enter-receipts"

        for fixture in files:
            raw = json.loads(fixture.read_text(encoding="utf-8"))
            if fixture.name == "failure-receipt.json":
                for case_id, observation in raw["observations"].items():
                    for path in object_paths(observation):
                        mutated = json.loads(json.dumps(observation))
                        inject(mutated, path)
                        with self.subTest(file=fixture.relative_to(fixture_root).as_posix(), case=case_id, path=path):
                            with self.assertRaises(verifier_receipts.ReceiptError):
                                verifier_receipts.validate_failure_capture(mutated)
                continue
            if raw.get("schema") == "lockspire-installed-verifier-rollout-v1":
                expected = {
                    "expected_pair": raw["pair"], "expected_store": raw["store"],
                    "expected_runner": raw["runner_revision"],
                    "expected_candidate_source": raw["candidate"]["source_revision"],
                    "expected_scope": raw["scope"],
                }
                validator = lambda value, expected=expected: verifier_receipts.validate_rollout_receipt(
                    value, **expected,
                )
            else:
                validator = verifier_receipts.validate_receipt
            for path in object_paths(raw):
                mutated = json.loads(json.dumps(raw))
                inject(mutated, path)
                with self.subTest(file=fixture.relative_to(fixture_root).as_posix(), path=path):
                    with self.assertRaises(verifier_receipts.ReceiptError):
                        validator(mutated)

    def test_frozen_owner_overrides_group_checkout_request(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / "lockspire-1.6.1.tar"
            archive.write_bytes(b"owned archive")
            frozen = PackageSource(
                "frozen", str(archive), "a" * 64, "d" * 40, "b" * 64, str(root / "owner.json"),
            )

            def unpack(_archive: Path, package_root: Path) -> None:
                package_root.mkdir(parents=True)
                (package_root / "mix.exs").write_text('version: "1.6.1"\n', encoding="utf-8")
                (package_root / "lib.ex").write_text("candidate\n", encoding="utf-8")

            with patch("package_input.authenticated_frozen_source", return_value=frozen), \
                 patch("package_input.source_revision", return_value="e" * 40), \
                 patch("package_input.validate_local_tarball",
                       return_value=(archive, "1.6.1", "a" * 64)), \
                 patch("package_input.unpack_hex_tarball", side_effect=unpack), \
                 patch("package_input.verify_frozen_source_owner",
                       return_value=("d" * 40, "b" * 64)) as verify_owner, \
                 patch("package_input.verify_candidate_input"):
                _path, _entries, identity = prepare_package(root, PackageSource("checkout"))

            self.assertEqual(identity.kind, "frozen")
            self.assertEqual(identity.source_revision, "d" * 40)
            verify_owner.assert_called_once()

    def test_reviews_need_independent_identity_scope_and_dispositions(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            phase = Path(temporary)
            for name in ("178-REVIEW.md", "178-SECURITY.md", "178-INTEGRATION.md"):
                (phase / name).write_text("# Review\n\nStatus: clean\n", encoding="utf-8")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.validate_reviews(phase)


class ComposedMatrixContracts(unittest.TestCase):
    def _pair_roots(self, parent: Path) -> tuple[Path, Path, str, tuple[str, str, str]]:
        source = ROOT / "test/fixtures/verifier-matrix-26"
        runner = json.loads((source / "core/locked-builtin/receipt.json").read_text())["runner"]
        candidate = json.loads((source / "core/locked-builtin/receipt.json").read_text())["candidate"]
        owner = (candidate["source_revision"], candidate["archive_sha256"], candidate["tree_sha256"])
        roots = []
        for pair in ("locked", "floor"):
            root = parent / pair
            shutil.copytree(source, root)
            with redirect_stdout(StringIO()), redirect_stderr(StringIO()):
                result = clean_room_verifier_upgrade.main([
                    "--pair", pair, "--store", "all", "--group", "all",
                    "--validate-receipts", str(root),
                    "--expected-runner-revision", runner,
                    "--expected-candidate-source-revision", candidate["source_revision"],
                ])
            if result != 0:
                raise AssertionError("portable fixture pair index did not validate")
            roots.append(root)
        return roots[0], roots[1], runner, owner

    def test_two_pair_indexes_compose_to_exact_closed_validator_matrix(self) -> None:
        artifacts = ROOT / ".artifacts" / "phase178"
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            locked, floor, runner, candidate = self._pair_roots(Path(temporary))
            result = verifier_delivery.compose_pair_indexes(
                locked, floor, expected_runner=runner, expected_candidate=candidate,
            )
            self.assertEqual((result["executed_receipt_count"], result["passed_case_count"]), (26, 64))
            self.assertEqual(len(result["origins"]), 26)

    def test_downloaded_candidate_archives_validate_actual_index_and_raw_receipt_bytes(self) -> None:
        artifacts = ROOT / ".artifacts" / "phase178"
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            locked, floor, runner, candidate = self._pair_roots(Path(temporary))
            for pair, root, expected in (("locked", locked, (14, 33)), ("floor", floor, (12, 31))):
                archive_path = Path(temporary) / f"{pair}.zip"
                with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_STORED) as archive:
                    for path in sorted((root / "validated").iterdir()):
                        archive.write(path, f"validated/{path.name}")
                result = verifier_delivery._artifact_zip_pair(
                    archive_path, pair=pair, runner=runner, candidate=candidate,
                )
                self.assertEqual((result["receipts"], result["cases"]), expected)

    def test_composition_rejects_changed_raw_receipt_bytes(self) -> None:
        artifacts = ROOT / ".artifacts" / "phase178"
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            locked, floor, runner, candidate = self._pair_roots(Path(temporary))
            receipt = locked / "core/locked-builtin/receipt.json"
            receipt.write_bytes(receipt.read_bytes() + b" ")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.compose_pair_indexes(
                    locked, floor, expected_runner=runner, expected_candidate=candidate,
                )

    def test_composition_rejects_forged_green_index_and_mixed_candidate(self) -> None:
        artifacts = ROOT / ".artifacts" / "phase178"
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            locked, floor, runner, candidate = self._pair_roots(Path(temporary))
            index_path = floor / "validated/index.json"
            index = json.loads(index_path.read_text())
            index["cells"].pop()
            index_path.write_text(json.dumps(index), encoding="utf-8")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.compose_pair_indexes(
                    locked, floor, expected_runner=runner, expected_candidate=candidate,
                )

        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            locked, floor, runner, candidate = self._pair_roots(Path(temporary))
            index_path = floor / "validated/index.json"
            index = json.loads(index_path.read_text())
            index["candidate_source_archive_tree"][0] = "f" * 40
            index_path.write_text(json.dumps(index), encoding="utf-8")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.compose_pair_indexes(
                    locked, floor, expected_runner=runner, expected_candidate=candidate,
                )

    def test_composition_rejects_raw_scope_substitution_even_when_index_is_updated(self) -> None:
        artifacts = ROOT / ".artifacts" / "phase178"
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            locked, floor, runner, candidate = self._pair_roots(Path(temporary))
            receipt_path = locked / "core/locked-builtin/receipt.json"
            receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
            receipt["scope"] = "tracer"
            receipt["run_id"] = "d" * 32
            receipt["stable_case_ids"] = ["VPROOF-02-INSTALLED-TOKEN"]
            receipt["executed_count"] = 1
            receipt["observations"] = {"VPROOF-02-INSTALLED-TOKEN": {
                "outcome": "pass", "executed": True, "http_status": 200,
                "token_issued": True, "dedicated_verifier_persisted": True,
                "fresh_signed_assertion": True,
            }}
            raw = json.dumps(receipt, sort_keys=True, indent=2).encode() + b"\n"
            receipt_path.write_bytes(raw)
            index_path = locked / "validated/index.json"
            index = json.loads(index_path.read_text(encoding="utf-8"))
            cell = next(row for row in index["cells"] if row["scope"] == "core" and row["store"] == "builtin")
            cell["receipt_sha256"] = hashlib.sha256(raw).hexdigest()
            cell["run_id"] = receipt["run_id"]
            cell["executed_count"] = receipt["executed_count"]
            index_path.write_text(json.dumps(index), encoding="utf-8")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.compose_pair_indexes(
                    locked, floor, expected_runner=runner, expected_candidate=candidate,
                )


class SemanticDeliveryRejections(unittest.TestCase):
    def _source_record_with_observation(self, phase: Path, stage: str) -> None:
        (phase / "178-SOURCE-ACCEPTANCE.json").write_text(json.dumps({
            "schema": "lockspire-phase178-source-acceptance-v1",
            f"{stage.replace('-', '_')}_observation": {"available": True, "raw_sha256": "a" * 64},
        }), encoding="utf-8")

    def test_candidate_identity_rejects_mixed_observed_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            phase = Path(temporary)
            self._source_record_with_observation(phase, "candidate-identity")
            candidate = {"schema": "lockspire-phase178-candidate-v1", "reviewed_head_sha": "a" * 40,
                         "package_source_sha": "a" * 40, "runner_sha": "a" * 40,
                         "executed_checkout_sha": "f" * 40, "checkout_parents": [],
                         "checkout_tree": "b" * 40, "covered_input_relation": [],
                         "workflow_path": ".github/workflows/ci.yml", "event": "pull_request",
                         "run_id": "12345", "run_attempt": 2}
            (phase / "178-CANDIDATE.json").write_text(json.dumps(candidate), encoding="utf-8")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.check("candidate-identity", phase, phase, phase)

    def test_candidate_identity_accepts_observed_head_and_synthetic_checkout_relation(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            phase = Path(temporary)
            head = verifier_delivery._git("rev-parse", "HEAD")
            tree = verifier_delivery._git("rev-parse", "HEAD^{tree}")
            parents = verifier_delivery._git("show", "-s", "--format=%P", head).split()
            mix_digest = verifier_delivery.sha256(ROOT / "mix.exs")
            observation = {
                "schema": "lockspire-phase178-candidate-observation-v1",
                "event": "push", "run_id": "12345", "run_attempt": 2,
                "pull_request_head_sha": head, "executed_checkout_sha": head,
                "checkout_tree": tree, "checkout_parents": parents,
            }
            raw = json.dumps(observation, sort_keys=True).encode() + b"\n"
            (phase / "178-CANDIDATE-OBSERVATION.json").write_bytes(raw)
            source = {
                "schema": "lockspire-phase178-source-acceptance-v1",
                "tested_source_revision": head, "candidate_source_revision": head,
                "candidate_archive_sha256": "e" * 64, "candidate_tree_sha256": "f" * 64,
                "frozen_manifest_sha256": "d" * 64,
                "covered_inputs": [{"path": "mix.exs", "sha256": mix_digest}],
                "canonical_ci": {"exit_code": 0, "stages": [
                    {"name": name, "exit_code": 0, "tests": 1, "failures": 0}
                    for name in ("qa.architecture", "test.fast", "test.integration")
                ]}, "package_receipt_count": 26,
                "package_case_count": 64,
            }
            (phase / "178-SOURCE-ACCEPTANCE.json").write_text(json.dumps(source), encoding="utf-8")
            candidate = {
                "schema": "lockspire-phase178-candidate-v1",
                "reviewed_head_sha": head, "package_source_sha": head,
                "package_archive_sha256": "e" * 64, "package_tree_sha256": "f" * 64,
                "frozen_manifest_sha256": "d" * 64,
                "runner_sha": head, "executed_checkout_sha": head,
                "checkout_tree": tree, "checkout_parents": parents,
                "covered_input_relation": [{"path": "mix.exs", "runner_sha256": mix_digest,
                                             "package_sha256": mix_digest}],
                "workflow_path": ".github/workflows/ci.yml", "event": "push",
                "run_id": "12345", "run_attempt": 2,
                "observed_at": "2026-10-27T12:00:00Z", "failed_attempts": [],
                "source_acceptance_sha256": verifier_delivery.sha256(phase / "178-SOURCE-ACCEPTANCE.json"),
                "raw_observation_sha256": hashlib.sha256(raw).hexdigest(),
            }
            (phase / "178-CANDIDATE.json").write_text(json.dumps(candidate), encoding="utf-8")
            with patch.object(verifier_delivery, "_safe_repo_file", return_value=ROOT / "mix.exs"):
                result = verifier_delivery.check("candidate-identity", phase, phase, phase)
            self.assertEqual(result["executed_checkout_sha"], head)
            candidate["checkout_tree"] = "f" * 40
            (phase / "178-CANDIDATE.json").write_text(json.dumps(candidate), encoding="utf-8")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.check("candidate-identity", phase, phase, phase)
            candidate["checkout_tree"] = tree
            (phase / "178-CANDIDATE.json").write_text(json.dumps(candidate), encoding="utf-8")

            jobs = [{"name": name, "run_id": "12345", "run_attempt": 2,
                     "checkout_sha": head, "status": "completed", "conclusion": "success",
                     "job_id": index + 1}
                    for index, name in enumerate(verifier_delivery.CANONICAL_CI_JOBS)]
            gates = {
                "schema": "lockspire-phase178-candidate-gates-v1",
                "workflow_path": ".github/workflows/ci.yml", "event": "push",
                "run_id": "12345", "run_attempt": 2, "executed_checkout_sha": head,
                "runner_sha": head, "package_source_sha": head,
                "source_acceptance_sha256": candidate["source_acceptance_sha256"],
                "status": "completed", "conclusion": "success",
                "failed_attempts": [],
                "jobs": jobs,
                "package_artifacts": [{"pair": pair,
                                        "name": f"lockspire-verifier-upgrade-{head}-{pair}",
                                        "artifact_id": index + 1, "sha256": "c" * 64,
                                        "raw_index_sha256": "d" * 64,
                                        "receipt_count": 14 if pair == "locked" else 12,
                                        "case_count": 33 if pair == "locked" else 31}
                                       for index, pair in enumerate(("locked", "floor"))]
            }
            (phase / "178-CANDIDATE-GATES.json").write_text(json.dumps(gates), encoding="utf-8")
            with patch.object(verifier_delivery, "_safe_repo_file", return_value=ROOT / "mix.exs"):
                with self.assertRaises(verifier_delivery.DeliveryError):
                    verifier_delivery.check("candidate", phase, phase, phase)
            gates["jobs"][-1]["run_attempt"] = 1
            (phase / "178-CANDIDATE-GATES.json").write_text(json.dumps(gates), encoding="utf-8")
            with patch.object(verifier_delivery, "_safe_repo_file", return_value=ROOT / "mix.exs"), \
                 self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.check("candidate", phase, phase, phase)
            gates["jobs"][-1]["run_attempt"] = 2
            (phase / "178-CANDIDATE-GATES.json").write_text(json.dumps(gates), encoding="utf-8")

            pending = {"schema": "lockspire-phase178-handoff-v1", "integration_status": "pending",
                       "accepted_main_status": "pending", "owner": "maintainer",
                       "next_action": "observe reviewed integration", "main_acceptance_path": None,
                       "main_acceptance_sha256": None, "main_sha": None}
            (phase / "178-HANDOFF.json").write_text(json.dumps(pending), encoding="utf-8")
            self.assertFalse(verifier_delivery.check("handoff", phase, phase, phase)["accepted_main"])

            helper = {
                "schema": "lockspire-phase-139-acceptance-v1", "baseline_sha": head,
                "local_gate": {"status": "pass"},
                "required_ci": {"status": "pass", "event": "push", "conclusion": "success"},
                "release_no_publish": {"status": "pass", "outcome": "no_publish"},
            }
            helper_bytes = json.dumps(helper, sort_keys=True, separators=(",", ":")).encode() + b"\n"
            (phase / "178-MAIN-ACCEPTANCE.json").write_bytes(helper_bytes)
            accepted = {"schema": "lockspire-phase178-handoff-v1", "integration_status": "accepted",
                        "accepted_main_status": "accepted", "owner": "maintainer",
                        "next_action": "retain receipt", "main_acceptance_path": "178-MAIN-ACCEPTANCE.json",
                        "main_acceptance_sha256": hashlib.sha256(helper_bytes).hexdigest(), "main_sha": head}
            (phase / "178-HANDOFF.json").write_text(json.dumps(accepted), encoding="utf-8")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.check("handoff", phase, phase, phase)
            helper["baseline_sha"] = "f" * 40
            changed_bytes = json.dumps(helper, sort_keys=True, separators=(",", ":")).encode() + b"\n"
            (phase / "178-MAIN-ACCEPTANCE.json").write_bytes(changed_bytes)
            accepted["main_acceptance_sha256"] = hashlib.sha256(changed_bytes).hexdigest()
            (phase / "178-HANDOFF.json").write_text(json.dumps(accepted), encoding="utf-8")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.check("handoff", phase, phase, phase)

    def test_candidate_gate_rejects_mixed_attempts_and_handoff_requires_raw_helper_bytes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            phase = Path(temporary)
            jobs = [{"name": name, "run_id": "12345", "run_attempt": 2,
                     "checkout_sha": "a" * 40, "status": "completed", "conclusion": "success"}
                    for name in verifier_delivery.CANONICAL_CI_JOBS]
            jobs[-1]["run_attempt"] = 1
            gates = {"schema": "lockspire-phase178-candidate-gates-v1", "run_id": "12345",
                     "run_attempt": 2, "executed_checkout_sha": "a" * 40, "jobs": jobs}
            (phase / "178-CANDIDATE-GATES.json").write_text(json.dumps(gates), encoding="utf-8")
            self._source_record_with_observation(phase, "candidate")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.check("candidate", phase, phase, phase)

            handoff = {"schema": "lockspire-phase178-handoff-v1", "integration_status": "pending",
                       "accepted_main_status": "accepted", "owner": "maintainer",
                       "next_action": "run reviewed integration", "main_acceptance_path": None}
            (phase / "178-HANDOFF.json").write_text(json.dumps(handoff), encoding="utf-8")
            self._source_record_with_observation(phase, "handoff")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.check("handoff", phase, phase, phase)

    def test_reviews_reject_explicit_unresolved_blockers_for_unrelated_commit(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            phase = Path(temporary)
            for name, lane in (
                ("178-REVIEW.md", "source"),
                ("178-SECURITY.md", "security"),
                ("178-INTEGRATION.md", "integration"),
            ):
                (phase / name).write_text(
                    f"""# {lane} review
Reviewer: independent {lane} reviewer
Reviewed commit: {'f' * 40}
Scope: scripts/acceptance/clean_room/verifier_delivery.py
Date: 2026-10-27

## Findings
OPEN HIGH BLOCKER: acceptance is unsafe.
Disposition: open, do not approve.

## Evidence
The claimed commit is unrelated to the selected candidate.
""",
                    encoding="utf-8",
                )
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.validate_reviews(phase)

    def test_source_gate_rejects_caller_claimed_stage_without_owned_capture(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            phase = Path(temporary)
            runner = "a" * 40
            manifest = {"runner_revision": runner, "covered_inputs": [{"path": "x", "sha256": "b" * 64}]}
            record = {
                "schema": "lockspire-phase178-source-acceptance-v1",
                "tested_source_revision": runner,
                "covered_inputs": manifest["covered_inputs"],
                "canonical_ci": {
                    "exit_code": 0,
                    "command": "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 scripts/ci/run_owned_source_tests.py --ci",
                    "stages": [{"name": name, "exit_code": 0, "tests": 1,
                                "failures": 0, "properties": 0, "stdout_bytes": 1,
                                "stdout_sha256": "c" * 64}
                               for name in ("qa.architecture", "test.fast", "test.integration")],
                },
            }
            with patch.object(verifier_delivery, "validate_frozen_manifest", return_value=manifest), \
                 patch.object(verifier_delivery, "_read_json", return_value=record):
                with self.assertRaises(verifier_delivery.DeliveryError):
                    verifier_delivery._check_source(phase, phase / "locked", phase / "floor", {
                        "expected_runner": runner, "expected_candidate_source": runner,
                        "expected_archive_sha256": "d" * 64, "expected_tree_sha256": "e" * 64,
                        "expected_manifest_sha256": "f" * 64,
                    })

if __name__ == "__main__":
    unittest.main()
