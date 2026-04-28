---
phase: 33
plan: 03
subsystem: auth
tags: [dpop, oauth, policy, ecto, phoenix]
requires:
  - phase: 33
    provides: protocol-owned DPoP proof validation and durable replay enforcement
provides:
  - explicit durable client DPoP policy state
  - explicit durable server DPoP default state
  - protocol-owned effective DPoP policy resolution
affects: [phase-34-token-issuance, phase-35-userinfo, dpop-policy]
tech-stack:
  added: []
  patterns: [explicit enum policy fields, admin-normalized DPoP policy writes, protocol-owned effective policy resolution]
key-files:
  created:
    - priv/repo/migrations/20260428153000_add_dpop_policy_fields.exs
    - lib/lockspire/protocol/dpop_policy.ex
    - test/lockspire/protocol/dpop_policy_test.exs
  modified:
    - lib/lockspire/domain/client.ex
    - lib/lockspire/storage/ecto/client_record.ex
    - lib/lockspire/domain/server_policy.ex
    - lib/lockspire/storage/ecto/server_policy_record.ex
    - lib/lockspire/admin/clients.ex
    - lib/lockspire/admin/server_policy.ex
    - test/lockspire/admin/clients_test.exs
    - test/lockspire/admin/server_policy_test.exs
key-decisions:
  - "Model DPoP enablement as explicit durable enums instead of metadata so bearer-default behavior and later admin/DCR truth remain deterministic."
  - "Keep server policy as :bearer | :dpop and client policy as :inherit | :bearer | :dpop so existing clients stay inherited while explicit overrides can narrow or opt in."
  - "Make the resolver return explicit invalid-policy errors instead of silently coercing malformed state into bearer behavior."
patterns-established:
  - "Client and server token-mode policy now follows the PAR pattern: typed domain field, Ecto.Enum record field, admin normalization, and protocol resolver."
  - "Later token and userinfo work can consume one DPoP policy seam instead of re-deriving defaults from ad hoc maps."
requirements-completed: [DPoP-04]
duration: 6min
completed: 2026-04-28
---

# Phase 33 Plan 03: DPoP Policy State Summary

**Explicit client/server DPoP policy state with bearer-safe defaults and a protocol-owned effective-mode resolver**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-28T15:18:09Z
- **Completed:** 2026-04-28T15:23:37Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added explicit durable `dpop_policy` fields to `Client` and `ServerPolicy` with bearer-safe defaults for existing rows.
- Normalized and validated DPoP policy writes through the existing admin seams instead of metadata or runtime-only switches.
- Added `Lockspire.Protocol.DpopPolicy` so later token issuance and userinfo work can resolve effective DPoP mode through one deterministic seam.

## Task Commits

Each task was committed atomically through TDD phases:

1. **Task 1: Add explicit durable DPoP mode fields to client and server policy state**
   - `ed782b4` `test(33-03): add failing DPoP policy persistence tests`
   - `6da9d84` `feat(33-03): persist explicit DPoP policy state`
2. **Task 2: Add effective DPoP policy resolution with bearer-default proof**
   - `39b40b1` `test(33-03): add failing effective DPoP policy tests`
   - `faee94e` `feat(33-03): resolve effective DPoP policy`

## Files Created/Modified

- `lib/lockspire/domain/client.ex` and `lib/lockspire/storage/ecto/client_record.ex` - explicit client DPoP policy domain/schema state and update casting.
- `lib/lockspire/domain/server_policy.ex` and `lib/lockspire/storage/ecto/server_policy_record.ex` - explicit global DPoP default state on the singleton server-policy row.
- `lib/lockspire/admin/clients.ex` and `lib/lockspire/admin/server_policy.ex` - normalized admin write paths for valid DPoP policy values.
- `priv/repo/migrations/20260428153000_add_dpop_policy_fields.exs` - additive durable DPoP policy columns with safe defaults.
- `lib/lockspire/protocol/dpop_policy.ex` - effective DPoP policy resolver and malformed-state rejection.
- `test/lockspire/admin/clients_test.exs`, `test/lockspire/admin/server_policy_test.exs`, and `test/lockspire/protocol/dpop_policy_test.exs` - executable proof for defaults, persistence, overrides, and invalid values.

## Decisions Made

- Used durable enum fields instead of booleans or metadata because later DCR/admin truth needs explicit bearer vs DPoP vs inherit state.
- Preserved bearer-by-default by keeping the server default at `:bearer` and client default at `:inherit`.
- Rejected malformed policy values explicitly in the resolver so insecure fallback behavior cannot hide bad durable state.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The test database schema had not yet applied the new migration, so verification initially failed with `undefined_column` errors. Running `MIX_ENV=test mix lockspire.test.setup` applied `20260428153000_add_dpop_policy_fields.exs`, after which the targeted plan tests passed cleanly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 34 can now require DPoP only for clients whose effective policy resolves to `:dpop`, while leaving inherited bearer clients unchanged.
- Phase 35 can consume the same durable policy state for truthful admin/DCR and owned-endpoint behavior without repo-internal inference.

## Self-Check: PASSED

- `.planning/phases/33-dpop-proof-validation-and-replay-state/33-03-SUMMARY.md` exists.
- Commits `ed782b4`, `6da9d84`, `39b40b1`, and `faee94e` are present in git history.
- `MIX_ENV=test mix test test/lockspire/protocol/dpop_policy_test.exs test/lockspire/admin/clients_test.exs test/lockspire/admin/server_policy_test.exs` passed during execution.
