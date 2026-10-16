---
phase: 155-crypto-core-config-seam-bandit-baseline
plan: 01
subsystem: dependencies
tags: [bandit, mint, cve-hygiene, hosts]
requires: []
provides:
  - "adoption demo and both clean-room hosts on bandit 1.13.1"
affects: [155-02]
tech-stack:
  added: []
  patterns: []
key-files:
  created: []
  modified:
    - examples/adoption_demo/mix.exs
    - examples/adoption_demo/mix.lock
    - test/clean_room/provider_host/mix.exs
    - test/clean_room/provider_host/mix.lock
    - test/clean_room/confidential_client/mix.exs
    - test/clean_room/confidential_client/mix.lock
    - compatibility/phoenix_1_8_live_view_1_1/mix.lock
key-decisions:
  - "Pin bandit == 1.13.1 in demo and both clean-room hosts; prune unused bandit/thousand_island from compat lock (D-15, D-16, D-17)"
requirements-completed: [DEP-01]
status: complete
duration: 40 min
completed: 2026-10-15
commits: 2
plan_head_before: 09e45afacbd5f8cb8a409d11291a792b9dddf5ae
plan_head_after: 79f3af8b3568ede93f02c9b0ccfd63b85e2641db
actuals:
  tokens: 6000
  tasks: 2
  commits: 2
---

# Phase 155 Plan 01: Bandit 1.13.1 host baseline Summary

Adoption demo and both clean-room hosts pinned to Bandit 1.13.1 (thousand_island 1.6.0, hpax 1.1.0, mint 1.11.0); compat fixture lock pruned of unused bandit/thousand_island; library untouched.

## Commits
- 5d85b53a: provider host (Task 1, tracer)
- 79f3af8b: confidential client, demo, compat lock (Task 2)

## Lock changes (only these packages moved)
- bandit 1.12.5 -> 1.13.1 (demo, provider, client)
- thousand_island 1.5.0 -> 1.6.0 (same three)
- hpax 1.0.4 -> 1.1.0 (all four locks)
- mint 1.9.3 -> 1.11.0 (all four locks)
- compat lock: bandit and thousand_island entries removed

## Verification
- `mix test.clean-room.e2e` exit 0 (after both tasks); demo and compat `deps.get --check-locked` (fresh deps path) + `compile --warnings-as-errors` pass; `mix hex.audit` names no bandit or mint advisory (unrelated: decimal 3.1.1 EEF-CVE-2026-97853, MEDIUM, left as-is); `mix qa` exit 0; root mix.exs/mix.lock/lib/config unchanged.

## Deviations from Plan

**1. [Rule 3 - Blocking] mint lock entry build-tools quirk**
- **Found during:** Task 1. `mix deps.update` in the scratch copy wrote the mint entry with `[]` build tools (the update errored "Unknown dependency mint for environment dev" after resolving), so `deps.get --check-locked` on a fresh deps tree failed "mix.lock is out of date".
- **Fix:** replaced the mint line in each host lock with the identical 1.11.0 line from the root `mix.lock` (`[:mix]`). Same version and checksums.
- **Commits:** 5d85b53a, 79f3af8b

**2. [Environment] Elixir version for verification**
- The specified Elixir 1.20.4 fails `--warnings-as-errors` on pre-existing type warnings in untouched code (`test/clean_room/confidential_client/lib/clean_room_client/oauth_http.ex:4`, `lib/lockspire/protocol/authorization_request.ex:727`). Verification (e2e, demo, qa) was therefore run on the CI versions: Elixir 1.19.5/OTP 28.1; compat on 1.18.4/OTP 27.3.4.15. Not fixed (out of scope); worth a follow-up before moving CI to Elixir 1.20.

**Total deviations:** 1 auto-fixed (Rule 3), 1 environment note.

## Known Stubs
None.

## Self-Check: PASSED
Commits 5d85b53a and 79f3af8b present on main; modified files exist.
