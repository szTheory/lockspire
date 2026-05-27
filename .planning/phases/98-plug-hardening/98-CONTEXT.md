# Phase 98: Plug Hardening - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

`Lockspire.Plug.VerifyToken` is narrowed to accept only RFC 9068 `at+jwt` access tokens, with the RFC 9068 / RFC 8725 / RFC 9449 compliance gaps that are currently silent or wrong made explicit and distinct. This closes the runtime-narrowing half of Phase 97's D-07 forward-reference caveat before Phase 99 flips default issuance to JWT.

In scope: opaque-token structural rejection on the verifier surface (VERIFIER-01); RFC 9068 §4 issuer pinning, §2.1 `typ: at+jwt` enforcement, and §2.2 mandatory `exp`/`iat`/`sub` enforcement (VERIFIER-02/03/04); `WWW-Authenticate` scheme derivation from the token's binding claim with the request's auth scheme as tiebreaker (VERIFIER-05); `enforce_audience:` opt-in option on `VerifyToken.init/1` plus a `release_readiness_contract_test` clause asserting every canonical-pipeline declaration carries `audience:` (VERIFIER-06).

Out of scope (lands later in v1.27): `Protocol.AccessTokenSigner` extraction and JWT-default issuance flip across AC/refresh/device/CIBA (Phase 99); DPoP-bound and mTLS-bound `at+jwt` end-to-end pipeline proof (Phase 100); adoption-demo smoke proving `200` with an issued `at+jwt` (Phase 101); install-template uncomment, telemetry `[:lockspire, :rs, :token_format]`, migration guide, and doctor task (Phase 102). Phase 98 does NOT touch `lib/lockspire/protocol/userinfo.ex`, `lib/lockspire/protocol/introspection.ex`, or `lib/lockspire/protocol/token_formatter.ex` — opaque tokens continue to back the Lockspire-owned RS endpoints unchanged.
</domain>

<decisions>
## Implementation Decisions

### Opaque-token rejection mechanism (VERIFIER-01)

- **D-01:** Detect opaque tokens by **structural shape** at the front of `verify_token/3` — before key fetch or signature verification — by checking that the trimmed token splits into exactly three non-empty Base64URL segments by `.`. Tokens that fail this structural check classify as `:opaque_token_not_accepted` and short-circuit to a structured invalid-token error with `challenge: :bearer`, `error: "invalid_token"`, `error_description: "opaque tokens not accepted on this route"`. This new check sits in front of the current `extract_kid/1` rescue path at `verify_token.ex:325-335` and replaces today's silent `:malformed` lumping for the opaque-shape case. Note: an existing test at `verify_token_test.exs:323-333` asserts `reason=malformed` on a three-segment-but-bad JWT (`"Bearer not.a.jwt"`) — that test stays valid because three-segment-but-bad still falls through to JOSE rejection; the new opaque-shape rejection only fires on shapes that are *not* three non-empty segments.

### RFC 9068 claim/header enforcement (VERIFIER-02, 03, 04)

- **D-02:** Add a single `validate_rfc9068_compliance/2` step that runs **after** `JOSE.JWT.verify_strict/3` succeeds (at the equivalent of `verify_token.ex:345-358`) and **before** `apply_restrictions/2`. It checks five things in this order, each producing a distinct `reason_code`:
  1. JWT protected header `typ == "at+jwt"` (case-insensitive per D-03) → `:invalid_typ`
  2. `claims["iss"] == Lockspire.Config.issuer!()` exact string compare → `:invalid_issuer`
  3. `claims["exp"]` is a positive integer → `:missing_exp`
  4. `claims["iat"]` is a positive integer → `:missing_iat`
  5. `claims["sub"]` is a non-empty string → `:missing_sub`
