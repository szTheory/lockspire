---
phase: 100-sender-constraint-end-to-end-proof
verified: 2026-05-28T20:21:02Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
---

# Phase 100: Sender-Constraint End-to-End Proof Verification Report

**Phase Goal:** A DPoP-bound `at+jwt` and an mTLS-bound `at+jwt` both traverse the `VerifyToken → EnforceSenderConstraints → RequireToken` pipeline end-to-end producing a usable `%AccessToken{}` at the host controller, and a pipeline missing `EnforceSenderConstraints` after `VerifyToken` is no longer a silent bypass path.
**Verified:** 2026-05-28T20:21:02Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

The three roadmap Success Criteria, plus the plan-frontmatter must-have truths across all three plans (merged, deduped).

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| SC1 | DPoP-bound `at+jwt` (cnf.jkt) with valid DPoP proof on host protected route → 200 with `conn.assigns.access_token` populated | ✓ VERIFIED | `phase100_..._e2e_test.exs:59-116`: signer-minted token, real 3-plug pipeline, nonce dance (401 use_dpop_nonce → 200), asserts `binding_type: "dpop"` + `binding_requirements: %{"dpop_jkt" => ^jkt}`. **Ran `mix test.phase100.e2e` → 2 tests, 0 failures.** |
| SC2 | mTLS-bound `at+jwt` (cnf x5t#S256) presenting bound cert → 200 with `conn.assigns.access_token` populated | ✓ VERIFIED | `phase100_..._e2e_test.exs:119-159`: cert + x5t from same source (lines 121-123), `put_private(:lockspire_mtls_cert, cert)`, asserts 200 + `binding_type: "mtls"`. Same passing run. |
| SC3 | Pipeline omitting `EnforceSenderConstraints` fail-closes 403/401 in RequireToken when binding_requirements non-nil, OR contract test asserts misorder cannot ship | ✓ VERIFIED | BOTH layers present: runtime guard `require_token.ex:26-28` (403 for bound-but-unverified) + contract clause `release_readiness_contract_test.exs:1187-1204` (offset ordering across 4 RECIPE-01 sites). |
| P01-1 | `%AccessToken{}` carries `binding_verified` defaulting to false | ✓ VERIFIED | `access_token.ex:14` `binding_verified: false`; `:30` `binding_verified: boolean()` in `@type`. |
| P01-2 | EnforceSenderConstraints sets `binding_verified: true` on every binding-validated success (DPoP, mTLS, both); unbound no-op leaves it false | ✓ VERIFIED | `mark_binding_verified/1` (`:130-135`) called at mTLS-success `:118` and DPoP-only catch-all `:128`; failure arms (`:121,:124`), `{:error,...}` arm (`:76`), and unbound `_other -> conn` (`:62-63`) never set it. |
| P01-3 | Bound token (error: nil, binding_requirements != nil, binding_verified: false) reaching RequireToken halts 403 with binding-derived challenge | ✓ VERIFIED | `require_token.ex:26-28` clause ordered FIRST; `handle_sender_constraint_bypass/2` (`:99-112`) sends 403; `sender_constraint_bypass_error/1` (`:117-132`) derives :dpop/:bearer. Proven by require_token_test.exs (in 129-test green run). |
| P01-4 | Bearer (unbound, binding_requirements: nil) token passes RequireToken unchanged — zero false-positive surface | ✓ VERIFIED | Guard gated on `not is_nil(req)` (`:27`); bearer hits pass-through `:30`. Negative test in require_token_test.exs green. |
| P01-5 | Existing bound-token error tests stay green (D-03 gated on error: nil) | ✓ VERIFIED | `error: nil` gate on `:26`; full verify_token_test.exs + require_token_test.exs green (129 tests, 0 failures). |
| P02-1 | Contract test asserts all four RECIPE-01 sites order Verify → Enforce → Require, failing on transposition | ✓ VERIFIED | `release_readiness_contract_test.exs:1187-1204` offset comparison `v < e and e < r`; `byte_offset/2` (`:1207-1212`) flunks on nomatch. Green. |
| P02-2 | Ordering clause reuses `extract_canonical_pipeline!/2` + four {path,kind} tuples — no parallel extractor | ✓ VERIFIED | `:1196` calls the shared `extract_canonical_pipeline!/2` (`:140`); same four tuples as audience clause. |
| P02-3 | List-valued aud passes VerifyToken audience matcher when audience: set (A1 spike) | ✓ VERIFIED | `verify_token_test.exs:354-372` asserts `["billing-api"]` token accepted with `audience: "billing-api"`, `error == nil`. Green. |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/lockspire/access_token.ex` | binding_verified: false field + boolean() type | ✓ VERIFIED | Field at `:14`, type at `:30`; 7 prior fields still bare-atom (nil default). |
| `lib/lockspire/plug/enforce_sender_constraints.ex` | mark_binding_verified on success paths | ✓ VERIFIED | Helper `:130`, wired at `:118` and `:128`; failure/unbound paths untouched. |
| `lib/lockspire/plug/require_token.ex` | fail-closed bypass clause + 403 handler | ✓ VERIFIED | Clause `:26-28`, handler `:99-112`, error builder `:117-132`. |
| `test/lockspire/plug/require_token_test.exs` | bound→403, bearer→pass clauses | ✓ VERIFIED | Part of 129-test green run. |
| `test/lockspire/release_readiness_contract_test.exs` | D-05 ordering clause + byte_offset/2 | ✓ VERIFIED | `:1187-1212`. |
| `test/lockspire/plug/verify_token_test.exs` | A1 list-aud assertion | ✓ VERIFIED | `:354-372`. |
| `test/integration/phase100_sender_constraint_e2e_test.exs` | BIND-01 DPoP + BIND-02 mTLS e2e proofs | ✓ VERIFIED | Both tests `:59`, `:119`; uses `AccessTokenSigner.issue` (`:82,:143`), no JOSE hand-sign. |
| `mix.exs` | test.phase100.e2e alias | ✓ VERIFIED | `:78-81` mirrors test.phase3.e2e; `:128` preferred env. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| enforce_sender_constraints.ex | access_token.ex | sets binding_verified: true | ✓ WIRED | `:132` `%AccessToken{at \| binding_verified: true}`. |
| require_token.ex | access_token.ex | reads binding_verified + binding_requirements | ✓ WIRED | `:26` pattern-matches both off assign. |
| require_token.ex | protected_resource_challenge.ex | 403 path → put_dpop_challenge | ✓ WIRED | `:103` `ProtectedResourceChallenge.put_dpop_challenge`; category :sender_constraint at `:125`. |
| contract test | four RECIPE-01 files | extract_canonical_pipeline!/2 | ✓ WIRED | `:1196`. |
| e2e test | access_token_signer.ex | AccessTokenSigner.issue/3 | ✓ WIRED | `:82,:143`. |
| e2e test | GeneratedHostAppWeb pipeline | Phoenix.ConnTest get/2 | ✓ WIRED | `:92,:106,:150` `get(@protected_route)`. |
| e2e test | KeyCache | send(:refresh) + :sys.get_state | ✓ WIRED | `:197-198`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| protected_api_controller.ex (200 body) | access_token.binding_type / binding_requirements | Real `conn.assigns.access_token` populated by VerifyToken→Enforce pipeline | Yes — e2e test asserts the real cnf-derived `^jkt` value, not a literal | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| BIND-01 DPoP + BIND-02 mTLS e2e to 200 | `mix test.phase100.e2e` | 2 tests, 0 failures | ✓ PASS |
| Plan 01 + Plan 02 unit/contract suite | `mix test <5 files>` | 129 tests, 0 failures | ✓ PASS |
| Clean compile | `mix compile --warnings-as-errors` | no output (clean) | ✓ PASS |

### Probe Execution

No `scripts/*/tests/probe-*.sh` declared or implied for this phase. Verification ran via the declared `mix test.phase100.e2e` alias and direct `mix test` of supporting files (above). N/A.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| BIND-01 | 100-02, 100-03 | DPoP-bound at+jwt verified end-to-end → usable %AccessToken{} | ✓ SATISFIED | e2e test BIND-01 case green; 200 + dpop binding metadata. |
| BIND-02 | 100-02, 100-03 | mTLS-bound at+jwt verified end-to-end | ✓ SATISFIED | e2e test BIND-02 case green; 200 + mtls binding_type. |
| BIND-03 | 100-01, 100-02 | Misordered/omitting pipeline fails closed in RequireToken OR asserted by contract test | ✓ SATISFIED | Runtime guard (require_token.ex) + contract ordering clause; both green. |

All three declared requirement IDs accounted for. No orphaned requirements (REQUIREMENTS.md maps exactly BIND-01/02/03 to Phase 100; all three claimed across plan frontmatter).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (none) | — | — | — | No TBD/FIXME/XXX/HACK/PLACEHOLDER in any phase-modified file. |

### Human Verification Required

None. Both adopter-facing Success Criteria (SC1, SC2) are fully exercised by automated integration proofs that drive the real `GeneratedHostAppWeb.Endpoint` 3-plug pipeline and assert at the host controller (200 + populated `conn.assigns.access_token` with correct binding metadata). There is no residual visual/UX/external-service dimension requiring manual testing.

### Pre-Existing Failures (Not Phase 100 Regressions)

Per the verification brief and `deferred-items.md`: 9 pre-existing integration test failures (phase81 ×5, phase32 ×2, AuditWriter ×2) stem from Phase 98's strict `typ: "at+jwt"` enforcement landing before those hand-signed tests were updated. They live in files Phase 100 did NOT modify and are documented as Phase 98 tech debt. The Phase 100 e2e tests deliberately demonstrate the correct `AccessTokenSigner.issue/3` approach and both pass. Not attributed to this phase; not a blocker.

### Gaps Summary

No gaps. All 11 must-have truths verified, all 8 artifacts substantive and wired, all 7 key links connected, data flows through to the controller, all three requirement IDs satisfied, no anti-patterns, clean compile. The phase goal is achieved at every level: the DPoP-bound and mTLS-bound proofs reach 200 through the real pipeline (SC1/SC2), and the sender-constraint bypass is closed by BOTH a runtime fail-closed guard and a structural contract assertion (SC3).

---

_Verified: 2026-05-28T20:21:02Z_
_Verifier: Claude (gsd-verifier)_
