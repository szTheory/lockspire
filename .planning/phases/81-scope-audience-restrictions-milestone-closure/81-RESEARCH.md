# Phase 81: Scope/Audience Restrictions & Milestone Closure - Research

**Researched:** 2026-05-23
**Domain:** Phoenix/Plug OAuth resource-server route restrictions and milestone proof
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

- OR-style grouped scope requirements
- singular `scope:` alias for route protection
- exact-set or all-of audience modes
- URI normalization/canonicalization for audience comparison
- generic API gateway or service-mesh middleware claims
- multi-issuer token validation support
- remote third-party issuer validation/JWKS discovery for arbitrary APIs
- business-policy DSLs or policy-engine features on top of the protected-resource plugs
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VAL-PLUG-01 | Lockspire MUST provide a standard Plug to easily protect host Phoenix API routes. `[VERIFIED: .planning/REQUIREMENTS.md]` | Keep the three-plug pipeline and prove it in router and generated-host tests. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md][VERIFIED: lib/lockspire/plug/verify_token.ex][VERIFIED: lib/lockspire/plug/require_token.ex][VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex]` |
| VAL-PLUG-04 | The Plug MUST optionally enforce required scopes or audience restrictions passed via Plug options. `[VERIFIED: .planning/REQUIREMENTS.md]` | Validate `scopes:`, `audience:`, and `audiences:` in `VerifyToken.init/1`; perform audience checks as token-validity checks and scope checks as authorization checks. `[CITED: https://www.rfc-editor.org/rfc/rfc6750][CITED: https://www.ietf.org/rfc/rfc7519.html][CITED: https://www.rfc-editor.org/rfc/rfc9068][VERIFIED: lib/lockspire/protocol/jar.ex]` |
| VAL-DX-01 | Successful validation MUST assign the validated token, client_id, and claims into `conn.assigns`. `[VERIFIED: .planning/REQUIREMENTS.md]` | Preserve `%Lockspire.AccessToken{}` assignment contract and document it in the executable guide. `[VERIFIED: lib/lockspire/access_token.ex][VERIFIED: lib/lockspire/plug/verify_token.ex][VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]` |
| VAL-DX-02 | Failures MUST emit standardized 401 responses with RFC 6750 or DPoP `WWW-Authenticate` headers. `[VERIFIED: .planning/REQUIREMENTS.md]` | Extend `RequireToken` to distinguish `401 invalid_token` from `403 insufficient_scope`, preserving DPoP-aware challenges for sender failures. `[CITED: https://www.rfc-editor.org/rfc/rfc6750][CITED: https://www.ietf.org/rfc/rfc9449.html][VERIFIED: lib/lockspire/plug/require_token.ex]` |
| VAL-BIND-03 | The Plug MUST reject requests with `401 Unauthorized` if cryptographic binding validation fails. `[VERIFIED: .planning/REQUIREMENTS.md]` | Keep sender-constraint failure handling in `EnforceSenderConstraints` and ensure route restrictions do not bypass it. `[VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex][VERIFIED: test/lockspire/plug/enforce_sender_constraints_test.exs]` |
</phase_requirements>

## Summary

Phase 81 should stay inside the existing Lockspire resource-server shape: `VerifyToken` remains the only place that parses JWTs and route options, `EnforceSenderConstraints` remains the only place that evaluates `cnf`-driven DPoP/MTLS proofing, and `RequireToken` remains the only place that renders HTTP denials. That matches the locked phase context, the current code layout, and the Phoenix/Plug expectation that route-level plug options are passed explicitly and normalized in `init/1`. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md][VERIFIED: lib/lockspire/plug/verify_token.ex][VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex][VERIFIED: lib/lockspire/plug/require_token.ex][CITED: https://hexdocs.pm/phoenix/plug.html][CITED: https://hexdocs.pm/plug/1.8.3/Plug.Builder.html]`

The safest semantics split is the one the RFCs already support: audience is part of token validity for the current resource server, while scopes are an authorization layer evaluated after the token is otherwise valid. RFC 7519 defines `aud` as a case-sensitive string or array and requires the consumer to reject a JWT when its own identifier is not present. RFC 9068 requires a resource server to reject JWT access tokens when `aud` does not contain the current resource indicator and to return `invalid_token` on validation failure per RFC 6750. RFC 6750 separately reserves `403 insufficient_scope` for tokens that are otherwise valid but under-privileged, and allows including the required `scope` in the challenge. `[CITED: https://www.ietf.org/rfc/rfc7519.html][CITED: https://www.rfc-editor.org/rfc/rfc9068][CITED: https://www.rfc-editor.org/rfc/rfc6750]`

The repo already contains the right internal building blocks for this phase. `VerifyToken` soft-assigns `%Lockspire.AccessToken{}`, `RequireToken` already formats Bearer versus DPoP challenges, `EnforceSenderConstraints` already records typed sender failures, and `lib/lockspire/protocol/jar.ex` already implements the exact `aud` string-or-list validation pattern this phase needs. The remaining work is to add explicit option validation, route-level restriction checks, structured failure reasons for scope versus audience, truthful support-doc updates, and milestone proof that uses real routed Phoenix requests instead of only plug-unit tests. `[VERIFIED: lib/lockspire/access_token.ex][VERIFIED: lib/lockspire/plug/verify_token.ex][VERIFIED: lib/lockspire/plug/require_token.ex][VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex][VERIFIED: lib/lockspire/protocol/jar.ex][VERIFIED: docs/supported-surface.md][VERIFIED: test/integration/phase6_onboarding_e2e_test.exs][VERIFIED: test/integration/phase31_generated_host_verification_e2e_test.exs]`

**Primary recommendation:** Add validated `scopes:` / `audience:` / `audiences:` options to `Lockspire.Plug.VerifyToken`, reuse the existing `aud` string-or-list normalization pattern from `Lockspire.Protocol.Jar`, keep `401 invalid_token` for token/resource-targeting/sender failures and `403 insufficient_scope` for valid-but-under-scoped tokens, and close the milestone only with unit, router, docs, and generated-host proof. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md][VERIFIED: lib/lockspire/protocol/jar.ex][CITED: https://www.rfc-editor.org/rfc/rfc6750][CITED: https://www.rfc-editor.org/rfc/rfc9068]`

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| JWT extraction, signature checks, time checks, option normalization | API / Backend | — | This logic lives in route plugs and uses server-side key material plus claims parsing. `[VERIFIED: lib/lockspire/plug/verify_token.ex]` |
| DPoP / MTLS sender-constraint enforcement | API / Backend | — | Sender proof validation depends on request headers, request URI, certificate extraction, and token `cnf` claims. `[VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex][CITED: https://www.ietf.org/rfc/rfc9449.html]` |
| Scope and audience restriction enforcement | API / Backend | — | RFC 9068 validation is a resource-server responsibility, not a browser or database responsibility. `[CITED: https://www.rfc-editor.org/rfc/rfc9068][CITED: https://www.rfc-editor.org/rfc/rfc6750]` |
| Route wiring and per-endpoint protection shape | Frontend Server (SSR) | API / Backend | Phoenix router pipelines own how host routes compose plugs; the protected resource still runs in the same host server. `[CITED: https://hexdocs.pm/phoenix/plug.html][VERIFIED: test/support/generated_host_app_web/router/lockspire.ex]` |
| Business authorization after token acceptance | Frontend Server (SSR) | API / Backend | Host app keeps tenant checks, record lookup, and domain policy after Lockspire finishes token-level checks. `[VERIFIED: docs/install-and-onboard.md][VERIFIED: docs/sigra-companion-host.md][VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]` |
| Milestone proof and docs-truth enforcement | API / Backend | Frontend Server (SSR) | Lockspire uses ExUnit, integration fixtures, and docs contract tests to prove the shipped support posture. `[VERIFIED: test/integration/phase6_onboarding_e2e_test.exs][VERIFIED: test/integration/phase31_generated_host_verification_e2e_test.exs][VERIFIED: test/lockspire/release_readiness_contract_test.exs]` |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | `1.8.7` (released 2026-05-06) `[VERIFIED: mix.lock][VERIFIED: mix hex.info phoenix]` | Router pipelines and host route integration | Route protection is mounted through Phoenix pipelines and tested through Phoenix conn helpers already used across Lockspire integration proof. `[VERIFIED: mix.lock][VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]` |
| `plug` | `1.19.1` locked; `1.19.2` current as of 2026-05-23 `[VERIFIED: mix.lock][VERIFIED: mix hex.info plug]` | Module-plug lifecycle and explicit route options | `init/1` plus `call/2` is the native place to validate and normalize route-level protection options. `[CITED: https://hexdocs.pm/plug/1.8.3/Plug.Builder.html][CITED: https://hexdocs.pm/phoenix/plug.html]` |
| `nimble_options` | `1.1.1` (released 2024-05-25) `[VERIFIED: mix.lock][VERIFIED: mix hex.info nimble_options]` | Up-front validation for `scopes:` / `audience:` / `audiences:` plug options | It provides structured validation errors and docs generation instead of ad hoc keyword parsing. `[CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html][VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phoenix_live_view` | `1.1.30` locked; `1.1.30` current stable as of 2026-05-23 `[VERIFIED: mix.lock][VERIFIED: mix hex.info phoenix_live_view]` | No new Phase 81 protocol logic, but part of the host/admin stack | Keep unchanged; only mention when docs touch host-owned UX boundaries. `[VERIFIED: mix.lock][VERIFIED: docs/install-and-onboard.md]` |
| `JOSE` | `~> 1.11` configured in repo `[VERIFIED: mix.exs][VERIFIED: lib/lockspire/plug/verify_token.ex]` | Existing JWT signature verification | Reuse existing JWT validation path; Phase 81 should not add a second JWT library. `[VERIFIED: lib/lockspire/plug/verify_token.ex]` |
| ExUnit + Phoenix.ConnTest | repo standard `[VERIFIED: mix.exs][VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]` | Router and generated-host proof | Use for real request/response semantics and docs-aligned route snippets. `[VERIFIED: test/integration/phase31_generated_host_verification_e2e_test.exs]` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit route options on `VerifyToken` | Global `Application` config | Hidden, app-wide policy would contradict the locked phase shape and make per-route DX worse. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]` |
| `nimble_options` validation | Manual `Keyword.get`/`case` trees | Manual validation is harder to keep consistent, harder to document, and already inferior to the repo’s existing `EnforceSenderConstraints.init/1` pattern. `[VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex][CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html]` |
| Reusing `Lockspire.Protocol.Jar`-style audience checks | New bespoke audience parser inside `RequireToken` | Duplicating `aud` rules invites drift and would put token-validity logic in the wrong plug. `[VERIFIED: lib/lockspire/protocol/jar.ex][VERIFIED: lib/lockspire/plug/require_token.ex]` |

**Installation:** Directly declare `nimble_options` if Phase 81 continues to call it from Lockspire code, because the repo currently uses it only transitively through other packages. `[VERIFIED: mix.exs][VERIFIED: mix.lock][VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex]`

```elixir
# mix.exs
{:nimble_options, "~> 1.1"}
```

## Architecture Patterns

### System Architecture Diagram

```text
[HTTP Request]
      |
      | Authorization + optional DPoP header
      v
