---
phase: 132-public-api-and-resource-server-truth
verified: 2026-08-27T00:24:19Z
status: passed
score: 8/8
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 8/8
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 132: Public API and Resource-Server Truth Verification Report

**Phase Goal:** Adopters can use documented client and resource-server APIs without relying on raw claims or unsupported implementation details.
**Verified:** 2026-08-27T00:24:19Z
**Status:** passed
**Re-verification:** Yes — final integration fixes `3938a4a` and `2ac56ce`

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Resource servers can read normalized subject, scopes, audiences, expiry, and confirmation through additive `Lockspire.AccessToken` readers. | VERIFIED | `AccessToken` exports five total readers and preserves the original struct and `claims`; direct malformed-value tests and signed-token tests passed. |
| 2 | Route enforcement and public readers give scope, audience, and sender confirmation the same meaning. | VERIFIED | `VerifyToken` delegates to `AccessToken.scopes/1`, `normalize_audiences/1`, and `normalize_confirmation/1`; the focused signed-JWT parity suite passed. |
| 3 | Raw claims remain a compatible, explicitly low-level path rather than a removed API. | VERIFIED | No struct field was removed; the guide and v1.37 upgrade notes retain `access_token.claims` for compatibility/extension use. |
| 4 | Direct and dynamic registration accept advertised `openid`, `private_key_jwt`, and device-only shapes. | VERIFIED | Both facades call `Lockspire.ClientRegistration.Shape`; DCR now intentionally permits omitted optional scope metadata while the direct facade still rejects an empty required scope list; focused direct/DCR/discovery/controller tests passed. |
| 5 | Redirect-capable clients remain constrained to nonempty valid redirects and exact runtime membership. | VERIFIED | Shared shape validation requires redirects for `authorization_code` or `code`; `AuthorizationRequest` uses `redirect_uri in client.redirect_uris`; negative protocol tests passed. |
| 6 | Private-key client registration remains confidential, key-constrained, and redaction-safe. | VERIFIED | Shared validator requires exactly one safe key source, validates inline public JWKS/algorithm compatibility, and accepts only HTTPS `jwks_uri`; focused registration tests passed. |
| 7 | DPoP replay recording uses the configured durable repository by default and custom stores fail closed. | VERIFIED | `EnforceSenderConstraints` omits nil overrides, `ProtectedResourceDPoP` selects `Storage.Ecto.Repository`, and the integration test persisted once then rejected the identical proof. Custom-store failure coverage passed. |
| 8 | The guide, generated fixture/demo, authorization boundary, and upgrade guidance match the compiled behavior. | VERIFIED | The generated controller and adoption demo call all five readers and make a host-owned authorization decision; generated-host integration proves both 200 and host 403 paths; docs/release contracts and `mix docs.verify` passed. |

**Score:** 8/8 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/lockspire/access_token.ex` | Additive normalized token readers | VERIFIED | Five public readers plus strict internal audience/confirmation normalizers. |
| `lib/lockspire/plug/verify_token.ex` | Shared enforcement semantics | VERIFIED | Calls the AccessToken normalization seam for scopes, audiences, and confirmation. |
| `lib/lockspire/client_registration/shape.ex` | Neutral registration capability validator | VERIFIED | Direct and DCR adapters share the same redirect, OIDC, and key-source checks. |
| `lib/lockspire/clients.ex` and `lib/lockspire/protocol/registration.ex` | Public registration adapters | VERIFIED | Preserve facade-specific error/result behavior while persisting accepted fields. |
| `lib/lockspire/plug/enforce_sender_constraints.ex` and `lib/lockspire/protocol/protected_resource_dpop.ex` | Durable/fail-closed DPoP path | VERIFIED | Default repository selection and compatible custom-store boundary are wired. |
| `docs/protect-phoenix-api-routes.md`, `docs/upgrading/v1.37.md` | Truthful resource-server and migration contract | VERIFIED | Exact reader names/types, replay default, boundary, and additive compatibility are documented. |
| Generated template/fixture/demo | Executable adopter examples | VERIFIED | Fixture controller and adoption demo use semantic readers; integration executes generated behavior. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `VerifyToken` | `AccessToken` | scope/audience/confirmation normalization | WIRED | Direct calls at `verify_token.ex:241`, `:270`, `:464`, `:528`, and `:547`; manual source check resolves the generic helper's escaped-regex false negative. |
| `Clients` and `Registration` | `ClientRegistration.Shape` | shared capability validation | WIRED | Both adapters invoke `RegistrationShape.validate/2`; focused facade tests passed. |
| `AuthorizationRequest` | persisted client redirects | exact membership | WIRED | `redirect_uri in client.redirect_uris` at `authorization_request.ex:274`; mismatch tests passed. |
| sender plug | protected-resource DPoP | omitted override/default store | WIRED | Plug omits nil option; protocol selects repository; default-store integration persisted and replay-rejected. |
| generated controller | `AccessToken` | all five readers and host policy | WIRED | Real compiled fixture calls each reader; E2E covers authorized and forbidden outcomes. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Semantic-reader/verifier parity, registration safety, and custom-store failures | `mix test test/lockspire/access_token_test.exs test/lockspire/plug/verify_token_test.exs test/lockspire/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/controllers/registration_controller_test.exs test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs` | 267 tests, 0 failures | PASS |
| Final DCR scope-boundary and sender-confirmation integration fixes | `mix test test/lockspire/protocol/registration_test.exs test/lockspire/clients_test.exs test/integration/phase100_sender_constraint_e2e_test.exs` | 69 tests, 0 failures | PASS |
| Durable default replay, generated resource route, docs/release contracts | `mix test --include integration test/integration/protected_resource_dpop_default_store_test.exs test/lockspire/storage/ecto/repository_dpop_replay_test.exs test/integration/install_generator_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs test/lockspire/release/support_surface_contract_test.exs test/lockspire/release_readiness_contract_test.exs` | 57 tests, 0 failures | PASS |
| Documentation and warning-free compilation | `mix docs.verify && mix compile --warnings-as-errors` | Both commands exited 0 | PASS |

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
| --- | --- | --- | --- |
| API-01 | 132-01, 132-04 | SATISFIED | Additive readers, verifier parity, raw-claims compatibility, and executable reader examples. |
| API-02 | 132-02, 132-04 | SATISFIED | Shared direct/DCR capability matrix, safe `private_key_jwt`, device-only allowance, exact redirect enforcement. |
| API-03 | 132-03, 132-04 | SATISFIED | Configured-repository default, durable uniqueness path, custom-store injection, and fail-closed evidence. |
| API-04 | 132-04 | SATISFIED | Canonical guide, generated fixture, adoption demo, support/upgrade documentation, and drift contracts match runtime behavior. |

### Anti-Patterns Found

No blockers or warnings found. The phase-modified production, documentation, template, fixture, and example files contain no unresolved `TBD`, `FIXME`, or `XXX` markers. The only generic key-link helper misses two valid Elixir call patterns because its supplied regular expressions are double-escaped; direct source inspection above verifies those links.

### Scope Boundary Check

Phase 132 did not add a separate-origin client journey, full lifecycle acceptance app, broad dependency-topology enforcement, new grant, or host-owned product-policy API. Those remain Phase 133/134 or explicit non-goals; this phase limits itself to truthful in-library public contracts and focused executable proofs.

---

_Verified: 2026-08-27T00:24:19Z_
_Verifier: the agent (gsd-verifier)_
