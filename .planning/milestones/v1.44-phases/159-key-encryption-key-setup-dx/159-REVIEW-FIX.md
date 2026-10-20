---
phase: 159-key-encryption-key-setup-dx
fixed_at: 2026-10-19T00:00:00Z
review_path: .planning/phases/159-key-encryption-key-setup-dx/159-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 159: Code Review Fix Report

**Fixed at:** 2026-10-19
**Source review:** .planning/phases/159-key-encryption-key-setup-dx/159-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4
- Fixed: 4
- Skipped: 0

Verification ran in the main checkout (`workflow.use_worktrees` is false), not an isolated worktree.

## Fixed Issues

### WR-01: Clean-room boundary audit silently weakened for the non-install path

**Files modified:** `scripts/acceptance/clean_room/build_provider.py`
**Commit:** 53030375
**Applied fix:** Added `assert_below(vendor, child, "provider vendor dependency")` after the inventory check in the `install=False` branch. `phase133_provider_install_test.exs` (4 tests, and `--only gen_kek`) pass.

### WR-02: `{:system, var}` whitespace-only value gives a misleading error

**Files modified:** `lib/lockspire/config.ex`, `test/lockspire/config_key_encryption_test.exs`
**Commit:** 927db3ac
**Applied fix:** A whitespace-only value now fails with `invalid config :key_encryption (:keys: blank_env)`, naming only the variable. Values are still never trimmed or accepted (fail closed, D-06), so a valid value with a trailing newline still fails as `invalid_base64`. Added a test for the new error.

### IN-01: Rotation guide does not match gen.kek output

**Files modified:** `docs/upgrading/signing-key-encryption.md`
**Commit:** 12c8a490
**Applied fix:** Rotation step 1 now says to use `mix lockspire.gen.kek --raw`, store the value as `LOCKSPIRE_KEY_ENCRYPTION_KEY_NEXT`, and not copy the full output, which names the current key's variable. `gen.kek` still appears before the `elixir -e` fallback; the contract tests pass.

### IN-02: `--raw` ignores `--id`; double trailing blank line

**Files modified:** `lib/mix/tasks/lockspire.gen.kek.ex`
**Commit:** 65eb68e6
**Applied fix:** The moduledoc and help text now say `--id` has no effect with `--raw` (an invalid id is still rejected, as existing tests require). The block's trailing newline is trimmed before printing. `--raw` output is unchanged (one line).

---

_Fixed: 2026-10-19_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
