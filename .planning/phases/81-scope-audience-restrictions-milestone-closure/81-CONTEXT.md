# Phase 81: Scope/Audience Restrictions & Milestone Closure - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 81 completes the v1.21 resource-server wedge by adding route-level scope and audience restrictions on top of the existing protected-resource plug pipeline, publishing an executable Phoenix API protection guide, and closing the milestone with repo-provable end-to-end DX.

This phase extends the current embedded Phoenix shape. It does not turn Lockspire into a generic API gateway, policy engine, multi-issuer validator, or broad cross-service resource-server platform.

</domain>

<decisions>
## Implementation Decisions

### Protected-resource API shape

- **D-01:** Preserve the existing split-plug architecture from Phases 79-80:
  - `Lockspire.Plug.VerifyToken` remains the soft validation/assignment plug.
  - `Lockspire.Plug.EnforceSenderConstraints` remains a separate composable sender-constraint plug.
  - `Lockspire.Plug.RequireToken` remains the strict response-rendering/enforcement plug.
- **D-02:** Phase 81 should add route-level restrictions as a narrow extension of that pipeline, not as a second policy system.
- **D-03:** Downstream planning should bias toward explicit Plug options validated up front rather than hidden global config.

### Scope restriction semantics

- **D-04:** Ship scope restriction as plural `scopes:` only in v1.21.
- **D-05:** `scopes: [...]` means exact, case-sensitive, all-of matching against the validated access token scopes.
- **D-06:** Omitted or empty `scopes` means no scope restriction.
- **D-07:** Token scope values should be normalized by splitting the RFC 6749 space-delimited `scope` claim, trimming, and de-duplicating before comparison.
- **D-08:** Do not add `scope:` singular alias, OR-style grouped scope alternatives, or nested scope-expression syntax in this phase.

### Audience restriction semantics

- **D-09:** Ship `audience:` as the primary route option for the common case.
- **D-10:** Also support `audiences:` as an explicit escape hatch for any-of matching across a small allowed set.
- **D-11:** Reject plug configuration that sets both `:audience` and `:audiences`.
- **D-12:** `audience:` means the token `aud` must contain that exact string.
- **D-13:** `audiences:` means the token `aud` must contain at least one configured value.
- **D-14:** Normalize JWT `aud` to a list for comparison:
  - string -> one-item list
  - list -> require all members be non-empty strings
  - any other shape -> invalid token
- **D-15:** If audience restriction is configured, missing or malformed `aud` is an `invalid_token` failure.
- **D-16:** Use exact string comparison only. Do not add URI normalization, canonicalization, exact-set matching, or all-of audience semantics in this phase.

### Evaluation order and composition

- **D-17:** Scope, audience, and sender-constraint checks compose as AND conditions.
- **D-18:** Audience validation should be treated as a token-validity/resource-targeting check, not as mere business authorization.
- **D-19:** When multiple restrictions could fail, prefer resource-targeting failure over scope failure in internal reasoning and telemetry so wrong-resource tokens do not look like simple permission misses.
- **D-20:** Sender constraints remain automatic when `cnf` is present on the token; this phase should not introduce a separate public “gateway mode” or new sender-constraint topology.

### Failure semantics and response contract

- **D-21:** Keep OAuth-style split failure semantics:
  - `401 Unauthorized` for missing token, malformed token, signature/time failures, malformed/missing required `aud`, audience mismatch, and sender-constraint failures
  - `403 Forbidden` for valid token lacking required scopes
- **D-22:** Use `error="invalid_token"` for `401` failures.
- **D-23:** Use `error="insufficient_scope"` for `403` scope failures.
- **D-24:** For scope failures, include the required scope set in the `WWW-Authenticate` challenge when practical.
- **D-25:** Keep `WWW-Authenticate` scheme-aware:
  - use DPoP challenge only when a DPoP-specific failure is implicated
  - otherwise use Bearer challenge
- **D-26:** Keep response bodies minimal and machine-readable. Put richer operator detail into typed telemetry/log metadata rather than the HTTP body.
- **D-27:** Never log raw access tokens, raw DPoP proofs, raw certificates, or full claim dumps in support of this phase.