[VerifyToken.init/1]
      |
      | validate route opts: scopes/audience/audiences
      v
[VerifyToken.call/2]
      |
      | extract token -> verify sig/time -> normalize scope/aud restrictions
      | assign %Lockspire.AccessToken{} or token-validity error
      v
[EnforceSenderConstraints.call/2]
      |
      | if cnf present: validate DPoP/MTLS proof against request + token
      | assign structured sender error on failure
      v
[RequireToken.call/2]
      |
      | valid token? yes -> continue
      | invalid/malformed/audience/sender failure -> 401 invalid_token
      | scope failure only -> 403 insufficient_scope
      v
[Host Phoenix Controller / API Action]
      |
      | host-owned business auth, tenant checks, record lookup from sub
      v
[JSON Resource Response]
```

### Recommended Project Structure
```text
lib/
├── lockspire/plug/                  # VerifyToken / EnforceSenderConstraints / RequireToken pipeline
├── lockspire/protocol/              # shared claim normalization helpers and DPoP/MTLS protocol rules
└── lockspire/access_token.ex        # assigned token state struct

docs/
├── supported-surface.md             # public support contract
├── install-and-onboard.md           # canonical onboarding guide
└── phoenix-api-protection.md        # recommended new executable Phase 81 guide

test/
├── lockspire/plug/                  # unit coverage for option validation and response contracts
├── integration/                     # routed Phoenix and generated-host proof
└── support/generated_host_app_web/  # generated-host router fixture
```

### Pattern 1: Validate and Normalize Route Options in `init/1`
**What:** `VerifyToken.init/1` should reject impossible plug configurations before requests hit the pipeline, including empty/non-string scope entries and simultaneous `audience` plus `audiences`. `[CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html][CITED: https://hexdocs.pm/plug/1.8.3/Plug.Builder.html][VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex]`
**When to use:** Every route-level restriction option for this phase. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]`
**Example:**
```elixir
# Source: https://hexdocs.pm/nimble_options/NimbleOptions.html
@options_schema [
  scopes: [type: {:list, :string}, required: false],
  audience: [type: :string, required: false],
  audiences: [type: {:list, :string}, required: false]
]

