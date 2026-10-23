---
phase: 169-install-and-upgrade-convergence
fixed_at: 2026-10-23T23:17:36Z
review_path: .planning/phases/169-install-and-upgrade-convergence/169-REVIEW.md
iteration: 3
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 169: Code Review Fix Report

**Fixed at:** 2026-10-23T23:17:36Z
**Source review:** .planning/phases/169-install-and-upgrade-convergence/169-REVIEW.md
**Iteration:** 3

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: A file mutation can become unjournaled before a crash

**Status:** fixed; confirmed closed by the iteration 2 review
**Files modified:** lib/lockspire/install/file_transaction.ex, test/lockspire/install/file_transaction_test.exs
**Commit:** 8d708bb1
**Applied fix:** A pending intent is persisted before each target mutation. Recovery reconciles the intent against target and backup checksums, restoring or removing only transaction-owned bytes. Journal replacement writes and syncs a same-filesystem temporary file before atomic rename. Existing journals without pending remain readable.

### WR-01: Recovery retries rollback after rollback already completed

**Status:** fixed; confirmed closed by the iteration 2 review
**Files modified:** lib/lockspire/install/file_transaction.ex, test/lockspire/install/file_transaction_test.exs
**Commit:** 8d708bb1
**Applied fix:** Rollback writes terminal rolled_back state with an empty committed list only after restoration completes. Recovery seeing that state skips rollback and finishes cleanup; create and update rollback also treat already-restored or removed targets as complete.

### CR-02: A partial create leaves recovery permanently blocked

**Status:** fixed; confirmed closed by the iteration 3 review
**Files modified:** lib/lockspire/install/file_transaction.ex, test/lockspire/install/file_transaction_test.exs
**Commits:** aa758972, 827b24b7
**Applied fix:** Creates publish the checksum-verified staged file with an exclusive hard link, so the final path is absent or complete. Recovery compares the destination and staged file device/inode identity before removing a created file, preserving even an identical-byte competing file. If the filesystem cannot provide usable identity, creation refuses before publication.

### WR-02: An interrupted update can leave an untracked sibling temporary file

**Status:** fixed; confirmed closed by the iteration 3 review
**Files modified:** lib/lockspire/install/file_transaction.ex, test/lockspire/install/file_transaction_test.exs
**Commit:** aa758972
**Applied fix:** Updates atomically rename the staged transaction file into the destination. Rollback atomically renames its tracked backup into place. Neither operation creates a temporary file beside host source files.

### WR-03: An interruption before journal publication leaves an undiscoverable transaction directory

**Status:** fixed; independent source audit pending
**Files modified:** lib/lockspire/install/file_transaction.ex, test/lockspire/install/file_transaction_test.exs
**Commits:** 1049556c, 04438699
**Review ID note:** The iteration 3 review reused WR-01 for this new issue. This report aliases it as WR-03 to distinguish it from the earlier terminal rollback finding.
**Applied fix:** Publish a valid empty journal before creating the transaction directory, then atomically record staged artifact paths. Before removing staging, persist terminal committed or rolled_back state. Cleanup removes the transaction directory before its journal; recovery treats either terminal state as cleanup-only. When the initial atomic journal replacement is interrupted before publication, a fixed, narrowly named temporary file is detected by read-only status and safely removed by recovery.

The findings share the transaction journal and cleanup lifecycle. CR-01/WR-01 were committed together; CR-02/WR-02 share tracked-file publication; WR-03 makes staging and final cleanup discoverable.

## Verification

Verification ran in the main checkout at source revision 04438699.

- Iteration 1: File transaction tests passed 14/14.
- Iteration 1: Transaction, upgrade, and generator selectors passed 45/45 with a fresh disposable database.
- Iteration 2: File transaction tests passed 18/18.
- Iteration 2: Transaction, upgrade, and generator selectors passed 49/49 with a fresh disposable database.
- Iteration 3: ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/install/file_transaction_test.exs — 24 passed.
- Iteration 3: ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 LOCKSPIRE_TEST_DB_NAME=lockspire_169_reviewfix_iter3b HEX_HOME=/tmp/lockspire-169-reviewfix-hex asdf exec mix test test/lockspire/install/file_transaction_test.exs test/integration/install_upgrade_test.exs test/integration/install_generator_test.exs — 55 passed. The disposable database was initialized with mix test.setup under the same environment.
- mix format --check-formatted lib/lockspire/install/file_transaction.ex test/lockspire/install/file_transaction_test.exs — passed.
- git diff --check — passed before the iteration 3 commit.

Regression coverage includes interruption before initial journal publication, after empty-journal publication, after staging, ordinary staging failure cleanup, after committed cleanup, and after rolled-back cleanup; it also verifies read-only status and legacy terminal committed recovery. Test hooks model process interruption boundaries, not power loss. Journal file contents are synced before rename, but the containing directory is not synced. Hard-link publication and update/restore rename fail safely when unsupported or crossing filesystems; there is no copy or overwrite fallback. No claim is made about hostile same-user ancestor replacement or simultaneous writers. Existing compiler warnings were present; the full suite was not rerun.

---

_Fixed: 2026-10-23T23:17:36Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
