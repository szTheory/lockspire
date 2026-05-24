# Phase 37: Protocol Strictness & Conformance - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Tighten Lockspire's existing OIDC authorization behavior so it behaves like a serious provider rather
than a best-effort OAuth layer: support strict `prompt=none` behavior, implement truthful
`max_age` / `auth_time` handling, preserve exact redirect and numeric-claim validation, and add
automated OIDF conformance proof that fits the embedded-library shape.

This phase is not a general UX expansion, not a hosted-session product, and not a broad public
certification-marketing exercise. It is a correctness and proof phase for the existing embedded
provider surface.

</domain>

<decisions>
## Implementation Decisions

### `prompt=none` semantics

- **D-01:** Lockspire should implement **strict non-interactive `prompt=none` semantics**. When
  `prompt=none` is present, Lockspire must never redirect into host login, Lockspire consent, or
  any other UI-producing step.
- **D-02:** `prompt=none` should be treated as a **hard gate**, not a soft preference. If the
  request cannot complete silently, Lockspire should return an OIDC error rather than falling back
  to interactive host behavior.
- **D-03:** Lockspire should reject `prompt=none` combined with any other prompt value as
  `invalid_request`.
- **D-04:** Silent failure taxonomy is locked:
  - `login_required` when no usable authenticated browser session exists, or when freshness rules
    such as `max_age` require re-authentication.
  - `consent_required` when the user is authenticated but the exact request still requires consent.
  - `interaction_required` for other policy or UX blockers that would require UI
    (account chooser, tenant selection, legal interstitial, step-up requirement, upstream hop).
- **D-05:** Silent success should only occur when authentication, freshness, consent, and product
  policy are all satisfiable without UI and with truthful durable state.
- **D-06:** The host seam for silent checks should be **read-only and decision-oriented**:
  Lockspire may inspect current browser-session/account state through the host seam, but must not
  broaden that seam into redirect orchestration or Lockspire-owned session control.

### `max_age` and `auth_time`

- **D-07:** Lockspire should introduce **durable protocol-owned `auth_time` truth** rather than
  deriving freshness from generic Phoenix session state, page hits, consent timestamps, or request
  time.
- **D-08:** `auth_time` should represent the last time the host performed a **fresh end-user
  authentication event** acknowledged by Lockspire, not the last time an existing host session was
  reused.
- **D-09:** Only an explicit fresh-auth event should advance `auth_time`. Consent reuse, consent
  approval, authorization code issuance, token exchange, refresh, and silent session reuse must not
  mutate it.
- **D-10:** `max_age` evaluation must use that durable `auth_time` as its sole freshness source.
  This keeps behavior truthful across redirects, retries, node restarts, and conformance tests.
- **D-11:** ID tokens should include `auth_time` when required by OIDC behavior:
  `max_age` requests and explicit essential-claim demand. Do not make always-on `auth_time`
  emission the default in this phase.
- **D-12:** The host seam should carry explicit freshness data rather than forcing inference.
  Downstream planning should prefer a narrow contract equivalent to “fresh auth occurred at time T”
  over implicit session heuristics.

### Conformance proof strategy

- **D-13:** Phase 37 should use a **repo-native conformance harness** as the center of gravity,
  not a maintainer-memory workflow and not an every-PR full hosted-suite dependency.
- **D-14:** The harness should encode Lockspire's real embedded assumptions in checked-in code:
  generated host app, deterministic login behavior, exact redirect URIs, durable Postgres truth,
  fixed client fixtures, and reproducible result capture.
- **D-15:** Conformance should run in **two lanes**:
  - a primary checked-in harness lane for local/CI use and repeatable regression proof
  - a maintainer-triggered or scheduled hosted/staging OIDF lane for fuller certification-grade
    evidence
- **D-16:** Do not make the full hosted browser-driven OIDF suite a required path on every PR.
  That would add too much flake, public-reachability coupling, and contributor friction for an
  embedded Phoenix library.
- **D-17:** Lockspire's public support posture must stay truthful: repeated conformance evidence can
  justify stronger protocol claims, but Phase 37 should not automatically broaden marketing to
  “broad certification coverage” unless the repo can keep proving it.
- **D-18:** The conformance host app used by the harness should be intentionally boring and narrow.
  It exists to prove Lockspire's protocol seams, not to test arbitrary host UX variation.

### Developer ergonomics and surprise minimization

- **D-19:** Favor explicit, narrowly named seams over “magic inference” for both silent auth and
  freshness. This is the least surprising model for Phoenix teams embedding a provider into an
  existing app.
- **D-20:** Error behavior should be deterministic and standards-shaped, with public behavior that
  SDKs and RP implementers can rely on without Lockspire-specific folklore.
- **D-21:** Conformance tooling should optimize for maintainable DX: one obvious script/task path,
  clear fixture setup, saved artifacts, and strong docs about browser-cookie limitations and
  hosted-suite prerequisites.

### the agent's Discretion

- Exact schema shape for durable freshness state may be chosen during planning so long as
  `auth_time` remains protocol-owned, durable, and not derived from ambient session churn.
- Exact module/file boundaries for silent-session inspection, freshness checks, and conformance
  helpers may be chosen during planning as long as Plug/Phoenix adapters stay thin.
- Exact conformance-plan scope may start with the most relevant OP cases for `prompt=none`,
  `max_age`, `auth_time`, and strict authorization validation before broadening further.
- Future GSD work should default to assumption-first, research-backed recommendations and only
  escalate to the user on genuinely high-impact product choices or when evidence is insufficient.

