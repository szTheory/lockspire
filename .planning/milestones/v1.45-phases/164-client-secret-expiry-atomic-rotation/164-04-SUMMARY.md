---
phase: 164-client-secret-expiry-atomic-rotation
plan: "04"
subsystem: token-exchange
tags: [elixir, oauth, oidc, client-secrets, lifetimes]
requires:
  - phase: 164-02
    provides: Locked code and refresh secret authority checks
  - phase: 164-03
    provides: Atomic secret rotation and current-client storage behavior
provides:
  - Final authority checks for authenticated device/CIBA polls and RFC 8693 requesters
  - Queued CIBA push and existing token behavior independent of secret expiry
affects: [164-05, 164-06, token-exchange, client-lifetime]
actuals:
  tokens: 8803
  tasks: 3
  commits: 3
commits: 3
plan_head_before: cc711f6a9d40235d9d4d07bc0317d8c79d75d2f7
plan_head_after: fc21b4cc2b7afef0dd9909688cb1afcb6641f7f4
tech-stack:
  added: []
  patterns:
    - Trusted grant entrypoints set internal authority; requests cannot select queued-push treatment.
    - Final requester checks follow required locks and use one fresh decision time.
key-files:
  created:
    - test/integration/client_secret_lifetime_poll_exchange_test.exs
    - test/integration/client_secret_lifetime_existing_tokens_test.exs
    - .planning/phases/164-client-secret-expiry-atomic-rotation/164-04-01-red-evidence.json
    - .planning/phases/164-client-secret-expiry-atomic-rotation/164-04-02-red-evidence.json
    - .planning/phases/164-client-secret-expiry-atomic-rotation/164-04-03-red-evidence.json
  modified:
    - lib/lockspire/protocol/token_exchange/internal/ciba_grant.ex
    - lib/lockspire/protocol/token_exchange/internal/device_code_grant.ex
    - lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex
    - test/integration/app_lifetime_ciba_push_test.exs
key-decisions:
  - "Only trusted poll and RFC 8693 requester contexts apply secret eligibility after locks; queued push and issuer app checks stay secret-independent."
  - "Secret expiry does not revoke issued tokens or gate non-secret methods; confidential refresh still requires current credentials."
requirements-completed: [DCR-08]
coverage:
  - id: D1
    description: Polls recheck secret authority after request-row locking; queued push remains secret-independent.
    requirement: DCR-08
    verification:
      - kind: integration
        ref: "test/integration/client_secret_lifetime_poll_exchange_test.exs#device and CIBA polls reject a secret that expires before final issuance"
        status: pass
      - kind: integration
        ref: "test/integration/app_lifetime_ciba_push_test.exs#queued push remains eligible after its shared secret expires"
        status: pass
    human_judgment: false
  - id: D2
    description: RFC 8693 checks requester authority after token locks and keeps issuer checks app-only.
    requirement: DCR-08
    verification:
      - kind: integration
        ref: "test/integration/client_secret_lifetime_poll_exchange_test.exs#RFC 8693 rejects a requester expiring during token locks without output or audit"
        status: pass
      - kind: integration
        ref: "test/integration/client_secret_lifetime_poll_exchange_test.exs#expired issuer secrets do not block opaque or signed RFC 8693 outputs"
        status: pass
      - kind: integration
        ref: "test/integration/client_secret_lifetime_poll_exchange_test.exs#client_credentials remains an unsupported grant"
        status: pass
    human_judgment: false
  - id: D3
    description: Issued tokens, online targets and non-secret methods survive secret expiry; refresh needs current credentials.
    requirement: DCR-08
    verification:
      - kind: integration
        ref: "test/integration/client_secret_lifetime_existing_tokens_test.exs#issued access token validity and online targets survive secret expiry and rotation"
        status: pass
      - kind: integration
        ref: "test/integration/client_secret_lifetime_existing_tokens_test.exs#non-secret final issuance authority ignores dormant expired secret material"
        status: pass
    human_judgment: false
duration: 16 min
completed: 2026-10-21
status: complete
---

# Phase 164 Plan 04: Final Issuance Authority Summary

