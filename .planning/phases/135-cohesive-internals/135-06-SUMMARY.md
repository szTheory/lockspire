---
phase: 135-cohesive-internals
plan: 06
subsystem: token-exchange
tags: [oauth, oidc, dependencies, compatibility, architecture]
status: complete
requires: [135-01]
provides:
  - One typed token-exchange dependency bundle per stable request boundary
  - Exhaustive legacy option normalization with production defaults
  - Dependency-aware coordinator paths for authorization-code, device, CIBA, refresh, and RFC 8693 grants
affects: [135-07, 135-08, 135-09]
key-files:
  created:
    - lib/lockspire/protocol/token_exchange/internal/dependencies.ex
    - lib/lockspire/protocol/token_exchange/internal/legacy_options.ex
    - test/lockspire/protocol/token_exchange/dependencies_test.exs
  modified:
    - lib/lockspire/protocol/token_exchange.ex
    - lib/lockspire/protocol/token_exchange/internal/grant_support.ex
    - lib/lockspire/protocol/token_exchange/internal/token_endpoint_dpop.ex
    - lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex
decisions:
  - Legacy request options are normalized only by LegacyOptions; all token internals consume Dependencies fields.
  - Stable and retained lower facades preserve their arities and public TokenResult conversion while adapting once at entry.
metrics:
  completed: 2026-08-27
---

# Phase 135 Plan 06: Explicit Token Dependencies Summary

Token exchanges now construct one typed, validated dependency bundle at their stable facade boundary and thread it through all five neutral grant coordinators without changing public result shapes.

## Completed Tasks

1. Added `Dependencies` and `LegacyOptions`, including exhaustive legacy option mapping, established defaults, and deterministic safe capability validation.
2. Threaded dependencies through authorization-code, device, CIBA, refresh, and RFC 8693 dispatch; retained lower compatibility facades adapt existing requests through the same boundary.

## Verification

- `mix compile --warnings-as-errors` — passed.
- `mix test test/lockspire/protocol/token_exchange/dependencies_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/token_exchange/delegation_test.exs test/lockspire/protocol/token_exchange/characterization_test.exs` — 17 tests, 0 failures.
- `mix xref graph --format cycles` — No cycles found.
- Option-read inventory confirms that `LegacyOptions` is the sole token-internal request-option reader.

## Decisions Made

- Required durable capability groups return the existing safe `TokenResult.Error` category before a coordinator can mutate durable state.
- The temporary broad collaborators remain in place for the following focused-extraction plans, but receive the typed bundle and no longer independently read legacy option bags.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking compile issue] Waited for the concurrent storage extraction to repair its temporary compile error before running this plan's verification.**
- **Found during:** Task 1 verification.
- **Issue:** Concurrent Plan 02 briefly had an invalid nested capture in `Repository.ClientStore`.
- **Resolution:** The Plan 02 owner repaired it; no Plan 06 storage file was changed.

## Self-Check: PASSED

- `Dependencies`, `LegacyOptions`, and their focused test file exist.
- Commits `a5b4a50` and `d59b8f8` exist in repository history.
