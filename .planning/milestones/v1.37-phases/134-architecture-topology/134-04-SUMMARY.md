---
phase: 134-architecture-topology
plan: 04
subsystem: configuration-topology
tags: [configuration, storage, security, xref]
dependency_graph:
  requires: [application-environment]
  provides: [pure-prefix-normalization, explicit-secret-key-sealing]
  affects: [ecto-storage, oban, client-secret-jwt]
tech_stack:
  added: []
  patterns: [argument-only-normalization, compatible-adapter-wrapper, explicit-cryptographic-input]
key_files:
  created:
    - lib/lockspire/storage/prefix.ex
    - test/lockspire/storage/prefix_test.exs
    - test/lockspire/security/policy_test.exs
  modified:
    - lib/lockspire/storage/ecto/prefix.ex
    - lib/lockspire/config.ex
    - lib/lockspire/security/policy.ex
decisions:
  - Prefix normalization and option construction are dependency-neutral functions of explicit arguments.
  - Policy supports explicit secret-key-base inputs while its compatible no-option path resolves host configuration locally without depending on Config.
metrics:
  tasks_completed: 3
status: complete
---

# Phase 134 Plan 04: Configuration Topology Summary

Prefix handling is now pure and the Config/Policy/Prefix xref cycle has been removed without changing host-facing prefix or verifier behavior.

## Completed Work

- Added `Lockspire.Storage.Prefix` with pure `normalize/1`, `prefix_opts/1`, and `oban_opts/1` functions.
- Retained zero-arity Ecto Prefix accessors and added explicit compatible arities for adapter callers that already have a configured value.
- Updated `Config.storage_prefix/0` and `Config.oban_prefix/0` to normalize through the neutral utility.
- Removed `Lockspire.Security.Policy`'s dependency on `Lockspire.Config`; explicit binary key-base sealing/unsealing is available, and legacy keyword/default calls retain host configuration behavior.

## Verification

- `mix compile --warnings-as-errors`
- `mix test test/lockspire/security/policy_test.exs test/lockspire/config_test.exs test/lockspire/storage/prefix_test.exs test/lockspire/storage/ecto/prefix_test.exs` — 16 tests, 0 failures
- `mix xref graph --format cycles` — the Config/Policy/Prefix cycle is absent. Output contains only the token-exchange and protected-resource/userinfo cycles assigned to other Phase 134 plans.

## TDD Gate Compliance

- RED prefix normalization characterization: `91258f7`; GREEN pure utility: `14fc287`.
- RED explicit sealing-key characterization: `64dffba`; GREEN Policy extraction: `02d01f9`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Made the prefix identifier regex run-time rather than guard-based for Elixir 1.19.**
- **Found during:** Task 1 compile verification.
- **Issue:** Elixir 1.19 rejects Regex structs in guards.
- **Fix:** Performed the identifier test inside `normalize/1` while preserving all validation outcomes.
- **Files modified:** `lib/lockspire/storage/prefix.ex`
- **Commit:** `14fc287`

**2. [Rule 1 - Bug] Used a shared function header for explicit and keyword secret-key-base overloads.**
- **Found during:** Task 3 warnings-as-errors compile verification.
- **Issue:** Multiple clauses with a default argument must share a declaration header.
- **Fix:** Added common function headers and expanded specs to cover binary explicit key material.
- **Files modified:** `lib/lockspire/security/policy.ex`
- **Commit:** `02d01f9`

## Known Stubs

None.

## Self-Check: PASSED

- New pure prefix and regression-test files exist.
- Commits `91258f7`, `14fc287`, `0541709`, `64dffba`, and `02d01f9` exist.
