"""Actual serialized boundary regressions; diagnostics stay in memory."""
from __future__ import annotations

from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import shutil
import tarfile
import time
import unittest
import zipfile
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts/acceptance/clean_room"))
sys.path.insert(0, str(ROOT / "scripts/acceptance"))
sys.path.insert(0, str(ROOT / "test/acceptance"))
import verifier_delivery as delivery
import verifier_receipts as receipts
import client_verifier_delivery_test as contracts
import clean_room_verifier_upgrade as upgrade
import package_input
import verifier_receipt_owner as owner_context
sys.path.insert(0, str(ROOT / "scripts/ci"))
import provision_verifier_candidate as provisioner
import run_owned_source_tests as source_guard
from verifier_input_closure import selected_path


class ReviewedCandidateHistory(unittest.TestCase):
    """The real candidate selector needs its frozen source objects in shallow CI checkouts."""

    def git(self, cwd: Path, *args: str) -> str:
        result = subprocess.run(("git", *args), cwd=cwd, stdin=subprocess.DEVNULL,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                check=False, timeout=20)
        self.assertEqual(result.returncode, 0, "private Git fixture operation failed")
        return result.stdout.decode("utf-8").strip()

    def test_actual_candidate_source_selector_fails_shallow_then_accepts_required_history(self):
        with tempfile.TemporaryDirectory(prefix="lockspire-candidate-history-") as directory:
            root = Path(directory)
            origin = root / "origin"
            checkout = root / "shallow"
            origin.mkdir()
            self.git(origin, "init", "-q")
            self.git(origin, "config", "user.name", "Lockspire Fixture")
            self.git(origin, "config", "user.email", "fixture@example.invalid")

            for relative in provisioner.verifier_delivery.PLANNING_INPUTS:
                source = ROOT / relative
                if source.is_file() and not source.is_symlink():
                    target = origin / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(source, target)

            self.git(origin, "add", "--all")
            self.git(origin, "commit", "-qm", "frozen candidate source")
            source_revision = self.git(origin, "rev-parse", "HEAD")

            metadata = origin / ".metadata/runner"
            metadata.parent.mkdir(parents=True, exist_ok=True)
            metadata.write_text("runner-only metadata\n")
            self.git(origin, "add", ".metadata/runner")
            self.git(origin, "commit", "-qm", "workflow checkout metadata")
            runner_revision = self.git(origin, "rev-parse", "HEAD")

            subprocess.run(("git", "clone", "--depth=1", f"file://{origin}", str(checkout)),
                           stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                           check=True, timeout=30)
            phase = checkout / ".planning/phases/fixture-phase"
            phase.mkdir(parents=True)
            rows = []
            with patch.object(provisioner.verifier_delivery, "ROOT", origin):
                covered = provisioner.verifier_delivery.covered_inputs(source_revision)
            for relative in covered:
                content = subprocess.run(("git", "show", f"{source_revision}:{relative}"),
                                         cwd=origin, stdin=subprocess.DEVNULL,
                                         stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                         check=True, timeout=20).stdout
                rows.append({"path": relative, "sha256": hashlib.sha256(content).hexdigest()})
            frozen = {
                "schema": "lockspire-phase178-frozen-inputs-v1",
                "closure_rule": provisioner.verifier_delivery.CLOSURE_RULE,
                "runner_revision": source_revision,
                "candidate_owner": {"source_revision": source_revision},
                "covered_inputs": rows,
            }
            (phase / "178-FROZEN-INPUTS.json").write_text(json.dumps(frozen))

            with patch.object(provisioner, "ROOT", checkout), \
                    patch.object(provisioner.verifier_delivery, "ROOT", checkout), \
                    patch.object(provisioner.verifier_delivery, "PHASE_NAME", "fixture-phase"):
                with self.assertRaises(ValueError, msg="shallow checkout must fail closed"):
                    provisioner.reviewed_candidate_source(runner_revision)

                self.git(checkout, "fetch", "--deepen=1", "origin")
                self.assertEqual(provisioner.reviewed_candidate_source(runner_revision), source_revision,
                                 "required source history should make the same selector pass")


