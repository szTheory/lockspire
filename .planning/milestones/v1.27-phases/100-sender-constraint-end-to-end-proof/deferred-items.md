# Deferred Items — Phase 100 Plan 03

## Pre-existing Integration Test Failures (Out of Scope)

The following integration test failures exist in the worktree but are NOT caused by
Phase 100 Plan 03 changes. They are pre-existing breakage caused by Phase 98's
strict RFC 9068 `typ: "at+jwt"` enforcement landing before the hand-signed
integration tests (phase81, phase32) were updated to use `AccessTokenSigner.issue/3`.

**Root cause:** `phase81_generated_host_route_protection_e2e_test.exs` uses
`JOSE.JWT.sign` to mint tokens without setting `"typ" => "at+jwt"` in the header.
Phase 98's `VerifyToken` plug now rejects any JWT where `typ != "at+jwt"` with
`reason_code: invalid_typ`. The phase81 test assertions were written against the
pre-Phase-98 plug behavior.

**Affected tests (5 failures in phase81 file):**
- `test protected route returns 200 with the assigns contract for a valid bearer token`
- `test protected route returns 401 invalid_token for audience mismatch`
- `test protected route returns 403 insufficient_scope for a valid but under-scoped token`
- `test protected route keeps sender-constraint enforcement active for DPoP-bound tokens`
- `test protected route keeps the insufficient_scope split for DPoP-bound under-scoped tokens`

**Also affected:**
- `phase32_device_flow_token_exchange_e2e_test.exs` (2 failures) — same root cause
- `Lockspire.Audit.AuditWriterTest` (2 failures) — different root cause (likely DB state)

**Why out of scope:** These failures exist in files Phase 100 Plan 03 does NOT
modify. The scope boundary rule prohibits fixing pre-existing failures in unrelated
files. Phase 100 Plan 03 deliberately demonstrates the CORRECT approach (using
`AccessTokenSigner.issue/3` which emits `typ: "at+jwt"`) and both Phase 100 tests
pass green.

**Recommended fix:** Update `phase81_generated_host_route_protection_e2e_test.exs`
and `phase32_device_flow_token_exchange_e2e_test.exs` to use `AccessTokenSigner.issue/3`
instead of hand-signing with `JOSE.JWT.sign` — the same D-07 refinement Phase 100
demonstrates. This is a candidate for Phase 101 (Adoption-Demo Re-Wire) or a
separate cleanup plan.