def init(opts) do
  opts = NimbleOptions.validate!(opts, @options_schema)

  if Keyword.has_key?(opts, :audience) and Keyword.has_key?(opts, :audiences) do
    raise ArgumentError, "expected only one of :audience or :audiences"
  end

  opts
  |> Keyword.update(:scopes, [], &normalize_required_scopes/1)
  |> normalize_audience_opts()
end
```

### Pattern 2: Keep Audience in the Token-Validity Path
**What:** Evaluate `aud` during `VerifyToken.call/2` and write a token-validity error when the configured resource audience is absent or malformed. `[CITED: https://www.ietf.org/rfc/rfc7519.html][CITED: https://www.rfc-editor.org/rfc/rfc9068][VERIFIED: lib/lockspire/protocol/jar.ex]`
**When to use:** Whenever `audience:` or `audiences:` is configured. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]`
**Example:**
```elixir
# Source: lib/lockspire/protocol/jar.ex
defp normalize_aud(%{"aud" => aud}) when is_binary(aud) do
  trimmed = String.trim(aud)
  if trimmed == "", do: {:error, :invalid_audience}, else: {:ok, [trimmed]}
end

defp normalize_aud(%{"aud" => aud}) when is_list(aud) do
  aud
  |> Enum.map(&normalize_string/1)
  |> Enum.reject(&is_nil/1)
  |> case do
    [] -> {:error, :invalid_audience}
    values when length(values) == length(aud) -> {:ok, Enum.uniq(values)}
    _ -> {:error, :invalid_audience}
  end