**Device and CIBA polls and RFC 8693 now recheck requester secrets after required locks; queued push and issued tokens remain independent of secret expiry.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-10-21T14:32:57Z
- **Completed:** 2026-10-21T14:48:57Z
- **Tasks:** 3/3
- **Files modified:** 9

## Accomplishments

- Trusted entrypoints set CIBA authority: authenticated polls use `:client_request`; the worker uses `:queued_push`, regardless of request fields.
- Final poll issuance checks locked identity, app state and secret deadline at the fresh time used for grant/output expiry. Denials preserve approved grants, tokens and audits.
- RFC 8693 validates the requester after client and input-token locks; issuers receive app-only checks, and `client_credentials` remains unsupported.
- Signed token expiry, UserInfo, introspection and four non-secret methods remain independent of dormant secret expiry. Confidential refresh rejects the expired secret and succeeds after rotation.

## Task Commits

1. **164-04-01: Guard authenticated device and CIBA polls without gating queued push** — `ee5bf41a` (`feat`)
2. **164-04-02: Revalidate only the RFC 8693 requesting secret after token locks** — `afeae94d` (`feat`)
3. **164-04-03: Prove existing tokens and non-secret finalizers remain usable** — `fc21b4cc` (`test`)

## Verification

All commands used the dedicated database `lockspire_phase164_validation` and pinned Elixir/OTP and Mix/Hex homes.

- C041 polling, queued push and app regressions: **9 tests, 0 failures**.
- C042 RFC 8693 regressions: **11 tests, 0 failures**.
- Final C043 existing-token, poll/exchange and online-consumer selection: **15 tests, 0 failures**.
- All three RED records passed `gsd-tools.cjs check tdd-red-evidence` as `RED_EVIDENCE_OK`. Task 3 used a temporary strict-secret-gate mutation to verify regression sensitivity; production code was restored before the passing C043 run.
- `git diff --check` passed before task commits.

Exact focused test commands:

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/integration/client_secret_lifetime_poll_exchange_test.exs test/integration/app_lifetime_ciba_push_test.exs test/integration/app_lifetime_poll_issuance_test.exs --max-failures 1 --timeout 55000
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/integration/client_secret_lifetime_poll_exchange_test.exs test/integration/app_lifetime_rfc8693_test.exs --max-failures 1 --timeout 55000
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/integration/client_secret_lifetime_existing_tokens_test.exs test/integration/client_secret_lifetime_poll_exchange_test.exs test/integration/app_lifetime_online_consumers_test.exs --max-failures 1 --timeout 55000
```

## TDD Evidence

- 164-04-01 RED: poll regressions failed because approved grants issued at secret equality; after the authority fix C041 passed.
- 164-04-02 RED: exchange succeeded at final requester equality; neighboring regressions passed, then C042 passed after revalidation.
- 164-04-03 RED: a temporary generic secret-gate mutation failed the non-secret regression while the existing-token regression passed. The mutation was removed and C043 passed. This is regression evidence, not a phase-wide strict TDD claim.

No temporary formatter or test dependency remains.

## Deviations from Plan

None. Implementation stayed within plan scope.

## Issues Encountered

- The first existing-token fixture omitted `offline_access`, so it had no refresh token. The fixture was corrected; final verification covered expired-secret rejection and refresh success after rotation.
- `state.update-progress` skipped because STATE.md has no body `Progress:` line, and `roadmap.update-plan-progress 164` skipped because ROADMAP.md has no writable Phase 164 detail entry. The requested SDK updates were attempted; no manual phase-completion or requirement update was made.

## Known Stubs

None found in files created or modified by this plan.

## Threat Flags

None. Authority is set at trusted entrypoints; no new network or storage trust boundary was added.

## Next Phase Readiness

Plan 164-04 is complete. Plan 164-05 owns independent PostgreSQL lock/rotation-race proof; plan 164-06 owns remaining full-suite and cross-phase evidence. No Phase 165 or 166 requirement is claimed complete.

---
*Phase: 164-client-secret-expiry-atomic-rotation*
*Completed: 2026-10-21*

## Self-Check: PASSED

The summary exists, all three task commits are ancestors of HEAD, and the measured plan commit count is three. No new TODO/FIXME/placeholder stubs or tracked deletions were found.
