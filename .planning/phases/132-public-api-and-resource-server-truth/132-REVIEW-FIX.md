---
phase: 132-public-api-and-resource-server-truth
fixed_at: 2026-08-27T00:08:39Z
review_path: .planning/phases/132-public-api-and-resource-server-truth/132-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 132: Code Review Fix Report

**Fixed at:** 2026-08-27T00:08:39Z  
**Source review:** `.planning/phases/132-public-api-and-resource-server-truth/132-REVIEW.md`  
**Iteration:** 1

## Summary

- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: Audience normalization weakens the documented exact-match boundary

**Files modified:** `lib/lockspire/access_token.ex`, `test/lockspire/access_token_test.exs`, `test/lockspire/plug/verify_token_test.exs`  
**Commits:** `6924204`

Audience validation now rejects blank values without trimming accepted identifiers.
The signed-token verifier tests prove both whitespace-surrounded variants fail
an exact `audience: "billing-api"` check, while exact string and list claims
continue to pass. Focused semantic-reader/verifier suite: 83 tests, 0 failures.

### WR-01: `private_key_jwt` accepts and persists arbitrary maps as “validated” inline JWKS

**Files modified:** `lib/lockspire/client_registration/shape.ex`, `test/lockspire/clients_test.exs`, `test/lockspire/protocol/registration_test.exs`  
**Commits:** `574061b`, `563ea28`

The shared shape validator now requires a nonempty JWKS `keys` array whose
members are public, parseable JWKs and which includes a key usable by the
declared (or allowed default) `private_key_jwt` algorithm. It rejects private
members, malformed entries, empty sets, and algorithm-incompatible keys using
only `%{field: :jwks, reason: :invalid_public_jwks, detail: nil}`. Direct
registration and DCR each cover valid public JWKS plus empty/private/unparseable/
incompatible rejection and assert that submitted private material is absent from
errors. Focused registration suite: 66 tests, 0 failures.

### WR-02: The new resource-server truth fences do not cover the executable demo or behavior

**Files modified:** `examples/adoption_demo/lib/adoption_demo_web/controllers/api_controller.ex`, `scripts/demo/adoption_smoke.py`, `test/integration/phase81_generated_host_route_protection_e2e_test.exs`  
**Commit:** `5597d9a`

The adoption controller now uses `Lockspire.AccessToken` semantic readers,
returns plural `scopes` and `audiences`, and makes Billingo's subject-based
authorization decision explicit. The smoke payload asserts that semantic shape.
The generated-fixture router test executes both host-authorized (200) and
host-denied (403) requests and verifies the reader-derived response values;
source parity assertions remain supplemental drift protection. Fixture and
generator integration suites: 19 tests, 0 failures. Python smoke syntax check
also passed.

## Verification Notes

- `mix compile --warnings-as-errors` passed.
- `mix qa` found no new issue, but remains nonzero for a pre-existing Credo
  refactoring suggestion in `lib/lockspire/clients.ex:333` outside this review
  scope.

---

_Fixed: 2026-08-27T00:08:39Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