end

defp normalize_aud(_claims), do: {:error, :missing_audience}
```

### Pattern 3: Represent Scope Failure as a Structured Authorization Error
**What:** Scope failure should remain distinct from invalid-token failure so `RequireToken` can emit `403 insufficient_scope` while keeping machine-readable body and challenge data. `[CITED: https://www.rfc-editor.org/rfc/rfc6750][VERIFIED: lib/lockspire/plug/require_token.ex]`
**When to use:** Token is otherwise valid, sender constraints passed, and required scopes are missing. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]`
**Example:**
```elixir
# Source: https://www.rfc-editor.org/rfc/rfc6750
%{
  category: :authorization,
  reason_code: :insufficient_scope,
  error: "insufficient_scope",
  error_description: "The access token lacks required scope",
  required_scopes: ["read:billing"]
}
```

### Pattern 4: Prove the Canonical Router Shape, Not Just Plug Units
**What:** Build a small Phoenix router fixture or integration suite that mounts the exact pipeline order and exercises real requests. `[VERIFIED: test/integration/phase6_onboarding_e2e_test.exs][VERIFIED: test/integration/phase31_generated_host_verification_e2e_test.exs][VERIFIED: test/support/generated_host_app_web/router/lockspire.ex]`
**When to use:** Milestone closure and docs-truth proof. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]`
**Example:**
```elixir
# Source: https://hexdocs.pm/phoenix/plug.html
pipeline :lockspire_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"]
  plug Lockspire.Plug.EnforceSenderConstraints
  plug Lockspire.Plug.RequireToken
end

scope "/api" do
  pipe_through [:api, :lockspire_api]
  get "/billing", BillingController, :show
end
```

### Anti-Patterns to Avoid
- **Config-driven hidden policy:** Do not read route restrictions from application config; the phase explicitly chose visible per-route options. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]`
- **Audience as business authorization:** Do not downgrade audience mismatch to `insufficient_scope`; RFC 9068 treats it as token validation for the current resource server. `[CITED: https://www.rfc-editor.org/rfc/rfc9068][CITED: https://www.rfc-editor.org/rfc/rfc6750]`
- **Scope DSL creep:** Do not add singular `scope:`, OR groups, or nested expressions in this phase. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]`
- **Bespoke `aud` parser drift:** Do not implement a second audience checker when `Lockspire.Protocol.Jar` already proves the string-or-list pattern. `[VERIFIED: lib/lockspire/protocol/jar.ex]`
- **Docs without routed proof:** Do not claim the support surface changed unless release-readiness tests and integration tests prove the exact new wording. `[VERIFIED: docs/supported-surface.md][VERIFIED: test/lockspire/release_readiness_contract_test.exs]`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Plug option validation | ad hoc keyword parsing | `NimbleOptions.validate!/2` | It gives predictable error surfaces and better docs for route options. `[CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html]` |
| Audience shape parsing | a new one-off `aud` parser | shared internal helper based on `Lockspire.Protocol.Jar` | Lockspire already has an exact string-or-list audience precedent with malformed-shape rejection. `[VERIFIED: lib/lockspire/protocol/jar.ex]` |
| HTTP denial rendering | status/body/header branches spread across plugs | centralized `RequireToken` rendering | `RequireToken` already owns Bearer vs DPoP challenges and should stay the only response renderer. `[VERIFIED: lib/lockspire/plug/require_token.ex]` |
| Milestone closure proof | unit tests only | unit + router + generated-host + docs contract verification | Lockspire’s existing milestone proof culture relies on executable repo truth, not helper-only tests. `[VERIFIED: test/integration/phase6_onboarding_e2e_test.exs][VERIFIED: test/integration/phase31_generated_host_verification_e2e_test.exs][VERIFIED: test/lockspire/release_readiness_contract_test.exs]` |

**Key insight:** Phase 81 is not a new policy engine; it is a narrow extension of the existing resource-server plug pipeline, so new code should concentrate on option normalization, structured failures, and proof alignment rather than expanding topology or introducing new middleware shapes. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md][VERIFIED: .planning/PROJECT.md]`

