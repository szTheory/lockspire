---
phase: 132-public-api-and-resource-server-truth
plan: 03
subsystem: api
tags: [dpop, plug, ecto, replay-protection, oauth]
requires:
  - phase: 131-executable-installation
    provides: durable Lockspire Ecto migrations and host configuration seam
provides:
  - Protected-resource DPoP defaults to the configured durable Ecto repository.
  - Custom DPoP replay-store injection remains supported and fails closed.
affects: [132-04, 133-clean-room-saas-journey, resource-server-docs]
tech-stack:
  added: []
  patterns:
    - Optional security-store overrides are omitted when unset and resolve through a durable adapter.
    - Storage capability errors are converted to generic invalid-token failures without fallback.
key-files:
  created:
    - test/integration/protected_resource_dpop_default_store_test.exs
  modified:
    - lib/lockspire/plug/enforce_sender_constraints.ex
    - lib/lockspire/protocol/protected_resource_dpop.ex
    - test/lockspire/plug/enforce_sender_constraints_test.exs
    - test/lockspire/protocol/protected_resource_dpop_test.exs
key-decisions:
  - "An absent or legacy nil protected-resource replay override resolves only to Storage.Ecto.Repository."
  - "Replay-store capability and execution failures map to generic invalid_dpop_proof without a fallback store."
patterns-established:
  - "Fail-closed injected storage: validate module capability at Plug init and protect protocol invocation from store exceptions."
requirements-completed: [API-03]
coverage:
  - id: D1
    description: "The ordinary protected-resource Plug path stores an accepted DPoP proof in the configured repository and rejects the same proof on a new request."
    requirement: API-03
    verification:
      - kind: integration
        ref: "test/integration/protected_resource_dpop_default_store_test.exs#omitting the replay-store override persists once and rejects the identical proof"
        status: pass
    human_judgment: false
  - id: D2
    description: "Valid custom replay stores remain injectable while unavailable and incompatible stores reject without fallback acceptance."
    requirement: API-03
    verification:
      - kind: unit
        ref: "test/lockspire/plug/enforce_sender_constraints_test.exs and test/lockspire/protocol/protected_resource_dpop_test.exs"
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-08-26
status: complete
---

# Phase 132 Plan 03: Durable Protected-Resource DPoP Summary

**Protected-resource DPoP replay handling now uses the configured Ecto repository by default, while custom stores remain injectable and every replay-store failure rejects the token.**

## Performance

- **Duration:** 12 min
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added a configured-TestRepo Plug integration proof: the first DPoP proof creates the durable row and an identical fresh request is rejected as a replay.
- Removed the nil-option mask by omitting an absent Plug override and resolving both absent and legacy nil protocol values to `Lockspire.Storage.Ecto.Repository`.
- Preserved compatible custom stores, rejected incompatible configuration early, and converted custom-store errors or exceptions into generic `:invalid_dpop_proof` failures without fallback acceptance.

## Task Commits

1. **Task 1: Exercise the omitted-store Plug path against the configured repository** - `785c106` (test), `894813f` (fix)
2. **Task 2: Preserve compatible overrides and fail closed on store failures** - `eed37c4` (test)

## Files Created/Modified

- `lib/lockspire/plug/enforce_sender_constraints.ex` - omits nil replay overrides and validates explicitly injected store modules.
- `lib/lockspire/protocol/protected_resource_dpop.ex` - uses the durable default and treats invalid, failing, or raising stores as an invalid proof.
- `test/integration/protected_resource_dpop_default_store_test.exs` - verifies configured repository persistence and replay rejection through the Plug.
- `test/lockspire/plug/enforce_sender_constraints_test.exs` - covers unavailable and invalid custom stores at the Plug boundary.
- `test/lockspire/protocol/protected_resource_dpop_test.exs` - covers generic protocol failure mapping and no fallback after custom-store error.

## Decisions Made

- The protected-resource default is exactly `Lockspire.Storage.Ecto.Repository`; token-store configuration is not a replay-store fallback.
- A custom module is the advanced injection contract. Its error, exception, or incompatible capability cannot cause a successful binding.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Made replay-store invocation resilient to invalid or raising modules**
- **Found during:** Task 2
- **Issue:** An invalid direct protocol override or a custom store exception could raise rather than return the required fail-closed token result.
- **Fix:** Guarded capability checks and converted raised/caught store execution to the existing generic invalid-DPoP failure path.
- **Files modified:** `lib/lockspire/protocol/protected_resource_dpop.ex`
- **Verification:** Focused Plug and protocol tests pass.
- **Committed in:** `eed37c4`

**Total deviations:** 1 auto-fixed (Rule 1)

## Verification

- PASS: `mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs` — 19 tests, 0 failures.
- PASS: `mix test --include integration test/integration/protected_resource_dpop_default_store_test.exs test/lockspire/storage/ecto/repository_dpop_replay_test.exs` — 9 tests, 0 failures.
- BLOCKED BY CONCURRENT WORKTREE STATE: `mix compile --warnings-as-errors` currently fails on an uncommitted, unrelated `present?/1` warning in `lib/lockspire/plug/verify_token.ex`; this plan's touched files compile under the focused suites. Re-run the full compile after the concurrent Plan 01 executor commits its work.

## Known Stubs

None.

## Next Phase Readiness

Plan 132-04 can document the configured repository as the ordinary secure protected-resource path; the advanced custom store option is no longer required for default adoption.

## Self-Check: PASSED

- Confirmed all five Plan 03 source/test artifacts exist.
- Confirmed task commits `785c106`, `894813f`, and `eed37c4` exist.
