---
phase: 169-install-and-upgrade-convergence
reviewed: 2026-10-23T23:11:53Z
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
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 169: Code Review Report

**Reviewed:** 2026-10-23T23:11:53Z  
**Depth:** standard  
**Files Reviewed:** 41  
**Status:** issues_found

## Summary

Re-reviewed the unchanged 41-file Phase 169 scope, focusing on the transaction recovery and publication changes in `8d708bb1`, `aa758972`, and `827b24b7`. The four prior findings are closed: write-ahead intent and terminal rollback make recovery retryable, creates publish by exclusive hard link with staged inode proof, and updates/restores publish by renaming tracked transaction files. One process-interruption path still leaves an untracked transaction directory with no journal to recover or clean it.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: An interruption before journal publication leaves an undiscoverable transaction directory

**Classification:** WARNING  
**File:** `lib/lockspire/install/file_transaction.ex:284-313, 694-706`
**Issue:** `stage/2` creates `.lockspire/.install-tx-*` and writes staged files before the first durable journal is published. If the process stops during staging or at the existing `:after_staging` interruption point, `apply/3` returns without cleanup and no journal exists; subsequent `recover/1` treats the project as clean, so the orphaned staged files persist. A similar orphan can remain if interruption occurs after `cleanup/1` removes the journal at line 703 but before it removes the transaction directory at line 704. Repeated interruptions can accumulate stale transaction directories in the host project.
**Fix:** Make the staging directory discoverable before writing staged artifacts (for example, publish an initial valid journal with no committed or pending mutations, then update it once staging completes), so recovery can remove incomplete staging. For the post-commit cleanup window, preserve a durable completion/cleanup record until the transaction directory is removed, then remove that record; recovery should recognize the completed state and finish cleanup without attempting rollback.

---

_Reviewed: 2026-10-23T23:11:53Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