## Common Pitfalls

### Pitfall 1: Returning `403 insufficient_scope` for audience mismatches
**What goes wrong:** Wrong-resource tokens look like ordinary permission misses. `[CITED: https://www.rfc-editor.org/rfc/rfc6750][CITED: https://www.rfc-editor.org/rfc/rfc9068]`
**Why it happens:** Scope and audience both feel “authorization-like”, so implementers flatten them into one bucket. `[CITED: https://www.rfc-editor.org/rfc/rfc6750][CITED: https://www.rfc-editor.org/rfc/rfc9068]`
**How to avoid:** Treat audience as a token-validity/resource-targeting check in `VerifyToken`, and let only scope failures become `403 insufficient_scope`. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]`
**Warning signs:** Telemetry shows “permission denied” for tokens minted to a different API, or controller code starts inspecting `aud` manually. `[ASSUMED]`

### Pitfall 2: Allowing both `audience` and `audiences`
**What goes wrong:** Route semantics become ambiguous and hard to reason about. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]`
**Why it happens:** Keyword options make it easy to treat one as a fallback for the other instead of rejecting the configuration. `[CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html]`
**How to avoid:** Raise in `init/1` when both are present; never defer that ambiguity to request time. `[CITED: https://hexdocs.pm/plug/1.8.3/Plug.Builder.html]`
**Warning signs:** Request-time branches compare both singular and plural values, or docs cannot explain which takes precedence. `[ASSUMED]`

### Pitfall 3: Parsing `scope` or `aud` differently across modules
**What goes wrong:** A token can pass one Lockspire path and fail another because normalization differs. `[VERIFIED: lib/lockspire/protocol/jar.ex][VERIFIED: lib/lockspire/protocol/authorization_request.ex]`
**Why it happens:** String splitting and audience list handling look simple, so duplicate helpers get added casually. `[VERIFIED: lib/lockspire/protocol/authorization_request.ex][VERIFIED: lib/lockspire/protocol/jar.ex]`
**How to avoid:** Create one internal normalization helper for route protection and mirror the proven semantics in `Lockspire.Protocol.Jar`. `[VERIFIED: lib/lockspire/protocol/jar.ex]`
**Warning signs:** Multiple `String.split(scope, " ", trim: true)` or `aud when is_list(aud)` branches appear in unrelated files. `[VERIFIED: lib/lockspire/protocol/authorization_request.ex][VERIFIED: lib/lockspire/protocol/jar.ex]`

### Pitfall 4: Updating docs without updating release-readiness contract tests
**What goes wrong:** The public support posture drifts from repo proof. `[VERIFIED: test/lockspire/release_readiness_contract_test.exs][VERIFIED: docs/supported-surface.md]`
**Why it happens:** Support wording lives in docs, but Lockspire pins important claims in tests. `[VERIFIED: test/lockspire/release_readiness_contract_test.exs]`
**How to avoid:** Update support-surface wording and the release-readiness assertions in the same phase, then add Phase 81 guide links to the proof story. `[VERIFIED: test/lockspire/release_readiness_contract_test.exs][VERIFIED: docs/install-and-onboard.md]`
**Warning signs:** CI fails on release-readiness assertions after doc edits, or docs still say generic host protected-resource middleware is out of scope after route-protection support ships. `[VERIFIED: test/lockspire/release_readiness_contract_test.exs][VERIFIED: docs/supported-surface.md]`

## Code Examples

Verified patterns from official sources and repo precedent:

### Validated Plug Options
```elixir
# Source: https://hexdocs.pm/nimble_options/NimbleOptions.html
@type option :: unquote(NimbleOptions.option_typespec(@options_schema))

@options_schema [
  scopes: [type: {:list, :string}, required: false],
  audience: [type: :string, required: false],
  audiences: [type: {:list, :string}, required: false]
]

def init(opts) do
  opts = NimbleOptions.validate!(opts, @options_schema)
  # reject both :audience and :audiences here
  opts
end
```

### Audience Match Against the Current Resource Server
```elixir
# Source: https://www.ietf.org/rfc/rfc7519.html
# Source: https://www.rfc-editor.org/rfc/rfc9068
defp audience_match?(claims, expected_values) do
  with {:ok, audiences} <- normalize_aud(claims) do
    Enum.any?(expected_values, &Enum.member?(audiences, &1))
  end
end
```

