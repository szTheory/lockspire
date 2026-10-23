---
phase: 169-install-and-upgrade-convergence
reviewed: 2026-10-23T23:04:36Z
depth: standard
files_reviewed: 41
files_reviewed_list:
  - README.md
  - docs/adoption-demo.md
  - docs/install-and-onboard.md
  - docs/operator-admin.md
  - docs/supported-surface.md
  - docs/upgrading/host-admin-integration.md
  - examples/adoption_demo/lib/adoption_demo_web/operator_authorization.ex
  - examples/adoption_demo/lib/adoption_demo_web/plugs/require_operator.ex
  - examples/adoption_demo/lib/adoption_demo_web/router.ex
  - lib/lockspire/generators/install.ex
  - lib/lockspire/generators/templates.ex
  - lib/lockspire/install/file_transaction.ex
  - lib/lockspire/install/operation_plan.ex
  - lib/lockspire/install/verify.ex
  - lib/lockspire/web/admin_routes.ex
  - lib/mix/tasks/lockspire.upgrade.ex
  - lib/mix/tasks/lockspire.verify.ex
  - mix.exs
  - priv/templates/lockspire.install/operator_authorization.ex
  - priv/templates/lockspire.install/router.ex
  - scripts/acceptance/clean_room/build_provider.py
  - test/clean_room/provider_host/lib/clean_room_provider_web/operator_authorization.ex
  - test/clean_room/provider_host/lib/clean_room_provider_web/router_patch.exs
  - test/integration/install_admin_integration_test.exs
  - test/integration/install_generator_test.exs
  - test/integration/install_upgrade_test.exs
  - test/lockspire/adoption_demo_admin_integration_test.exs
  - test/lockspire/adoption_demo_docker_contract_test.exs
  - test/lockspire/clean_room_admin_integration_test.exs
  - test/lockspire/clean_room_release_source_contract_test.exs
  - test/lockspire/install/file_transaction_test.exs
  - test/lockspire/install/verify_test.exs
  - test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs
  - test/mix/tasks/lockspire_verify_test.exs
  - test/support/fixtures/install_upgrade/README.md
  - test/support/fixtures/install_upgrade/v1_45_forward_router.ex.eex
  - test/support/generated_host_app_web/operator_authorization.ex
  - test/support/generated_host_app_web/router.ex
  - test/support/generated_host_app_web/router/lockspire.ex
  - test/support/lockspire/release_proof/documentation_assertions.ex
  - test/support/lockspire/web/admin_proof/route_assertions.ex
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 169: Code Review Report

**Reviewed:** 2026-10-23T23:04:36Z
**Depth:** standard
**Files Reviewed:** 41
**Status:** issues_found

## Summary

Re-reviewed the 41-file Phase 169 scope after fix commit `8d708bb1`. The two previously reported journal ordering and rollback retry defects are closed by the pending-intent journal and terminal cleanup state. A remaining write failure window can leave a partial newly-created destination that recovery cannot safely identify as transaction-owned; interrupted update staging can also leave an untracked temporary file beside the destination.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-02: A partial create leaves recovery permanently blocked

**Classification:** BLOCKER  
**File:** `lib/lockspire/install/file_transaction.ex:449-453, 501-519`
**Issue:** The create path writes directly to the final target with `File.write/3`. If that write is interrupted or fails after creating/writing only part of the file (for example, an I/O or space error), the pending intent remains durable but the target checksum does not match the intended artifact. Recovery's `"created"` branch treats any existing non-matching bytes as a competing host change and refuses rollback. The incomplete generated file then remains in place and subsequent install/upgrade attempts stay blocked in `recovery_required`.
**Fix:** Write creates to an exclusive temporary file in the destination directory, verify its checksum, then rename it to the absent target. On recovery, a missing target is already a completed rollback; clean up only transaction-owned temporary files recorded in the intent (or use a deterministic transaction-specific temporary name and checksum validation).

## Warnings

### WR-02: An interrupted update can leave an untracked sibling temporary file

**Classification:** WARNING  
**File:** `lib/lockspire/install/file_transaction.ex:457-472, 667-679`
**Issue:** Updates stage replacement bytes in a `.lockspire-tx-*` file beside the destination and remove it in an `after` block. If the process stops after the temporary file is written but before `File.rename/2` or the `after` cleanup runs, recovery sees the old target and correctly considers rollback complete, but `cleanup/1` only removes the transaction directory and journal. The sibling temporary file is left in the host source tree after recovery.
**Fix:** Include the update temporary path in the pending intent and have recovery remove it only after verifying it is a regular file with the staged checksum, or create it under the transaction directory when same-filesystem rename is guaranteed.

---

_Reviewed: 2026-10-23T23:04:36Z_
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
