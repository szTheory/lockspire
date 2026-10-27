"""Actual production wrapper dispatch with real frozen byte/Git validation.

Package rebuild/unpack alone are replaced at their OS boundary: these controls
never build a package, start a database, or produce accepted package receipts.
"""

from __future__ import annotations

import hashlib
import importlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
CLEAN_ROOM = ROOT / "scripts/acceptance/clean_room"
WRAPPER_PATH = "scripts/ci/run_verifier_upgrade_proof.sh"
PHASE_PATH = ".planning/phases/178-packaged-upgrade-proof-delivery-handoff"
sys.path.insert(0, str(CLEAN_ROOM))
delivery = importlib.import_module("verifier_delivery")


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class ActualWrapperFrozenPaths(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="lockspire-wrapper-paths-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.git("init", "-q")
        self.git("config", "user.name", "Lockspire Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        for relative in delivery.COVERED_INPUTS:
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, target)
        self.phase = self.root / PHASE_PATH
        self.phase.mkdir(parents=True, exist_ok=True)
        self.artifacts = self.root / ".artifacts/phase178"
        self.tree = self.artifacts / "fixture-tree"
        self.tree.mkdir(parents=True)
        shutil.copyfile(self.root / "mix.exs", self.tree / "mix.exs")
        self.archive = self.artifacts / "lockspire-0.0.0.tar"
        self.archive.write_bytes(b"OS-boundary archive fixture")
        self.build = {"command": "fixture build", "cwd": "fixture source",
                      "git_archive_exit_code": 0, "package_build_exit_code": 0,
                      "rebuilt_tree_sha256": delivery.package_tree_digest(self.tree)}
        # Keep the complete real bounded input set, immutable Phase175 checks,
        # source-owner checks, actual Git ancestry and commit blob comparisons.
        # Only the prohibited package-producing OS boundary is replaced.
        shim = self.root / "scripts/acceptance/clean_room/verifier_delivery.py"
        shim.write_text(
            "import importlib.util,pathlib,shutil,sys\n"
            f"sys.path.insert(0, {str(CLEAN_ROOM)!r})\n"
            f"spec=importlib.util.spec_from_file_location('actual_delivery', {str(CLEAN_ROOM / 'verifier_delivery.py')!r})\n"
            "real=importlib.util.module_from_spec(spec)\n"
            "spec.loader.exec_module(real)\n"
            f"real.ROOT=pathlib.Path({str(self.root)!r})\n"
            "real._git.__kwdefaults__['cwd']=real.ROOT\n"
            "real.ARTIFACT_DEFAULT=real.ROOT / '.artifacts/phase178'\n"
            f"real._rebuild_source_package=lambda revision: ({self.build['rebuilt_tree_sha256']!r}, {self.build!r})\n"
            f"real.unpack_hex_tarball=lambda archive,target: shutil.copytree(pathlib.Path({str(self.tree)!r}), target)\n"
            "import verifier_receipt_owner as authority\n"
            "def observe(command,*,root,env=None):\n"
            " if command[0]=='elixir':\n"
            "  elixir,otp,_=authority.selected_runtime(root,'local-current')\n"
            "  return (elixir+'\\n'+otp+'\\n').encode()\n"
            " if command[0]=='psql' and command[-1]=='SHOW server_version_num' and env.get('PGOPTIONS')=='-c default_transaction_read_only=on': return b'140017\\n'\n"
            " raise AssertionError('runtime observation boundary changed')\n"
            "authority._observe=observe\n"
            "raise SystemExit(real.main())\n", encoding="utf-8",
        )
        producer = self.root / "scripts/acceptance/clean_room_verifier_upgrade.py"
        producer.write_text(
            "import json,os,pathlib,sys\n"
            f"pathlib.Path({str(self.root / 'producer-reached.json')!r}).write_text(json.dumps({{"
            "'pair':sys.argv[sys.argv.index('--pair')+1],"
            "'runner':os.environ['LOCKSPIRE_EXPECTED_FROZEN_RUNNER_REVISION'],"
            "'source':os.environ['LOCKSPIRE_EXPECTED_CANDIDATE_SOURCE_REVISION'],"
            "'manifest':os.environ['LOCKSPIRE_FROZEN_INPUTS']}))\n"
            "raise SystemExit(7)\n", encoding="utf-8",
        )
        self.git("add", "-f", "--", *delivery.COVERED_INPUTS)
        self.git("commit", "-qm", "bounded runner fixture")
        self.runner = self.git("rev-parse", "HEAD")
        self.owner = {
            "schema": "lockspire-frozen-candidate-owner-v1",
            "source_revision": self.runner, "source_tree": self.git("rev-parse", "HEAD^{tree}"),
            "archive_path": self.archive.relative_to(self.root).as_posix(),
            "archive_sha256": digest(self.archive),
            "extracted_tree_path": self.tree.relative_to(self.root).as_posix(),
            "tree_sha256": delivery.package_tree_digest(self.tree),
            "package_files": [{"path": "mix.exs", "sha256": digest(self.tree / "mix.exs")}],
            "source_build": self.build,
        }
        self.owner["owner_sha256"] = hashlib.sha256(json.dumps(
            self.owner, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        self.manifest = {
            "schema": "lockspire-phase178-frozen-inputs-v1", "frozen_at": "fixture",
            "closure_rule": delivery.CLOSURE_RULE,
            "runner_revision": self.runner, "runner_tree": self.git("rev-parse", "HEAD^{tree}"),
            "candidate_owner": self.owner,
            "covered_inputs": [{"path": path, "sha256": digest(self.root / path)}
                               for path in delivery.COVERED_INPUTS],
        }
        self.manifest_path = self.phase / "178-FROZEN-INPUTS.json"
        self.write_manifest()

    def git(self, *args: str) -> str:
        result = subprocess.run(["git", *args], cwd=self.root, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, check=False, timeout=15)
        self.assertTrue(result.returncode == 0, "fixture Git command failed")
        return result.stdout.decode("ascii").strip()

    def write_manifest(self) -> None:
        self.manifest_path.parent.mkdir(parents=True, exist_ok=True)
        self.manifest_path.write_text(json.dumps(self.manifest), encoding="utf-8")

    def invoke(self, pair: str, path: str, *, extra: tuple[str, ...] = (),
               omit: str | None = None) -> subprocess.CompletedProcess:
        pins = {
            "--expected-runner": self.runner, "--expected-candidate-source": self.runner,
            "--expected-archive-sha256": self.owner["archive_sha256"],
            "--expected-tree-sha256": self.owner["tree_sha256"],
            "--expected-manifest-sha256": digest(self.manifest_path),
        }
        arguments = ["bash", str(self.root / WRAPPER_PATH), "--pair", pair, "--receipt-dir", path]
        for flag, value in pins.items():
            if flag != omit:
                arguments.extend([flag, value])
        environment = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
        environment.pop("LOCKSPIRE_FROZEN_INPUTS", None)
        result = subprocess.run(arguments + list(extra), cwd=self.root, env=environment,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20)
        return result

    def assert_reached(self, pair: str, path: str, **kwargs) -> None:
        result = self.invoke(pair, path, **kwargs)
        marker = self.root / "producer-reached.json"
        self.assertTrue(marker.is_file(), "authorized path never reached safe fake producer")
        self.assertTrue(result.returncode == 1, "intentional fake producer failure was not preserved")
        observed = json.loads(marker.read_text(encoding="utf-8"))
        self.assertTrue(observed["pair"] == pair, "producer pair changed")
        self.assertTrue(observed["runner"] == self.runner and observed["source"] == self.runner,
                        "preserved frozen pins were restamped at later checkout")
        self.assertTrue(observed["manifest"] == str(self.manifest_path), "selected manifest changed")
        self.assertTrue(not (self.root / path / "validated").exists(), "fake producer created accepted receipts")

    def test_final_locked_reaches_safe_producer_through_real_validator(self) -> None:
        self.assert_reached("locked", ".artifacts/phase178/final-locked")

    def test_final_floor_reaches_safe_producer_through_real_validator(self) -> None:
        self.assert_reached("floor", ".artifacts/phase178/final-floor")

    def test_ci_uses_separate_job_manifest_without_overwriting_retained_owner(self) -> None:
        canonical = self.manifest_path
        original = canonical.read_bytes()
        selected = ".artifacts/phase178/ci-candidate/178-FROZEN-INPUTS.json"
        self.manifest_path = self.root / selected
        self.write_manifest()
        self.assert_reached("locked", ".artifacts/phase178/ci-locked", extra=("--frozen-manifest", selected))
        self.assertTrue(canonical.read_bytes() == original, "retained canonical owner was overwritten")

    def test_later_metadata_commit_keeps_archived_runner_pin(self) -> None:
        (self.root / ".planning/fixture-metadata.txt").write_text("later observation\n", encoding="ascii")
        self.git("add", ".planning/fixture-metadata.txt")
        self.git("commit", "-qm", "later metadata")
        self.assertTrue(self.git("rev-parse", "HEAD") != self.runner, "fixture checkout did not advance")
        self.assert_reached("locked", ".artifacts/phase178/final-locked")

    def test_synthetic_merge_checkout_preserves_pinned_covered_bytes(self) -> None:
        self.git("checkout", "-qb", "fixture-side", self.runner)
        (self.root / ".planning/fixture-side-metadata.txt").write_text("side metadata\n", encoding="ascii")
        self.git("add", ".planning/fixture-side-metadata.txt")
        self.git("commit", "-qm", "side metadata")
        side = self.git("rev-parse", "HEAD")
        self.git("checkout", "--detach", self.runner)
        (self.root / ".planning/fixture-main-metadata.txt").write_text("main metadata\n", encoding="ascii")
        self.git("add", ".planning/fixture-main-metadata.txt")
        self.git("commit", "-qm", "main metadata")
        self.git("merge", "--no-ff", "-m", "synthetic checkout", side)
        self.assert_reached("floor", ".artifacts/phase178/final-floor")

    def test_covered_source_change_is_rejected_before_producer_or_receipt_mutation(self) -> None:
        with (self.root / "mix.exs").open("a", encoding="ascii") as output:
            output.write("\n# changed covered source\n")
        self.git("commit", "-qam", "covered change")
        result = self.invoke("locked", ".artifacts/phase178/final-locked")
        self.assertTrue(result.returncode == 2, "covered checkout change was accepted")
        self.assertFalse((self.root / "producer-reached.json").exists(), "producer started before relation validation")
        self.assertFalse((self.artifacts / "final-locked").exists(), "receipt mutated before relation validation")

    def test_wrong_paths_and_symlink_ancestors_are_rejected(self) -> None:
        for path in (".artifacts/phase178/final-floor", ".artifacts/phase178/final-locked-extra",
                     ".artifacts/phase178/../final-locked", ".artifacts/phase178/arbitrary"):
            result = self.invoke("locked", path)
            self.assertTrue(result.returncode == 2, "wrong or arbitrary receipt path was accepted")
        (self.artifacts / "final-locked").symlink_to(self.tree, target_is_directory=True)
        self.assertTrue(self.invoke("locked", ".artifacts/phase178/final-locked").returncode == 2,
                        "symlink receipt path was accepted")
        self.assertFalse((self.root / "producer-reached.json").exists(), "unsafe path reached producer")

    def test_each_independent_pin_is_mandatory(self) -> None:
        for flag in ("--expected-runner", "--expected-candidate-source", "--expected-archive-sha256",
                     "--expected-tree-sha256", "--expected-manifest-sha256"):
            result = self.invoke("locked", ".artifacts/phase178/final-locked", omit=flag)
            self.assertTrue(result.returncode == 2, "missing independent caller pin was accepted")
        self.assertFalse((self.root / "producer-reached.json").exists(), "missing pins reached producer")

    def test_mismatched_independent_runner_pin_is_rejected_by_real_consumer(self) -> None:
        result = self.invoke("locked", ".artifacts/phase178/final-locked",
                             extra=("--expected-runner", "a" * 40))
        self.assertTrue(result.returncode == 2, "mismatched independent runner pin was accepted")
        self.assertFalse((self.root / "producer-reached.json").exists(), "wrong pin reached producer")

    def test_stale_final_path_preserves_existing_bytes(self) -> None:
        target = self.artifacts / "final-locked"
        target.mkdir()
        marker = target / "preserve"
        marker.write_bytes(b"existing custody")
        result = self.invoke("locked", ".artifacts/phase178/final-locked")
        self.assertTrue(result.returncode == 2, "stale final receipt root was accepted")
        self.assertTrue(marker.read_bytes() == b"existing custody", "stale receipt bytes changed")

    def test_job_manifest_symlink_ancestor_is_rejected(self) -> None:
        target = self.artifacts / "manifest-target"
        target.mkdir()
        shutil.copyfile(self.manifest_path, target / "178-FROZEN-INPUTS.json")
        (self.artifacts / "ci-candidate").symlink_to(target, target_is_directory=True)
        result = self.invoke("locked", ".artifacts/phase178/ci-locked", extra=(
            "--frozen-manifest", ".artifacts/phase178/ci-candidate/178-FROZEN-INPUTS.json"))
        self.assertTrue(result.returncode == 2, "manifest symlink ancestor was accepted")
        self.assertFalse((self.root / "producer-reached.json").exists(), "unsafe manifest reached producer")


if __name__ == "__main__":
    unittest.main()
