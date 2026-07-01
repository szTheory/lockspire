---
phase: 100-sender-constraint-end-to-end-proof
plan: "03"
subsystem: testing
tags: [elixir, jwt, dpop, mtls, sender-constraint, integration-test, access-token-signer, cnf, binding]

# Dependency graph
requires:
  - phase: 100-sender-constraint-end-to-end-proof-01
    provides: binding_verified breadcrumb (D-01/D-02/D-03), EnforceSenderConstraints marks binding_verified:true, RequireToken 403 fail-closed guard
  - phase: 100-sender-constraint-end-to-end-proof-02
    provides: A1 confirmed list-aud accepted by VerifyToken; BIND-03 pipeline-ordering contract clause
  - phase: 99-signer-extraction-jwt-default-issuance
    provides: AccessTokenSigner.issue/3 with maybe_put_cnf/2 carry-through, typ:at+jwt emission

provides:
  - BIND-01 DPoP end-to-end proof: signer-minted DPoP-bound at+jwt traverses real 3-plug pipeline through nonce-retry dance to 200
  - BIND-02 mTLS end-to-end proof: signer-minted mTLS-bound at+jwt with matching cert to 200 with binding_type mtls
  - test.phase100.e2e mix alias for targeted e2e proof runs

affects:
  - Phase 101 (Adoption-Demo Re-Wire) — demonstrates D-07 AccessTokenSigner.issue/3 signer pattern that adoption demo should adopt
  - Phase 102 (Generated-Host Scaffolding) — the BIND-01/02 proofs are the canonical happy-path references

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "D-07 signer-mint integration test pattern: %Token{cnf: ...} -> AccessTokenSigner.issue/3 -> raw at+jwt (never JOSE.JWT.sign for access tokens)"
    - "Mandatory KeyCache sync: send(KeyCache, :refresh) -> :sys.get_state(KeyCache) before any sign/verify; prevents async race -> flaky unknown-kid"
    - "mTLS thumbprint agreement: MTLSTokenBinding.thumbprint(cert) used for BOTH cnf value and conn.private[:lockspire_mtls_cert]; confirmation_matches?/2 passes only when source is identical"
    - "DPoP nonce-retry dance: 3-request mandatory shape (no-nonce->401 use_dpop_nonce, with-nonce->200); single-shot 200 not possible"

key-files:
  created:
    - test/integration/phase100_sender_constraint_e2e_test.exs
  modified:
    - mix.exs

key-decisions:
  - "Both BIND-01 and BIND-02 proofs live side-by-side in one file (D-10) — enables co-evolution and side-by-side comparison of the two binding approaches"
  - "list aud ['billing-api'] used throughout (A1 confirmed) — no string-aud workaround needed"
  - "expires_at from DateTime.add(3600, :second) passed to %Token{} — base_claims/3 reads it but AccessTokenSigner overrides with iat + @access_token_ttl_seconds"

patterns-established:
  - "Integration test signer-mint recipe: %Token{required_no_default_keys + cnf} + %Client{access_token_format: :jwt} + request %{opts: [key_store: Config.repo!()]} -> AccessTokenSigner.issue/3"
  - "Phase 100 proof hierarchy: plug-unit (Plan 01) -> contract ordering (Plan 02) -> e2e signer proof (Plan 03)"

requirements-completed: [BIND-01, BIND-02]

# Metrics
duration: 5min
completed: 2026-05-28
---

# Phase 100 Plan 03: Sender-Constraint End-to-End Proof Summary

**BIND-01 (DPoP) + BIND-02 (mTLS) signer-minted at+jwt e2e proofs: AccessTokenSigner.issue/3 cnf carry-through survives the VerifyToken->EnforceSenderConstraints->RequireToken pipeline through the nonce-retry dance to 200, confirming Wave 1's binding_verified breadcrumb is wired end-to-end**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-28T20:03:00Z
- **Completed:** 2026-05-28T20:08:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created `test/integration/phase100_sender_constraint_e2e_test.exs` with both BIND-01 (DPoP) and BIND-02 (mTLS) proofs side-by-side
- BIND-01: signer-minted `%Token{cnf: %{"jkt" => jkt}}` -> `AccessTokenSigner.issue/3` -> mandatory 3-request nonce dance (401 use_dpop_nonce -> 200) -> `binding_type: "dpop"`, `binding_requirements: %{"dpop_jkt" => jkt}` verified at controller
- BIND-02: signer-minted `%Token{cnf: %{"x5t#S256" => x5t}}` -> `AccessTokenSigner.issue/3` -> Bearer + `conn.private[:lockspire_mtls_cert]` presented (same source as thumbprint) -> `binding_type: "mtls"` verified at controller (no nonce dance)
- Both proofs use `publish_signing_key/1` (publishes both public JWK for VerifyToken/KeyCache and private JWK for the signer) with mandatory `:sys.get_state(KeyCache)` sync point
- Added `test.phase100.e2e` mix alias mirroring `test.phase30.e2e` pattern
- Anti-cheat verification: no `JOSE.JWT.sign` for access tokens; both use `AccessTokenSigner.issue/3`

