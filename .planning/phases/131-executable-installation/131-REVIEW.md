---
phase: 131-executable-installation
reviewed: 2026-08-26T22:36:03Z
depth: standard
files_reviewed: 31
files_reviewed_list:
  - lib/lockspire/generators/install.ex
  - lib/lockspire/generators/templates.ex
  - lib/lockspire/install/file_transaction.ex
  - lib/lockspire/install/manifest.ex
  - lib/lockspire/install/migrations.ex
  - lib/lockspire/install/operation_plan.ex
  - lib/lockspire/install/verify.ex
  - lib/lockspire/web/consent_context.ex
  - lib/lockspire/web/live/consent_live.ex
  - lib/mix/tasks/lockspire.install.ex
  - lib/mix/tasks/lockspire.upgrade.ex
  - priv/templates/lockspire.install/account_resolver.ex
  - priv/templates/lockspire.install/config.exs
  - priv/templates/lockspire.install/consent_live.ex
  - priv/templates/lockspire.install/default_smoke_e2e_test.exs
  - priv/templates/lockspire.install/fapi_smoke_e2e_test.exs
  - priv/templates/lockspire.install/router.ex
  - test/integration/install_generator_test.exs
  - test/integration/install_upgrade_test.exs
  - test/integration/phase57_rar_introspection_verification_e2e_test.exs
  - test/integration/phase6_onboarding_e2e_test.exs
  - test/lockspire/install/file_transaction_test.exs
  - test/lockspire/install/migrations_test.exs
  - test/lockspire/install/verify_test.exs
  - test/lockspire/web/consent_context_test.exs
  - test/mix/tasks/lockspire_verify_test.exs
  - test/support/generated_host_app_web/live/lockspire_consent_live.ex
  - test/support/generated_host_app_web/plugs/require_operator.ex
  - test/support/generated_host_app_web/router.ex
  - test/support/generated_host_app_web/router/lockspire.ex
  - docs/install-and-onboard.md
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 131: Code Review Report

**Reviewed:** 2026-08-26T22:36:03Z
**Depth:** standard
**Files Reviewed:** 31
**Status:** issues_found

## Summary

The review fixes correctly narrow admin verification to route shape rather than falsely certifying host authorization; preserve the FAPI opt-in across upgrade; honor configured logout paths; randomize generated FAPI request values; and integrate a staged journaled artifact transaction with manifest-last ordering. The focused regression command passed: 48 tests, 0 failures. Two recovery/path-safety gaps remain in the new transaction layer, so this report is not clean.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Ordinary rollback leaves a live journal that makes the next install unrecoverable

**File:** `lib/lockspire/install/file_transaction.ex:225-246,329-361,422-429`
**Issue:** On an ordinary commit error, `commit/1` successfully calls `rollback(current)` but returns the error without cleaning or marking the journal. The journal still records the now-reverted `current.committed` entries. The next `apply/3` calls `recover/1`, which attempts to roll back those entries a second time; a reverted `created` artifact is absent, so `checksum_file?/2` fails and recovery returns `:created_target_changed`. A transient manifest/managed-file write failure can therefore permanently block retries despite the claimed ordinary-failure rollback guarantee.

**Fix:** Distinguish normal rollback from simulated interruption. After a successful ordinary rollback, durably mark the journal `rolled_back` and clean it (and staging) before returning the original error; retain the journal only when rollback itself fails or an interruption is intentionally simulated. Add a failure-injection hook that returns an ordinary write error after at least one committed migration/update, then assert the preimage tree is restored, the journal is absent (or explicitly terminal), and a retry succeeds.

### WR-02: Recovery follows a symlinked `.lockspire` ancestor before checking containment

**File:** `lib/lockspire/install/file_transaction.ex:73-109,422-429`
**Issue:** `recover/1` immediately `File.lstat`s and later reads `Path.join(project_root, ".lockspire/install_transaction.json")` without first running `safe_ancestry/3` on the journal path. `lstat` does not protect against symlinked ancestors. If `project_root/.lockspire` is a symlink to another directory containing a syntactically valid transaction journal, recovery accepts its nominal paths, then `cleanup/1` removes the externally located journal and may recursively remove its transaction directory through the symlink. This violates the documented refusal of symlinked journal/ancestor paths and can delete files outside the project tree.

**Fix:** Before every recovery read, require `safe_ancestry(project_root, journal, allow_missing?: true)` and revalidate the journal/staging ancestry immediately before cleanup. Reject an ancestor symlink before parsing any journal. Add an adversarial test that symlinks `<root>/.lockspire` to an outside directory containing a valid journal and sentinel transaction directory; `recover/1` must refuse and leave both outside files byte-identical. Keep the documented same-user swap caveat, but do not allow a pre-existing ancestor symlink to bypass the non-racy checks.

---

_Reviewed: 2026-08-26T22:36:03Z_
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
