---
phase: 160-admin-key-protection-missing-kek-copy
plan: 01
subsystem: admin-ui
tags: [liveview, admin, key-encryption, vocabulary]
requires:
  - phase: 159-key-encryption-key-setup-dx
    provides: mix lockspire.gen.kek, Admin.encryption_status/0
provides:
  - KeysLive.Protection.summarize/1 (seven-state presenter)
  - Read-only Key protection line on the admin Keys page
  - PRODUCT.md vocabulary rows for key-encryption key and Key protection states
affects: [160-02]
tech-stack:
  added: []
  patterns: [fail-closed status presenter, independent assign for a second read]
key-files:
  created:
    - lib/lockspire/web/live/admin/keys_live/protection.ex
    - test/lockspire/web/live/admin/keys_live/protection_test.exs
  modified:
    - lib/lockspire/web/live/admin/keys_live/index.ex
    - test/lockspire/web/live/admin/keys_live_test.exs
    - PRODUCT.md
key-decisions:
  - "Presenter returns only state, tone, value, detail, command; the raw status map never reaches the assign"
  - "load_key_protection/0 rescues and catches into could_not_check without logging"
requirements-completed: [KEY-UI-01, KEY-UI-03]
status: complete
duration: 20 min
completed: 2026-10-19
commits: 2
plan_head_before: 6d283727be66c01f52619d9715c31e24d60be5eb
plan_head_after: ab8c44ec48c4f252b26d99362b99e3e02ca02a9a
actuals:
  tokens: 30000
  tasks: 2
  commits: 2
---

# Phase 160 Plan 01: Key protection line Summary

**Read-only Key protection line on the admin Keys page: `Protection.summarize/1` collapses `Admin.encryption_status/0` into seven states, a failed check reads Unknown and never healthy, and the current key-encryption key id is the only value shown.**

## Accomplishments

- `KeysLive.Protection` presenter with first-match precedence (invalid config, not set up, unreadable, unencrypted, older key, encrypted, catch-all could-not-check).
- `KeysLive.Index` loads it into a separate `key_protection` assign in `assign_inventory/2` and after each successful generate; renders it under the hero, outside the inventory `case`, via `AdminComponents.decision_summary`, with no controls.
- PRODUCT.md gains key-encryption key, Key protection and key protection state rows (all seven labels); Last reviewed bumped.
- Tests: 9 pure presenter tests, plus a "key protection" describe in keys_live_test.exs covering all seven states, nil assign, failure isolation, line above inventory error, disclosure limits and refresh after generate.

## Task Commits

1. Task 1 (tracer): 0712d2df - presenter, wiring, PRODUCT.md, tracer tests. Tracer verify (compile warnings-as-errors plus protection, keys_live and vocabulary tests) passed before Task 2.
2. Task 2: ab8c44ec - seven-state matrix, isolation, disclosure, refresh tests.

The refresh-after-generate wiring in `generate_key/3` was included in the Task 1 commit (the same file edit as the rest of index.ex); Task 2 added its proving test.

## Deviations from Plan

None - plan executed exactly as written. (Only note: the generate_key refresh code landed in the Task 1 commit rather than Task 2.)

## Verification

- Plan verify and acceptance greps pass; `mix test test/lockspire/web test/lockspire/admin test/lockspire/security`: 544 tests, 0 failures.
- `lib/lockspire/admin/keys.ex`, `lib/lockspire/admin/keys/`, admin_components.ex and admin_css.ex unchanged vs dda81e8d.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Files exist, commits 0712d2df and ab8c44ec are on main, and `.planning/state.json` was left unstaged.