### Public support posture

- **D-28:** Update the support contract from “generic host protected-resource middleware remains out of scope” to a narrower shipped claim:
  - Lockspire supports a first-class Plug pipeline for protecting host Phoenix API routes with Lockspire-issued access tokens.
- **D-29:** Keep the public claim explicitly narrow:
  - same host shape
  - same issuer family
  - Phoenix route protection
  - token validation plus scope/audience/sender-constraint enforcement
- **D-30:** Keep these explicitly out of scope for this phase:
  - generic API gateway or service-mesh middleware
  - multi-issuer validation
  - remote JWKS / arbitrary third-party issuer validation
  - business authorization or policy-engine decisions beyond token validation and narrow route restrictions

### Documentation contract

- **D-31:** The executable guide should lead with the canonical Plug pipeline:
  - `VerifyToken`
  - `EnforceSenderConstraints` when used
  - `RequireToken`
- **D-32:** The guide must show one route-level scope example and one route-level audience example.
- **D-33:** The guide must document the assigns contract for downstream Phoenix code: validated token struct, claims, `client_id`, and binding metadata.
- **D-34:** The guide must explicitly state that the host still owns business authorization, tenant checks, rate limiting, and domain record lookup from `sub`.
- **D-35:** The guide must include a short failure matrix for Bearer/DPoP-style failures and scope denial behavior.
- **D-36:** The guide must be close enough to the tested route snippets that docs drift is easy to catch.

### Milestone-closing proof

- **D-37:** Do not treat plug-level unit coverage alone as milestone closure.
- **D-38:** Minimum acceptable proof for Phase 81:
  - unit coverage for scope/audience option behavior
  - a Phoenix router integration suite proving real route dispatch and HTTP semantics
  - an executable “protect Phoenix API routes” guide
  - a verification report
- **D-39:** Preferred proof for milestone closure:
  - everything in D-38
  - generated-host protected-route proof in the existing host fixture app
  - at least one combined sender-constraint + scope/audience case
- **D-40:** Proof should explicitly cover:
  - valid token passes
  - missing token fails
  - required-scope failure returns the expected status/challenge/body
  - audience mismatch fails
  - sender-constrained tokens still work correctly with route restrictions enabled

### Workflow preference

- **D-41:** Shift medium-impact implementation choices left within GSD by default for this project. Downstream agents should proceed from the coherent recommendation set here without asking again unless a decision would materially change:
  - product boundary
  - security posture
  - support contract
  - public API shape
- **D-42:** For this phase specifically, the user has delegated the recommendation bundle and does not want another decision loop for medium-impact details covered here.

### the agent's Discretion

- Exact internal helper/module organization for audience/scope normalization and comparison.
- Exact NimbleOptions schema wording and validation error messages.
- Exact telemetry event names and metadata keys, provided they stay typed, useful, and redaction-safe.
- Exact test file split between plug unit coverage and router/generated-host integration coverage.
- Exact guide filename and section ordering, provided the support posture and tested examples remain aligned.

</decisions>

<specifics>
## Specific Ideas

- The coherent Phase 81 recommendation bundle is:
  - plural `scopes:` only, all-of semantics
  - `audience:` as the common-case route option, `audiences:` as the explicit any-of escape hatch
  - no OR-scope DSL, no exact-set audience mode, no URI canonicalization
  - `401 invalid_token` for token/resource-targeting/sender failures
  - `403 insufficient_scope` for scope-only denials
  - a narrow public claim around protecting host Phoenix API routes with Lockspire-issued tokens
  - milestone closure based on unit + router integration + generated-host proof + executable docs + verification
- Portable lessons worth following:
  - Guardian’s verify/enforce split is the right Elixir shape for predictable pipelines.
  - Spring Security and adjacent stacks distinguish invalid token from insufficient scope instead of flattening everything into one denial mode.
  - Resource-server libraries usually model audience as “single expected audience” plus optional extra audiences, not exact-set equality.
  - Strong auth libraries earn trust by testing the real integration path, not only local structs and helpers.
