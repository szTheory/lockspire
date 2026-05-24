---
phase: 84-host-plug-pipeline-docs-and-milestone-closure
verified: 2026-05-24T17:23:01+02:00
status: passed
score: 6/6 truths verified
---

# Phase 84: Host Plug Pipeline, Docs, and Milestone Closure Verification Report

**Phase Goal:** Extend the shipped host Phoenix plug contract and public support story to include nonce-backed DPoP while keeping the host-route seam narrow and truthful.
**Verified:** 2026-05-24T17:23:01+02:00
**Status:** passed
**Re-verification:** Yes — added after milestone audit flagged missing closure artifact

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The host plug pipeline now passes `conn.secret_key_base` into resource-side DPoP validation so nonce issuance works on generated host routes. | ✓ VERIFIED | `Lockspire.Plug.EnforceSenderConstraints` forwards `secret_key_base: conn.secret_key_base` at [lib/lockspire/plug/enforce_sender_constraints.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/enforce_sender_constraints.ex:95). |
| 2 | `/userinfo` and the host plug boundary share one DPoP challenge transport that emits consistent `WWW-Authenticate`, `DPoP-Nonce`, and exposed-header behavior. | ✓ VERIFIED | Shared transport lives at [lib/lockspire/web/protected_resource_challenge.ex](/Users/jon/projects/lockspire/lib/lockspire/web/protected_resource_challenge.ex:48) and exposes both headers at [lib/lockspire/web/protected_resource_challenge.ex](/Users/jon/projects/lockspire/lib/lockspire/web/protected_resource_challenge.ex:75); `/userinfo` uses it at [lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:50). |
| 3 | `RequireToken` remains the single strict HTTP boundary for host routes and preserves nonce retry handling without regressing bearer or scope semantics. | ✓ VERIFIED | Host-route DPoP rendering is asserted in [test/lockspire/plug/require_token_test.exs](/Users/jon/projects/lockspire/test/lockspire/plug/require_token_test.exs:106), including `Access-Control-Expose-Headers` at [test/lockspire/plug/require_token_test.exs](/Users/jon/projects/lockspire/test/lockspire/plug/require_token_test.exs:117). |
| 4 | Public support docs now describe only the shipped nonce-backed DPoP surface: Lockspire-owned `/token`, Lockspire-owned protected resources, and host Phoenix routes protected by the shipped plug pipeline. | ✓ VERIFIED | The supported-surface contract states that exact narrow claim at [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:31). |
| 5 | The optional host-route guide now documents the nonce retry contract while preserving the host-owned authorization boundary. | ✓ VERIFIED | The protected-route guide states the canonical plug order and nonce retry contract at [docs/protect-phoenix-api-routes.md](/Users/jon/projects/lockspire/docs/protect-phoenix-api-routes.md:7) and [docs/protect-phoenix-api-routes.md](/Users/jon/projects/lockspire/docs/protect-phoenix-api-routes.md:19). |
| 6 | Generated-host E2E proof demonstrates the real host-route retry path: first request challenged, second request with echoed nonce succeeds. | ✓ VERIFIED | The generated-host test asserts `error="use_dpop_nonce"` and exposed headers at [test/integration/phase81_generated_host_route_protection_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase81_generated_host_route_protection_e2e_test.exs:183) and [test/integration/phase81_generated_host_route_protection_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase81_generated_host_route_protection_e2e_test.exs:186). |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/lockspire/web/protected_resource_challenge.ex` | Shared protected-resource DPoP challenge transport | ✓ VERIFIED | Centralizes `WWW-Authenticate`, `DPoP-Nonce`, and exposed-header behavior for both `/userinfo` and host plugs. |
| `lib/lockspire/plug/enforce_sender_constraints.ex` | Explicit host-route `secret_key_base` handoff into DPoP validation | ✓ VERIFIED | Supplies the nonce-issuance secret on the host route seam. |
| `lib/lockspire/plug/require_token.ex` | Strict host-route boundary using the shared challenge transport | ✓ VERIFIED | Covered by targeted plug tests and generated-host E2E proof. |
| `lib/lockspire/web/controllers/userinfo_controller.ex` | `/userinfo` challenge rendering through the shared helper | ✓ VERIFIED | Uses the same helper to keep resource-side wire behavior consistent. |
| `docs/supported-surface.md` | Narrow support-truth wording for nonce-backed DPoP | ✓ VERIFIED | Claims only shipped surfaces, not generic gateways or third-party issuers. |
| `docs/protect-phoenix-api-routes.md` | Canonical host-route nonce retry contract | ✓ VERIFIED | Documents exact plug order, `401` retry contract, and ownership boundary. |
| `docs/install-and-onboard.md` | Canonical optional host-route path wording | ✓ VERIFIED | Points to the route guide without widening the product shape. |
| `test/integration/phase81_generated_host_route_protection_e2e_test.exs` | Generated-host nonce challenge and retry proof | ✓ VERIFIED | Proves the canonical plug pipeline in a host app context. |
| `test/lockspire/release_readiness_contract_test.exs` | Release-truth fence for shipped nonce-backed claims | ✓ VERIFIED | Asserts supported-surface and guide wording at [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:424), [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:458), and [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:821). |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Host-route, `/userinfo`, generated-host, and release-truth subset stays green | `MIX_ENV=test mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs test/lockspire/release_readiness_contract_test.exs` | `43 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `NONCE-RS-01` | `84-01` | Host Phoenix protected routes return a DPoP-aware `401` challenge plus `DPoP-Nonce` when the proof lacks a valid resource-server nonce. | ✓ SATISFIED | [enforce_sender_constraints.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/enforce_sender_constraints.ex:95), [require_token_test.exs](/Users/jon/projects/lockspire/test/lockspire/plug/require_token_test.exs:106) |
| `NONCE-RS-02` | `84-03` | Generated-host protected routes accept the retried request when the proof includes the supplied resource-server nonce. | ✓ SATISFIED | [phase81_generated_host_route_protection_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase81_generated_host_route_protection_e2e_test.exs:183) |
| `NONCE-RS-03` | `84-01` | Existing protected-route semantics remain unchanged outside nonce handling. | ✓ SATISFIED | [require_token_test.exs](/Users/jon/projects/lockspire/test/lockspire/plug/require_token_test.exs:24), [require_token_test.exs](/Users/jon/projects/lockspire/test/lockspire/plug/require_token_test.exs:49), [require_token_test.exs](/Users/jon/projects/lockspire/test/lockspire/plug/require_token_test.exs:106) |
| `NONCE-TRUTH-01` | `84-02` | `docs/supported-surface.md` truthfully describes the shipped nonce-backed DPoP surface. | ✓ SATISFIED | [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:31), [release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:821) |
| `NONCE-TRUTH-02` | `84-02` | DPoP docs describe the nonce challenge and retry contract while preserving the host-owned boundary. | ✓ SATISFIED | [docs/protect-phoenix-api-routes.md](/Users/jon/projects/lockspire/docs/protect-phoenix-api-routes.md:19), [docs/install-and-onboard.md](/Users/jon/projects/lockspire/docs/install-and-onboard.md:60), [release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:458) |
| `NONCE-TRUTH-03` | `84-03` | Repo-native tests prove nonce challenge and retry behavior for `/token`, `/userinfo`, and the generated-host protected-route pipeline. | ✓ SATISFIED | `/token` proof at [test/lockspire/web/token_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/token_controller_test.exs:337), `/userinfo` proof at [test/lockspire/web/userinfo_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/userinfo_controller_test.exs:233), generated-host proof at [test/integration/phase81_generated_host_route_protection_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase81_generated_host_route_protection_e2e_test.exs:183) |

### Human Verification Required

None.

### Gaps Summary

No functional or evidence gaps remain in Phase 84. The milestone audit blocker for this phase was missing closure evidence, and that has now been added with current passing test proof and explicit docs-truth references.

---

_Verified: 2026-05-24T17:23:01+02:00_
_Verifier: Codex_
