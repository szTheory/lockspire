# Phase 100: Sender-Constraint End-to-End Proof - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove end-to-end that a DPoP-bound and an mTLS-bound `at+jwt` — now that Phase 99's `AccessTokenSigner` copies `%Token{}.cnf` into the JWT via `maybe_put_cnf/2` — traverse the canonical `VerifyToken → EnforceSenderConstraints → RequireToken` pipeline and arrive as a usable `%Lockspire.AccessToken{}` at the host controller; and close the sender-constraint bypass that exists when a pipeline omits `EnforceSenderConstraints`.

In scope: a DPoP-bound `at+jwt` (carrying `cnf.jkt`) verified end-to-end to a `200` with `conn.assigns.access_token` populated (BIND-01); an mTLS-bound `at+jwt` (carrying `cnf["x5t#S256"]`) verified end-to-end to a `200` (BIND-02); and a **runtime fail-closed guard plus a contract-test ordering clause** so a misordered/omitting pipeline can no longer silently accept a bound token (BIND-03).

Out of scope (lands later in v1.27): adoption-demo smoke proving `200` with an issued `at+jwt` against `/api/billing/summary` (Phase 101, DEMO-01..03); install-template canonical-block uncomment, `[:lockspire, :rs, :token_format]` telemetry, `docs/upgrading/v1.27.md` migration guide, and `mix lockspire.doctor token_format` (Phase 102). Phase 100 adds NO new protocol breadth and does NOT change issuance (Phase 99), the verifier's claim/header rules (Phase 98), `/userinfo`, or `/introspect`. The one piece of new runtime code is the BIND-03 fail-closed guard described in D-01..D-04 — a deliberate, scoped exception to "proof only" that BIND-03's own wording permits (it carries no "no new enforcer code" caveat, unlike BIND-01/02).

**Scope note — deliberate expansion beyond pure proof:** BIND-01 and BIND-02 are pure proof (no new enforcer code). BIND-03 adds a small runtime guarantee (one struct field + two small plug edits) because research found this is the only option that satisfies the RFC 9449 §7.2 MUST-reject and matches Lockspire's documented secure-by-default posture. See `<specifics>` for the full rationale and `<deferred>` for the larger architectural follow-up this points to.
</domain>

<decisions>
## Implementation Decisions

### BIND-03 bypass closure — runtime fail-closed guard + contract-test ordering clause (defense-in-depth)

