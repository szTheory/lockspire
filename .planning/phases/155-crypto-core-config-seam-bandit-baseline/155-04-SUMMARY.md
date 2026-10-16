---
phase: 155-crypto-core-config-seam-bandit-baseline
plan: 04
subsystem: security
tags: [envelope-encryption, admin-keys, clean-room, test-seeders]
requires: ["155-03"]
provides:
  - "Admin.Keys.generate_key/1 seals under the current KEK or returns {:error, :key_encryption_not_configured} with no row and no audit"
  - "Clean-room provider host config carries fixed test KEK clean-room-1"
  - "SeedingHelpers.seed_signing_key/1 and TokenExchangeCase.publish_signing_key/1 write LSK envelopes"
affects: [155-05, 156, 157]
tech-stack:
  added: []
  patterns: ["resolve KeySet before any JWK generation or DB write", "absent-KEK tests via put_key_encryption(nil) only"]
key-files:
  created:
    - test/lockspire/security/sealed_seeders_test.exs
  modified:
    - lib/lockspire/admin/keys.ex
    - scripts/acceptance/clean_room/build_provider.py
    - test/lockspire/admin/keys_test.exs
    - test/support/seeding_helpers.ex
    - test/support/token_exchange_case.ex
key-decisions:
  - "check_bootstrap() inspects the source of write_host_runtime (inspect.getsource) rather than the whole script file, so the assertion cannot be satisfied by its own text"
requirements-completed: [ENC-01, KEK-02, ENC-02]
status: complete
duration: 20 min
completed: 2026-10-15
commits: 2
plan_head_before: 36500ca8df15c1f64b22920390c49f045dccbbeb
plan_head_after: 762e519072bc5c3a7280addf90efc98659df6725
actuals:
  tokens: 14000
  tasks: 2
  commits: 2
coverage:
  - deliverable: "generate_key writes sealed envelope that decodes and signs"
    verification:
      - {kind: test, ref: "test/lockspire/admin/keys_test.exs", status: pass}
    human_judgment: false
  - deliverable: "generate_key refuses without KEK, zero rows and zero audit; legacy rows still sign"
    verification:
      - {kind: test, ref: "test/lockspire/admin/keys_test.exs", status: pass}
    human_judgment: false
  - deliverable: "Clean-room provider bootstraps and verifies with its KEK"
    verification:
      - {kind: command, ref: "mix test.clean-room.e2e", status: pass}
      - {kind: test, ref: "test/integration/phase133_provider_install_test.exs", status: pass}
    human_judgment: false
  - deliverable: "Shared seeders write envelopes"
    verification:
      - {kind: test, ref: "test/lockspire/security/sealed_seeders_test.exs", status: pass}
    human_judgment: false
---

# Phase 155 Plan 04: Sealed key generation write seam Summary

generate_key now seals every new signing key under the current KEK (LSK envelope bound to the kid) or refuses with `{:error, :key_encryption_not_configured}` before touching the repo; the clean-room provider ships a fixed `clean-room-1` test KEK in the same commit, and the two shared test seeders write envelopes.

## Tasks

| Task | Commit | Notes |
|------|--------|-------|
| 1 (tracer) write seam + clean-room KEK + tests | f9d36fa1 | Verified end-to-end: keys_test, phase133 integration, clean-room e2e |
| 2 sealed seeders (RED then GREEN, one commit) | 762e5190 | sealed_seeders_test failed with `:legacy` before the seeder change |

## Verification

- `mix test.fast` (after last code change): 2 properties, 1645 tests, 0 failures, 6 skipped (286 excluded)
- `mix qa` exit 0; `mix qa.dialyzer`: Total errors 0
- `mix test.clean-room.e2e` exit 0 (re-run after final commit)
- phase133 integration: 3 tests, 0 failures; keys_test: 12 tests, 0 failures
- Boundary diffs (KeysLive, PRODUCT.md, adoption demo seeds, mix.exs/mix.lock/priv) are empty.

## Deviations from Plan

- Toolchain: used CI toolchain (Elixir 1.19.5-otp-28 / OTP 28.1) instead of the plan's 1.20.4-otp-29, per orchestrator instruction.
- Test additions: `sealed_seeders_test.exs` needed a `setup_all` that starts `Lockspire.TestRepo` (DataCase alone does not start it); not a behavior deviation.
- RED and GREEN for Task 2 were committed together (one `test(155-04)` commit) as the plan specified a single commit per task.
- No existing test outside the touched files asserted on stored plaintext from the shared seeders (matches RESEARCH Pitfall 7).

## Known Stubs

None.

## Threat Flags

None. T-155-22 (plaintext write) and T-155-25 (clean-room breakage) mitigated as planned; T-155-27/28 accepted (adoption demo "Generate" shows the generic failure flash until Phase 157).

## Self-Check: PASSED

Files exist, both commits are ancestors of HEAD, `commits` measured from the persisted ledger (2).