## Task Commits

Both tasks implemented and committed together as the test file was created in one pass:

1. **Tasks 1 + 2: BIND-01 DPoP + BIND-02 mTLS e2e proofs via AccessTokenSigner.issue/3** - `f2a36d8` (feat)

## Files Created/Modified

- `test/integration/phase100_sender_constraint_e2e_test.exs` - New integration test file with BIND-01 (DPoP nonce-retry dance to 200) and BIND-02 (mTLS cert-binding to 200) proofs, `publish_signing_key/1` helper verbatim from phase81, `generate_dpop_proof/3` verbatim from phase81, `protected_conn/0` with host/port pin
- `mix.exs` - Added `test.phase100.e2e` alias to `aliases/0` and `preferred_envs/0`

## Decisions Made

- Committed both BIND-01 and BIND-02 in a single task commit since both proofs were implemented together in one file creation pass — TDD structure acknowledged: these tests prove correctness of prior Wave 1 work, not new implementation
- Worktree symlinks for `deps` and `_build` created pointing to main project's shared directories (same pattern as Wave 1 summary documented)

## Deviations from Plan

None — plan executed exactly as written. The A1 confirmation from Plan 02 was applied (list aud used throughout, no mitigation needed). Both BIND-01 and BIND-02 came up green on first run because the Wave 1 infrastructure was already in place.

## Issues Encountered

**Pre-existing integration test failures (out of scope):**
`test/integration/phase81_generated_host_route_protection_e2e_test.exs` (5 failures) and `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` (2 failures) are failing due to Phase 98's strict `typ: "at+jwt"` RFC 9068 enforcement. Those tests use the old `JOSE.JWT.sign` hand-signing approach (without the `typ: "at+jwt"` header). Phase 100's tests demonstrate the correct approach (using `AccessTokenSigner.issue/3` which emits `typ: "at+jwt"` automatically). Documented in `deferred-items.md`. NOT caused by Phase 100 Plan 03 changes — these files were not modified.

**Worktree `deps`/`_build`:** Normal worktree isolation — symlinks created to main project shared dirs.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None — both BIND-01 and BIND-02 proofs are fully wired assertions against live pipeline behavior. No stub patterns introduced.

## Threat Flags

None — this plan adds test-only files. No new network endpoints, auth paths, file access patterns, or schema changes introduced.

## TDD Gate Compliance

Both tasks marked `tdd="true"`. The gate behavior was:
- **RED phase:** Tests go straight to GREEN on first run because Wave 1 (Plans 01/02) already delivered the runtime infrastructure — the `binding_verified` breadcrumb, `EnforceSenderConstraints` marking it `true` on success, and `RequireToken`'s 403 guard. The failing state existed BEFORE Wave 1.
- **GREEN phase:** Both proofs green on first run — no implementation needed (this is a verification/proof plan; all primitives existed).

Per the plan frontmatter (`depends_on: ["100-01", "100-02"]`), this plan is a proof that Wave 1 work is wired end-to-end. TDD gate passes: the implementation (Wave 1) is proven correct by the tests (this plan).

## Next Phase Readiness

- BIND-01 and BIND-02 are both proven end-to-end with faithful proofs (real signer, real nonce dance, real cert-thumbprint agreement)
- Phase 100 overall: all three plans complete — BIND-03 runtime guard (Plan 01), BIND-03 contract ordering (Plan 02), BIND-01/02 e2e proofs (Plan 03)
- Phase 101 (Adoption-Demo Re-Wire) can proceed; the D-07 signer-mint pattern in this file is the canonical reference for what the adoption demo should adopt (replacing its own JOSE.JWT.sign hand-signing where applicable)

---
*Phase: 100-sender-constraint-end-to-end-proof*
*Completed: 2026-05-28*