- **D-01:** Add a `binding_verified` field to `%Lockspire.AccessToken{}` (`lib/lockspire/access_token.ex`), **defaulting to `false`** — a fail-closed default ("not verified until something proves otherwise"). Do NOT remove or repurpose any of the existing seven fields. This is the explicit, named breadcrumb that records "sender constraints were enforced," replacing the current state where `RequireToken` cannot tell "EnforceSenderConstraints ran and passed" from "it was omitted."
- **D-02:** `Lockspire.Plug.EnforceSenderConstraints` sets `binding_verified: true` on the `access_token` assign on **every success path** where it actually validated a binding — the DPoP-success→mTLS-skip path, the mTLS-success path, and the DPoP+mTLS-both-success path (`enforce_sender_constraints.ex:67-78,111-128`). The bearer/unconstrained no-op path (`binding_requirements` is `nil`) is unchanged and leaves `binding_verified: false` — that value is never consulted for unbound tokens (see D-03). This is the one bit of new enforcer code in the phase.
- **D-03:** `Lockspire.Plug.RequireToken` (`require_token.ex:20-35`) gains a fail-closed clause, ordered **before** the existing `%AccessToken{error: nil, claims: present} -> conn` pass-through: when a token has `binding_requirements != nil` **and** `binding_verified == false` (i.e. a bound token reached `RequireToken` without enforcement having marked it), halt fail-closed with a sender-constraint error (`403`, `error: "invalid_token"`, sender-constraint `error_description`, challenge derived from binding type like the existing sender-constraint path). **Disambiguator (the surprise-free guarantee):** the guard fires ONLY for tokens that arrived bound; bearer-only routes carry `binding_requirements: nil` and pass through exactly as today. There is no legitimate configuration in which a bound token should be honored without its proof checked, so the guard has zero false-positive surface.
- **D-04:** Do **NOT** clear `binding_requirements` on success as the verified-signal. The host controller reads `binding_requirements` off `conn.assigns.access_token` for legitimate visibility (the `phase81` proof controller asserts `binding_requirements: %{dpop_jkt: jkt}`). Use the positive `binding_verified` breadcrumb (D-01) instead — clearing the field would destroy host-facing data and conflate "verified" with "absent."
- **D-05:** Also add the contract-test layer (defense-in-depth, mirroring Phase 98's both-mechanisms posture for VERIFIER-06): a `release_readiness_contract_test` clause asserting all four RECIPE-01 canonical pipeline sites order `VerifyToken → EnforceSenderConstraints → RequireToken`. Reuse the existing `extract_canonical_pipeline!/2` helper and the four-file iteration the audience clause already uses (`release_readiness_contract_test.exs:140-157,761-791`); assert ordering via byte-offset comparison or a single `~s` multiline regex over the normalized block. **All four blocks already declare the three plugs in correct order today**, so this clause is satisfied by current content and does NOT ripple the four-file content hash.

### BIND-01 — DPoP-bound `at+jwt` end-to-end proof

- **D-06:** Prove BIND-01 by running a DPoP-bound `at+jwt` (carrying `cnf.jkt`) through the real `GeneratedHostAppWeb.Endpoint` whose `:lockspire_protected_api` pipeline is exactly the canonical 3-plug chain (`test/support/generated_host_app_web/router.ex:19-27`), supplying a valid `DPoP:` proof (with the nonce-challenge/retry dance), and asserting `200` with `conn.assigns.access_token` populated and `binding_type: "dpop"`. Lift the existing harness in `test/integration/phase81_generated_host_route_protection_e2e_test.exs:150-215` (DPoP proof via `JarTestHelpers.sign_dpop_proof/2`, `jkt` via `DPoP.thumbprint/1`).
- **D-07:** Mint the bound token via `Lockspire.Protocol.AccessTokenSigner.issue/3` with a `%Token{cnf: %{"jkt" => jkt}}` — exercising Phase 99's `maybe_put_cnf/2` carry-through — **rather than** hand-signing with `JOSE.JWT.sign` as `phase81` does. This is the refinement over `phase81`: BIND-01 must prove that *the Phase 99 signer's `cnf` carry-through* survives the pipeline, not just that the plug chain works on a hand-crafted JWT.

### BIND-02 — mTLS-bound `at+jwt` end-to-end proof

- **D-08:** Prove BIND-02 (genuinely new — no existing full-pipeline mTLS-to-`200` test) by minting an `at+jwt` with `cnf["x5t#S256"]` and presenting the bound client cert via `conn.private[:lockspire_mtls_cert]` — the primary path in `EnforceSenderConstraints.fetch_mtls_cert/2` (`enforce_sender_constraints.ex:178-189`). Derive the token's `cnf["x5t#S256"]` from the same cert string via `Lockspire.Protocol.MTLSTokenBinding.thumbprint/1` so `confirmation_matches?/2` (`mtls_token_binding.ex:22-27`) passes. Assert `200` with `conn.assigns.access_token` populated and `binding_type: "mtls"`. Mint via `AccessTokenSigner.issue/3` per D-07 (synthetic string cert is sufficient for the proof; a real DER-cert/`:mtls_extractor` path is not required — see `<deferred>`).

### Bound-token issuance fixture

- **D-09:** Issue both bound tokens via `AccessTokenSigner.issue/3` and publish the signing key to `KeyCache` so `VerifyToken` resolves the `kid` (the `verify_token_test.exs:39-91` / `access_token_signer_test.exs:21-31` recipe: generate key → `Repository.publish_key/1` → `send(KeyCache, :refresh)` → sign). Do NOT drive a full DB-backed token-endpoint exchange (clients, grants, DPoP-at-`/token`, mTLS client-auth) — that is heavier than the proof needs and the signer path is faithful to the thing being proven (signer `cnf` carry-through → verifier → enforcer).

### Test placement

- **D-10:** Add one new `test/integration/phase100_sender_constraint_e2e_test.exs` (`@moduletag :integration`, `@endpoint GeneratedHostAppWeb.Endpoint`, `async: false`, mirroring `phase81`) holding the BIND-01 (DPoP) and BIND-02 (mTLS) happy-path proofs side-by-side. Add the BIND-03 contract-ordering clause (D-05) to the existing `test/lockspire/release_readiness_contract_test.exs`. Add a BIND-03 **negative** runtime test (a bound token through a `VerifyToken → RequireToken` pipeline that omits `EnforceSenderConstraints` returns fail-closed `403`, while a bearer token through the same pipeline still returns `200`) at the plug layer (alongside `enforce_sender_constraints_test.exs` / `require_token` tests) — this is the observable proof that D-01..D-03 closed the bypass without surprising bearer-only routes.

### Claude's Discretion

- Exact name/shape of the BIND-03 fail-closed clause and its error map in `RequireToken`, provided it routes through the existing sender-constraint error/challenge emission (`handle_structured_error`/`handle_invalid_token`) and returns `403` for the bound-but-unverified case (D-03).
- Whether `EnforceSenderConstraints` sets `binding_verified: true` by re-assigning the `access_token` at each success return or via one shared helper, provided every binding-validated success path sets it and the no-op bearer path does not (D-02).
- Exact ordering-assertion technique in the contract test (offset comparison vs multiline regex), provided it composes with `extract_canonical_pipeline!/2` and does not introduce a parallel extraction path (D-05).
- Exact DPoP proof/nonce-retry construction and key-publish plumbing in the new test, provided BIND-01 mints through `AccessTokenSigner.issue/3` (D-07/D-09).
- Exact synthetic cert string and `cnf["x5t#S256"]` derivation for BIND-02, provided the presented cert and the token's confirmation thumbprint agree via `MTLSTokenBinding.thumbprint/1` (D-08).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase boundary and prior decisions
- `.planning/PROJECT.md` — v1.27 milestone goal; Branch A + JWT-default issuance Key Decision; standing sustainment-default policy
- `.planning/REQUIREMENTS.md` — BIND-01/02/03 verbatim (lines 44-46); traceability (Phase 100 = 3 reqs); Out-of-Scope rationale; RS-DPoP-01 deferred replay-store durability gap (line 91)
- `.planning/ROADMAP.md` — Phase 100 goal + three success criteria; build-order rationale (Phase 100 between 99 and 101 so the canonical pipeline the demo mirrors is proven safe against misordering first)
- `.planning/STATE.md` — milestone position, decisions log, session continuity
- `.planning/METHODOLOGY.md` — assumption-first decisive defaults, least-surprise host seam, high-threshold escalation
- `.planning/phases/97-contract-docs-first/97-CONTEXT.md` — RECIPE-01 four canonical-pipeline files and content-hash machinery the BIND-03 D-05 clause extends
- `.planning/phases/98-plug-hardening/98-CONTEXT.md` — D-05 challenge-derivation taxonomy the BIND-03 guard's challenge must match; D-07 both-mechanisms (option + contract test) posture BIND-03 D-05 mirrors
- `.planning/phases/99-signer-extraction-jwt-default-issuance/99-CONTEXT.md` and `99-LEARNINGS.md` — `maybe_put_cnf/2` conditional-`cnf`-copy pattern (the thing BIND-01/02 prove survives); `AccessTokenSigner.issue/3` shape; the signer-test `cnf` carry-through proof

### Runtime surfaces Phase 100 reads + the three it edits for BIND-03
- `lib/lockspire/access_token.ex` — the 7-field struct; **edited by D-01** (adds `binding_verified: false`)
- `lib/lockspire/plug/verify_token.ex` — `binding_requirements/1` at lines 528-537 derives `%{dpop_jkt: ...}` / `%{mtls_x5t_s256: ...}` from the `cnf` claim; set onto the struct at line 134 (read-only for Phase 100 — confirms a `cnf`-carrying JWT yields non-nil `binding_requirements` so enforcement fires)
- `lib/lockspire/plug/enforce_sender_constraints.ex` — success paths at lines 67-78, 111-128 (DPoP `{:ok,_}`, mTLS success, both); `fetch_mtls_cert/2` at 178-189 (`conn.private[:lockspire_mtls_cert]` primary path BIND-02 uses); **edited by D-02** (sets `binding_verified: true` on success)
- `lib/lockspire/plug/require_token.ex` — call clauses at lines 20-35; structured-error/challenge emission at 86-93, 48-61; **edited by D-03** (adds the bound-but-unverified fail-closed clause)

### Issuance + binding primitives (read-only)
- `lib/lockspire/protocol/access_token_signer.ex` — `issue/3` and `maybe_put_cnf/2` (mints the `cnf`-carrying `at+jwt`; the issuance fixture for D-07/D-09)
- `lib/lockspire/protocol/mtls_token_binding.ex` — `thumbprint/1` (lines 7-17) and `confirmation_matches?/2` (22-27) — BIND-02's `cnf["x5t#S256"]` derivation + match
- `lib/lockspire/protocol/dpop.ex` — `thumbprint/1` (BIND-01's `jkt`); `check_typ/1`
- `lib/lockspire/protocol/protected_resource_dpop.ex` — `validate_access/2` (the DPoP proof check `EnforceSenderConstraints` calls; BIND-01 must satisfy it end-to-end)
- `lib/lockspire/domain/token.ex` — the `cnf:` field (line ~53) the signer reads

### Test harness to lift + extend
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs` — the DPoP end-to-end harness (lines 150-215) BIND-01 lifts; hand-signs the JWT today (D-07 replaces that with `AccessTokenSigner.issue/3`)
- `test/support/generated_host_app_web/router.ex` — `:lockspire_protected_api` pipeline = the canonical 3-plug chain (lines 19-27); the endpoint BIND-01/02 run against
- `test/support/generated_host_app_web/controllers/protected_api_controller.ex` — surfaces `binding_type`/`binding_requirements` for assertion (and the reason D-04 must NOT clear `binding_requirements`)
- `test/lockspire/plug/enforce_sender_constraints_test.exs` — `dpop_fixture/2` (~279-311) and the `put_private(:lockspire_mtls_cert, ...)` + `MTLSTokenBinding.thumbprint/1` patterns BIND-02 reuses; canvas for the BIND-03 negative test
- `test/lockspire/plug/verify_token_test.exs` — `generate_key_and_token/2` (39-91) KeyCache publish-then-sign recipe for D-09
- `test/lockspire/protocol/access_token_signer_test.exs` — `MockKeyStore` (21-31) and the `cnf` carry-through assertion (~247-256)
- `test/lockspire/release_readiness_contract_test.exs` — `extract_canonical_pipeline!/2` + four-file iteration (140-157); audience-substring clause (761-791) the BIND-03 ordering clause (D-05) parallels

### The four RECIPE-01 canonical pipeline files (D-05 asserts ordering across all four; already compliant)
- `docs/protect-phoenix-api-routes.md` (lines 17-21)
- `examples/adoption_demo/lib/adoption_demo_web/router.ex` (lines 24-28)
- `priv/templates/lockspire.install/router.ex` (lines 13-16, commented)
- `scripts/demo/adoption_smoke.py` (lines 245-249, commented)

### Standards
- RFC 9449 §7.1 / §7.2 — DPoP at the resource server; **§7.2 MUST-reject**: a protected resource MUST reject a DPoP-bound access token received as a bearer token (the normative basis for the BIND-03 runtime guard)
- RFC 8705 §3 — mTLS certificate-bound access tokens (`x5t#S256` confirmation)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The `phase81` DPoP end-to-end test already proves the full happy path (DPoP-bound token → real 3-plug endpoint → `200` → populated `access_token`); BIND-01 is largely lift-and-refine (swap the hand-signed JWT for an `AccessTokenSigner.issue/3` mint).
- `GeneratedHostAppWeb.Endpoint`'s `:lockspire_protected_api` pipeline IS the canonical 3-plug chain — BIND-01 and BIND-02 do not need a new endpoint or router.
- `EnforceSenderConstraints` already reads `conn.private[:lockspire_mtls_cert]` first (`fetch_mtls_cert/2`), so BIND-02 presents a cert with a one-line `put_private` rather than standing up a TLS chain.
- `MTLSTokenBinding.thumbprint/1` makes the bound token's `cnf["x5t#S256"]` trivially reproducible from the same cert string the test presents.
- `AccessTokenSigner.issue/3` + the `KeyCache` publish-then-sign recipe (`verify_token_test.exs:39-91`) is the complete, faithful issuance fixture — no DB-backed grant fixtures required.
- The `release_readiness_contract_test` four-file extraction machinery (Phase 97/98) is reused as-is for the BIND-03 ordering clause — no new extraction path.

### Established Patterns
- Fail-closed default for a security-load-bearing flag: `binding_verified: false` until enforcement proves otherwise (D-01) — mirrors how Guardian's downstream plugs treat absent prerequisite state.
- One explicit, named breadcrumb consumed only by the sibling plug in the documented pipeline (D-01/D-02/D-03) — an explicit cross-plug signal, not an implicit/ambient one. Idiomatic for a fixed library-owned pipeline (cf. Guardian `Plug.Pipeline` private state).
- Both-mechanisms defense-in-depth (runtime guarantee + contract-test proof) repeats Phase 98's VERIFIER-06 posture (D-05).
- Discovery/issuance carry-through proven via the signer test, then proven end-to-end via an integration test — the same proof ladder Phase 99 used for `cnf`.

### Integration Points
- The BIND-03 guard composes with Phase 98's challenge taxonomy: a bound-but-unverified rejection should emit a challenge consistent with `EnforceSenderConstraints.sender_error/2` / `mtls_error/0` (DPoP-bound → `DPoP`; mTLS-bound → `Bearer`) so the `WWW-Authenticate` story stays coherent.
- The new `binding_verified` field flows through the existing `RequireToken` clauses; existing tests that run the full 3-plug pipeline on a bound token (e.g. `phase81`) stay green because `EnforceSenderConstraints` now sets `binding_verified: true` before `RequireToken` runs. Any pre-existing test that ran a bound token through `VerifyToken → RequireToken` *without* `EnforceSenderConstraints` will newly fail-closed — that is the intended behavior change and must be reconciled, not worked around.
- Phase 101's adoption-demo re-wire (DEMO-01..03) mirrors the canonical pipeline Phase 100 proves safe; running Phase 100 first means the pipeline the demo copies is already proven against misordering.
- The runtime guard is forward-compatible with a future single composed `Plug.Builder` pipeline (see `<deferred>`): the `binding_verified` invariant holds whether the three plugs are hand-composed or wrapped in one umbrella plug.
</code_context>

<specifics>
## Specific Ideas

- Preferred Phase 100 feel: **prove the binding survives, and make the bypass unreachable — not just untested.** BIND-01/02 are pure proof; BIND-03 buys a runtime guarantee for the small cost of one fail-closed field.
- The BIND-03 decision was researched, not assumed. Two independent research passes (ecosystem/idiomatic-Elixir + Lockspire's own `prompts/` corpus) converged on runtime fail-closed + contract test:
  - **RFC 9449 §7.2** states the resource server MUST reject a DPoP-bound token presented as bearer — Option B (contract-test only) leaves a spec-MUST violation reachable at runtime for any host that omits the plug.
  - **CVE-2024-49755 (Duende IdentityServer)** is this exact bypass class — insufficient `cnf` enforcement letting a bound token be used without proof — already shipped by a serious vendor. Proof-only would ship the precondition for the same CVE in adopters' hands.
  - **Lockspire's corpus** is explicit: "secure-by-default even when setup is stricter"; "make dangerous policy downgrades explicit and visible"; "ship as the *only* default"; golden rule "what a token says / how it's issued, library owns" (proof-of-possession is library-owned protocol truth, not a host composition choice); and the corpus's own downgrade-footgun pattern (PKCE: "reject exchange if client registered PKCE but omitted it") is *runtime rejection*.
  - **Idiomatic Elixir:** Guardian's downstream plugs fail-closed on absent prerequisite state and compose via `Plug.Builder` — cross-plug coupling here is idiomatic, not an anti-pattern.
- The disambiguator is the crux that makes the guard surprise-free: it fires ONLY for a token that arrived bound (`binding_requirements != nil`) yet reached `RequireToken` unverified. Bearer-only routes (`binding_requirements: nil`) are untouched. `EnforceSenderConstraints` is already a documented no-op for unconstrained tokens, so no legitimate config trips the guard.
- Implementation shape is decided: positive `binding_verified` breadcrumb (default `false`), NOT clearing `binding_requirements` (the host controller reads it). An explicit named field beats an absence-signal.
- BIND-01 must mint via the real signer (`AccessTokenSigner.issue/3`), not a hand-signed JWT — otherwise the proof doesn't exercise Phase 99's change, only the plug chain.

## Methodology Lenses Applied
- **Assumption-first decisive defaults / one-shot bundle:** BIND-01/02/issuance/placement (areas B–E) resolved decisively from real call sites and confirmed by the user in one pass.
- **Research-first on the one genuinely product-shaping decision:** BIND-03 is a security-posture + public-surface choice, so it was escalated, researched against ecosystem + corpus, and resolved with a single evidence-backed recommendation (the user delegated: "one-shot a perfect set so I don't have to think").
- **Least-surprise host seam:** the fail-closed guard fires only for the genuinely-unsafe case (bound token, enforcement skipped); bearer-only routes are unaffected.
- **High-threshold escalation:** the architectural reshape (single composed pipeline plug) is deferred, not forced into a proof phase.
</specifics>

<deferred>
## Deferred Ideas

- **Export the protected-route pipeline as a single composed `Plug.Builder` unit** (e.g. `plug Lockspire.ProtectedAPI, scopes: [...], audience: ...`) so the secure ordering is the only orderable thing and omission of `EnforceSenderConstraints` becomes *structurally impossible* rather than runtime-detected. This is the idiomatic Elixir end-state (cf. Guardian `Plug.Pipeline`) and the root-cause fix for the bypass class. **Out of scope for Phase 100** — it reshapes the public plug surface, the `mix lockspire.install` router template, and the four RECIPE-01 canonical blocks. The Phase 100 `binding_verified` guard is forward-compatible with it. Recommend tracking as a v1.28+ candidate / roadmap backlog item.
- **Real DER-cert / `:mtls_extractor` end-to-end proof for BIND-02** — Phase 100 uses a synthetic string cert via `conn.private[:lockspire_mtls_cert]`, which faithfully exercises `confirmation_matches?/2`. A proof driving a real certificate chain through an `:mtls_extractor` (and the generated host's mTLS pipeline wiring) is heavier and not required for BIND-02; revisit only if adopter evidence shows the extractor path needs end-to-end coverage.
- **Full token-endpoint issuance fixture** (DB-backed clients/grants, DPoP-at-`/token`, mTLS client-auth) instead of `AccessTokenSigner.issue/3` — more faithful to where `cnf` originates in production (`TokenEndpointDPoP.resolve_context`), but far heavier than this proof phase needs. Defer unless a reviewer requires `cnf` to originate from a real exchange.
- **DPoP-at-RS replay-store durability gap (RS-DPoP-01)** — already deferred in REQUIREMENTS.md Future Requirements; Phase 100 does not address replay-store durability, only that the bound proof is checked end-to-end.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 100 scope.
</deferred>

---

*Phase: 100-sender-constraint-end-to-end-proof*
*Context gathered: 2026-05-28*
