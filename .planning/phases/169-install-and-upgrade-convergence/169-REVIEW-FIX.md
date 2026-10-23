---
phase: 169-install-and-upgrade-convergence
fixed_at: 2026-10-23T23:10:19Z
review_path: .planning/phases/169-install-and-upgrade-convergence/169-REVIEW.md
iteration: 2
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 169: Code Review Fix Report

**Fixed at:** 2026-10-23T23:10:19Z
**Source review:** .planning/phases/169-install-and-upgrade-convergence/169-REVIEW.md  
**Iteration:** 2

**Summary:**
- Findings in scope: 4
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: A file mutation can become unjournaled before a crash

**Status:** fixed
**Files modified:** lib/lockspire/install/file_transaction.ex, test/lockspire/install/file_transaction_test.exs  
**Commit:** 8d708bb1  
**Applied fix:** A pending intent is persisted before each target mutation. Recovery reconciles the intent against target and backup checksums, restoring or removing only transaction-owned bytes. Journal replacement writes and syncs a same-filesystem temporary file before atomic rename. Existing journals without pending remain readable. The iteration 2 review confirmed this finding closed.

### WR-01: Recovery retries rollback after rollback already completed

**Status:** fixed
**Files modified:** lib/lockspire/install/file_transaction.ex, test/lockspire/install/file_transaction_test.exs  
**Commit:** 8d708bb1  
**Applied fix:** Rollback writes terminal rolled_back state with an empty committed list only after restoration completes. Recovery seeing that state skips rollback and finishes cleanup; create and update rollback also treat already-restored or removed targets as complete. The iteration 2 review confirmed this finding closed.

### CR-02: A partial create leaves recovery permanently blocked

**Status:** fixed
**Files modified:** lib/lockspire/install/file_transaction.ex, test/lockspire/install/file_transaction_test.exs
**Commits:** aa758972, 827b24b7
**Applied fix:** Creates no longer write directly to the final destination. They publish the checksum-verified staged file with an exclusive hard link, so the final path is either absent or complete. Recovery compares the destination and staged file device/inode identity before removing a created file, preserving even an identical-byte competing file. If the filesystem cannot provide a regular staged file with usable identity, creation refuses before publication.

### WR-02: An interrupted update can leave an untracked sibling temporary file

**Status:** fixed
**Files modified:** lib/lockspire/install/file_transaction.ex, test/lockspire/install/file_transaction_test.exs
**Commit:** aa758972
**Applied fix:** Updates atomically rename the staged transaction file into the destination. Rollback atomically renames its tracked backup into place. Neither operation writes temporary files beside host source files, so recovery cleanup removes remaining staged bytes from the transaction directory.

CR-01 and WR-01 share the journal-state transition and were committed together. CR-02 and WR-02 share tracked transaction-directory publication and rollback, and were committed together.

## Verification

Verification ran in the main checkout at source revision 827b24b7.

- Iteration 1: File transaction tests passed 14/14.
- Iteration 1: Transaction, upgrade, and generator selectors passed 45/45 with a fresh disposable database.
- Iteration 2: ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/install/file_transaction_test.exs — 18 passed.
- Iteration 2: ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 LOCKSPIRE_TEST_DB_NAME=lockspire_169_reviewfix_iter2b HEX_HOME=/tmp/lockspire-169-reviewfix-hex asdf exec mix test test/lockspire/install/file_transaction_test.exs test/integration/install_upgrade_test.exs test/integration/install_generator_test.exs — 49 passed. The disposable database was initialized with mix test.setup under the same environment.
- mix format --check-formatted lib/lockspire/install/file_transaction.ex test/lockspire/install/file_transaction_test.exs — passed.
- git diff --check — passed before the iteration 2 commit.

Regression coverage includes interrupted intent and journal replacement, legacy journal recovery, terminal rollback retry, complete staged create publication, a competing create with identical desired bytes, update interruption before publication, and rollback interruption after restoring from backup. Test hooks model these process interruption boundaries; they do not prove behavior under power loss. Hard-link publication and update/restore rename fail safely when unsupported or crossing filesystems; there is no copy or overwrite fallback. Journal file contents are synced before rename, but the containing directory is not synced. No claim is made about hostile same-user ancestor replacement or simultaneous writers. Existing compiler warnings were present; the full suite was not rerun.

---

_Fixed: 2026-10-23T23:10:19Z_
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 2_

