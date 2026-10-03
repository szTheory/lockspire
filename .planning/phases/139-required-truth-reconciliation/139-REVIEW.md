---
phase: 139-required-truth-reconciliation
reviewed: 2026-10-03T20:26:26Z
depth: standard
files_reviewed: 31
files_reviewed_list:
  - .github/workflows/ci.yml
  - .release-please-manifest.json
  - CHANGELOG.md
  - docs/lockspire-milestone-roadmap-ratchet-prompt.txt
  - mix.exs
  - scripts/maintainer/baseline_inventory.sh
  - scripts/maintainer/finalize_phase_139_acceptance.sh
  - scripts/maintainer/repo_hygiene_check.sh
  - scripts/maintainer/run_lockspire_phase_finalizer.sh
  - scripts/maintainer/supersede_phase_139_host_receipt.sh
  - test/integration/phase133_harness_test.exs
  - test/integration/phase133_provider_install_test.exs
  - test/lockspire/admin/keys_test.exs
  - test/lockspire/audit/audit_writer_test.exs
  - test/lockspire/protocol/authorization_request_test.exs
  - test/lockspire/protocol/pushed_authorization_request_test.exs
  - test/lockspire/quality/phase_138_prohibition_consistency_test.exs
  - test/lockspire/quality/phase_139_planning_consistency_test.exs
  - test/lockspire/release/repository_hygiene_contract_test.exs
  - test/lockspire/release_readiness_contract_test.exs
  - test/lockspire/web/authorize_controller_test.exs
  - test/lockspire/web/live/admin/clients_live_test.exs
  - test/lockspire/web/live/admin/policies_live/dpop_test.exs
  - test/lockspire/web/live/admin/policies_live/par_test.exs
  - test/lockspire/web/live/admin/policies_live/security_profile_test.exs
  - test/support/lockspire/release_proof/package_assertions.ex
  - test/support/lockspire/release_proof/workflow_assertions.ex
  - test/support/quality_baseline.ex
  - test/support/seeding_helpers.ex
  - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs
  - tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 139: Code Review Report

**Reviewed:** 2026-10-03T20:26:26Z
**Depth:** standard
**Files Reviewed:** 31
**Status:** issues_found

## Summary

Reviewed the Phase 139 source scope, including the acceptance and inventory shell workflows, lifecycle receipt helper, CI changes, release metadata, and related test/support changes. The exact-SHA acceptance path can miss leftover adoption-demo Docker volumes and report a clean result, so its hygiene receipt can overstate the observed state.

## Critical Issues

### CR-01: [BLOCKER] Exact-SHA acceptance misses active-project volumes

**File:** `scripts/maintainer/repo_hygiene_check.sh:250`
**Issue:** Docker's `volume ls --filter name=...` matches all or part of a volume name; it does not interpret the supplied value as a regular expression. The anchored expression `^${project}_(db_data|deps_volume|build_volume)$` therefore does not match volumes named, for example, `lockspire-adoption-demo_db_data`. The exact acceptance path sees an empty result, records `PASS` at line 270, and can emit a passing receipt despite project volumes remaining. The local hygiene path repeats the same ineffective filter at line 890.
**Fix:** List names without a name filter, then compare each result against the three exact allowlisted names (for example, with `case "$volume" in "${project}_db_data"|"${project}_deps_volume"|"${project}_build_volume") ...`). Use the same exact comparison in both hygiene paths.

## Warnings

## Info

---

_Reviewed: 2026-10-03T20:26:26Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