</decisions>

<specifics>
## Specific Ideas

- Treat `prompt=none` like a real interoperability contract, not a convenience flag. Popular
  providers that succeed here behave as silent checkers, not redirectors.
- `prompt=login` is only a UX hint; `max_age` plus truthful `auth_time` is the enforceable,
  testable protocol mechanism. Lockspire should align to that model.
- Browser privacy constraints matter: silent auth often runs in iframe-style contexts and can fail
  when the host session is not observable. Docs and tests should make that limitation explicit
  rather than pretending the protocol can override browser cookie policy.
- The best conformance posture for Lockspire is “repo-native proof plus release-grade hosted
  verification”, not “full public-suite automation on every contributor change”.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and local implementation surface

- `.planning/ROADMAP.md` — Phase 37 goal, success criteria, and milestone dependency position
- `.planning/REQUIREMENTS.md` — `CONF-01` through `CONF-04`
- `.planning/PROJECT.md` — embedded-library boundaries, host seam ownership, and truthful preview
  posture
- `.planning/STATE.md` — current milestone state and accumulated protocol-boundary decisions
- `lib/lockspire/protocol/authorization_request.ex` — current authorization validation entry point,
  prompt handling, nonce handling, and exact `redirect_uri` checks
- `lib/lockspire/protocol/authorization_flow.ex` — current login/consent state machine and the
  main place Phase 37 decisions will affect silent-vs-interactive behavior
- `lib/lockspire/protocol/id_token.ex` — current ID token claim shaping and likely `auth_time`
  integration point
- `lib/lockspire/host/claims.ex` — current host-claims merge boundary and protocol-claim filtering
- `lib/lockspire/domain/interaction.ex` — durable authorization interaction state
- `lib/lockspire/storage/ecto/interaction_record.ex` — persisted interaction fields and migration
  precedent for adding protocol-owned timestamps
- `lib/lockspire/protocol/jar.ex` — existing strict numeric claim validation precedent
- `lib/lockspire/protocol/request_object.ex` — JAR request projection and `invalid_request_object`
  mapping precedent
- `test/lockspire/protocol/authorization_request_test.exs` — current prompt/nonce/JAR validation
  contracts
- `test/lockspire/web/authorize_controller_test.exs` — current browser-safe vs redirect-safe
  authorization behavior
- `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` — existing OIDC integration-test
  path and nonce/ID token proof precedent
- `docs/supported-surface.md` — public support-truth contract that must not drift ahead of proof

### Standards and ecosystem authority

- `https://openid.net/specs/openid-connect-core-1_0-31.html` — authority for `prompt=none`,
  `max_age`, and `auth_time` behavior
- `https://openid.net/certification/connect_op_testing/` — OP conformance expectations and plan
  categories
- `https://openid.net/certification/about-conformance-suite/` — official suite operating model,
  local Docker support, and CI-script guidance
- `https://github.com/panva/node-oidc-provider` — strong ecosystem example of embedded-provider
  seriousness and certification discipline
- `https://github.com/doorkeeper-gem/doorkeeper-openid_connect` — useful precedent for Rails-style
  library OIDC behavior, especially `max_age` / `auth_time` support expectations

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Protocol.AuthorizationRequest` already enforces exact `redirect_uri` matching,
  nonce-on-`openid`, and several prompt validations. Phase 37 should tighten it rather than replace
  it.
- `Lockspire.Protocol.AuthorizationFlow` already distinguishes login-required, consent-required,
  and consent-reused paths. This is the natural protocol seam for strict `prompt=none` decisions.
- `Lockspire.Protocol.Jar` already treats numeric claim typing seriously (`exp`, `nbf`, `iat`).
  That is the project's best current precedent for “strict protocol inputs over permissive casting”.
- `Interaction` and `InteractionRecord` already persist multiple timestamps and state transitions,
  which makes them the most natural base for protocol-owned freshness state.
- Existing integration tests under `test/integration/` already prove earlier OIDC surfaces through
  a repo-native harness. Conformance work should extend that philosophy rather than introducing a
  separate ad hoc proof story.

### Established Patterns

- Thin Phoenix adapters over protocol-owned correctness.
- Durable Ecto/Postgres truth over transport-only inference.
- Exact-match and standards-shaped validation over permissive coercion.
- Public docs/support claims enforced by executable contract tests.
- Embedded-library host seams kept explicit and narrow rather than hidden inside a monolithic OP.

### Integration Points

- `AuthorizationRequest.validate/1` needs stricter prompt semantics and likely new request
  parameter handling for `max_age`.
- `AuthorizationFlow.start_authorization/3` is where silent-vs-interactive completion must become
  protocol-deterministic.
- `IdToken.sign/1` and `Host.Claims.build_id_token_claims/2` will need coherent `auth_time`
  handling without letting host claims silently override protocol truth.
- Conformance harness work should compose with the generated host-app and integration-test patterns
  already used in this repo, not bypass them.

</code_context>

<deferred>
## Deferred Ideas

- Broad public certification-mark usage or “broad conformance coverage” positioning beyond what the
  repo can repeatedly prove
- Full hosted OIDF conformance execution on every PR
- Solving browser third-party-cookie limitations from inside Lockspire itself
- Broader session/logout product work beyond what is already scoped into Phases 38 and 39
- Generalized host protected-resource or CIAM-scope expansion unrelated to Phase 37

</deferred>

---

*Phase: 37-protocol-strictness-conformance*
*Context gathered: 2026-04-28*
