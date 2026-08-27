---
phase: 137-ci-conformance-and-release-proof
reviewed: 2026-08-27T22:47:53Z
depth: standard
files_reviewed: 44
files_reviewed_list:
  - .github/workflows/ci.yml
  - .github/workflows/oidf-conformance.yml
  - .github/workflows/release.yml
  - .sobelow-conf
  - docs/maintainer-conformance.md
  - docs/maintainer-release.md
  - lib/mix/tasks/lockspire.oidf_conformance.ex
  - mix.exs
  - scripts/acceptance/clean_room/build_provider.py
  - scripts/acceptance/clean_room/package_input.py
  - scripts/acceptance/clean_room_saas_journey.py
  - scripts/acceptance/run_clean_room_saas_journey.sh
  - scripts/ci/aggregate_coverage.sh
  - scripts/ci/check_architecture_topology.sh
  - scripts/ci/check_dependency_truth.sh
  - scripts/ci/check_sobelow_routers.sh
  - scripts/ci/run_test_matrix.sh
  - scripts/conformance/build_redacted_evidence.py
  - scripts/conformance/oidf-suite-lock.json
  - scripts/conformance/oidf_inputs.py
  - scripts/conformance/prepare_oidf_suite.sh
  - scripts/conformance/run_fapi2_suite.sh
  - scripts/conformance/run_oidf_profile.sh
  - scripts/conformance/run_phase37_suite.sh
  - scripts/publish/publish_hex_idempotently.sh
  - scripts/publish/release_artifact.py
  - scripts/publish/verify_install_truth.sh
  - test/integration/install_generator_test.exs
  - test/lockspire/ci_coverage_aggregation_contract_test.exs
  - test/lockspire/ci_security_dependency_contract_test.exs
  - test/lockspire/ci_workflow_evidence_contract_test.exs
  - test/lockspire/clean_room_release_source_contract_test.exs
  - test/lockspire/conformance_immutable_inputs_contract_test.exs
  - test/lockspire/conformance_redacted_evidence_contract_test.exs
  - test/lockspire/conformance_workflow_contract_test.exs
  - test/lockspire/coverage/integration_surface_behavior_test.exs
  - test/lockspire/coverage/protocol_behavior_test.exs
  - test/lockspire/coverage/storage_operator_behavior_test.exs
  - test/lockspire/coverage_baseline_contract_test.exs
  - test/lockspire/publish_verification_test.exs
  - test/lockspire/release_artifact_chain_contract_test.exs
  - test/lockspire/release_workflow_artifact_contract_test.exs
  - test/mix/tasks/lockspire/oidf_conformance_test.exs
  - test/support/lockspire/release_proof/workflow_assertions.ex
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 137: Code Review Report

**Reviewed:** 2026-08-27T22:47:53Z
**Depth:** standard
**Files Reviewed:** 44
**Status:** issues_found

## Summary

The coverage, router scanning, immutable-input validation, clean-room source selection, and bounded-receipt code were reviewed alongside their workflows and contract tests. Shell syntax, Python compilation, and the repository workflow linter complete successfully. Two release-readiness claims are nevertheless unsound: supplemental conformance never executes a test plan, and the protected release path does not actually publish the clean-room-proven tarball.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Supplemental conformance jobs can report success without running any OIDF plan

**Classification:** BLOCKER

**File:** `scripts/conformance/run_oidf_profile.sh:44-48`

**Issue:** The runner downloads and checksum-validates inputs, starts Docker Compose, then assigns `passed`/`success` and exits. It never invokes the pinned `scripts/run-test-plan.py`, `scripts/conformance.py`, or any other test-plan command. Consequently both scheduled workflow lanes upload a receipt saying `success` after containers merely start. This is false conformance evidence and defeats the stated supplemental proof goal.

**Fix:** After Compose readiness is established, invoke the pinned suite runner against the requested JSON plan and make its exit status control `status`/`classification`. Preserve only a redacted, allowlisted summary; distinguish a suite assertion failure from setup/runner failure. Add an execution-level test that substitutes a failing runner and proves the shell command returns non-zero with a `suite_failure` receipt, plus a success fixture that proves the plan runner was invoked.

### CR-02: The Hex publish operation rebuilds instead of uploading the tar that passed clean-room proof

**Classification:** BLOCKER

**File:** `scripts/publish/publish_hex_idempotently.sh:53-60`

**Issue:** The script verifies a separately built tar with `cmp`, but then calls `mix hex.publish --yes`, which builds its own package internally rather than consuming `$package_tar`. A build can vary between the prepublish job, the comparison build, and the publish task (timestamps, tool behavior, or package-task changes). A checksum mismatch is only detected after the immutable public release has been uploaded, so the claimed prepublication exact-artifact proof is not real.

**Fix:** Publish the already verified tar through an upload mechanism that accepts the artifact bytes directly, or use a Hex/Mix API path that exposes the exact archive passed to the registry and verify that payload before sending it. If the supported Hex tooling cannot publish a supplied tar, do not describe this as a single-artifact chain; redesign the trusted job so the byte-producing build and upload are one verifiable operation and block publication whenever the outgoing checksum cannot be proven equal to the manifest beforehand. Add an integration/command-level test that proves the publish command receives the manifest-bound tar rather than merely rebuilding from the checkout.

---

_Reviewed: 2026-08-27T22:47:53Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