- Footguns to avoid:
  - reintroducing “generic host protected-resource middleware” language after this phase chooses a narrower claim
  - collapsing audience and scope into one generic authorization bucket
  - adding convenience aliases or nested authorization syntax before proven need
  - allowing docs to imply multi-issuer or gateway support
  - proving plug behavior without proving a real routed Phoenix API example

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and product boundary
- `.planning/ROADMAP.md` — Phase 81 goal and milestone context
- `.planning/REQUIREMENTS.md` — active milestone requirements for resource-server protection
- `.planning/PROJECT.md` — embedded-library thesis, host boundary, and support posture
- `.planning/STATE.md` — current milestone execution status

### Upstream phase decisions and proof
- `.planning/phases/79-core-validation-plug/79-RESEARCH.md` — locked two-plug architecture and ETS-backed validation context
- `.planning/phases/79-core-validation-plug/79-VALIDATION.md` — original validation expectations for `VerifyToken` / `RequireToken`
- `.planning/phases/80-sender-constraining-integration/80-CONTEXT.md` — locked sender-constraint composition model
- `.planning/phases/54-resource-indicators/54-VERIFICATION.md` — audience/resource-indicator proof and current `aud` shape expectations

### Current code and route-protection surface
- `lib/lockspire/access_token.ex` — current protected-resource token state shape
- `lib/lockspire/plug/verify_token.ex` — soft token validation plug
- `lib/lockspire/plug/require_token.ex` — strict enforcement and challenge rendering
- `lib/lockspire/plug/enforce_sender_constraints.ex` — sender-constraint enforcement plug
- `lib/lockspire/protocol/mtls_token_binding.ex` — MTLS confirmation helper shape
- `lib/lockspire/protocol/dpop.ex` — DPoP proof helper shape

### Current docs and support contract
- `docs/supported-surface.md` — public support contract that must be updated truthfully
- `docs/install-and-onboard.md` — canonical install and repo-proof posture
- `docs/sigra-companion-host.md` — host seam and ownership boundary

### Current proof fixtures and tests
- `test/lockspire/plug/enforce_sender_constraints_test.exs` — current sender-constraint unit proof
- `test/support/generated_host_app_web/router/lockspire.ex` — generated-host router seam precedent
- `test/integration/phase6_onboarding_e2e_test.exs` — canonical repo-proof pattern for executable host flow
- `test/integration/phase31_generated_host_verification_e2e_test.exs` — generated-host proof precedent

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Plug.VerifyToken` already extracts Bearer and DPoP authorization schemes and assigns `%Lockspire.AccessToken{}`.
- `Lockspire.Plug.RequireToken` already centralizes challenge rendering, making it the right place to separate `invalid_token` and `insufficient_scope` behavior.
- `Lockspire.Plug.EnforceSenderConstraints` already provides typed sender-constraint failures that can compose with Phase 81 restrictions.
- Phase 54 already gives Lockspire a durable audience story through Resource Indicators and existing integration proof.
- The generated-host fixture app and prior integration tests already provide a realistic embedded Phoenix proof path for milestone closure.

### Established Patterns

- Lockspire prefers explicit, composable plugs over fat opaque middleware.
- Public claims are supposed to stay narrow and repo-provable.
- Host-owned business policy stays outside Lockspire-owned protocol correctness layers.
- Route and install DX are treated as product surface, not just internal implementation detail.

### Integration Points

- Phase 81 planning should center around:
  - option validation and normalization in the protected-resource plug surface
  - structured error propagation from `VerifyToken`/restriction checks into `RequireToken`
  - docs/support-contract updates for the narrower public claim
  - router integration and generated-host proof additions
  - final verification artifact for milestone closure

</code_context>

<deferred>
## Deferred Ideas

- OR-style grouped scope requirements
- singular `scope:` alias for route protection
- exact-set or all-of audience modes
- URI normalization/canonicalization for audience comparison
- generic API gateway or service-mesh middleware claims
- multi-issuer token validation support
- remote third-party issuer validation/JWKS discovery for arbitrary APIs
- business-policy DSLs or policy-engine features on top of the protected-resource plugs

</deferred>

---

*Phase: 81-scope-audience-restrictions-milestone-closure*
*Context gathered: 2026-05-23*
