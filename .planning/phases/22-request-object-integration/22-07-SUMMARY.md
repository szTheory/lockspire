---
phase: 22-request-object-integration
plan: 07
subsystem: request-object-integration
tags: [jar, e2e, par, integration, canonical-flow]
requires: [22-03, 22-04, 22-05, JAR-01]
provides: [phase15-par-jar-e2e-proof]
affects: [test/integration/phase15_par_authorization_e2e_test.exs]
tech-stack: [Elixir, ExUnit, Phoenix.ConnTest, JOSE]
key-files: [test/integration/phase15_par_authorization_e2e_test.exs]
decisions: [D-03, D-10, D-21]
metrics:
  duration: "~20m"
  completed_date: 2026-04-25
---

# Phase 22 Plan 07: JAR-via-PAR E2E Proof Summary

One new integration branch proves a signed request object can go `/par` -> `request_uri` -> `/authorize` -> consent -> `/token` without changing the downstream PAR auth-code + PKCE flow.

## What Changed

- Added a new JAR-by-value e2e test branch at `test/integration/phase15_par_authorization_e2e_test.exs:230`.
- Reused existing Phase 15 helpers and assertions; no new test file was created.
- Added `JarTestHelpers` usage and Basic-auth PAR coverage with a fresh confidential client fixture.

## Verification

- `mix test test/integration/phase15_par_authorization_e2e_test.exs --include integration --trace` ✅
- `mix test --include integration` ❌ blocked by pre-existing `test/lockspire/release_readiness_contract_test.exs` wording expectation
- `mix test` ❌ blocked by the same pre-existing release-readiness failure
- Acceptance checks confirmed the new test name, `JarTestHelpers`, `request_uri_prefix`, and nonce assertion are present.

## Deviations from Plan

### Auto-fixed Issues

None.

### Deferred Issues

- Full-suite verification still fails on an older milestone-wording assertion in `test/lockspire/release_readiness_contract_test.exs`.
- `gsd-sdk query state.advance-plan` and `roadmap.update-plan-progress` did not apply cleanly, so STATE.md/ROADMAP.md were synchronized manually for this plan.

## Self-Check

PASSED