class ExternalBoundaries:
    """Only OS/build/database/GitHub seams; real producers remain in control."""
    def __init__(self, repo):
        self.repo = repo
        self.owner = None
        self.exists = False
        self.oid = 412
        self.real_run = subprocess.run
        self.api = {}
        self.beam = ("1.19.5", "28")

    def observe_runtime(self, command, *, root, env=None):
        if command[0] == "elixir":
            return ("\n".join(self.beam) + "\n").encode()
        if command[0] == "psql" and command[-1] == "SHOW server_version_num" and env.get("PGOPTIONS") == "-c default_transaction_read_only=on":
            return b"140017\n"
        raise AssertionError("runtime observation boundary changed")

    def process(self, command, *, env, cwd, timeout, started):
        owner = self.owner
        stage = owner.manifest["commands"][-1]["stage"]
        started(8000 + len(owner.manifest["commands"]))
        if stage == "source":
            result = self.real_run(command, cwd=cwd, capture_output=True, timeout=20)
            return source_guard.Result(result.returncode, result.stdout, result.stderr)
        if stage == "preflight":
            data = {"env": "test", "repo": source_guard.REPO, "ecto_repos": [source_guard.REPO],
                    "database": owner.target.database, "hostname": owner.target.hostname,
                    "port": owner.target.port, "credentials_match": True}
            return source_guard.Result(0, (source_guard.MARKER + json.dumps(data) + "\n").encode())
        if stage == "catalog":
            return source_guard.Result(0, str(self.oid).encode() + b"\n" if self.exists else b"")
        if stage == "identity":
            return source_guard.Result(0, json.dumps({"database": owner.target.database, "oid": self.oid,
                                      "server_address": "127.0.0.1", "server_port": owner.target.port}).encode())
        if stage == "create":
            self.exists = True
            return source_guard.Result(0, source_guard.CREATED + b"\n")
        if stage == "drop":
            self.exists = False
        if stage == "ci":
            return source_guard.Result(0, b"15 tests, 0 failures\n2 properties, 2138 tests, 0 failures\n270 tests, 0 failures\n")
        return source_guard.Result(0)

    def run(self, command, **kwargs):
        if tuple(command[:2]) == ("mix", "hex.build"):
            output = Path(command[3])
            source = Path(kwargs["cwd"])
            with tarfile.open(output, "w") as archive:
                paths = [source / "mix.exs", *sorted((source / "lib").rglob("*")), *sorted((source / "priv").rglob("*"))]
                for path in paths:
                    if path.is_file():
                        data = path.read_bytes()
                        info = tarfile.TarInfo(path.relative_to(source).as_posix())
                        info.size = len(data)
                        archive.addfile(info, __import__("io").BytesIO(data))
            return subprocess.CompletedProcess(command, 0, b"package-built\n", b"")
        if tuple(command[:2]) == ("gh", "api"):
            data = self.api.get(command[2])
            return subprocess.CompletedProcess(command, int(data is None), json.dumps(data).encode(), b"")
        return self.real_run(command, **kwargs)

    def unpack(self, archive, destination):
        destination.mkdir(parents=True)
        with tarfile.open(archive) as source:
            for entry in source:
                path = Path(entry.name)
                if not entry.isfile() or path.is_absolute() or ".." in path.parts:
                    raise package_input.PackageInputError("fixture package framing invalid")
                target = destination / path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(source.extractfile(entry).read())

    __call__ = process


def validator(raw):
    if raw.get("schema") == "lockspire-installed-verifier-rollout-v1":
        return receipts._validate_rollout_structure(
            raw, expected_pair=raw["pair"], expected_store=raw["store"],
            expected_runner=raw["runner_revision"],
            expected_candidate_source=raw["candidate"]["source_revision"], expected_scope=raw["scope"],
        )
    return receipts._validate_receipt_structure(raw, historical_structure_only=True)


def upload_tree(root: Path, pair: str) -> None:
    """Execute the actual wrapper's postvalidator producer, unchanged."""
    wrapper = (ROOT / "scripts/ci/run_verifier_upgrade_proof.sh").read_text()
    marker = 'python3 - "$repo_root/$receipt_dir" "$pair" <<\'PY\''
    body = wrapper.split(marker, 1)[1].split("\n", 1)[1].split("\nPY\n", 1)[0]
    body = body.replace('Path.cwd() / "scripts/acceptance/clean_room"', repr(str(ROOT / "scripts/acceptance/clean_room")))
    from verifier_owner_fixture import CONTEXT_PINS
    context_env = {} if os.environ.get("LOCKSPIRE_RECEIPT_OWNER") else CONTEXT_PINS.get(str(root), {})
    # Execute the unchanged upload producer under the same explicit private
    # lock context as its pair validator, including in the full private chain.
    bootstrap = ("import sys\nfrom pathlib import Path\nsys.path.insert(0, "
                 + repr(str(ROOT / "scripts/acceptance/clean_room")) + ")\nsys.path.insert(0, "
                 + repr(str(ROOT / "test/acceptance")) + ")\n"
                 "from verifier_owner_fixture import retained_lock_context\n"
                 "with retained_lock_context(Path(sys.argv[1]).parent):\n    exec("
                 + repr(body) + ")\n")
    result = subprocess.run((sys.executable, "-c", bootstrap, str(root), pair),
                            capture_output=True, timeout=20, check=False,
                            env={**os.environ, **context_env, "PYTHONDONTWRITEBYTECODE": "1"})
    if result.returncode:
        raise AssertionError("actual upload producer failed")


def zip_upload(root: Path, archive: Path) -> None:
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_STORED) as output:
        for path in sorted((root / "validated").rglob("*")):
            if path.is_file():
                output.write(path, path.relative_to(root / "validated").as_posix())


