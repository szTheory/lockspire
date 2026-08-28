---
phase: 136-static-analysis-and-sustainable-proof
plan: "08"
subsystem: token-exchange
tags: [oauth, oidc, dialyzer, token-issuance, refresh-rotation]
requires: [136-03, 136-07]
provides: [truthful-five-grant-results, typed-pre-persistence-token-issuance]
affects: [136-09, 136-11]
tech-stack:
  added: []
  patterns: [exact-neutral-result-unions, pre-persistence-token-refinement]
key-files:
  modified:
    - lib/lockspire/protocol/token_exchange/authorization_code_grant.ex
    - lib/lockspire/protocol/token_exchange/device_code_grant.ex
    - lib/lockspire/protocol/token_exchange/ciba_grant.ex
    - lib/lockspire/protocol/token_exchange/internal/authorization_code_grant.ex
    - lib/lockspire/protocol/token_exchange/internal/device_code_grant.ex
    - lib/lockspire/protocol/token_exchange/internal/ciba_grant.ex
    - lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex
    - lib/lockspire/protocol/token_exchange/internal/token_issuer.ex
decisions:
  - Lower grant facades explicitly expose the stable public success/error union.
  - Token issuance accepts only the narrow pre-persistence refinement where token_hash may be absent before signing.
metrics:
  tasks_completed: 3
  tests: 55
  dialyzer_warnings_removed: 30
status: complete
---

# Phase 136 Plan 08: Token Exchange Dialyzer Summary

All five token-grant paths now retain exact neutral and public result shapes, and the signing boundary truthfully accepts tokens before their final hashes exist.

## Accomplishments

- Added explicit public contracts for authorization-code, device, and CIBA compatibility facades.
- Tightened the focused authorization-code, device, CIBA, and refresh coordinator results to `TokenResult.Success` or `TokenResult.Error`.
- Introduced a narrow pre-persistence token refinement for signing rather than weakening durable `Token.t()` contracts.
- Removed unreachable token-generator branches by giving refresh-token formatting a single-purpose helper.

## Verification

- `mix test test/lockspire/protocol/token_exchange/characterization_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/device_authorization_test.exs test/lockspire/protocol/authorization_flow_test.exs test/lockspire/protocol/rfc8693_exchange_test.exs` — 55 tests, 0 failures.
- `mix qa.dialyzer` — 6 project warnings remain in later-plan owners; none reference `lib/lockspire/protocol/token_exchange` or `lib/lockspire/protocol/refresh_exchange`.

## Task Commits

1. `3714ed31` — type the lower grant facades.
2. `0bcba412` — type focused grant coordinators.
3. `5ff6252e` — model pre-persistence token issuance and narrow refresh formatting.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Type contract] The reported GrantSupport dead-code cluster was downstream of broad coordinator contracts.**
- **Found during:** Task 2.
- **Fix:** corrected the owning coordinator unions first; Dialyzer then proved the retained GrantSupport helpers reachable, so no protocol behavior or audit/telemetry path was removed.
- **Verification:** the five-flow suite passed and all token-exchange diagnostics disappeared.

## Known Stubs

None.

## Self-Check: PASSED

- The three task commits are present in git history.
- The final Dialyzer capture has no token-exchange or refresh-exchange source diagnostic.
