---
phase: 81-scope-audience-restrictions-milestone-closure
verified: 2026-05-23T16:27:48+02:00
status: passed
score: 4/4 requirements verified
---

# Phase 81: Scope, Audience Restrictions & Milestone Closure Verification Report

**Phase Goal:** Route-level scope and audience restrictions, generated-host protected-route proof, and release-truthful docs all land together.
**Verified:** 2026-05-23T16:27:48+02:00
**Status:** passed

## Goal Achievement

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `VerifyToken` validates `scopes:` / `audience:` / `audiences:` and emits structured restriction failures without leaking token material. | ✓ VERIFIED | `test/lockspire/plug/verify_token_test.exs` passed with warnings as errors and covers option validation, audience mismatch, insufficient scope, and redaction-safe logs. |
| 2 | `RequireToken` is the single strict HTTP boundary and distinguishes `401 invalid_token` from `403 insufficient_scope`. | ✓ VERIFIED | `test/lockspire/plug/require_token_test.exs` passed and pins structured audience failures to `401` plus scope failures to `403` with `WWW-Authenticate` scope hints. |
| 3 | A generated host Phoenix route is provably protected with the shipped plug order for bearer and DPoP-bound access tokens. | ✓ VERIFIED | `test/integration/phase81_generated_host_route_protection_e2e_test.exs` passed and covers valid access, missing token, audience mismatch, insufficient scope, DPoP missing proof, and DPoP success. |
| 4 | Public docs, ExDoc extras, and release-readiness checks now describe the shipped protected-route surface truthfully. | ✓ VERIFIED | `mix docs --warnings-as-errors` passed, and `test/lockspire/release_readiness_contract_test.exs` passed after adding `docs/protect-phoenix-api-routes.md` and updating the supported-surface assertions. |

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/lockspire/plug/verify_token.ex` | Route restriction validation and typed soft-failure metadata | ✓ VERIFIED | Proven by the targeted `verify_token` suite from Plan 81-01. |
| `lib/lockspire/plug/require_token.ex` | Strict HTTP rendering for invalid token vs insufficient scope | ✓ VERIFIED | Proven by the targeted `require_token` suite from Plan 81-02. |
| `test/integration/phase81_generated_host_route_protection_e2e_test.exs` | End-to-end protected-route proof through generated-host Phoenix dispatch | ✓ VERIFIED | Covered in the final phase suite. |
| `docs/protect-phoenix-api-routes.md` | Canonical protected-route guide with plug order and ownership boundary | ✓ VERIFIED | Included in ExDoc and referenced by onboarding, Sigra companion, and supported-surface docs. |
| `test/lockspire/release_readiness_contract_test.exs` | Release-truth contract for the new protected-route support claim | ✓ VERIFIED | Passed with 21 tests, 0 failures. |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Docs build stays warning-free with the new guide in ExDoc | `mix docs --warnings-as-errors` | Passed | ✓ PASS |
| Release-readiness contract matches the shipped docs surface | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs --warnings-as-errors` | `21 tests, 0 failures` | ✓ PASS |
| Final protected-route phase suite passes end to end | `MIX_ENV=test mix test test/lockspire/plug/verify_token_test.exs test/lockspire/plug/require_token_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs test/lockspire/release_readiness_contract_test.exs --include integration --warnings-as-errors` | `52 tests, 0 failures` | ✓ PASS |

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `VAL-PLUG-01` | `81-02` | Protected-route boundary returns truthful OAuth HTTP semantics for invalid tokens, insufficient scope, and sender failures. | ✓ SATISFIED | `test/lockspire/plug/require_token_test.exs`, `test/integration/phase81_generated_host_route_protection_e2e_test.exs` |
| `VAL-PLUG-04` | `81-01` | Route-level scope and audience restrictions are enforced from `VerifyToken` options. | ✓ SATISFIED | `test/lockspire/plug/verify_token_test.exs` |
| `VAL-DX-02` | `81-03` | Docs show the canonical Phoenix protected-route pattern without broadening the product claim. | ✓ SATISFIED | `docs/protect-phoenix-api-routes.md`, `docs/install-and-onboard.md`, `docs/supported-surface.md`, `docs/sigra-companion-host.md` |
| `VAL-BIND-03` | `81-02` | DPoP-bound access tokens are enforced correctly on the shipped Phoenix route pipeline. | ✓ SATISFIED | `test/integration/phase81_generated_host_route_protection_e2e_test.exs` |

## Gaps Summary

No functional gaps found in the shipped Phase 81 surface.

One non-blocking observation remains: targeted test commands still log an early `KeyCache` refresh error before the test repo starts, but the relevant suites complete green and did not affect this phase's protected-route behavior or docs contract.