class DeliveryChainRegressions(unittest.TestCase):
    def test_current_commit_selected_tree_is_complete(self):
        paths = subprocess.run(("git", "ls-tree", "-r", "--name-only", "HEAD"), cwd=ROOT,
                               capture_output=True, timeout=20, check=True).stdout.decode().splitlines()
        prefixes = ("lib/", "config/", "priv/", "test/", "scripts/", ".github/", "compatibility/", "docs/")
        selected = {p for p in paths if p.startswith(prefixes) or "/" not in p}
        self.assertTrue(selected <= set(delivery.COVERED_INPUTS), "selected tracked closure is incomplete")

    def test_known_value_channels_are_typed_for_all_26_cells(self):
        files = sorted((ROOT / "test/fixtures/verifier-matrix-26").rglob("*.json"))
        self.assertEqual(len(files), 26, "matrix fixture count changed")
        def leaves(value, path=()):
            if isinstance(value, dict):
                for key, child in value.items():
                    yield from leaves(child, (*path, key))
            elif isinstance(value, list):
                yield path, value
            else:
                yield path, value
        accepted = 0
        for fixture in files:
            raw = json.loads(fixture.read_text())
            # A disclosure failure fixture is an established full receipt too.
            validator(raw)
            for path, original in leaves(raw):
                for replacement in ({"sensitive_contract_marker": "private-value"}, [], 1 if type(original) is bool else False):
                    mutated = copy.deepcopy(raw)
                    node = mutated
                    for part in path[:-1]:
                        node = node[part]
                    node[path[-1]] = replacement
                    try:
                        validator(mutated)
                    except (receipts.ReceiptError, TypeError, AttributeError, KeyError):
                        continue
                    accepted += 1
        self.assertEqual(accepted, 0, "known scalar or container mutation passed")

    def test_actual_wrapper_upload_tree_is_consumed(self):
        with tempfile.TemporaryDirectory(dir=ROOT / ".artifacts/phase178") as temporary:
            locked, floor, runner, candidate = contracts.ComposedMatrixContracts()._pair_roots(Path(temporary))
            for pair, root, expected in (("locked", locked, 14), ("floor", floor, 12)):
                upload_tree(root, pair)
                archive = Path(temporary) / f"{pair}.zip"
                zip_upload(root, archive)
                with self.assertRaises(delivery.DeliveryError):
                    delivery._artifact_zip_pair(archive, pair=pair, runner=runner, candidate=candidate)

    def test_raw_archive_substitution_cannot_hide_behind_index(self):
        with tempfile.TemporaryDirectory(dir=ROOT / ".artifacts/phase178") as temporary:
            locked, _floor, runner, candidate = contracts.ComposedMatrixContracts()._pair_roots(Path(temporary))
            index_path = locked / "validated/index.json"
            index = json.loads(index_path.read_text())
            row = next(row for row in index["cells"] if row["scope"] == "core" and row["store"] == "builtin")
            path = locked / "validated/core-locked-builtin-receipt.json"
            raw = json.loads(path.read_text())
            raw["candidate"]["archive_sha256"] = "e" * 64
            raw["candidate"]["source_proof"] = hashlib.sha256(json.dumps({
                key: raw["candidate"][key] for key in ("archive_sha256", "source_revision", "tree_sha256")
            }, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
            changed = json.dumps(raw).encode()
            path.write_bytes(changed)
            (locked / row["receipt_path"]).write_bytes(changed)
            row["receipt_sha256"] = hashlib.sha256(changed).hexdigest()
            index_path.write_text(json.dumps(index))
            with self.assertRaises(AssertionError):
                upload_tree(locked, "locked")
            return  # The independent owner rejects substitution before raw copying.
            archive = Path(temporary) / "substitution.zip"
            zip_upload(locked, archive)
            with self.assertRaises(delivery.DeliveryError):
                delivery._artifact_zip_pair(archive, pair="locked", runner=runner, candidate=candidate)

    def test_actual_helper_sorted_graph_and_outcome_are_consumed(self):
        sha = "a" * 40
        for release in (False, True):
            names = (("Maintain Release Please PR", "Validate exact main head and CI evidence",
                      "Prove exact package before publication", "Publish verified release to Hex",
                      "Verify public install truth", "Record terminal release outcome")
                     if release else delivery.CANONICAL_CI_JOBS)
            graph = {"status": "pass", "run_id": 100, "run_attempt": 1,
                     "workflow_path": ".github/workflows/release.yml" if release else ".github/workflows/ci.yml",
                     "head_sha": sha, "event": "push", "conclusion": "success",
                     "url": "https://github.com/fixture/repo/actions/runs/100",
                     "jobs": [{"name": name, "id": i + 1, "run_id": 100, "run_attempt": 1,
                               "head_sha": sha, "status": "completed",
                               "conclusion": "skipped" if release and name != "Maintain Release Please PR" else "success"}
                              for i, name in enumerate(sorted(names))]}
            if release:
                graph["outcome"] = "no_publish"
            def api(endpoint):
                if endpoint.endswith("/jobs?per_page=100"):
                    return {"total_count": len(graph["jobs"]), "jobs": list(reversed(graph["jobs"]))}
                if "/actions/workflows/" in endpoint:
                    return {"id": 10}
                return {"id": 100, "run_attempt": 1, "repository": {"full_name": "fixture/repo"},
                        "head_sha": sha, "head_branch": "main", "event": "push", "path": graph["workflow_path"],
                        "workflow_id": 10, "status": "completed", "conclusion": "success", "html_url": graph["url"]}
            with patch.object(delivery, "_github_json", side_effect=api):
                delivery._validate_helper_graph(graph, repo="fixture/repo", sha=sha, release=release)


class ActualEndToEndDelivery(unittest.TestCase):
    def stage(self, name):
        print(json.dumps({"chain_stage": name, "pid": os.getpid(),
                          "elapsed_seconds": round(time.monotonic() - self.started, 3)}, sort_keys=True), flush=True)
    def git(self, root, *args):
        result = self.boundary.real_run(("git", *args), cwd=root, capture_output=True, timeout=30)
        self.assertTrue(result.returncode == 0, "owned fixture Git operation failed")
        return result.stdout.decode().strip()

    def pairs(self, root, runner, candidate, proof, profiles=None):
        roots = []
        for pair in ("locked", "floor"):
            target = root / f"final-{pair}"
            shutil.copytree(ROOT / "test/fixtures/verifier-matrix-26", target)
            profile = (profiles or {}).get(pair, "local-current")
            self.boundary.beam = owner_context.selected_runtime(delivery.ROOT, profile)[:2]
            context_path = target / "receipt-owner.json"
            if profile == "hosted-minimum":
                self.boundary.beam = owner_context.selected_runtime(delivery.ROOT, "local-current")[:2]
                with self.assertRaises(owner_context.OwnerError):
                    delivery.capture_receipt_owner(self.current_phase, self.current_pins, profile, context_path)
                self.assertTrue(not context_path.exists(), "wrong observed minimum toolchain created authority")
                self.boundary.beam = owner_context.selected_runtime(delivery.ROOT, profile)[:2]
            context_digest = delivery.capture_receipt_owner(self.current_phase, self.current_pins, profile, context_path)
            context = json.loads(context_path.read_text())
            for path in target.rglob("*.json"):
                if path == context_path:
                    continue
                raw = json.loads(path.read_text())
                rollout = raw["schema"].endswith("rollout-v1")
                raw["runner_revision" if rollout else "runner"] = runner
                raw["candidate"].update(kind="frozen", source_revision=candidate[0], archive_sha256=candidate[1],
                                         tree_sha256=candidate[2], source_proof=proof, runner_revision=runner)
                (raw["candidate"] if rollout else raw["host"])["vendor_tree_sha256"] = candidate[2]
                raw["runtime"] = dict(context["runtime"])
                path.write_text(json.dumps(raw, sort_keys=True) + "\n")
            with patch.dict(os.environ, {"LOCKSPIRE_RECEIPT_OWNER": str(context_path),
                                        "LOCKSPIRE_EXPECTED_RECEIPT_OWNER_SHA256": context_digest}), redirect_stdout(StringIO()), redirect_stderr(StringIO()):
                if pair == "locked":
                    self.reject_owned_pair_mutations(target, pair, runner, candidate[0])
                result = package_input.bounded_run(
                    (sys.executable, str(delivery.ROOT / "scripts/acceptance/clean_room_verifier_upgrade.py"),
                     "--pair", pair, "--store", "all", "--group", "all", "--validate-receipts", str(target),
                     "--expected-runner-revision", runner, "--expected-candidate-source-revision", candidate[0]),
                    cwd=ROOT, env=dict(os.environ), stdin=subprocess.DEVNULL,
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30,
                )
                self.assertTrue(result.returncode == 0, "actual owner-bound pair CLI failed")
                index = json.loads((target / "validated/index.json").read_text())
            self.assertEqual(index["executed_receipts"], 14 if pair == "locked" else 12)
            self.assertEqual(index["passed_cases"], 33 if pair == "locked" else 31)
            roots.append(target)
        return roots

    def reject_owned_pair_mutations(self, root, pair, runner, source):
        """Mutated file observations stay in memory; copy gates are real."""
        read_bytes, read_text = Path.read_bytes, Path.read_text
        opaque = __import__("secrets").token_hex(16)
        for scope in ("release-rpc", "rollout"):
            path = root / scope / f"{pair}-builtin/receipt.json"
            original = json.loads(read_text(path))
            for field in ("version", "runtime"):
                value = __import__("copy").deepcopy(original)
                if field == "version":
                    value["candidate"]["version"] += "-" + opaque
                    if scope == "release-rpc":
                        value["observations"][receipts.RELEASE_RPC_CASE_ID]["compiled_module_relative_path"] = (
                            f"lib/lockspire-{value['candidate']['version']}/ebin/Elixir.Lockspire.Admin.ClientVerifierMaintenance.beam")
                else:
                    value["runtime"]["elixir"] += "-" + opaque
                encoded = json.dumps(value).encode()
                def memory_bytes(selected):
                    return encoded if selected == path else read_bytes(selected)
                def memory_text(selected, *args, **kwargs):
                    return encoded.decode() if selected == path else read_text(selected, *args, **kwargs)
                with patch.object(Path, "read_bytes", memory_bytes), patch.object(Path, "read_text", memory_text):
                    with self.assertRaises(receipts.ReceiptError):
                        upgrade._validate_pair_directory(root, pair, expected_runner=runner, expected_candidate_source=source)
                self.assertTrue(not (root / "validated").exists(), "unsafe owner claims reached pair-copy output")

    def api_run(self, number, sha, *, release=False, event="push", pr=None):
        names = (("Maintain Release Please PR", "Validate exact main head and CI evidence",
                  "Prove exact package before publication", "Publish verified release to Hex",
                  "Verify public install truth", "Record terminal release outcome")
                 if release else delivery.CANONICAL_CI_JOBS)
        run = {"id": number, "run_attempt": 1, "head_sha": sha, "head_branch": "main",
               "event": event, "path": ".github/workflows/release.yml" if release else ".github/workflows/ci.yml",
               "workflow_id": 20 if release else 10, "name": "Release" if release else "CI",
               "status": "completed", "conclusion": "success", "repository": {"full_name": "fixture/repo"},
               "html_url": f"https://github.com/fixture/repo/actions/runs/{number}", "pull_requests": [pr] if pr else []}
        jobs = [{"name": name, "id": number * 10 + i, "run_id": number, "run_attempt": 1,
                 "head_sha": sha, "status": "completed",
                 "conclusion": "skipped" if release and name != "Maintain Release Please PR" else "success"}
                for i, name in enumerate(names, 1)]
        base = "repos/fixture/repo"
        self.boundary.api[f"{base}/actions/runs/{number}/attempts/1"] = run
        self.boundary.api[f"{base}/actions/runs/{number}/attempts/1/jobs?per_page=100"] = {"total_count": len(jobs), "jobs": list(reversed(jobs))}
        self.boundary.api[f"{base}/actions/runs/{number}/jobs?per_page=100&page=1"] = {"total_count": len(jobs), "jobs": list(reversed(jobs))}
        workflow = "release.yml" if release else "ci.yml"
        self.boundary.api[f"{base}/actions/workflows/{workflow}"] = {"id": run["workflow_id"]}
        self.boundary.api[f"{base}/actions/workflows/{workflow}/runs?branch=main&event=push&head_sha={sha}&per_page=100"] = {"workflow_runs": [run]}
        return run, jobs

    def test_one_actual_chain_with_full_closure_and_authoritative_boundaries(self):
        from contextlib import ExitStack
        import base64
        with tempfile.TemporaryDirectory(prefix="lockspire-delivery-chain-") as temporary, ExitStack() as stack:
            self.started = time.monotonic()
            self.stage("fixture_created")
            repo = Path(temporary).resolve() / "repo"
            repo.mkdir()
            self.boundary = ExternalBoundaries(repo)
            self.git(repo, "init", "-q", "--initial-branch=main")
            self.git(repo, "config", "user.email", "fixture@example.invalid")
            self.git(repo, "config", "user.name", "Synthetic Authority Fixture")
            all_paths = self.git(ROOT, "ls-files", "--cached", "--others", "--exclude-standard").splitlines()
            selected = sorted({path for path in all_paths if selected_path(path, delivery.PLANNING_INPUTS)})
            self.assertGreaterEqual(len(selected), len(delivery.COVERED_INPUTS), "chain shrank the selected tracked closure")
            for relative in selected:
                target = repo / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / relative, target)
            from verifier_owner_fixture import materialize_epoch_locks
            import build_provider
            epoch_locks = materialize_epoch_locks(repo, repository_layout=True)
            stack.enter_context(patch.dict(build_provider.PROOF_PAIR_LOCKS, epoch_locks))
            self.git(repo, "add", "-f", "--", *selected)
            self.git(repo, "commit", "-qm", "full selected implementation fixture")
            frozen_revision = self.git(repo, "rev-parse", "HEAD")
            self.git(repo, "remote", "add", "origin", "https://github.com/fixture/repo.git")
            artifacts = repo / ".artifacts/phase178"
            artifacts.mkdir(parents=True)
            phase = repo / ".planning/phases" / delivery.PHASE_NAME
            for module, name, value in ((delivery, "ROOT", repo), (delivery, "ARTIFACT_DEFAULT", artifacts),
                                        (provisioner, "ROOT", repo), (package_input, "PROJECT_ROOT", repo)):
                stack.enter_context(patch.object(module, name, value))
            stack.enter_context(patch.object(subprocess, "run", side_effect=self.boundary.run))
            for module in (delivery, provisioner, package_input):
                stack.enter_context(patch.object(module, "unpack_hex_tarball", side_effect=self.boundary.unpack))
            stack.enter_context(patch.object(owner_context, "_observe", side_effect=self.boundary.observe_runtime))
            reviewed_files = [{"path": path, "sha256": delivery._blob_sha(frozen_revision, path)} for path in selected]
            review_record = {"schema": "lockspire-phase178-independent-reviews-v1", "implementation_revision": frozen_revision, "lanes": {}}
            for lane in ("source", "security", "integration"):
                judgment = {"reviewer_identity": f"synthetic-{lane}-reviewer-fixture", "reviewed_revision": frozen_revision,
                            "reviewed_at": "2026-10-27", "verdict": "accepted", "reviewed_files": reviewed_files, "findings": []}
                report = phase / f"178-SYNTHETIC-{lane}.md"
                report.write_text(f"# Synthetic fixture only\nReviewer: {judgment['reviewer_identity']}\nReviewed commit: {frozen_revision}\n"
                                  "Disposition: accepted\nActive blocking findings: 0\n\n```json\n" + json.dumps(judgment) + "\n```\n")
                review_record["lanes"][lane] = {**judgment, "report_path": report.name, "report_sha256": delivery.sha256(report)}
            packet = phase / "178-INDEPENDENT-REVIEWS.json"
            packet.write_text(json.dumps(review_record))
            delivery.validate_reviews(phase, expected_revision=frozen_revision)
            source_report = phase / review_record["lanes"]["source"]["report_path"]
            accepted_report = source_report.read_text()
            source_report.write_text(accepted_report + "\nOPEN HIGH BLOCKER: active fixture finding remains.\n")
            review_record["lanes"]["source"]["report_sha256"] = delivery.sha256(source_report)
            packet.write_text(json.dumps(review_record))
            with self.assertRaises(delivery.DeliveryError):
                delivery.validate_reviews(phase, expected_revision=frozen_revision)
            source_report.write_text(accepted_report + "\n> OPEN HIGH BLOCKER: historical quotation only.\n")
            review_record["lanes"]["source"]["report_sha256"] = delivery.sha256(source_report)
            packet.write_text(json.dumps(review_record))
            delivery.validate_reviews(phase, expected_revision=frozen_revision)
            self.stage("full_scope_active_judgment_contradiction_rejected")
            pins = provisioner.provision(frozen_revision, frozen_revision, phase / "178-FROZEN-INPUTS.json")
            self.stage("actual_provisioner_and_full_freeze_consumed")
            frozen = delivery._read_json(phase / "178-FROZEN-INPUTS.json", "fixture frozen manifest")
            owner = frozen["candidate_owner"]
            candidate = (owner["source_revision"], owner["archive_sha256"], owner["tree_sha256"])
            self.assertEqual(len(frozen["covered_inputs"]), len(selected), "frozen path enumeration drifted")
            self.git(repo, "add", "-f", "--", str(phase.relative_to(repo)))
            self.git(repo, "commit", "-qm", "preserve frozen evidence metadata")
            tested = self.git(repo, "rev-parse", "HEAD")
            changed = repo / "lib/lockspire/domain/client.ex"
            before = changed.read_bytes()
            changed.write_bytes(before + b"\n# controlled covered mutation\n")
            with self.assertRaises(delivery.DeliveryError):
                delivery.validate_frozen_manifest(phase, **pins)
            changed.write_bytes(before)
            dependency = repo / "scripts/ci/new_tracked_chain_dependency.py"
            dependency.write_text("# controlled newly tracked dependency\n")
            self.git(repo, "add", "-f", "--", dependency.relative_to(repo).as_posix())
            self.git(repo, "commit", "-qm", "controlled selected path addition")
            with self.assertRaises(delivery.DeliveryError):
                delivery.validate_frozen_manifest(phase, **pins)
            self.git(repo, "checkout", "--detach", "-q", tested)
            self.stage("covered_and_new_tracked_mutations_rejected")
            guard = source_guard.OwnedSourceTests([], root=repo, ci=True, inherited={}, process_runner=self.boundary)
            self.boundary.owner = guard
            self.addCleanup(shutil.rmtree, guard.directory, True)
            self.assertEqual(guard.run(), 0, "actual owned source producer failed")
            self.stage("actual_owned_source_run_passed")
            self.current_phase, self.current_pins = phase, pins
            locked, floor = self.pairs(artifacts, tested, candidate, owner["owner_sha256"])
            source = delivery.record_source_acceptance(phase, guard.manifest_path, locked, floor, pins)
            self.assertEqual(source["tested_source_revision"], tested)
            self.assertEqual(source["frozen_runner_revision"], frozen_revision)
            delivery._check_source(phase, locked, floor, pins)
            self.stage("source_acceptance_and_26_cell_pair_tree_consumed")
            authorization_path = phase / "178-INTEGRATION-AUTHORIZATION.json"
            authorization_path.write_text(json.dumps({"schema": "lockspire-phase178-integration-authorization-v1",
                "status": "authorized", "candidate_sha": tested, "authorized_by": "synthetic-fixture-only",
                "authorized_at": "2026-10-27T12:00:00Z"}))
            self.git(repo, "add", "-f", "--", str(phase.relative_to(repo)))
            self.git(repo, "commit", "-qm", "preserve source and synthetic authorization metadata")
            head = self.git(repo, "rev-parse", "HEAD")
            merge = self.git(repo, "commit-tree", self.git(repo, "rev-parse", "HEAD^{tree}"),
                             "-p", frozen_revision, "-p", head, "-m", "synthetic PR merge fixture")
            self.git(repo, "checkout", "--detach", "-q", merge)
            self.git(repo, "update-ref", "refs/heads/main", merge)
            self.git(repo, "update-ref", "refs/remotes/origin/main", merge)
            self.assertEqual(len({frozen_revision, tested, head, merge}), 4, "actual checkout roles collapsed")
            hosted = Path(temporary).resolve() / "hosted"
            self.git(Path(temporary), "clone", "--quiet", "--shared", str(repo), str(hosted))
            with patch.object(delivery, "ROOT", hosted), patch.object(delivery, "ARTIFACT_DEFAULT", hosted / ".artifacts/phase178"), \
                 patch.object(provisioner, "ROOT", hosted), patch.object(package_input, "PROJECT_ROOT", hosted):
                self.assertEqual(provisioner.reviewed_candidate_source(merge), frozen_revision)
                hosted_pins = provisioner.provision(merge, frozen_revision)
                hosted_manifest = delivery._read_json(hosted / ".artifacts/phase178/ci-candidate/178-FROZEN-INPUTS.json", "hosted manifest")
                self.current_phase, self.current_pins = hosted / ".planning/phases" / delivery.PHASE_NAME, hosted_pins
                with patch.dict(os.environ, {"LOCKSPIRE_FROZEN_INPUTS": str(hosted / ".artifacts/phase178/ci-candidate/178-FROZEN-INPUTS.json")}):
                    hosted_pairs = self.pairs(hosted / ".artifacts/phase178", merge, candidate, hosted_manifest["candidate_owner"]["owner_sha256"],
                        {"locked": "hosted-current", "floor": "hosted-minimum"})
                uploads = []
                for pair, root in zip(("locked", "floor"), hosted_pairs, strict=True):
                    with patch.dict(os.environ, {"LOCKSPIRE_FROZEN_INPUTS": str(hosted / ".artifacts/phase178/ci-candidate/178-FROZEN-INPUTS.json"),
                        "LOCKSPIRE_RECEIPT_OWNER": str(root / "receipt-owner.json"),
                        "LOCKSPIRE_EXPECTED_RECEIPT_OWNER_SHA256": delivery.sha256(root / "receipt-owner.json")}):
                        upload_tree(root, pair)
                        delivery.copy_upload_owner(root / "validated", hosted / ".planning/phases" / delivery.PHASE_NAME, hosted_pins)
                    output = artifacts / "candidate-downloads/300-1" / f"{pair}.zip"
                    output.parent.mkdir(parents=True, exist_ok=True)
                    zip_upload(root, output)
                    uploads.append(output)
            self.stage("actual_uploaded_trees_zipped")
            tree, parents = delivery._commit_shape(merge)
            pr = {"number": 7, "head": {"sha": head}, "base": {"sha": frozen_revision}}
            run, jobs = self.api_run(300, head, event="pull_request", pr=pr)
            self.boundary.api["repos/fixture/repo/git/ref/pull/7/merge"] = {"ref": "refs/pull/7/merge", "object": {"sha": merge}}
            self.boundary.api[f"repos/fixture/repo/git/commits/{merge}"] = {"sha": merge, "tree": {"sha": tree}, "parents": [{"sha": p} for p in parents]}
            observation = {"schema": "lockspire-phase178-candidate-observation-v1", "event": "pull_request",
                "run_id": "300", "run_attempt": 1, "pull_request_head_sha": head, "executed_checkout_sha": merge,
                "checkout_tree": tree, "checkout_parents": parents, "workflow_head_sha": head,
                "pull_request_number": 7, "pull_request_base_sha": frozen_revision, "checkout_ref": "refs/pull/7/merge"}
            (phase / "178-CANDIDATE-OBSERVATION.json").write_text(json.dumps(observation))
            relation = provisioner.covered_input_relation(repo, merge, frozen_revision, list(delivery.covered_inputs(tested)))
            identity = {"schema": "lockspire-phase178-candidate-v1", "reviewed_head_sha": head,
                "package_source_sha": frozen_revision, "package_archive_sha256": candidate[1], "package_tree_sha256": candidate[2],
                "frozen_manifest_sha256": pins["expected_manifest_sha256"], "runner_sha": merge, "executed_checkout_sha": merge,
                "checkout_tree": tree, "checkout_parents": parents, "covered_input_relation": relation,
                "workflow_path": ".github/workflows/ci.yml", "event": "pull_request", "run_id": "300", "run_attempt": 1,
                "observed_at": "2026-10-27T12:00:00Z", "failed_attempts": [],
                "source_acceptance_sha256": delivery.sha256(phase / "178-SOURCE-ACCEPTANCE.json"),
                "raw_observation_sha256": delivery.sha256(phase / "178-CANDIDATE-OBSERVATION.json")}
            (phase / "178-CANDIDATE.json").write_text(json.dumps(identity))
            artifact_rows, api_artifacts = [], []
            for i, (pair, output) in enumerate(zip(("locked", "floor"), uploads, strict=True), 1):
                name = f"lockspire-verifier-upgrade-{merge}-{pair}"
                artifact_rows.append({"pair": pair, "name": name, "artifact_id": i, "archive_path": output.relative_to(repo).as_posix()})
                api_artifacts.append({"id": i, "name": name, "expired": False, "digest": "sha256:" + delivery.sha256(output)})
            self.boundary.api["repos/fixture/repo/actions/runs/300/artifacts?per_page=100"] = {"artifacts": api_artifacts}
            (phase / "178-CANDIDATE-GATES.json").write_text(json.dumps({"schema": "lockspire-phase178-candidate-gates-v1",
                **{key: identity[key] for key in ("workflow_path", "event", "run_id", "run_attempt", "executed_checkout_sha", "runner_sha", "package_source_sha", "source_acceptance_sha256", "failed_attempts")},
                "status": "completed", "conclusion": "success", "jobs": [{"name": job["name"], "job_id": job["id"],
                    "run_id": "300", "run_attempt": 1, "checkout_sha": merge, "status": "completed", "conclusion": "success"} for job in jobs], "package_artifacts": artifact_rows}))
            self.assertEqual(delivery._check_candidate(phase)["jobs"], 7)
            self.stage("candidate_identity_and_authoritative_graph_consumed")
            self.reject_uploaded_owner_mutations(uploads[0], merge, candidate)
            self.stage("grammar_preserving_package_runtime_zip_mutations_rejected")
            pr["base"]["sha"] = head
            with self.assertRaises(delivery.DeliveryError):
                delivery._check_candidate_identity(phase)
            pr["base"]["sha"] = frozen_revision
            self.boundary.api["repos/fixture/repo/actions/runs/300/attempts/1"]["run_attempt"] = 2
            with self.assertRaises(delivery.DeliveryError):
                delivery._check_candidate_identity(phase)
            run["run_attempt"] = 1
            substituted = artifacts / "substituted-upload.zip"
            with zipfile.ZipFile(uploads[0]) as archive:
                members = {name: archive.read(name) for name in archive.namelist()}
            members["candidate/package.tar"] += b"controlled-package-substitution"
            with zipfile.ZipFile(substituted, "w") as archive:
                for name, value in members.items():
                    archive.writestr(name, value)
            with self.assertRaises(delivery.DeliveryError):
                delivery._artifact_zip_pair(substituted, pair="locked", runner=merge, candidate=candidate, require_owner=True, profile="hosted-current")
            self.stage("authoritative_base_attempt_and_archive_mutations_rejected")
            self.git(repo, "add", "-f", "--", str(phase.relative_to(repo)))
            self.git(repo, "commit", "-qm", "preserve candidate evidence metadata")
            main_sha = self.git(repo, "rev-parse", "HEAD")
            self.git(repo, "update-ref", "refs/heads/main", main_sha)
            self.git(repo, "update-ref", "refs/remotes/origin/main", main_sha)
            self.boundary.api["repos/fixture/repo/git/ref/heads/main"] = {"ref": "refs/heads/main", "object": {"sha": main_sha}}
            for path in ("scripts/maintainer/repo_hygiene_check.sh", authorization_path.relative_to(repo).as_posix()):
                self.boundary.api[f"repos/fixture/repo/contents/{path}?ref={main_sha}"] = {"encoding": "base64", "content": base64.b64encode((repo / path).read_bytes()).decode()}
            self.api_run(100, main_sha)
            self.api_run(200, main_sha, release=True)
            gate = delivery.run_main_source_gate(main_sha, process_runner=self.boundary)
            authorization = delivery.integration_authorization(main_sha)
            fakebin = Path(temporary) / "bin"
            fakebin.mkdir()
            gh = fakebin / "gh"
            gh.write_text("#!/usr/bin/env python3\nimport os,json,sys\nd=json.loads(os.environ['SYNTHETIC_API'])[sys.argv[2]]\nprint(json.dumps(d))\n")
            gh.chmod(0o700)
            helper = (repo / "scripts/maintainer/repo_hygiene_check.sh").read_text().split("\nrepo_owned_checks\n", 1)[0]
            helper += '\nACCEPT_SHA="$SYNTHETIC_MAIN"\nREPOSITORY=fixture/repo\nWAIT_SECONDS=0\nLOCAL_GATE_JSON="$SYNTHETIC_GATE"\nLOCAL_TEST_COUNT=2423\nINTEGRATION_AUTHORIZATION_JSON="$SYNTHETIC_AUTH"\nWARN_DISPOSITIONS_JSON="[]"\nvalidate_required_ci_run\nvalidate_required_ci_jobs\nvalidate_no_publish_release_run\nemit_acceptance_receipt\n'
            produced = self.boundary.real_run(("bash", "-c", helper), cwd=repo, capture_output=True, timeout=30,
                env={**os.environ, "PATH": str(fakebin) + os.pathsep + os.environ["PATH"], "SYNTHETIC_API": json.dumps(self.boundary.api),
                     "SYNTHETIC_MAIN": main_sha, "SYNTHETIC_GATE": json.dumps(gate), "SYNTHETIC_AUTH": json.dumps(authorization)})
            self.assertEqual(produced.returncode, 0, "actual helper collector/validator/emitter failed")
            self.stage("actual_helper_collector_validator_emitter_passed")
            main_path = phase / "178-MAIN-ACCEPTANCE.json"
            main_path.write_bytes(produced.stdout)
            handoff = {"schema": "lockspire-phase178-handoff-v1", "integration_status": "accepted", "accepted_main_status": "accepted",
                "owner": "synthetic-fixture-only", "next_action": "mechanism test only", "main_acceptance_path": main_path.name,
                "main_acceptance_sha256": delivery.sha256(main_path), "main_sha": main_sha}
            (phase / "178-HANDOFF.json").write_text(json.dumps(handoff))
            self.assertTrue(delivery._check_handoff(phase)["accepted_main"], "actual helper bytes failed handoff consumption")
            self.stage("handoff_consumed_actual_helper_bytes")
            self.boundary.api["repos/fixture/repo/actions/runs/100/attempts/1"]["head_sha"] = frozen_revision
            with self.assertRaises(delivery.DeliveryError):
                delivery._check_handoff(phase)
            self.assertFalse(self.boundary.exists, "fake owned database was not cleaned")

    def reject_uploaded_owner_mutations(self, path, runner, candidate):
        """Coordinate raw/flat/index/copy digests in an in-memory actual ZIP."""
        read = __import__("io").BytesIO
        opaque = __import__("secrets").token_hex(16)
        with zipfile.ZipFile(path) as archive:
            original = {name: archive.read(name) for name in archive.namelist()}
        for scope in ("release-rpc", "rollout"):
            for field in ("version", "runtime"):
                members = dict(original)
                flat = f"{scope}-locked-builtin-receipt.json"
                value = json.loads(members[flat])
                if field == "version":
                    value["candidate"]["version"] += "-" + opaque
                    if scope == "release-rpc":
                        value["observations"][receipts.RELEASE_RPC_CASE_ID]["compiled_module_relative_path"] = (
                            f"lib/lockspire-{value['candidate']['version']}/ebin/Elixir.Lockspire.Admin.ClientVerifierMaintenance.beam")
                else:
                    value["runtime"]["elixir"] += "-" + opaque
                changed = json.dumps(value).encode()
                digest = hashlib.sha256(changed).hexdigest()
                members[flat] = changed
                members[f"raw/{scope}-locked-builtin.json"] = changed
                index = json.loads(members["index.json"])
                for row in index["cells"]:
                    if row["scope"] == scope and row["store"] == "builtin":
                        row["receipt_sha256"] = digest
                members["index.json"] = json.dumps(index).encode()
                copies = json.loads(members["raw-copies.json"])
                for row in copies["copies"]:
                    if row["scope"] == scope and row["store"] == "builtin":
                        row["sha256"] = digest
                members["raw-copies.json"] = json.dumps(copies).encode()
                output = read()
                with zipfile.ZipFile(output, "w") as archive:
                    for name, content in members.items():
                        archive.writestr(name, content)
                output.seek(0)
                with self.assertRaises(delivery.DeliveryError):
                    delivery._artifact_zip_pair(output, pair="locked", runner=runner, candidate=candidate,
                                                require_owner=True, profile="hosted-current")


if __name__ == "__main__":
    unittest.main()