### Scope Failure Challenge Rendering
```elixir
# Source: https://www.rfc-editor.org/rfc/rfc6750
defp www_authenticate_insufficient_scope(required_scopes) do
  scopes = Enum.join(required_scopes, " ")
  ~s(Bearer realm="Lockspire", error="insufficient_scope", scope="#{scopes}")
end
```

### Canonical Route Wiring
```elixir
# Source: https://hexdocs.pm/phoenix/plug.html
pipeline :protected_api do
  plug Lockspire.Plug.VerifyToken, audience: "https://api.example.test", scopes: ["read:billing"]
  plug Lockspire.Plug.EnforceSenderConstraints
  plug Lockspire.Plug.RequireToken
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Public docs said generic host protected-resource middleware was out of scope. `[VERIFIED: docs/supported-surface.md][VERIFIED: test/lockspire/release_readiness_contract_test.exs]` | Recommended Phase 81 claim is a narrow Lockspire-issued-token Phoenix API route-protection pipeline in the same host shape. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]` | Phase 81 milestone closure target. `[VERIFIED: .planning/ROADMAP.md]` | Docs, release-readiness tests, and onboarding guidance must move together. `[VERIFIED: docs/install-and-onboard.md][VERIFIED: test/lockspire/release_readiness_contract_test.exs]` |
| Sender-constraint proof existed, but route-level scope/audience restriction proof did not. `[VERIFIED: test/lockspire/plug/enforce_sender_constraints_test.exs][VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex]` | Recommended proof couples sender constraints with route restrictions in routed tests and generated-host fixtures. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]` | Phase 81. `[VERIFIED: .planning/ROADMAP.md]` | Prevents the milestone from closing on helper-only coverage. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]` |

**Deprecated/outdated:**
- “Generic host protected-resource middleware remains out of scope” as blanket wording should be replaced by the narrower shipped Phase 81 claim once proof lands. `[VERIFIED: docs/supported-surface.md][VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]`

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Warning signs for audience/scope misclassification will show up mainly in telemetry/controller fallbacks. `[ASSUMED]` | Common Pitfalls | Low; implementation guidance remains unchanged. |
| A2 | Warning signs for dual `audience`/`audiences` config will surface as docs ambiguity or branching code. `[ASSUMED]` | Common Pitfalls | Low; init-time rejection still stands. |

## Open Questions (RESOLVED)

