"""Closed-matrix contract tests for installed verifier receipts."""

from __future__ import annotations

import sys
import unittest
import json
import ast
import base64
import copy
import secrets
import shutil
import tempfile
from contextlib import redirect_stdout, redirect_stderr
from io import StringIO
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))

import verifier_receipts  # noqa: E402


class CompleteMatrixContracts(unittest.TestCase):
    def _fixture_cli(self, source, arguments):
        from verifier_owner_fixture import retained_lock_context
        inputs = Path(arguments[arguments.index("--validate-receipts") + 1])
        with retained_lock_context(inputs.parent):
            return source.main(arguments)

    def test_private_lock_epoch_matches_all_retained_receipts_and_restores_current_inputs(self):
        from verifier_owner_fixture import check_template_epoch, retained_lock_context
        import build_provider
        import hashlib
        before = dict(build_provider.PROOF_PAIR_LOCKS)
        files = sorted((ROOT / "test/fixtures/verifier-matrix-26").rglob("*.json"))
        self.assertTrue(len(files) == 26, "retained epoch matrix lost a required cell")
        with tempfile.TemporaryDirectory() as temporary:
            with retained_lock_context(Path(temporary)) as paths:
                for path in files:
                    raw = json.loads(path.read_text())
                    check_template_epoch(raw)
                    self.assertTrue(hashlib.sha256(paths[raw["pair"]].read_bytes()).hexdigest() == raw["host"]["lock_sha256"],
                                    "private epoch lock failed its retained source binding")
        self.assertTrue(build_provider.PROOF_PAIR_LOCKS == before, "fixture lock authority escaped its private scope")

    def test_private_lock_epoch_rejects_borrowed_source_and_changed_private_bytes(self):
        from verifier_owner_fixture import check_template_epoch, retained_lock_context
        raw = json.loads((ROOT / "test/fixtures/verifier-matrix-26/core/locked-builtin/receipt.json").read_text())
        for field in ("source_revision", "runner_revision"):
            borrowed = copy.deepcopy(raw)
            if field == "source_revision":
                borrowed["candidate"][field] = "9" * 40
            else:
                borrowed["runner"] = "9" * 40
            with self.assertRaises(AssertionError):
                check_template_epoch(borrowed)
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with retained_lock_context(root) as paths:
                paths["locked"].write_bytes(paths["locked"].read_bytes() + b"\n")
            with self.assertRaises(AssertionError):
                with retained_lock_context(root):
                    self.fail("changed private lock acquired fixture authority")

    def test_grammar_preserving_package_and_runtime_substitutions_require_owner(self):
        accepted = 0
        opaque = secrets.token_hex(16)
        for scope in ("release-rpc", "rollout"):
            original = json.loads((ROOT / f"test/fixtures/verifier-matrix-26/{scope}/locked-builtin/receipt.json").read_text())
            for field in ("version", "runtime"):
                mutated = copy.deepcopy(original)
                if field == "version":
                    mutated["candidate"]["version"] += "-" + opaque
                    if scope == "release-rpc":
                        mutated["observations"][verifier_receipts.RELEASE_RPC_CASE_ID]["compiled_module_relative_path"] = (
                            f"lib/lockspire-{mutated['candidate']['version']}/ebin/Elixir.Lockspire.Admin.ClientVerifierMaintenance.beam")
                else:
                    mutated["runtime"]["elixir"] += "-" + opaque
                try:
                    if scope == "rollout":
                        verifier_receipts.validate_rollout_receipt(mutated, expected_pair="locked", expected_store="builtin",
                            expected_runner=original["runner_revision"], expected_candidate_source=original["candidate"]["source_revision"], expected_scope="rollout")
                    else:
                        verifier_receipts.validate_receipt(mutated)
                except verifier_receipts.ReceiptError:
                    continue
                accepted += 1
        self.assertTrue(accepted == 0, "grammar-preserving receipt claims bypassed independent ownership")

    def _producer_release_invocations(self):
        names = {"rpc_invocation", "check_invocation", "task_local_invocation"}
        source = ROOT / "scripts/acceptance/clean_room/verifier_endpoints.py"
        rows = {}
        for node in ast.walk(ast.parse(source.read_text(encoding="utf-8"))):
            if isinstance(node, ast.Dict):
                for key, value in zip(node.keys, node.values):
                    if isinstance(key, ast.Constant) and key.value in names:
                        self.assertTrue(isinstance(value, ast.Constant) and type(value.value) is str,
                                        "release producer invocation must remain a literal")
                        self.assertTrue(key.value not in rows, "release producer invocation is duplicated")
                        rows[key.value] = value.value
        self.assertTrue(set(rows) == names, "release producer invocation set changed")
        return rows

    def test_actual_release_producer_invocation_literals_are_accepted(self):
        receipt = json.loads((ROOT / "test/fixtures/verifier-matrix-26/release-rpc/locked-builtin/receipt.json").read_text())
        observation = receipt["observations"][verifier_receipts.RELEASE_RPC_CASE_ID]
        observation.update(self._producer_release_invocations())
        self.assertTrue(verifier_receipts._validate_receipt_structure(receipt) is receipt,
                        "actual release producer invocations failed their consumer")

    def test_release_invocations_reject_generated_same_type_private_strings(self):
        receipt = json.loads((ROOT / "test/fixtures/verifier-matrix-26/release-rpc/locked-builtin/receipt.json").read_text())
        opaque = "opaque_" + secrets.token_hex(24)
        variants = (opaque, base64.urlsafe_b64encode(opaque.encode()).decode(), opaque.encode().hex(),
                    "".join("%%%02X" % byte for byte in opaque.encode()))
        accepted = 0
        for field in self._producer_release_invocations():
            for value in variants:
                mutated = copy.deepcopy(receipt)
                mutated["observations"][verifier_receipts.RELEASE_RPC_CASE_ID][field] = value
                try:
                    verifier_receipts._validate_receipt_structure(mutated)
                except verifier_receipts.ReceiptError:
                    continue
                accepted += 1
        self.assertTrue(accepted == 0, "fixed release invocation accepted a private same-type string")

    def test_all_26_receipt_string_leaves_reject_generated_opaque_and_encoded_values(self):
        def strings(value, path=()):
            if isinstance(value, dict):
                for key, child in value.items():
                    yield from strings(child, (*path, key))
            elif isinstance(value, list):
                for index, child in enumerate(value):
                    yield from strings(child, (*path, index))
            elif type(value) is str:
                yield path
        opaque = "opaque_" + secrets.token_hex(24)
        variants = (opaque, base64.urlsafe_b64encode(opaque.encode()).decode(), opaque.encode().hex(),
                    "".join("%%%02X" % byte for byte in opaque.encode()))
        files = sorted((ROOT / "test/fixtures/verifier-matrix-26").rglob("*.json"))
        self.assertTrue(len(files) == 26, "receipt string inventory lost a matrix cell")
        accepted = 0
        for path in files:
            raw = json.loads(path.read_text())
            rollout = raw["schema"] == "lockspire-installed-verifier-rollout-v1"
            def validate(value):
                if rollout:
                    return verifier_receipts._validate_rollout_structure(value, expected_pair=raw["pair"],
                        expected_store=raw["store"], expected_runner=raw["runner_revision"],
                        expected_candidate_source=raw["candidate"]["source_revision"], expected_scope=raw["scope"])
                return verifier_receipts._validate_receipt_structure(value)
            validate(raw)
            for leaf in strings(raw):
                for replacement in variants:
                    mutated = copy.deepcopy(raw)
                    node = mutated
                    for part in leaf[:-1]:
                        node = node[part]
                    node[leaf[-1]] = replacement
                    try:
                        validate(mutated)
                    except verifier_receipts.ReceiptError:
                        continue
                    accepted += 1
        self.assertTrue(accepted == 0, "finite receipt string inventory accepted an opaque same-type value")

    def test_release_and_endpoint_strings_match_actual_producer_relationships(self):
        raw = json.loads((ROOT / "test/fixtures/verifier-matrix-26/release-rpc/locked-builtin/receipt.json").read_text())
        opaque = "opaque_" + secrets.token_hex(24)
        case = verifier_receipts.RELEASE_RPC_CASE_ID
        mutations = {
            "release_node": "lockspire-verifier-" + ("0" if raw["run_id"][0] != "0" else "1") + raw["run_id"][1:12] + "@127.0.0.1",
            "compiled_module_relative_path": f"lib/lockspire-{raw['candidate']['version']}/ebin/{opaque}.beam",
            "process_pid": "9" * 20,
        }
        for field, value in mutations.items():
            mutated = copy.deepcopy(raw)
            mutated["observations"][case][field] = value
            with self.assertRaises(verifier_receipts.ReceiptError):
                verifier_receipts._validate_receipt_structure(mutated)
        for pair in ("locked", "floor"):
            raw = json.loads((ROOT / f"test/fixtures/verifier-matrix-26/endpoints/{pair}-builtin/receipt.json").read_text())
            for value in (opaque, "http://127.0.0.1:1/lockspire/" + opaque):
                mutated = copy.deepcopy(raw)
                for observation in mutated["observations"].values():
                    observation["rejected_audience_uri"] = value
                with self.assertRaises(verifier_receipts.ReceiptError):
                    verifier_receipts._validate_receipt_structure(mutated)

    def _fixture_runner_revision(self) -> str:
        path = ROOT / "test/fixtures/verifier-matrix-26/core/locked-builtin/receipt.json"
        return json.loads(path.read_text(encoding="utf-8"))["runner"]

    def _matrix_copy(self, parent: Path) -> Path:
        source = ROOT / "test" / "fixtures" / "verifier-matrix-26"
        destination = parent / "inputs"
        shutil.copytree(source, destination)
        return destination

    def test_read_only_cli_accepts_portable_26_receipt_fixture(self) -> None:
        import clean_room_verifier_upgrade as source
        artifacts = ROOT / ".artifacts"
        artifacts.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            parent = Path(temporary)
            inputs = self._matrix_copy(parent)
            output = parent / "aggregate.json"
            stdout, stderr = StringIO(), StringIO()
            with redirect_stdout(stdout), redirect_stderr(stderr):
                result = self._fixture_cli(source, ["--pair", "all", "--store", "all", "--group", "all",
                                      "--historical-structure-only", "--validate-receipts", str(inputs),
                                      "--expected-runner-revision", self._fixture_runner_revision(),
                                      "--expected-candidate-source-revision", self._fixture_runner_revision(),
                                      "--aggregate-output", str(output)])
            self.assertEqual(result, 0, "read-only matrix fixture should validate")
            self.assertEqual(stderr.getvalue(), "")
            aggregate = json.loads(output.read_text(encoding="utf-8"))
            self.assertTrue(aggregate["authoritative"] is False and aggregate["runtime_acceptance"] is False,
                            "historical structure corroboration claimed current acceptance")
            self.assertEqual(aggregate["executed_receipt_count"], 26)
            self.assertEqual(aggregate["executed_case_count"], 64)
            self.assertEqual(aggregate["failed_case_count"], 0)
            self.assertNotEqual(aggregate["runner_revision"], aggregate["aggregate_validator_revision"])
            self.assertEqual(len(aggregate["cells"]), 26)

    def test_read_only_cli_rejects_retained_matrix_without_explicit_runner_pin(self) -> None:
        import clean_room_verifier_upgrade as source
        artifacts = ROOT / ".artifacts"
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            parent = Path(temporary)
            inputs = self._matrix_copy(parent)
            output = parent / "aggregate.json"
            with redirect_stdout(StringIO()), redirect_stderr(StringIO()):
                result = self._fixture_cli(source, ["--pair", "all", "--store", "all", "--group", "all",
                                      "--historical-structure-only", "--validate-receipts", str(inputs), "--aggregate-output", str(output)])
            self.assertEqual(result, 1)
            self.assertFalse(output.exists())

    def test_retained_checkout_source_pin_is_independent_of_runner_pin(self) -> None:
        """The caller's explicit candidate owner may differ from this validator's runner."""
        import hashlib
        import clean_room_verifier_upgrade as source
        artifacts = ROOT / ".artifacts"
        expected_runner = self._fixture_runner_revision()
        expected_candidate_source = "9" * 40
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            inputs = self._matrix_copy(Path(temporary))
            for key in verifier_receipts.required_receipt_keys():
                path = source.matrix_receipt_path(inputs, *key)
                receipt = json.loads(path.read_text(encoding="utf-8"))
                candidate = receipt["candidate"]
                candidate["source_revision"] = expected_candidate_source
                proof = {"archive_sha256": candidate["archive_sha256"],
                         "source_revision": candidate["source_revision"],
                         "tree_sha256": candidate["tree_sha256"]}
                candidate["source_proof"] = hashlib.sha256(
                    json.dumps(proof, sort_keys=True, separators=(",", ":")).encode()
                ).hexdigest()
                path.write_text(json.dumps(receipt), encoding="utf-8")
            with redirect_stdout(StringIO()), redirect_stderr(StringIO()):
                result = self._fixture_cli(source, [
                    "--pair", "all", "--store", "all", "--group", "all",
                    "--historical-structure-only", "--validate-receipts", str(inputs),
                    "--expected-runner-revision", expected_runner,
                    "--expected-candidate-source-revision", expected_candidate_source,
                ])
            self.assertEqual(result, 0)

    def test_pair_cli_projects_exact_required_cells_for_each_dependency_pair(self) -> None:
        import clean_room_verifier_upgrade as source
        from client_verifier_delivery_test import ComposedMatrixContracts
        from verifier_owner_fixture import CONTEXT_PINS
        from unittest.mock import patch
        artifacts = ROOT / ".artifacts"
        expected = {"locked": (14, 33), "floor": (12, 31)}
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            locked, floor, expected_runner, candidate = ComposedMatrixContracts()._pair_roots(Path(temporary))
            for pair, inputs in (("locked", locked), ("floor", floor)):
                receipt_count, case_count = expected[pair]
                shutil.rmtree(inputs / "validated")
                with self.subTest(pair=pair), patch.dict(__import__("os").environ, CONTEXT_PINS[str(inputs)]), redirect_stdout(StringIO()), redirect_stderr(StringIO()):
                    result = self._fixture_cli(source, ["--pair", pair, "--store", "all", "--group", "all",
                                          "--validate-receipts", str(inputs),
                                          "--expected-runner-revision", expected_runner,
                                          "--expected-candidate-source-revision", candidate[0]])
                self.assertEqual(result, 0)
                index = json.loads((inputs / "validated" / "index.json").read_text(encoding="utf-8"))
                self.assertEqual(index["executed_receipts"], receipt_count)
                self.assertEqual(index["passed_cases"], case_count)
                self.assertEqual(index["failed_cases"], 0)
                self.assertNotEqual(index["runner_revision"], index["aggregate_validator_revision"])

    def test_pair_cli_rejects_inputs_missing_the_selected_pair(self) -> None:
        import clean_room_verifier_upgrade as source
        artifacts = ROOT / ".artifacts"
        expected_runner = self._fixture_runner_revision()
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            inputs = self._matrix_copy(Path(temporary))
            for scope, pair, store in verifier_receipts.required_receipt_keys():
                if pair == "locked":
                    source.matrix_receipt_path(inputs, scope, pair, store).unlink()
            with redirect_stdout(StringIO()), redirect_stderr(StringIO()):
                result = self._fixture_cli(source, ["--pair", "locked", "--store", "all", "--group", "all",
                                      "--historical-structure-only", "--validate-receipts", str(inputs),
                                      "--expected-runner-revision", expected_runner,
                                      "--expected-candidate-source-revision", expected_runner])
            self.assertEqual(result, 1)

    def test_read_only_cli_rejects_missing_and_substituted_receipts(self) -> None:
        import clean_room_verifier_upgrade as source
        artifacts = ROOT / ".artifacts"
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            parent = Path(temporary)
            inputs = self._matrix_copy(parent)
            missing = inputs / "disclosure" / "locked-delegated" / "failure-receipt.json"
            missing.unlink()
            with redirect_stdout(StringIO()), redirect_stderr(StringIO()):
                result = self._fixture_cli(source, ["--pair", "all", "--store", "all", "--group", "all",
                                      "--historical-structure-only", "--validate-receipts", str(inputs),
                                      "--expected-runner-revision", self._fixture_runner_revision(),
                                      "--expected-candidate-source-revision", self._fixture_runner_revision()])
            self.assertEqual(result, 1)

    def test_read_only_cli_rejects_every_missing_cell_and_identity_substitution(self) -> None:
        import clean_room_verifier_upgrade as source
        artifacts = ROOT / ".artifacts"

        expected_runner = self._fixture_runner_revision()

        def rejected(mutate) -> None:
            with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
                parent = Path(temporary)
                inputs = self._matrix_copy(parent)
                mutate(inputs)
                with redirect_stdout(StringIO()), redirect_stderr(StringIO()):
                    result = self._fixture_cli(source, ["--pair", "all", "--store", "all", "--group", "all",
                                          "--historical-structure-only", "--validate-receipts", str(inputs),
                                          "--expected-runner-revision", expected_runner,
                                          "--expected-candidate-source-revision", expected_runner])
                self.assertEqual(result, 1)

        for key in verifier_receipts.required_receipt_keys():
            scope, pair, store = key
            with self.subTest(missing=key):
                rejected(lambda inputs, k=key: source.matrix_receipt_path(inputs, *k).unlink())

        def mutate_cell(key, field, value):
            def apply(inputs):
                path = source.matrix_receipt_path(inputs, *key)
                receipt = json.loads(path.read_text(encoding="utf-8"))
                receipt[field] = value
                path.write_text(json.dumps(receipt), encoding="utf-8")
            return apply

        wrong_labels = (
            (("core", "locked", "builtin"), "scope", "recovery"),
            (("core", "locked", "builtin"), "pair", "floor"),
            (("core", "locked", "builtin"), "store", "delegated"),
        )
        for key, field, value in wrong_labels:
            with self.subTest(label=(key, field, value)):
                rejected(mutate_cell(key, field, value))

        def mutate_candidate(key, field, value):
            def apply(inputs):
                path = source.matrix_receipt_path(inputs, *key)
                receipt = json.loads(path.read_text(encoding="utf-8"))
                candidate = receipt["candidate"]
                candidate[field] = value
                binding = {"archive_sha256": candidate["archive_sha256"],
                           "source_revision": candidate["source_revision"],
                           "tree_sha256": candidate["tree_sha256"]}
                import hashlib
                candidate["source_proof"] = hashlib.sha256(
                    json.dumps(binding, sort_keys=True, separators=(",", ":")).encode()
                ).hexdigest()
                path.write_text(json.dumps(receipt), encoding="utf-8")
            return apply

        key = ("core", "locked", "builtin")
        for field, value in (("source_revision", "c" * 40), ("archive_sha256", "c" * 64), ("tree_sha256", "c" * 64)):
            with self.subTest(candidate=field):
                rejected(mutate_candidate(key, field, value))
        def mutate_host(key, field, value):
            def apply(inputs):
                path = source.matrix_receipt_path(inputs, *key)
                receipt = json.loads(path.read_text(encoding="utf-8"))
                receipt["host"][field] = value
                path.write_text(json.dumps(receipt), encoding="utf-8")
            return apply

        with self.subTest(host="lock_sha256"):
            rejected(mutate_host(key, "lock_sha256", "c" * 64))
        with self.subTest(host="compiled_candidate_sha256"):
            disclosure_failure = ("disclosure-failure", "locked", "delegated")
            rejected(mutate_host(disclosure_failure, "compiled_candidate_sha256", "c" * 64))

        def duplicate_run_id(inputs):
            first = source.matrix_receipt_path(inputs, "core", "locked", "builtin")
            second = source.matrix_receipt_path(inputs, "core", "floor", "builtin")
            one, two = json.loads(first.read_text()), json.loads(second.read_text())
            two["run_id"] = one["run_id"]
            second.write_text(json.dumps(two))
        rejected(duplicate_run_id)

        def mismatched_disclosure_owner(inputs):
            success = source.matrix_receipt_path(inputs, "disclosure", "locked", "delegated")
            failure = source.matrix_receipt_path(inputs, "disclosure-failure", "locked", "delegated")
            one, two = json.loads(success.read_text()), json.loads(failure.read_text())
            two["host"]["compiled_candidate_sha256"] = "c" * 64
            failure.write_text(json.dumps(two))
        rejected(mismatched_disclosure_owner)
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            parent = Path(temporary)
            inputs = self._matrix_copy(parent)
            path = inputs / "core" / "locked-builtin" / "receipt.json"
            receipt = json.loads(path.read_text(encoding="utf-8"))
            receipt["runner"] = "c" * 40
            path.write_text(json.dumps(receipt), encoding="utf-8")
            with redirect_stdout(StringIO()), redirect_stderr(StringIO()):
                result = self._fixture_cli(source, ["--pair", "all", "--store", "all", "--group", "all",
                                      "--historical-structure-only", "--validate-receipts", str(inputs),
                                      "--expected-runner-revision", expected_runner])
            self.assertEqual(result, 1)

    def test_disclosure_failure_case_maps_to_the_existing_disclosure_directory(self) -> None:
        import clean_room_verifier_upgrade as source
        root = Path(".artifacts/phase178/complete")
        self.assertEqual(
            source.matrix_receipt_path(root, "disclosure-failure", "locked", "delegated"),
            root / "disclosure" / "locked-delegated" / "failure-receipt.json",
        )

    def test_all_matrix_paths_match_the_existing_producer_layout(self) -> None:
        import clean_room_verifier_upgrade as source
        root = Path("/matrix")
        for scope, pair, store in verifier_receipts.required_receipt_keys():
            if scope == "disclosure-failure":
                expected = root / "disclosure" / f"{pair}-{store}" / "failure-receipt.json"
            elif scope == "rollout":
                expected = root / "rollout" / f"{pair}-{store}" / "receipt.json"
            else:
                expected = root / scope / f"{pair}-{store}" / "receipt.json"
            self.assertEqual(source.matrix_receipt_path(root, scope, pair, store), expected)

    def test_read_only_cli_entrypoint_rejects_missing_cell_without_starting_package(self) -> None:
        import clean_room_verifier_upgrade as source
        from unittest.mock import patch
        with __import__("tempfile").TemporaryDirectory() as temporary:
            empty = Path(temporary) / "inputs"
            empty.mkdir()
            output = Path(temporary) / "aggregate.json"
            with patch.object(source, "_complete_matrix", side_effect=AssertionError("package execution forbidden")):
                result = self._fixture_cli(source, ["--pair", "all", "--store", "all", "--group", "all",
                                      "--historical-structure-only", "--validate-receipts", str(empty), "--aggregate-output", str(output)])
            self.assertEqual(result, 1)
            self.assertFalse(output.exists())

    def test_directory_validation_is_read_only_and_rejects_missing_matrix_inputs(self) -> None:
        import clean_room_verifier_upgrade as source
        with __import__("tempfile").TemporaryDirectory() as temporary:
            with self.assertRaises(source.ReceiptError):
                source.validate_matrix_directory(Path(temporary), expected_runner="a" * 40,
                                                 expected_candidate_source="b" * 40)

    def test_owned_listener_gets_server_flag_without_mutating_one_off_environment(self) -> None:
        import clean_room_verifier_upgrade as source
        one_off = {"MIX_ENV": "dev", "CLEAN_ROOM_HTTP_SERVER": "false"}
        listener = source.owned_listener_environment(one_off)
        self.assertEqual(listener["CLEAN_ROOM_HTTP_SERVER"], "true")
        self.assertEqual(one_off["CLEAN_ROOM_HTTP_SERVER"], "false")
        core_source = (ROOT / "scripts" / "acceptance" / "clean_room" / "verifier_core.py").read_text(encoding="utf-8")
        self.assertIn("listener_env = runner.owned_listener_environment(env)", core_source)
        self.assertIn("env=listener_env", core_source)

    def test_required_scope_is_explicit_and_keeps_both_disclosure_receipts(self) -> None:
        required = verifier_receipts.required_receipt_keys()
        self.assertEqual(len(required), 26)
        self.assertIn(("core", "locked", "builtin"), required)
        self.assertIn(("rollout", "floor", "delegated"), required)
        self.assertIn(("legacy-control", "locked", "builtin"), required)
        self.assertIn(("release-rpc", "locked", "builtin"), required)
        self.assertIn(("disclosure", "locked", "delegated"), required)
        self.assertIn(("disclosure-failure", "locked", "delegated"), required)
        self.assertNotIn(("legacy-control", "floor", "delegated"), required)

    def test_aggregate_rejects_missing_duplicate_unknown_and_zero_case_links(self) -> None:
        required = verifier_receipts.required_receipt_keys()
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_complete_matrix([], expected_runner="a" * 40)
        rows = [
            {"scope": scope, "pair": pair, "store": store,
             "run_id": f"{index:032x}", "receipt_sha256": f"{index + 1:064x}",
             "runner_revision": "a" * 40,
             "candidate_source_archive_tree": ["d" * 40, "e" * 64, "f" * 64],
             "host_lock_sha256": "1" * 64, "compiled_candidate_sha256": "2" * 64,
             "executed_count": len(verifier_receipts.expected_case_ids((scope, pair, store))),
             "outcome": "pass",
             "stable_case_ids": verifier_receipts.expected_case_ids((scope, pair, store))}
            for index, (scope, pair, store) in enumerate(required)
        ]
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_matrix_links(rows[:-1], expected_runner="a" * 40)
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_matrix_links(rows + [rows[0]], expected_runner="a" * 40)
        changed = [*rows[:-1], {**rows[-1], "scope": "unknown"}]
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_matrix_links(changed, expected_runner="a" * 40)

    def test_disclosure_success_and_failure_receipts_share_one_owned_run_id(self) -> None:
        required = verifier_receipts.required_receipt_keys()
        rows = [
            {"scope": scope, "pair": pair, "store": store,
             "run_id": f"{index:032x}", "receipt_sha256": f"{index + 1:064x}",
             "runner_revision": "a" * 40,
             "candidate_source_archive_tree": ["d" * 40, "e" * 64, "f" * 64],
             "host_lock_sha256": "1" * 64, "compiled_candidate_sha256": "2" * 64,
             "executed_count": len(verifier_receipts.expected_case_ids((scope, pair, store))),
             "outcome": "pass",
             "stable_case_ids": verifier_receipts.expected_case_ids((scope, pair, store))}
            for index, (scope, pair, store) in enumerate(required)
        ]
        success = next(row for row in rows if (row["scope"], row["pair"]) == ("disclosure", "locked"))
        failure = next(row for row in rows if (row["scope"], row["pair"]) == ("disclosure-failure", "locked"))
        failure["run_id"] = success["run_id"]
        self.assertEqual(len(verifier_receipts.validate_matrix_links(rows, expected_runner="a" * 40)), 26)
        # A shared run is valid only when both receipt siblings bind the same
        # pair, store, candidate package, dependency lock, and compiled code.
        failure["compiled_candidate_sha256"] = "3" * 64
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_matrix_links(rows, expected_runner="a" * 40)
        failure["compiled_candidate_sha256"] = "2" * 64
        failure["host_lock_sha256"] = "4" * 64
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_matrix_links(rows, expected_runner="a" * 40)
        failure["host_lock_sha256"] = "1" * 64
        failure["candidate_source_archive_tree"] = ["c" * 40, "e" * 64, "f" * 64]
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_matrix_links(rows, expected_runner="a" * 40)
        failure["candidate_source_archive_tree"] = ["d" * 40, "e" * 64, "f" * 64]
        failure["pair"] = "floor"
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_matrix_links(rows, expected_runner="a" * 40)
        failure["pair"] = "locked"
        # Runner source identity stays bound to retained receipts; aggregate
        # generation records the validator revision separately.
        import clean_room_verifier_upgrade as source
        aggregate = source._aggregate_document(
            tested_runner="a" * 40, records=rows,
            candidate_identity=("d" * 40, "e" * 64, "f" * 64), validator_revision="b" * 40,
        )
        self.assertEqual(aggregate["runner_revision"], "a" * 40)
        self.assertEqual(aggregate["aggregate_validator_revision"], "b" * 40)
        changed = [*rows[:-1], {**rows[-1], "stable_case_ids": []}]
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_matrix_links(changed, expected_runner="a" * 40)


if __name__ == "__main__":
    unittest.main()
