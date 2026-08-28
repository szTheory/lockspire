---
phase: 131
fixed_at: 2026-08-26T22:33:30Z
review_path: .planning/phases/131-executable-installation/131-REVIEW.md
iteration: 3
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 131: Filesystem Transaction Review Fix Report

| Finding | Status | Evidence |
| --- | --- | --- |
| WR-01 | fixed | `Lockspire.Install.FileTransaction` stages one immutable artifact list, writes/syncs a journal before mutation, commits the manifest last, rolls back ordinary failures, and recovers a simulated interruption before a new plan. |
| WR-02 | fixed with documented pure-Elixir boundary | Sources, project/destination ancestry, journal, staging paths, and targets are `lstat`-validated and symlinks are refused before staging and immediately before commit. The docs explicitly exclude hostile same-user ancestor swaps without descriptor-relative `openat`/`O_NOFOLLOW`. |

## Commits

- `445e0ce` `fix(131): journal installer filesystem transaction`
- `af8545f` `fix(131): report manifest transaction status`
- `4a65cfe` `fix(131): satisfy transaction static checks`
- `ce35107` `fix(131): close transaction recovery gaps`

## Post-review addendum

- Ordinary commit failures now write a terminal `rolled_back` journal state,
  remove only validated local journal/staging state after rollback, and return
  the original commit error. The regression asserts exact preimage restoration,
  no live transaction state, and an immediate successful retry.
- Recovery validates `.lockspire` ancestry before journal inspection and again
  before cleanup. A symlinked `.lockspire` directory containing valid-looking
  outside journal/staging files is refused without reading, deleting, or
  modifying the outside sentinel.

## Verification

- `mix compile --warnings-as-errors`
- `mix test test/lockspire/install/file_transaction_test.exs test/lockspire/install/migrations_test.exs test/integration/install_upgrade_test.exs` — 26 tests, 0 failures
- `mix test test/integration/install_generator_test.exs:560` — 1 test, 0 failures
- `mix test.fast` — the initial idempotency assertion exposed missing manifest status reporting; that was repaired in `af8545f`, and its focused regression passed afterward.
- `mix test.integration` — 252 tests, 0 failures
- `mix qa` — passed (Sobelow reports its existing no-router warning)
- `mix docs.verify` — passed
- `mix format --check-formatted`
- `mix test test/lockspire/install/file_transaction_test.exs test/lockspire/install/migrations_test.exs test/integration/install_upgrade_test.exs` — 28 tests, 0 failures after post-review fixes
- `mix test.fast --max-failures 1` — 1,326 tests, 0 failures

The report is intentionally uncommitted for the orchestration workflow.