1. **Should Phase 81 make `nimble_options` a direct dependency?**
   - Decision: **Yes.** Phase 81 should add `{:nimble_options, "~> 1.1"}` directly to `mix.exs` because Lockspire already invokes `NimbleOptions.validate!/2` in public plug code and this phase expands that usage into `VerifyToken.init/1`. `[VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex][VERIFIED: mix.exs][VERIFIED: mix.lock]`
   - Why resolved this way: depending on a transitive package for a first-class public plug surface makes the compile/runtime contract less explicit and weakens repo truth for future release hygiene. A direct dependency keeps the option-validation contract intentional and auditable. `[VERIFIED: mix.exs][VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex]`
   - Planning consequence: Plan 01 should add the direct dependency and treat `NimbleOptions` as the standard Phase 81 validation seam. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-01-PLAN.md]`

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | plug implementation and tests | ✓ `[VERIFIED: local command]` | `1.19.5` `[VERIFIED: elixir --version]` | — |
| Mix | repo test and docs aliases | ✓ `[VERIFIED: local command]` | `1.19.5` `[VERIFIED: mix --version]` | — |
| PostgreSQL service | repo Ecto-backed tests | ✓ `[VERIFIED: local command]` | accepting on `:5432` `[VERIFIED: pg_isready]` | — |
| `psql` client | local DB diagnostics if needed | ✓ `[VERIFIED: local command]` | `14.17` `[VERIFIED: psql --version]` | — |
| Docker | not required for this phase’s repo-native proof | ✓ `[VERIFIED: local command]` | `29.4.1` client `[VERIFIED: docker info]` | not needed |

**Missing dependencies with no fallback:**
- None. `[VERIFIED: local command]`

**Missing dependencies with fallback:**
- None. `[VERIFIED: local command]`

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.ConnTest / Plug.Test. `[VERIFIED: mix.exs][VERIFIED: test/lockspire/plug/verify_token_test.exs][VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]` |
| Config file | `test/test_helper.exs` through repo standard test setup. `[VERIFIED: mix.exs][VERIFIED: test/lockspire/plug/verify_token_test.exs]` |
| Quick run command | `MIX_ENV=test mix test test/lockspire/plug/verify_token_test.exs test/lockspire/plug/require_token_test.exs test/lockspire/plug/enforce_sender_constraints_test.exs -x` `[VERIFIED: repo layout]` |
| Full suite command | `MIX_ENV=test mix test.fast && MIX_ENV=test mix test.integration` `[VERIFIED: mix.exs]` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VAL-PLUG-01 | Canonical Phoenix route pipeline protects host API routes. `[VERIFIED: .planning/REQUIREMENTS.md]` | integration | `MIX_ENV=test mix test test/integration/phase81_route_protection_e2e_test.exs --include integration --warnings-as-errors` | ❌ Wave 0 |
| VAL-PLUG-04 | `scopes:` and `audience:` / `audiences:` are validated and enforced with exact semantics. `[VERIFIED: .planning/REQUIREMENTS.md]` | unit | `MIX_ENV=test mix test test/lockspire/plug/verify_token_test.exs --warnings-as-errors` | ✅ existing file; needs new cases |
| VAL-DX-01 | Valid route requests expose `%AccessToken{}` assigns through routed controllers. `[VERIFIED: .planning/REQUIREMENTS.md]` | integration | `MIX_ENV=test mix test test/integration/phase81_route_protection_e2e_test.exs --include integration --warnings-as-errors` | ❌ Wave 0 |
| VAL-DX-02 | Invalid token/audience/sender failures return `401`, scope failures return `403 insufficient_scope`, and DPoP challenges stay scheme-aware. `[VERIFIED: .planning/REQUIREMENTS.md]` | unit + integration | `MIX_ENV=test mix test test/lockspire/plug/require_token_test.exs test/integration/phase81_route_protection_e2e_test.exs --include integration --warnings-as-errors` | `require_token_test.exs` ✅ / integration ❌ |
| VAL-BIND-03 | Sender-constrained tokens still reject with `401` under route restrictions. `[VERIFIED: .planning/REQUIREMENTS.md]` | integration | `MIX_ENV=test mix test test/integration/phase81_route_protection_e2e_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs --include integration --warnings-as-errors` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `MIX_ENV=test mix test test/lockspire/plug/verify_token_test.exs test/lockspire/plug/require_token_test.exs -x` `[VERIFIED: repo layout]`
- **Per wave merge:** `MIX_ENV=test mix test.fast` `[VERIFIED: mix.exs]`
- **Phase gate:** `MIX_ENV=test mix test.integration` plus Phase 81 docs/release-readiness checks before verification closeout. `[VERIFIED: mix.exs][VERIFIED: test/lockspire/release_readiness_contract_test.exs]`

### Wave 0 Gaps
- [ ] `test/integration/phase81_route_protection_e2e_test.exs` — routed Phoenix proof for status/challenge/body semantics and assigns contract. `[VERIFIED: repo layout]`
- [ ] `test/integration/phase81_generated_host_route_protection_e2e_test.exs` — generated-host protected-route proof aligned with docs/support posture. `[VERIFIED: test/integration/phase6_onboarding_e2e_test.exs][VERIFIED: test/integration/phase31_generated_host_verification_e2e_test.exs]`
- [ ] `docs/phoenix-api-protection.md` or equivalent guide plus contract assertions in `test/lockspire/release_readiness_contract_test.exs`. `[VERIFIED: docs/install-and-onboard.md][VERIFIED: test/lockspire/release_readiness_contract_test.exs]`
- [ ] `81-VERIFICATION.md` — milestone closure report tied to unit, router, generated-host, and docs proof. `[VERIFIED: .planning/phases/54-resource-indicators/54-VERIFICATION.md]`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes `[CITED: https://www.rfc-editor.org/rfc/rfc9068]` | JOSE signature validation plus issuer/key checks already in `VerifyToken`. `[VERIFIED: lib/lockspire/plug/verify_token.ex]` |
| V3 Session Management | no `[VERIFIED: docs/install-and-onboard.md]` | Host session ownership remains outside Lockspire route protection. `[VERIFIED: docs/sigra-companion-host.md]` |
| V4 Access Control | yes `[CITED: https://www.rfc-editor.org/rfc/rfc6750]` | Exact `aud` validation, exact case-sensitive scope matching, and sender-constraint enforcement in the plug pipeline. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md][VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex]` |
| V5 Input Validation | yes `[CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html]` | Validate plug options in `init/1`; reject malformed `aud` claims when restriction is configured. `[VERIFIED: lib/lockspire/protocol/jar.ex]` |
| V6 Cryptography | yes `[CITED: https://www.rfc-editor.org/rfc/rfc9068][CITED: https://www.ietf.org/rfc/rfc9449.html]` | Reuse existing JOSE/JWKS validation and DPoP/MTLS proof helpers; do not hand-roll new crypto. `[VERIFIED: lib/lockspire/plug/verify_token.ex][VERIFIED: lib/lockspire/protocol/dpop.ex][VERIFIED: lib/lockspire/protocol/mtls_token_binding.ex]` |

### Known Threat Patterns for Phoenix/Plug OAuth Route Protection

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Wrong-resource token replay | Elevation of Privilege | Reject tokens whose `aud` does not contain the expected resource identifier. `[CITED: https://www.ietf.org/rfc/rfc7519.html][CITED: https://www.rfc-editor.org/rfc/rfc9068]` |
| Scope escalation via parser leniency | Tampering | Normalize RFC 6749-style space-delimited scope strings, use case-sensitive exact matching, and return `403 insufficient_scope` only after token validity succeeds. `[CITED: https://www.rfc-editor.org/rfc/rfc6750][VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]` |
| Sender-constraint downgrade | Spoofing | Preserve `EnforceSenderConstraints` as a separate mandatory stage when `cnf` is present, and keep DPoP-aware challenges on proof failures. `[VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex][VERIFIED: lib/lockspire/plug/require_token.ex][CITED: https://www.ietf.org/rfc/rfc9449.html]` |
| Token disclosure in logs | Information Disclosure | Keep errors typed and minimal; never log raw tokens, proofs, certificates, or full claims. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md]` |

## Sources

### Primary (HIGH confidence)
- `lib/lockspire/plug/verify_token.ex` - current soft validation behavior and insertion point for restrictions.
- `lib/lockspire/plug/require_token.ex` - current denial rendering and scheme-aware challenges.
- `lib/lockspire/plug/enforce_sender_constraints.ex` - current sender-constraint composition and NimbleOptions precedent.
- `lib/lockspire/protocol/jar.ex` - existing repo precedent for `aud` string-or-list validation.
- `docs/supported-surface.md` - current public support contract and out-of-scope wording.
- `docs/install-and-onboard.md` - canonical onboarding and host-ownership boundary.
- `test/integration/phase6_onboarding_e2e_test.exs` - canonical generated-host integration proof pattern.
- `test/integration/phase31_generated_host_verification_e2e_test.exs` - generated-host E2E proof pattern.
- https://www.rfc-editor.org/rfc/rfc6750 - Bearer error semantics for `invalid_token` and `insufficient_scope`.
- https://www.ietf.org/rfc/rfc7519.html - JWT `aud` semantics and case-sensitive string-or-array rules.
- https://www.rfc-editor.org/rfc/rfc9068 - JWT access-token validation requirements for resource servers.
- https://www.ietf.org/rfc/rfc9449.html - DPoP protected-resource semantics and challenge behavior.
- https://hexdocs.pm/nimble_options/NimbleOptions.html - official option validation and docs generation.
- https://hexdocs.pm/phoenix/plug.html - Phoenix plug routing guidance.
- https://hexdocs.pm/plug/1.8.3/Plug.Builder.html - Plug `init/1` / `call/2` lifecycle and init-time option handling.

### Secondary (MEDIUM confidence)
- `mix hex.info phoenix` - current Phoenix release metadata as of 2026-05-23.
- `mix hex.info plug` - current Plug release metadata as of 2026-05-23.
- `mix hex.info nimble_options` - current NimbleOptions release metadata as of 2026-05-23.
- `mix hex.info phoenix_live_view` - current LiveView release metadata as of 2026-05-23.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all package/version claims are repo-verified or Hex-verified in this session. `[VERIFIED: mix.exs][VERIFIED: mix.lock][VERIFIED: mix hex.info phoenix][VERIFIED: mix hex.info plug][VERIFIED: mix hex.info nimble_options][VERIFIED: mix hex.info phoenix_live_view]`
- Architecture: HIGH - recommendations align with locked phase decisions, current plug code, and official RFC semantics. `[VERIFIED: .planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md][VERIFIED: lib/lockspire/plug/verify_token.ex][VERIFIED: lib/lockspire/plug/require_token.ex][VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex][CITED: https://www.rfc-editor.org/rfc/rfc6750][CITED: https://www.rfc-editor.org/rfc/rfc9068]`
- Pitfalls: MEDIUM-HIGH - most are directly supported by RFCs and repo patterns; warning-sign heuristics remain partially inferred. `[CITED: https://www.rfc-editor.org/rfc/rfc6750][CITED: https://www.rfc-editor.org/rfc/rfc9068][VERIFIED: lib/lockspire/protocol/jar.ex][ASSUMED]`

**Research date:** 2026-05-23
**Valid until:** 2026-06-22
