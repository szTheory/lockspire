---
phase: 160-admin-key-protection-missing-kek-copy
fixed_at: 2026-10-19T00:00:00Z
review_path: .planning/phases/160-admin-key-protection-missing-kek-copy/160-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 160: Code Review Fix Report

**Source review:** 160-REVIEW.md
**Iteration:** 1
**Verification location:** main checkout (`workflow.use_worktrees=false`), Elixir 1.19.5-otp-28.

**Summary:** 5 in scope, 5 fixed, 0 skipped. IN-02 is out of scope and deferred.

## Fixed Issues

### WR-01: Unreadable legacy rows reported as unencrypted
**Commit:** 79a99935
**Files:** `protection.ex`, `protection_test.exs`
Rows `pending` reports as `:unsealable_legacy` now map to `:unreadable`, checked before the `legacy > 0` check. Requires human verification (logic change).

### WR-04: Reject-mode legacy keys showed only a warning
**Commit:** 67ae51e5
**Files:** `protection.ex`, `protection_test.exs`
`legacy_plaintext == :reject` with `legacy > 0` is now `:unreadable`, matching `EncryptionStatus.broken_now?/1`. The old "legacy_plaintext does not change the state" test was replaced. Requires human verification (logic change).

### WR-02: Unconfigured key set hid stranded encrypted keys
**Commit:** 46de39d2
**Files:** `protection.ex`, `protection_test.exs`, `keys_live_test.exs`
State precedence is unchanged (D-02): `configured: false` stays `:not_set_up`. When `unknown_kek != %{}` or `undecryptable > 0`, the detail now says existing keys were encrypted with a key-encryption key that is no longer configured, tells the operator to restore it rather than create a new one, and points to `mix lockspire.doctor.key_encryption`. Without such rows the copy and `mix lockspire.gen.kek` are unchanged. No ids or counts are shown (D-08), and no promise that keys keep working (D-03). The existing LiveView test "not set up state points at the generator and wins over unreadable" seeded a sealed key, which is now exactly the orphaned case. It was rewritten to use only legacy rows, and a new test covers the sealed-by-missing-key case. PRODUCT.md needed no change because the state labels are unchanged. Requires human verification (logic and copy change).

### WR-03: Invalid key-encryption config crashed the LiveView on generate
**Commit:** 31431286
**Files:** `lib/lockspire/web/live/admin/keys_live/index.ex`, `keys_live_test.exs`
`lib/lockspire/admin/keys.ex` and `lib/lockspire/admin/keys/` were NOT touched (SAFE-02 gate). The generate handler now rescues `ArgumentError` around `Admin.generate_key` and sets fixed `generation_error` copy, never echoing the message and with no flash or logging. The catch-all generation error copy is byte-identical. A new LiveView test sets invalid app env, erases the persistent_term cache, and asserts that the fixed copy is shown and the message text is not. Requires human verification (error-handling logic).

### IN-01: Bare rescue hid summarizer bugs
**Commit:** 2fd74fb1
**Files:** `index.ex`
The rescue/catch now wraps only `Admin.encryption_status()`. `Protection.summarize/1` runs outside it. No logging was added.

## Follow-up
Commit 2fda5f60: a small refactor commit extracts `unreadable?/1` in `protection.ex` to satisfy `mix credo --strict` cyclomatic complexity (no behavior change).
## Verification
- Targeted tests (protection_test, keys_live_test, vocabulary_contract_test): 43 tests, 0 failures.
- `MIX_ENV=test mix compile --warnings-as-errors --force`: clean.
- `mix format --check-formatted`: clean.
- `mix credo --strict` on touched files: no issues (after the refactor commit).
- `git diff dda81e8d -- lib/lockspire/admin/keys.ex lib/lockspire/admin/keys`: empty.

## Deferred

### IN-02: Private-key decryption on every page load
Not fixed. The reviewer judged it acceptable for v1; only counts and ids are returned. Revisit with a non-decrypting status variant or caching.

---

_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