- **D-03:** The `typ` header comparison is **case-insensitive on the header value but exact-form on the literal `at+jwt`**. Accept `at+jwt`, `application/at+jwt`, `AT+JWT`. Reject `JWT`, `jwt`, missing, anything else. The comparison normalizes by lowercasing and stripping any `application/` prefix. This is intentionally more permissive than the issuance-side comparisons (`dpop.ex:168`, `rfc8693_exchange.ex:343`) so Phase 99's signer extraction can evolve issuance-side formatting (e.g., emit `application/at+jwt` for stricter conformance) without breaking the Phase 98 verifier.
- **D-04:** All five RFC 9068 reason codes from D-02 flow through the **structured error map shape** already established at `verify_token.ex:184-204` for audience/scope failures, NOT the bare-atom `error: :invalid_token` shape. Each reason gets a distinct `error_description`: `"access token is missing required \"sub\" claim"`, `"access token \"iss\" claim does not match expected issuer"`, etc. `RequireToken` at `require_token.ex:48-77` already handles both shapes on the wire — the structured map preserves the distinct `error_description` for the `WWW-Authenticate` emission required by Success Criterion #2.

### WWW-Authenticate scheme derivation (VERIFIER-05)

- **D-05:** Set `challenge:` on every VerifyToken-produced error map based on the **token's binding claim** as derived by the existing `binding_type/1` helper at `verify_token.ex:288-300`, with the **request's authorization scheme as a tiebreaker** for the no-binding case. Mapping:
  - token has `cnf.jkt` → `challenge: :dpop`
  - token has only `cnf["x5t#S256"]` → `challenge: :bearer` (RFC 8705 §3: mTLS-bound tokens reuse the Bearer scheme with the cert as the constraint; RFC 9449 §7.1 only redefines the scheme for DPoP)
  - no `cnf` claim AND request used `Authorization: DPoP ...` → `challenge: :dpop` (rare misconfigured-client path: bearer-shaped token presented under DPoP scheme — still a DPoP-shaped failure for protocol fidelity)
  - else → `challenge: :bearer`
- **D-06:** This derivation replaces the four hard-coded `challenge: :bearer` sites at `verify_token.ex:187, 198` and the implicit `:bearer` defaults in `require_token.ex:81, 99, 113`. The downstream emission path is unchanged: `ProtectedResourceChallenge.put_dpop_challenge/2` at `web/protected_resource_challenge.ex:37-44` already formats DPoP challenges (including the `algs="..."` parameter required by RFC 9449 §7.1) when `challenge: :dpop` reaches `require_token.ex:51`. This is wire-up, not new mechanism.

### `audience:` enforcement shape (VERIFIER-06)

- **D-07:** Phase 98 closes the VERIFIER-06 OR-clause with **both** mechanisms — the requirement allows either, and the codebase makes both cheap:
  - **Option mechanism:** add `enforce_audience: true | false` to `VerifyToken.init/1` (default `false` for back-compat with already-shipped pipelines that intentionally have no audience constraint — see `verify_token_test.exs:111-114` and other no-audience mounts). When `enforce_audience: true` is set and neither `:audience` nor `:audiences` is supplied, `init/1` raises `ArgumentError` (the existing `NimbleOptions` + mutual-exclusion raise at `verify_token.ex:42-44` is the pattern this extends).
  - **Contract-test mechanism:** add a `release_readiness_contract_test` clause that, for each of the four RECIPE-01 canonical-pipeline files, extracts the canonical block via the existing `extract_canonical_pipeline!/2` helper at `release_readiness_contract_test.exs:140-157` and asserts the extracted block contains a non-empty `audience:` substring inside the `Lockspire.Plug.VerifyToken, ...` line. This extends the four-file content-hash machinery from Phase 97 (`release_readiness_contract_test.exs:745-759`).
- **D-08:** The install template `priv/templates/lockspire.install/router.ex` keeps `enforce_audience: true` in its `:lockspire_protected_api` pipeline so new adopters get the loud `init/1` raise if they delete the `audience:` line. Existing host pipelines that intentionally omit `audience:` are unaffected by the option default-false.

### Claude's Discretion

