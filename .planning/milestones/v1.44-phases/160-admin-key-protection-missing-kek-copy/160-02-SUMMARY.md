---
phase: 160-admin-key-protection-missing-kek-copy
plan: 02
subsystem: admin-ui
tags: [liveview, admin, key-encryption, vocabulary]
requires:
  - phase: 160-01
    provides: Key protection line, PRODUCT.md vocabulary rows
provides:
  - Missing key-encryption key refusal copy for signing and encryption key generation
  - Admin.generate_key/1 spec naming :key_encryption_not_configured
affects: []
tech-stack:
  added: []
  patterns: [domain refusal atom mapped to static alert-list copy]
key-files:
  created: []
  modified:
    - lib/lockspire/web/live/admin/keys_live/index.ex
    - lib/lockspire/admin.ex
    - test/lockspire/web/live/admin/keys_live_test.exs
key-decisions:
  - "Refusal copy is static, uses only vocabulary-map terms, and names no env var, id or material"
  - "Generate buttons stay enabled without a key-encryption key; the refusal explains why"
requirements-completed: [KEY-UI-02, KEY-UI-03]
status: complete
duration: 25 min
completed: 2026-10-19
commits: 2
plan_head_before: 18eb098f54e587413433ab2a7a27185c36b81d62
plan_head_after: 0c0c6235f1fad4e3d5870e00a8a50e0890fc7be8
actuals:
  tokens: 9000
  tasks: 2
  commits: 2
---

# Phase 160 Plan 02: Missing key-encryption key copy Summary

**Generating a signing or encryption key with no key-encryption key now shows a clear refusal in the alert list: none is set up, Lockspire will not store private keys unencrypted, and to run mix lockspire.gen.kek, add it to the app configuration and restart.**

## Accomplishments

- New `{:error, :key_encryption_not_configured}` clause in `KeysLive.Index.generate_key/3`, ahead of the untouched catch-all, with private `missing_key_encryption_error/1` for "Signing" and "Encryption". No flash, no control changes.
- `Admin.generate_key/1` @spec and @doc now name the atom (docs-only).
- Tests (`describe "missing key-encryption key"`): sig and enc refusal (alert list, no flash, buttons enabled, no env var or material), repeated refusal stores nothing, refusal beats a storage failure, use validation first. The existing DROP TABLE test now also refutes "key-encryption key" in the catch-all copy.

## Task Commits

1. Task 1: 81e6cf11 - refusal clause, copy, spec, tests.
2. Task 2 (gate): 0c0c6235 - credo fix only (`Enum.count == 0` to `Enum.empty?` in the Plan 01 `assert_protection_is_text_only` test helper).

## Phase gate results

- Stress, leak, encryption-status, vocabulary, keys_live and protection suites: 77 tests, 0 failures.
- `mix ci` on 1.19.5-otp-28: first run failed on one credo warning (above); after the fix exit 0, 105 tests, 0 failures (35 excluded).
- SAFE-02 diff vs dda81e8d over mix.exs, mix.lock, priv, protocol, storage, Admin.Keys, config, application, admin_components, admin_css: empty (exit 0).
- PRODUCT.md rows present once each, all seven state labels match protection.ex; retired table unchanged. Changed files vs phase base are exactly the six expected.

## Deviations from Plan

**1. [Rule 3 - Blocking] credo warning from Plan 01 test helper**
- **Found during:** Task 2 `mix ci`
- **Fix:** replaced `Enum.count(...) == 0` with `Enum.empty?(...)` in keys_live_test.exs (a declared file).
- **Commit:** 0c0c6235

Otherwise the plan was executed as written.

## Notes

- `roadmap update-plan-progress` / STATE updates are recorded separately in the planning docs commit.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Commits 81e6cf11 and 0c0c6235 are on main; `.planning/state.json` and `config.json` left unstaged.
