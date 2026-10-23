---
phase: 169-install-and-upgrade-convergence
fixed_at: 2026-10-23T23:02:41Z
review_path: .planning/phases/169-install-and-upgrade-convergence/169-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 169: Code Review Fix Report

**Fixed at:** 2026-10-23T23:02:41Z  
**Source review:** .planning/phases/169-install-and-upgrade-convergence/169-REVIEW.md  
**Iteration:** 1

**Summary:**
- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: A file mutation can become unjournaled before a crash

**Status:** fixed: requires human verification  
**Files modified:** lib/lockspire/install/file_transaction.ex, test/lockspire/install/file_transaction_test.exs  
**Commit:** 8d708bb1  
**Applied fix:** Persist a pending intent before each target mutation, with a safe preimage backup for updates. Recovery reconciles the pending intent against target and backup checksums, restores or removes only bytes matching the transaction, and preserves changed competing bytes. Journal replacements write and sync a same-filesystem temporary file before atomic rename. Existing journals without pending remain readable.

### WR-01: Recovery retries rollback after rollback already completed

**Status:** fixed: requires human verification  
**Files modified:** lib/lockspire/install/file_transaction.ex, test/lockspire/install/file_transaction_test.exs  
**Commit:** 8d708bb1  
**Applied fix:** Persist terminal rolled_back with an empty committed list only after rollback completes. Recovery seeing that terminal state skips rollback and finishes cleanup. Create and update rollback operations also treat already-restored or already-removed targets as complete, so interruption during rollback remains retryable.

The two fixes share the journal state transition and were committed together. Recovery tests cover interruption after a target write and before completion journaling, interruption before intent-journal replacement, a terminal rollback marker with the older non-empty committed list, legacy journals without the new fields, created and updated policy/helper artifacts, and refusal to remove competing host bytes.

## Verification

Verification ran in the main checkout at source revision 8d708bb1.

- ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/install/file_transaction_test.exs — 14 passed.
- ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 LOCKSPIRE_TEST_DB_NAME=lockspire_169_reviewfix HEX_HOME=/tmp/lockspire-169-reviewfix-hex asdf exec mix test test/lockspire/install/file_transaction_test.exs test/integration/install_upgrade_test.exs test/integration/install_generator_test.exs — 45 passed. The disposable database was initialized with mix test.setup under the same environment.
- mix format --check-formatted lib/lockspire/install/file_transaction.ex test/lockspire/install/file_transaction_test.exs — passed.
- git diff --check — passed before commit.

The test-only failure hooks simulate each interruption boundary; they do not prove behavior under power loss. Journal file contents are synced before rename, but the containing directory is not synced. No claim is made about hostile same-user ancestor replacement or simultaneous writers. Existing compiler warnings were present; no unrelated warning cleanup was attempted. The full suite was not rerun.

---

_Fixed: 2026-10-23T23:02:41Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_

