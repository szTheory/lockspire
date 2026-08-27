---
phase: 132-public-api-and-resource-server-truth
reviewed: 2026-08-27T00:01:56Z
depth: deep
files_reviewed: 29
files_reviewed_list:
  - docs/code-walkthrough.md
  - docs/protect-phoenix-api-routes.md
  - docs/supported-surface.md
  - docs/upgrading/v1.37.md
  - examples/adoption_demo/lib/adoption_demo_web/router.ex
  - lib/lockspire/access_token.ex
  - lib/lockspire/client_registration/shape.ex
  - lib/lockspire/clients.ex
  - lib/lockspire/plug/enforce_sender_constraints.ex
  - lib/lockspire/plug/verify_token.ex
  - lib/lockspire/protocol/dcr_policy.ex
  - lib/lockspire/protocol/protected_resource_dpop.ex
  - lib/lockspire/protocol/registration.ex
  - priv/templates/lockspire.install/router.ex
  - scripts/demo/adoption_smoke.py
  - test/integration/install_generator_test.exs
  - test/integration/phase81_generated_host_route_protection_e2e_test.exs
  - test/integration/protected_resource_dpop_default_store_test.exs
  - test/lockspire/access_token_test.exs
  - test/lockspire/clients_test.exs
  - test/lockspire/plug/enforce_sender_constraints_test.exs
  - test/lockspire/plug/verify_token_test.exs
  - test/lockspire/protocol/protected_resource_dpop_test.exs
  - test/lockspire/protocol/registration_test.exs
  - test/lockspire/release/support_surface_contract_test.exs
  - test/lockspire/release_readiness_contract_test.exs
  - test/support/generated_host_app_web/controllers/protected_api_controller.ex
  - test/support/generated_host_app_web/router.ex
  - test/support/generated_host_app_web/router/lockspire.ex
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 132: Code Review Report

**Reviewed:** 2026-08-27T00:01:56Z  
**Depth:** deep  
**Files Reviewed:** 29  
**Status:** issues_found

## Summary

The review traced the new public claim readers into route enforcement, both
registration paths, the DPoP store boundary, and generated/demo documentation.
The configured-repository DPoP fallback is fail-closed and the direct/DCR shape
validator is a useful consolidation, but the shared audience parser changes an
authorization comparison from exact to whitespace-normalized. The documentation
and fixture drift tests also leave important executable examples and key-material
rules unproven.

Focused verification ran successfully:
`mix test test/lockspire/access_token_test.exs test/lockspire/plug/verify_token_test.exs`
(82 tests, 0 failures). That suite currently encodes the audience widening rather
than detecting it.

## Critical Issues

### CR-01: Audience normalization weakens the documented exact-match boundary

**File:** `lib/lockspire/access_token.ex:100-116`, `lib/lockspire/plug/verify_token.ex:238-263`

**Issue:** `normalize_audiences/1` calls `nonblank/1`, which trims each `aud`
value before `VerifyToken` compares it with the route's expected audience. A
signed token whose audience is `" billing-api "` now passes a route configured
with `audience: "billing-api"`; before this change the values did not compare
equal. `aud` is an identifier/StringOrURI authorization boundary, not a
whitespace-delimited presentation field. This contradicts the guide's statement
that audience checks are exact-match and can permit a token minted for a distinct
identifier to be accepted by the protected API. The new happy-path test at
`test/lockspire/access_token_test.exs:42-54` explicitly blesses this behavior.

**Fix:** Keep whitespace normalization for `scope`, but make audience
normalization validate nonblankness without altering the returned value. For
example, have a `nonblank_audience/1` predicate return the original binary when
`String.trim(value) != ""`; use that original value for both singleton and list
claims. Add verifier-level negative tests proving `" billing-api "` and
`"billing-api "` are rejected for `audience: "billing-api"` while genuinely
exact values still pass.

## Warnings

### WR-01: `private_key_jwt` accepts and persists arbitrary maps as “validated” inline JWKS

**File:** `lib/lockspire/client_registration/shape.ex:145-162`, `lib/lockspire/clients.ex:216-218`, `lib/lockspire/protocol/registration.ex:493-494`

**Issue:** The shared validator treats every map, including `%{}`, `%{"keys" => []}`,
or a JWK containing private parameters such as `"d"`, as a valid `jwks` source.
Both direct registration and DCR then persist that map unchanged. As a result the
new documentation's “exactly one validated key source” claim is false, clients
can be registered in a permanently unauthenticatable state, and accidental
private JWK input is stored as ordinary client metadata rather than rejected or
redacted. The tests exercise only map presence and never malformed/empty/private
JWK content.

**Fix:** Validate inline JWKS as a nonempty public JWK set before persistence:
reject private key members, require parseable public keys, and require at least
one usable key compatible with the declared/default `private_key_jwt` algorithm.
Return only field/reason errors (never the submitted map) and add the same
negative cases through both `Clients.register_client/1` and DCR.

### WR-02: The new resource-server truth fences do not cover the executable demo or behavior

**File:** `examples/adoption_demo/lib/adoption_demo_web/controllers/api_controller.ex:4-16`, `scripts/demo/adoption_smoke.py:319`, `test/integration/install_generator_test.exs:408-425`

**Issue:** Phase 132 updates the demo router to advertise the canonical pipeline,
but its actual protected controller still reparses raw claims and emits the old
singular `scope`/`audience` payload. The smoke script asserts that stale payload
at line 319. Meanwhile the new install-generator assertion merely reads the
static test fixture and searches for `AccessToken.<reader>(access_token)` strings;
it neither renders a controller from a template nor executes those reader and
host-policy branches. This leaves the public, executable adoption example outside
the stated semantic-reader/host-authorization contract and lets docs-looking
source drift pass the release fences.

**Fix:** Update the adoption demo controller and smoke assertion to use and assert
the semantic readers (including the plural `audiences` shape), with an explicit
host-owned authorization decision. Add a request-level test for the rendered
fixture/controller covering both allow and deny paths; retain source parity checks
only as supplemental drift protection.

---

_Reviewed: 2026-08-27T00:01:56Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: deep_
