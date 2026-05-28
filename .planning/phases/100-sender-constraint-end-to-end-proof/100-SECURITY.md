# Security Audit — Phase 100: Sender-Constraint End-to-End Proof

**ASVS Level:** 2
**block_on:** high
**Audited:** 2026-05-28
**Disposition:** SECURED — 11/11 threats closed (9 mitigate verified in code, 2 accept verified by rationale)

The threat register was authored at plan time and is complete. Each mitigation was verified against the implemented code (file:line evidence below). Implementation files were not modified.

## Threat Verification

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-100-01 | Elevation/Spoofing | mitigate | CLOSED | `lib/lockspire/plug/require_token.ex:26-28` — fail-closed `call/2` clause `%AccessToken{error: nil, binding_requirements: req, binding_verified: false} when not is_nil(req)` routes to `handle_sender_constraint_bypass/2`; `:99-112` sends 403 + halts. Clause ordered BEFORE the pass-through (`:30`). |
| T-100-02 | Spoofing | mitigate | CLOSED | `lib/lockspire/access_token.ex:14` — `binding_verified: false` as last (kw-form) defstruct field; `:30` declares `binding_verified: boolean()` in `@type`. Default is `false`, not nil. |
| T-100-03 | Tampering/Repudiation | mitigate | CLOSED | `lib/lockspire/plug/enforce_sender_constraints.ex:130-135` — `mark_binding_verified/1` sets `binding_verified: true` reading the current struct from `conn.assigns`. Reached ONLY from the mTLS-success `with` body (`:118`) and the DPoP-only-success catch-all (`:128`). The unbound entry no-op (`:62-63`), the DPoP-error arm (`:104-105` → `:75-76`), and the mTLS-error arms (`:120-124`) never call it. |
| T-100-04 | DoS (false-positive) | accept | CLOSED | See Accepted Risks Log #1. Guard gated on `not is_nil(req)` (`require_token.ex:27`); bearer/unbound tokens (`binding_requirements: nil`) skip the guard and hit the pass-through (`:30`). `error: nil` gate (`:26`) excludes error-carrying bound tokens. Zero false-positive surface. |
| T-100-05 | Elevation/Tampering | mitigate | CLOSED | `test/lockspire/release_readiness_contract_test.exs:1187-1205` — iterates the four `{path,kind}` RECIPE-01 tuples via the shared `extract_canonical_pipeline!/2`, asserts `v < e and e < r` on real byte offsets (`byte_offset/2` at `:1207-1212`, flunks on `:nomatch`). Genuinely fails on transposition; no permissive regex. |
| T-100-06 | Elevation (cross-API reuse) | mitigate | CLOSED | `lib/lockspire/plug/verify_token.ex:275-280` — `normalize_token_audiences/1` accepts list `aud` only when all elements are non-empty strings, rejects `[]`. A1 spike assertion added in `test/lockspire/plug/verify_token_test.exs` (per 100-02-SUMMARY). The Phase 98 `enforce_audience` + `audience:` mitigation continues to bite for signer-emitted list aud. |
| T-100-07 | Tampering/Repudiation | mitigate | CLOSED | `test/integration/phase100_sender_constraint_e2e_test.exs:84-115` — genuine nonce-retry dance: request 1 (no nonce) asserts 401 `use_dpop_nonce` + `dpop-nonce` header; request 2 (with nonce) asserts 200. `ath` bound to the real minted token via `DPoP.access_token_ath(access_token)` (`:209`). Exercises the wired ProtectedApiReplayStore (no stub). |
| T-100-08 | Spoofing | mitigate | CLOSED | `test/integration/phase100_sender_constraint_e2e_test.exs:121-149` — `cert` and `cnf["x5t#S256"]` derived from the SAME string via `MTLSTokenBinding.thumbprint(cert)` (`:123`); cert presented via `put_private(:lockspire_mtls_cert, cert)` (`:149`); `confirmation_matches?/2` enforced at `enforce_sender_constraints.ex:117`. 200 + `binding_type: "mtls"` asserted at controller (`:152-158`). |
| T-100-09 | Tampering | mitigate | CLOSED | `lib/lockspire/protocol/access_token_signer.ex:165-175` — `sign_jwt/2` destructures `kid`, `alg`, `private_jwk` from `fetch_signing_key/1` (`:166-167`), which reads `fetch_active_signing_key([])` (`:202`). JWS header `%{"alg" => alg, "kid" => kid, "typ" => "at+jwt"}` is built solely from active-key fields; client-influenced `claims` never reach the header. No `alg:none` path. |
| T-100-10 | Elevation (cross-API reuse) | mitigate | CLOSED | `test/integration/phase100_sender_constraint_e2e_test.exs:71,133` — both bound tokens mint `audience: ["billing-api"]`; the canonical pipeline declares `audience: "billing-api"` (router, enforced by the T-100-05 contract clause and verify_token matcher). |
| T-100-SC | Tampering | accept | CLOSED | See Accepted Risks Log #2. No npm/pip/cargo installs in any Phase 100 plan; all changes are Elixir source/test edits. `tech-stack.added: []` in all three SUMMARYs. |

## Accepted Risks Log

1. **T-100-04 — DoS via false-positive RequireToken guard.** The bound-but-unverified 403 guard could in principle fail-close a legitimate request. Rationale verified to hold: the guard is gated on `not is_nil(req)` AND `binding_verified: false` AND `error: nil` (`require_token.ex:26-27`). Bearer/unbound tokens carry `binding_requirements: nil` and bypass the guard entirely; error-carrying bound tokens carry `error != nil` and reach the existing error clauses. No legitimate configuration trips it. Accepted.

2. **T-100-SC — Supply-chain via package installs.** No package-manager installs occur in Phase 100. Verified: no `mix.lock` dependency additions, `tech-stack.added: []` across 100-01/02/03 SUMMARYs; the only `mix.exs` change is a test alias (`test.phase100.e2e`). Not applicable surface. Accepted.

## Unregistered Flags

None. All three SUMMARYs declare `## Threat Flags: None` (test-only and source edits; no new network endpoints, auth paths, file-access patterns, or schema changes). No new attack surface appeared during implementation that lacks a threat mapping.

## Notes

- Implementation files inspected read-only; no modifications made.
- 100-03-SUMMARY notes pre-existing failures in `phase81_*` and `phase32_*` integration tests due to Phase 98's strict `typ: "at+jwt"` enforcement. These are outside the Phase 100 threat register, are not regressions introduced by Phase 100 (those files were not modified), and do not affect any declared mitigation here.