- Exact naming and arity of the `validate_rfc9068_compliance/2` step inside `verify_token.ex`, provided the five checks run in the D-02 order, each emits its distinct `reason_code`, and the result flows through the structured error map shape per D-04.
- Exact `error_description` wording per reason code, provided each is distinct, names the violated RFC 9068 / RFC 8725 rule or claim, and is suitable for a `WWW-Authenticate: ... error_description="..."` header value (printable ASCII, no double-quote escaping ambiguity).
- Exact structure of the new test cases added to `test/lockspire/plug/verify_token_test.exs` for the five new reason codes plus the opaque-token rejection, provided each new assertion exercises both the response status and the structured error reason_code.
- Exact name of the new `release_readiness_contract_test` clause and helper for the `audience:` substring assertion (D-07), provided the helper composes with the existing `extract_canonical_pipeline!/2` rather than introducing a parallel extraction path.
- Whether the `binding_type/1` helper is extracted/renamed when it gains the third tiebreaker case (D-05's "request scheme as tiebreaker"), provided the binding-from-claim path stays its primary input and the tiebreaker is explicit rather than implicit.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase boundary and prior decisions

- `.planning/PROJECT.md` — v1.27 milestone goal; Branch A + JWT-default issuance Key Decision (lines 225-227); standing sustainment-default policy
- `.planning/ROADMAP.md` — Phase 98 goal/success criteria (lines 59-71); build-order rationale that Phase 98 must precede Phase 99 to avoid a window of incoherent issuance (lines 144-158)
- `.planning/REQUIREMENTS.md` — VERIFIER-01..06 verbatim (lines 24-29); DOCS-02 non-goals including "no auto-detection of token shape" (line 70); Out-of-Scope rationale (lines 103-110)
- `.planning/phases/97-contract-docs-first/97-CONTEXT.md` — D-06 contract sentence (line 30); D-07 forward-reference caveat (line 31) whose runtime half Phase 98 closes; D-09 "no auto-detection" non-goal (lines 36-40); D-13 `audience: "billing-api"` placeholder across all four RECIPE-01 files (line 47)
- `.planning/METHODOLOGY.md` — assumption-first, least-surprise host seam, research-first decisive defaults, high-threshold escalation, one-shot recommendation bundles

### Primary runtime surface Phase 98 hardens

- `lib/lockspire/plug/verify_token.ex` — the file Phase 98 narrows and hardens. Key sites: `init/1` at lines 39-51 (extension point for `enforce_audience:` per D-07); `extract_token/1` at lines 66-72; `verify_token/3` at lines 74-97 (front-edge insertion point for D-01); structured error shape at lines 184-204 (the shape D-02/D-04 generalize); `log_invalid_token/2` at lines 253-261; `binding_type/1` at lines 288-300 (the helper D-05 wires into challenge derivation); `extract_kid/1` rescue at lines 325-335 (silent `:malformed` lumping that D-01 fixes); `verify_signature_and_claims` at lines 344-358 (insertion point for `validate_rfc9068_compliance/2` per D-02); `time_claims_valid?/1` at lines 360-377 with the explicit gap comment at line 366 ("Missing exp is currently treated as valid")
- `test/lockspire/plug/verify_token_test.exs` — existing test canvas Phase 98 extends. Key sites: test JWT factory at lines 38-71 (Phase 98 needs an opaque-token fixture too); existing `reason=malformed` assertion at lines 323-347 (stays valid because three-segment-but-bad still falls through; opaque-shape rejection is a new path); no-audience mounts at lines 111-114 (the back-compat surface preserved by D-07's default-false on `enforce_audience:`)

### Neighboring plugs in the canonical pipeline

- `lib/lockspire/plug/enforce_sender_constraints.ex` — gate on `access_token.error` at lines 56-65 (why VerifyToken-side challenge derivation per D-05 matters: EnforceSenderConstraints never runs when VerifyToken short-circuits); existing `sender_error/2` and `mtls_error/0` shapes at lines 130-149 (the `challenge:` taxonomy D-05 must match)
- `lib/lockspire/plug/require_token.ex` — error-shape dispatch at lines 19-36; `handle_invalid_token` and `handle_structured_error` at lines 48-77; normalizers at lines 79-104 (where implicit `:bearer` defaults live that D-06 displaces); `www_authenticate` emission at lines 121-132
- `lib/lockspire/web/protected_resource_challenge.ex` — DPoP reason-code allowlist at lines 9-35; `put_dpop_challenge/2` at lines 37-44; DPoP `WWW-Authenticate` emission with `algs=` at lines 57-70 (the downstream path D-06 leaves intact)

### Opaque-token boundary surfaces (read-only for Phase 98)

- `lib/lockspire/protocol/token_formatter.ex` — lines 29-33 reveal the opaque shape (32 bytes, Base64URL, no dots) that D-01 structurally rejects
- `lib/lockspire/protocol/userinfo.ex` — lines 42-67 show the opaque-token consumption pattern Phase 98 must NOT touch
- `lib/lockspire/protocol/introspection.ex` — lines 48-58, same boundary
- `lib/lockspire/domain/token.ex` — lines 1-63, the durable token record with `cnf`, `audience`, `scopes` fields

### Issuer + claim shape that VERIFIER-02/04 must accept

- `lib/lockspire/config.ex` — lines 49-59 (`issuer!/0` — the function D-02 step 2 calls)
- `lib/lockspire/protocol/rfc8693_exchange.ex` — lines 317-361 (the only `at+jwt`-signing site today; shows exact claim shape `iss`/`sub`/`aud`/`exp`/`iat`/`client_id`/`jti`/`scope` that Phase 99's signer extraction generalizes — Phase 98's verifier must accept tokens this signer produces today and ones the extracted signer produces tomorrow)

### Existing `typ` enforcement pattern (precedent for D-03)

- `lib/lockspire/protocol/dpop.ex` — lines 168-169 (`check_typ/1` exact-match pattern, case-sensitive, no `application/` stripping — Phase 98's D-03 intentionally softens this for the verifier side)

### Contract-test infrastructure D-07's structural backstop attaches to

- `test/lockspire/release_readiness_contract_test.exs` — canonical-block file paths at lines 84-92; `extract_canonical_pipeline/1`, `normalize/2`, `canonical_hash!/2` helpers at lines 140-214; existing four-file hash compare clause at lines 745-759 (D-07 adds a parallel "all four declare `audience:`" clause)
- `examples/adoption_demo/lib/adoption_demo_web/router.ex` — lines 23-30 (canonical block with `audience: "billing-api"` per Phase 97 D-13)
- `docs/protect-phoenix-api-routes.md` — lines 16-22 (canonical block in fenced Elixir)
- `priv/templates/lockspire.install/router.ex` — lines 11-19 (canonical block, commented inside heredoc; D-08 keeps `enforce_audience: true` here)
- `scripts/demo/adoption_smoke.py` — lines 245-251 (canonical block as Python comments)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- The `binding_type/1` helper at `verify_token.ex:288-300` already reads `cnf.jkt` and `cnf["x5t#S256"]` and returns `"dpop" | "mtls" | "dpop+mtls" | nil` — D-05's challenge derivation is wire-up to a primitive that already exists.
- The structured error map shape at `verify_token.ex:184-204` (`%{challenge:, reason_code:, error:, error_description:}`) is already a shipped error contract; D-04 generalizes it to the new RFC 9068 reason codes rather than inventing a parallel shape.
- `EnforceSenderConstraints` already emits `challenge: :dpop` via `sender_error/2` at `enforce_sender_constraints.ex:130-149`, and `ProtectedResourceChallenge.put_dpop_challenge/2` at `web/protected_resource_challenge.ex:37-44` already emits the RFC 9449-compliant DPoP `WWW-Authenticate` with `algs=` — D-05/D-06 plug into an emission path that's already correct.
- `init/1` at `verify_token.ex:39-51` already validates options via `NimbleOptions` and raises `ArgumentError` on `:audience` + `:audiences` mutual-exclusion — D-07's `enforce_audience:` extension is a one-key schema addition.
- The four-file extraction helpers from Phase 97 (`extract_canonical_pipeline!/2`, `normalize/2`, `canonical_hash!/2` at `release_readiness_contract_test.exs:140-214`) are reused as-is by D-07's new audience-substring clause — no new extraction machinery.

### Established Patterns

- Distinct atom `reason_code`s flow cleanly through `log_invalid_token/2` (`verify_token.ex:253-261`) and reach the WWW-Authenticate `error_description` via `RequireToken`'s structured-error path. The taxonomy is open for extension: `:no_kid`, `:invalid_signature`, and the audience/scope reasons already exist; the five new RFC 9068 codes from D-02 follow the same convention.
- `Lockspire.Config.issuer!/0` is the canonical issuer accessor in the codebase; call-site precedent exists at `introspection_controller.ex:68` and `protocol/discovery.ex:67`. D-02 step 2 reuses this rather than re-deriving an "expected issuer" string.
- The repo treats `release_readiness_contract_test` as the durable home for "docs/runtime/template stay aligned" assertions; Phase 97 just heavily extended this pattern (four-file SHA-256 content-hash). D-07's audience-substring clause is the same kind of extension.

### Integration Points

- Phase 99's `Protocol.AccessTokenSigner` extraction must mint tokens whose shape passes the D-02 `validate_rfc9068_compliance/2` step. The existing signer at `rfc8693_exchange.ex:317-361` already emits `iss`/`sub`/`aud`/`exp`/`iat` and `typ: "at+jwt"` — the extracted signer must preserve all five plus the `typ` header.
- Phase 100's end-to-end binding proof composes with D-05's challenge derivation: when EnforceSenderConstraints runs (because VerifyToken did not short-circuit), its `sender_error/2` continues to emit `challenge: :dpop` for DPoP-bound failures; the two emission paths now agree on the taxonomy.
- Phase 101's adoption-demo re-wire benefits from D-07's `enforce_audience: true` on the install template — the demo's `:lockspire_protected_api` pipeline (DEMO-03) is one of the four RECIPE-01 sites that will be asserted to carry `audience:` after Phase 98.
- Phase 102's `SCAFFOLD-01` uncomment of the install template canonical block must preserve `enforce_audience: true` (D-08) so the loud `init/1` raise stays in the generated host's first protected-route pipeline.

</code_context>

<specifics>
## Specific Ideas

- Preferred Phase 98 feel: **explicit and distinct, replacing silent and lumped.** Every RFC 9068 / 8725 / 9449 gap closes with a named reason code, not a generic 401. Adopters who break a rule see which rule they broke in the `error_description`.
- Lessons preserved from Phase 97:
  - prefer one canonical detection mechanism per concern (structural shape for opaque per D-01; binding-claim derivation for challenge scheme per D-05) over heuristic stacks;
  - prefer extending the existing contract-test machinery over building parallel test infrastructure (D-07's audience-substring clause reuses Phase 97's extraction helpers);
  - prefer composing with shipped error taxonomies (the structured error map per D-04, EnforceSenderConstraints' `challenge:` per D-05) over introducing parallel shapes.
- D-03's intentional verifier/signer asymmetry (verifier accepts `application/at+jwt` and case variants; current signers emit exact `at+jwt`) is a deliberate forward-compatibility margin for Phase 99's signer extraction. The comment in the verifier code should name this asymmetry so a future reader doesn't "tighten" the verifier in a way that breaks an evolved signer.
- D-07's both-mechanisms posture is the one-shot recommendation bundle: the planner can drop the `init/1` raise if it conflicts with adopter-pipeline back-compat and still satisfy VERIFIER-06 via the contract-test alone, but the default ship-state is both for defense-in-depth.

</specifics>

<deferred>
## Deferred Ideas

- **External RFC 9449 §7.1 confirmation for the "no `cnf` claim, request used DPoP scheme" tiebreaker.** Area C's recommendation reads the §7.1 conjunction ("derived from the request's authorization scheme AND the token's binding type") conservatively — request-scheme as tiebreaker only when binding is absent. If the planner wants belt-and-suspenders, a two-paragraph RFC 9449 §7.1 confirmation would lock this reading. Codebase alone is sufficient for the recommendation; this is an interop conformance confirmation, not a missing fact.
- **Per-reason `error_description` wording catalog** — D-02 names the five reason codes; the exact human-facing strings are Claude's discretion (above). A wording catalog could be lifted to a locked decision later if adopter feedback shows the strings need to be stable.
- **Telemetry emission on the new RFC 9068 reason codes** — out of scope. Phase 102's `[:lockspire, :rs, :token_format]` telemetry covers the `:jwt | :opaque-rejected` measurement; per-reason-code telemetry would be a separate decision and is not in any v1.27 requirement.
- **Removing the silent `time_claims_valid?/1` comment at `verify_token.ex:366`** — the `# Missing exp is currently treated as valid` comment is obsolete once D-02 lands (missing `exp` becomes `:missing_exp`). The comment should be deleted as part of D-02's implementation; not lifted to a separate decision.

</deferred>

---

*Phase: 98-plug-hardening*
*Context gathered: 2026-05-27*
