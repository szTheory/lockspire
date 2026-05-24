# Phase 84: Host Plug Pipeline, Docs, and Milestone Closure - Research

**Researched:** 2026-05-24 [VERIFIED: local system date]
**Domain:** Phoenix protected-route DPoP nonce contract closure, docs truth, and generated-host proof alignment [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: repo code/test scan; official RFC + Plug/Phoenix docs; focused local test runs]

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from [.planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md](/Users/jon/projects/lockspire/.planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md). [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md]

### Locked Decisions

#### Host plug contract

- **D-01:** Preserve the existing canonical protected-route pipeline:
  - `Lockspire.Plug.VerifyToken`
  - `Lockspire.Plug.EnforceSenderConstraints`
  - `Lockspire.Plug.RequireToken`
- **D-02:** Keep `VerifyToken` and `EnforceSenderConstraints` as soft validation plugs that assign structured failures onto `conn.assigns.access_token`; keep `RequireToken` as the single strict HTTP boundary.
- **D-03:** Do not collapse route protection into one fat plug and do not allow ad hoc response rendering from intermediate plugs.
- **D-04:** Treat plug order as contract, not suggestion. Downstream docs, generated examples, and proof should reinforce the exact order above.

#### Protected-resource nonce contract

- **D-05:** The shipped host Phoenix plug pipeline must use the same resource-server DPoP nonce semantics as Lockspire-owned protected resources:
  - `401 Unauthorized`
  - `WWW-Authenticate: DPoP ... error="use_dpop_nonce"`
  - `DPoP-Nonce` response header
  - successful retry when the new proof includes the supplied resource-server nonce and all normal DPoP checks still pass
- **D-06:** Bearer, MTLS, dual-bound token, replay, `ath`, binding, and `401` vs `403` behavior must remain otherwise unchanged.
- **D-07:** Keep nonce failures in the authentication-retry bucket, not the authorization bucket:
  - no `403` for nonce failures
  - no collapse into generic bearer `invalid_token`

#### Rendering and drift control

- **D-08:** Keep `Lockspire.Protocol.ProtectedResourceDPoP` as the single owner of protected-resource DPoP validation and typed nonce outcomes.
- **D-09:** Keep host-route HTTP rendering in `Lockspire.Plug.RequireToken` and Lockspire-owned protected-resource HTTP rendering in `Lockspire.Web.UserinfoController`.
- **D-10:** Extract one shared internal helper for protected-resource challenge rendering/data so `/userinfo` and the host plug pipeline emit the same:
  - `WWW-Authenticate` DPoP challenge semantics
  - `DPoP-Nonce`
  - `Access-Control-Expose-Headers`
- **D-11:** Do not let that shared helper absorb validation logic; it is for transport-shape consistency only.
- **D-12:** Ensure the host plug path passes the necessary endpoint secret material for resource-server nonce issuance/validation rather than relying on hidden ambient behavior.

#### Proof strategy

- **D-13:** Anchor Phase 84 milestone closure on generated-host protected-route proof, not on plug-only local coverage.
- **D-14:** Minimum milestone-closing proof for the host-route nonce slice is:
  - one generated-host protected-route E2E proving initial nonce challenge and successful retry on the documented pipeline
  - focused local plug tests for typed sender-constraint failure propagation, DPoP-aware challenge rendering, nonce-header exposure, and unchanged `401`/`403` behavior
  - release-contract assertions that pin the public nonce-backed host-route claim to repo proof
- **D-15:** Do not duplicate the entire DPoP negative matrix at generated-host E2E level. Exhaustive replay/`ath`/binding coverage remains protocol-heavy and adapter-thin.

#### Support truth and docs posture

- **D-16:** Public support language must stay narrow and explicit:
  - Lockspire supports nonce-backed DPoP for Lockspire-issued access tokens on Lockspire-owned `/token`, Lockspire-owned protected resources, and host Phoenix API routes protected by the shipped plug pipeline.
- **D-17:** Keep the anchor phrase:
  - `host Phoenix API routes protected by the shipped plug pipeline`
- **D-18:** Keep these explicitly out of scope in public wording for this phase:
  - generic resource-server middleware
  - gateway or service-mesh claims
  - arbitrary Plug-stack support
  - third-party issuer validation
  - multi-issuer protected-resource support
- **D-19:** `docs/supported-surface.md` remains the authoritative support contract; `docs/protect-phoenix-api-routes.md` is the concrete guide for this shipped surface; `docs/install-and-onboard.md` may link to it as the canonical optional protected-route path but must not imply a second product topology.
- **D-20:** Docs should explicitly say Lockspire verifies token protocol facts while the host app still owns business authorization, tenant policy, domain record lookup, and whether a protected route should exist at all.

#### Workflow preference

- **D-21:** Shift medium-impact implementation and wording choices left within GSD for this class of Lockspire phases.
- **D-22:** Downstream agents should resolve coherent medium-value choices autonomously after codebase + ecosystem research, and escalate only for decisions that materially affect:
  - product boundary
  - public API shape
  - security posture
  - support/release claims
  - hard-to-reverse strategic direction

### Claude's Discretion

- Exact helper/module placement for the shared protected-resource challenge-rendering helper, provided validation ownership and public semantics remain unchanged.
- Exact naming of any small internal helper APIs or structs used to share `/userinfo` and host-route challenge rendering.
- Exact split of assertions between plug tests, generated-host E2E, and release-contract tests, provided the proof hierarchy above stays intact.
- Exact prose ordering in `docs/protect-phoenix-api-routes.md` and `docs/supported-surface.md`, provided the narrow support boundary remains explicit and easy to discover.

### Deferred Ideas (OUT OF SCOPE)

- Generic resource-server middleware or gateway product claims
- Arbitrary Plug-stack or third-party framework support claims
- Multi-issuer or third-party issuer validation on host routes
- A broader resource-server validation product surface distinct from the shipped Phoenix plug pipeline
- New operator/client policy knobs for DPoP nonce behavior
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NONCE-RS-01 | On Lockspire-owned protected resources and the shipped host Phoenix plug pipeline, Lockspire MUST return a DPoP-aware `401` challenge with `error="use_dpop_nonce"` and a `DPoP-Nonce` response header when a DPoP proof is present but lacks a valid resource-server nonce. [VERIFIED: .planning/REQUIREMENTS.md] | Keep `Lockspire.Protocol.ProtectedResourceDPoP` as the only validator seam, keep `RequireToken` as the strict renderer, and extract only a transport-shape helper shared with `/userinfo`. [VERIFIED: lib/lockspire/protocol/protected_resource_dpop.ex] [VERIFIED: lib/lockspire/plug/require_token.ex] [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9449] |
| NONCE-RS-02 | Lockspire MUST accept the retried protected-resource request when the DPoP proof includes the supplied resource-server nonce and all existing DPoP checks still pass. [VERIFIED: .planning/REQUIREMENTS.md] | Use the existing generated-host E2E as the milestone anchor and keep local plug coverage focused on propagation/rendering, not full protocol duplication. [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] [VERIFIED: test/lockspire/protocol/protected_resource_dpop_test.exs] |
| NONCE-RS-03 | Existing protected-resource behavior for missing DPoP proofs, `Authorization: DPoP` enforcement, replay, `ath`, token binding, MTLS binding, and `401` vs `403` semantics MUST remain otherwise unchanged. [VERIFIED: .planning/REQUIREMENTS.md] | Preserve the current split between `VerifyToken`, `EnforceSenderConstraints`, and `RequireToken`, and extend tests only where adapter-level regressions can occur. [VERIFIED: lib/lockspire/plug/verify_token.ex] [VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex] [VERIFIED: lib/lockspire/plug/require_token.ex] |
| NONCE-TRUTH-01 | `docs/supported-surface.md` MUST stop claiming DPoP nonce support is out of scope and instead describe the shipped nonce-backed surface narrowly. [VERIFIED: .planning/REQUIREMENTS.md] | Update `docs/supported-surface.md` and pin the wording in `release_readiness_contract_test.exs`. [VERIFIED: docs/supported-surface.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| NONCE-TRUTH-02 | `docs/protect-phoenix-api-routes.md` and any Lockspire-owned DPoP docs MUST describe the nonce challenge/retry contract truthfully, including the retained narrow support boundary. [VERIFIED: .planning/REQUIREMENTS.md] | Keep `docs/protect-phoenix-api-routes.md` as the concrete guide and `docs/install-and-onboard.md` as the canonical onboarding doc that links to it. [VERIFIED: docs/protect-phoenix-api-routes.md] [VERIFIED: docs/install-and-onboard.md] |
| NONCE-TRUTH-03 | Repo-native tests MUST prove nonce challenge and retry behavior for `/token`, `/userinfo`, and the generated-host protected-route pipeline. [VERIFIED: .planning/REQUIREMENTS.md] | `/token` and `/userinfo` proof already exist; Phase 84 should close the host-route slice plus release-truth fences rather than rebuilding endpoint proof. [VERIFIED: test/lockspire/web/token_controller_test.exs] [VERIFIED: test/lockspire/web/userinfo_controller_test.exs] [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] |
</phase_requirements>

## Summary

Phase 84 is not greenfield work. As of 2026-05-24, the repo already contains nonce-aware host-route behavior in the canonical generated-host E2E, local sender-constraint propagation tests, and strict `RequireToken` rendering tests, and those focused suites are currently passing locally. [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] [VERIFIED: test/lockspire/plug/enforce_sender_constraints_test.exs] [VERIFIED: test/lockspire/plug/require_token_test.exs] [VERIFIED: local `MIX_ENV=test mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs`] [VERIFIED: local `MIX_ENV=test mix test test/lockspire/web/userinfo_controller_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs`]

The real planning problem is milestone closure and drift control. The protocol-owned nonce semantics already live in `Lockspire.Protocol.ProtectedResourceDPoP`, but `/userinfo` and the host plug boundary still duplicate response-shaping logic in separate adapters. That duplication is the highest-value implementation target because the current code already shows a concrete drift seam: `/userinfo` derives DPoP `algs` from the effective server profile, while `RequireToken` uses the profile-agnostic default helper. [VERIFIED: lib/lockspire/protocol/protected_resource_dpop.ex] [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [VERIFIED: lib/lockspire/plug/require_token.ex] [VERIFIED: lib/lockspire/protocol/dpop.ex]

The second planning problem is public truth. `docs/protect-phoenix-api-routes.md` already documents the nonce retry contract, but `docs/supported-surface.md` still contains out-of-scope wording about generic protected-resource middleware that must now be narrowed to the exact shipped surface, and `release_readiness_contract_test.exs` already has assertion hooks for that wording. [VERIFIED: docs/protect-phoenix-api-routes.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

**Primary recommendation:** plan Phase 84 as a closure/hardening phase: extract one internal protected-resource challenge helper, keep validation in `ProtectedResourceDPoP`, keep `RequireToken` as the only strict host-route HTTP boundary, update the support/docs contract to the narrow shipped phrase, and use the existing generated-host E2E plus release-contract tests as the milestone gate. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md] [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| DPoP proof validation, nonce classification, replay, `ath`, and binding checks | API / Backend [VERIFIED: lib/lockspire/protocol/protected_resource_dpop.ex] | Database / Storage for replay persistence [VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex] | `ProtectedResourceDPoP` already owns the protocol decision and `EnforceSenderConstraints` only forwards request data into it. [VERIFIED: lib/lockspire/protocol/protected_resource_dpop.ex] [VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex] |
| Host protected-route HTTP challenge rendering | API / Backend Plug boundary [VERIFIED: lib/lockspire/plug/require_token.ex] | Browser / Client retry behavior [CITED: https://www.rfc-editor.org/rfc/rfc9449] | RFC 9449 puts the nonce challenge on the resource response, and Lockspire has already centralized the strict route response boundary in `RequireToken`. [CITED: https://www.rfc-editor.org/rfc/rfc9449] [VERIFIED: lib/lockspire/plug/require_token.ex] |
| Lockspire-owned protected-resource HTTP challenge rendering | API / Backend controller boundary [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] | Browser / Client retry behavior [CITED: https://www.rfc-editor.org/rfc/rfc9449] | `/userinfo` is the Lockspire-owned reference transport adapter for the same resource-server nonce contract. [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] |
| Plug order contract for host Phoenix routes | Phoenix router / Plug pipeline [VERIFIED: docs/protect-phoenix-api-routes.md] | API / Backend internals [CITED: https://hexdocs.pm/plug/1.14.2/Plug.Builder.html] | Plug order is executable behavior, not documentation taste; Plug executes plugs in declaration order. [CITED: https://hexdocs.pm/plug/1.14.2/Plug.Builder.html] |
| Public support truth for the shipped protected-route surface | Docs + release contract tests [VERIFIED: docs/supported-surface.md] | Generated-host E2E proof [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] | Lockspire treats docs as the public contract and release-contract tests as the anti-drift fence. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| Business authorization, tenant policy, and route existence decisions | Host app [VERIFIED: docs/protect-phoenix-api-routes.md] | None | The docs and AGENTS boundary explicitly keep product authorization outside Lockspire’s protocol layer. [VERIFIED: docs/protect-phoenix-api-routes.md] [VERIFIED: AGENTS.md] |

## Project Constraints (from AGENTS.md)

- Lockspire must remain a separate embedded companion library, not a Sigra module or required standalone auth service. [VERIFIED: AGENTS.md]
- Internal boundaries must stay strong between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- The host seam must stay narrow: account resolution, claims, login redirects, branding, and product policy belong to the host app. [VERIFIED: AGENTS.md]
- v1 must not broaden into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md]
- Security defaults that matter directly to this phase include exact-match redirect URI validation, no `alg=none`, PKCE S256 by default, refresh-token rotation, and strong redaction in logs/operator surfaces. [VERIFIED: AGENTS.md]
- No project-defined skills were found under `.claude/skills/` or `.agents/skills/`, so no extra project skill rules constrain this phase. [VERIFIED: filesystem scan of `.claude/skills` and `.agents/skills`]

## Standard Stack

### Core

| Library / Surface | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| `Lockspire.Plug.VerifyToken` + `Lockspire.Plug.EnforceSenderConstraints` + `Lockspire.Plug.RequireToken` | repo local [VERIFIED: lib/lockspire/plug/verify_token.ex] [VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex] [VERIFIED: lib/lockspire/plug/require_token.ex] | Canonical shipped host-route contract. [VERIFIED: docs/protect-phoenix-api-routes.md] | The repo, docs, CONTEXT, and generated-host proof all converge on this exact plug order. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md] [VERIFIED: docs/protect-phoenix-api-routes.md] [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] |
| `Lockspire.Protocol.ProtectedResourceDPoP` | repo local [VERIFIED: lib/lockspire/protocol/protected_resource_dpop.ex] | Single validator seam for protected-resource DPoP including nonce outcomes. [VERIFIED: lib/lockspire/protocol/protected_resource_dpop.ex] | This is already shared by `/userinfo` and the host sender-constraint plug path, so Phase 84 should not fork validation logic. [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex] |
| Phoenix | repo declares `~> 1.8.5`; latest Hex release is `1.8.7` published 2026-05-06, but this phase should stay on the repo stack. [VERIFIED: mix.exs] [VERIFIED: hex.pm API `phoenix`] | Router pipelines, plugs, generated-host endpoint, and docs examples. [VERIFIED: mix.exs] | The shipped surface is specifically Phoenix route protection inside the host app. [VERIFIED: AGENTS.md] |
| Plug pipeline semantics | current Hex release `1.19.2` published 2026-05-14; official execution-order docs confirmed via `Plug.Builder`. [VERIFIED: hex.pm API `plug`] [CITED: https://hexdocs.pm/plug/1.14.2/Plug.Builder.html] | Makes plug order a real contract. [CITED: https://hexdocs.pm/plug/1.14.2/Plug.Builder.html] | Phase 84’s D-04 explicitly depends on plug execution order remaining authoritative. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md] |
| ExUnit + `Phoenix.ConnTest` | bundled / Phoenix docs [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/phoenix/Phoenix.ConnTest.html] | Generated-host end-to-end proof and adapter-level response assertions. [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] | Phoenix recommends endpoint testing for router-dispatched behavior, which matches the milestone-closure proof bar here. [CITED: https://hexdocs.pm/phoenix/Phoenix.ConnTest.html] |

### Supporting

| Library / Surface | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| Phoenix LiveView | repo declares `~> 1.1.28`; latest stable Hex release is `1.1.30` published 2026-05-05. [VERIFIED: mix.exs] [VERIFIED: hex.pm API `phoenix_live_view`] | Not a direct Phase 84 dependency, but part of the host-app stack whose docs must not be contradicted. [VERIFIED: AGENTS.md] | Keep untouched unless docs cross-links need clarification. [VERIFIED: docs/install-and-onboard.md] |
| Ecto SQL + PostgreSQL | repo declares `~> 3.13.5`; latest Hex release is `3.14.0` published 2026-05-19; local Postgres is `14.17` and accepting connections. [VERIFIED: mix.exs] [VERIFIED: hex.pm API `ecto_sql`] [VERIFIED: local `psql --version`] [VERIFIED: local `pg_isready`] | Supports generated-host E2E storage and replay proof. [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] | Required for running the integration proof, not for re-architecting the phase. [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] |
| Bandit | repo declares `~> 1.11`; latest Hex release is `1.11.1` published 2026-05-13. [VERIFIED: mix.exs] [VERIFIED: hex.pm API `bandit`] | Standard endpoint server dependency in the repo stack. [VERIFIED: mix.exs] | No planned Phase 84 behavior change. [VERIFIED: codebase scan] |
| Oban | repo declares `~> 2.21.0`; latest stable Hex release is `2.22.1` published 2026-04-30. [VERIFIED: mix.exs] [VERIFIED: hex.pm API `oban`] | Present in the supported install surface. [VERIFIED: docs/install-and-onboard.md] | Not part of the Phase 84 critical path. [VERIFIED: phase scope in 84-CONTEXT.md] |
| `test/lockspire/release_readiness_contract_test.exs` | repo local [VERIFIED: test/lockspire/release_readiness_contract_test.exs] | Release-truth fence for support/docs wording. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] | Use it for all public contract assertions instead of inventing a second docs-check mechanism. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared internal protected-resource challenge helper | Keep separate `/userinfo` and `RequireToken` rendering code | Rejected because the code already duplicates nonce/header/exposed-header rendering and already shows algorithm-list drift risk. [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [VERIFIED: lib/lockspire/plug/require_token.ex] |
| Generated-host E2E as milestone closure | Plug-only unit coverage | Rejected because the locked proof bar explicitly requires real routed Phoenix proof for the shipped host seam. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md] |
| Soft intermediate plugs plus one strict boundary | One fat route-protection plug | Rejected by locked decisions and by Plug composition norms that make order and ownership explicit. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md] [CITED: https://hexdocs.pm/plug/1.14.2/Plug.Builder.html] |
| Narrow support wording anchored to `host Phoenix API routes protected by the shipped plug pipeline` | Generic resource-server, gateway, or arbitrary Plug claims | Rejected because the supported product shape is the embedded Phoenix route path already proven in-repo. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md] [VERIFIED: docs/supported-surface.md] |

**Installation:**

```bash
mix deps.get
```

**Version verification:** The repo stack for this phase is pinned by `mix.exs`, while current package currency was verified against the Hex package API on 2026-05-24; the planning recommendation is to stay on the repo’s declared versions for Phase 84 and avoid incidental dependency upgrades. [VERIFIED: mix.exs] [VERIFIED: hex.pm API `phoenix`] [VERIFIED: hex.pm API `phoenix_live_view`] [VERIFIED: hex.pm API `ecto_sql`] [VERIFIED: hex.pm API `bandit`] [VERIFIED: hex.pm API `oban`] [VERIFIED: hex.pm API `plug`]

## Architecture Patterns

### System Architecture Diagram

```text
Client request
  -> Phoenix route pipeline
  -> Lockspire.Plug.VerifyToken
      -> JWT validation + scope/audience checks
      -> assigns conn.assigns.access_token
  -> Lockspire.Plug.EnforceSenderConstraints
      -> ProtectedResourceDPoP.validate_access(...)
          -> validate Authorization: DPoP scheme
          -> validate proof signature/htu/htm/iat/jti
          -> validate resource-server nonce
          -> validate ath + token binding + replay
      -> on failure, assign structured sender-constraint error
  -> Lockspire.Plug.RequireToken
      -> strict HTTP boundary
      -> render Bearer vs DPoP challenge
      -> emit DPoP-Nonce + Access-Control-Expose-Headers on nonce retry
  -> Host controller / business authorization

Parallel owned-surface reference:
  Client request -> Lockspire.Web.UserinfoController
    -> Lockspire.Protocol.Userinfo
    -> ProtectedResourceDPoP.validate_access(...)
    -> render same protected-resource nonce contract
```

The current repo already matches this shape except for the shared transport helper that should collapse `/userinfo` and `RequireToken` response duplication. [VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex] [VERIFIED: lib/lockspire/plug/require_token.ex] [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex]

### Recommended Project Structure

```text
lib/
├── lockspire/protocol/                 # DPoP validation and nonce typing
├── lockspire/plug/                     # host-route soft/strict plug boundary
└── lockspire/web/controllers/          # Lockspire-owned HTTP adapters
docs/
├── supported-surface.md                # authoritative support contract
├── protect-phoenix-api-routes.md       # concrete shipped host-route guide
└── install-and-onboard.md              # canonical onboarding doc with guide link
test/
├── lockspire/plug/                     # adapter-level plug proofs
├── lockspire/web/                      # Lockspire-owned endpoint proofs
├── integration/                        # generated-host end-to-end proof
└── lockspire/release_readiness_contract_test.exs
```

This structure already exists and should be extended in place rather than split into a second proof or docs lane. [VERIFIED: filesystem scan] [VERIFIED: docs/supported-surface.md] [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs]

### Pattern 1: Protocol-Owned Validation, Adapter-Owned Rendering

**What:** Keep `ProtectedResourceDPoP` responsible for all resource-server DPoP decisions and let `/userinfo` and `RequireToken` only translate typed outcomes into HTTP transport details. [VERIFIED: lib/lockspire/protocol/protected_resource_dpop.ex] [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [VERIFIED: lib/lockspire/plug/require_token.ex]

**When to use:** For any host route or Lockspire-owned endpoint that enforces DPoP-bound access tokens. [VERIFIED: docs/protect-phoenix-api-routes.md] [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex]

**Example:**

```elixir
# Source: lib/lockspire/plug/enforce_sender_constraints.ex
case ProtectedResourceDPoP.validate_access(access_token, request) do
  {:ok, proof} ->
    {:ok, proof}

  {:error, error} ->
    {:error, sender_error(:dpop, error)}
end
```

### Pattern 2: Soft Validation First, Single Strict HTTP Boundary Last

**What:** Intermediate plugs assign structured failures; only `RequireToken` halts and renders the response. [VERIFIED: lib/lockspire/plug/verify_token.ex] [VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex] [VERIFIED: lib/lockspire/plug/require_token.ex]

**When to use:** All host Phoenix protected routes using the shipped Lockspire pipeline. [VERIFIED: docs/protect-phoenix-api-routes.md]

**Example:**

```elixir
# Source: docs/protect-phoenix-api-routes.md
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
  plug Lockspire.Plug.EnforceSenderConstraints,
    dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
  plug Lockspire.Plug.RequireToken
end
```

### Pattern 3: Milestone Claims Must Be Proven Through Routed Endpoint Tests

**What:** Use `Phoenix.ConnTest` against the generated-host endpoint for the real shipped surface instead of relying only on plug unit tests. [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] [CITED: https://hexdocs.pm/phoenix/Phoenix.ConnTest.html]

**When to use:** Any public docs or supported-surface claim about host route protection behavior. [VERIFIED: docs/supported-surface.md]

**Example:**

```elixir
# Source: test/integration/phase81_generated_host_route_protection_e2e_test.exs
challenge_conn =
  protected_conn()
  |> put_req_header("authorization", "DPoP #{token}")
  |> put_req_header("dpop", generate_dpop_proof(dpop_keys.private_jwk, token, nil))
  |> get(@protected_route)

assert challenge_conn.status == 401
assert [retry_nonce] = get_resp_header(challenge_conn, "dpop-nonce")
```

### Anti-Patterns to Avoid

- **Fat route-protection plug:** It hides the soft/strict contract and directly violates locked phase decisions. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md]
- **Transport helper that performs validation:** The helper for this phase must normalize only rendering data, not move protocol logic out of `ProtectedResourceDPoP`. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md]
- **Docs that imply generic resource-server middleware support:** The supported surface must stay pinned to Lockspire-owned endpoints plus host Phoenix API routes protected by the shipped plug pipeline. [VERIFIED: docs/supported-surface.md] [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DPoP proof + nonce validation | A second host-route-specific validator | `Lockspire.Protocol.ProtectedResourceDPoP` [VERIFIED: lib/lockspire/protocol/protected_resource_dpop.ex] | Replay, `ath`, nonce purpose, authorization-scheme, and binding checks are already centralized there. [VERIFIED: lib/lockspire/protocol/protected_resource_dpop.ex] |
| Nonce transport rendering | Separate ad hoc nonce/header formatting in each adapter | One shared internal protected-resource challenge helper plus existing adapter boundaries. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md] | The repo already duplicates `DPoP-Nonce` and `Access-Control-Expose-Headers` logic in `RequireToken` and `UserinfoController`. [VERIFIED: lib/lockspire/plug/require_token.ex] [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] |
| Milestone-proof topology | A new fake plug harness or second demo app | Existing generated-host app + `phase81_generated_host_route_protection_e2e_test.exs`. [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] | The shipped host seam is already represented there and that file currently proves the nonce retry path end to end. [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] |
| Public support-truth enforcement | Manual checklist outside the test suite | `test/lockspire/release_readiness_contract_test.exs`. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] | The release contract already pins supported-surface and guide wording. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |

**Key insight:** The hard part of this phase is not DPoP math; it is keeping one shipped Phoenix route contract, one protected-resource validation seam, and one public truth story aligned across adapters, docs, and proof. [VERIFIED: repo code/test/doc scan] [CITED: https://www.rfc-editor.org/rfc/rfc9449]

## Common Pitfalls

### Pitfall 1: Adapter Drift Between `/userinfo` and `RequireToken`

**What goes wrong:** The two adapters emit slightly different DPoP challenge data or header-exposure behavior. [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [VERIFIED: lib/lockspire/plug/require_token.ex]
**Why it happens:** Both files currently build nonce/header behavior independently, and they already differ on how DPoP `algs` are sourced. [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [VERIFIED: lib/lockspire/plug/require_token.ex] [VERIFIED: lib/lockspire/protocol/dpop.ex]
**How to avoid:** Extract one internal helper for protected-resource challenge rendering data only, then keep local adapter tests on both entry points. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md]
**Warning signs:** A test passes on `/userinfo` but not on host routes, or the `WWW-Authenticate` / `DPoP-Nonce` / `Access-Control-Expose-Headers` trio diverges. [VERIFIED: test/lockspire/web/userinfo_controller_test.exs] [VERIFIED: test/lockspire/plug/require_token_test.exs]

### Pitfall 2: Breaking the Soft/Strict Plug Boundary

**What goes wrong:** `VerifyToken` or `EnforceSenderConstraints` starts halting or rendering responses directly. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md]
**Why it happens:** Route restrictions and sender constraints are evaluated in different soft-validation plugs before the strict HTTP boundary, so response rendering can drift if intermediate plugs start doing transport work. [VERIFIED: lib/lockspire/plug/verify_token.ex] [VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex] [VERIFIED: lib/lockspire/plug/require_token.ex]
**How to avoid:** Keep intermediate plugs assignment-only and route all transport decisions through `RequireToken`. [VERIFIED: lib/lockspire/plug/require_token.ex] [VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex]
**Warning signs:** Tests need to assert halted connections before `RequireToken`, or docs stop presenting the three-plug order as canonical. [VERIFIED: test/lockspire/plug/enforce_sender_constraints_test.exs] [VERIFIED: docs/protect-phoenix-api-routes.md]

### Pitfall 3: Reclassifying Nonce Retry as Authorization Failure

**What goes wrong:** Nonce failures become `403`, `insufficient_scope`, or generic bearer `invalid_token`. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md]
**Why it happens:** The host route surface mixes route restrictions and sender constraints in one pipeline, so error categorization can drift if rendering is normalized too aggressively. [VERIFIED: lib/lockspire/plug/verify_token.ex] [VERIFIED: lib/lockspire/plug/require_token.ex]
**How to avoid:** Preserve sender-constraint category metadata and assert the `401 DPoP use_dpop_nonce` path separately from `403 insufficient_scope`. [VERIFIED: test/lockspire/plug/require_token_test.exs] [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] [CITED: https://www.rfc-editor.org/rfc/rfc9449]
**Warning signs:** A nonce failure no longer includes `DPoP-Nonce`, or scope and nonce failures become indistinguishable in release tests. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

### Pitfall 4: Public Support Overclaim

**What goes wrong:** Docs imply generic API gateway, arbitrary Plug-stack, or third-party issuer support. [VERIFIED: docs/supported-surface.md]
**Why it happens:** The host-route guide is concrete, but the supported-surface page still contains broader out-of-scope phrasing that can be updated incorrectly when adding nonce wording. [VERIFIED: docs/supported-surface.md] [VERIFIED: docs/protect-phoenix-api-routes.md]
**How to avoid:** Reuse the exact anchor phrase `host Phoenix API routes protected by the shipped plug pipeline` and fence it in `release_readiness_contract_test.exs`. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
**Warning signs:** `docs/supported-surface.md` talks about “generic middleware” or “broader resource-server integration” without the narrow host-route qualifier. [VERIFIED: docs/supported-surface.md]

## Code Examples

Verified patterns from repo code and official docs:

### Canonical Protected Route Pipeline

```elixir
# Source: docs/protect-phoenix-api-routes.md
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
  plug Lockspire.Plug.EnforceSenderConstraints,
    dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
  plug Lockspire.Plug.RequireToken
end
```

### Generated-Host Nonce Retry Proof

```elixir
# Source: test/integration/phase81_generated_host_route_protection_e2e_test.exs
[retry_nonce] = get_resp_header(challenge_conn, "dpop-nonce")
proof = generate_dpop_proof(dpop_keys.private_jwk, token, retry_nonce)

success_conn =
  protected_conn()
  |> put_req_header("authorization", "DPoP #{token}")
  |> put_req_header("dpop", proof)
  |> get(@protected_route)

assert success_conn.status == 200
```

### Shared Rendering Target Shape

```elixir
# Source: lib/lockspire/web/controllers/userinfo_controller.ex
conn
|> put_resp_header("dpop-nonce", nonce)
|> expose_header("DPoP-Nonce")
|> expose_header("WWW-Authenticate")
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Host Phoenix route protection without nonce-backed DPoP retry proof in the milestone contract | Host Phoenix route protection includes nonce challenge/retry behavior and already has focused local plus generated-host proof in the repo. [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] [VERIFIED: test/lockspire/plug/require_token_test.exs] | v1.22 work landed by 2026-05-24 in the current tree. [VERIFIED: local code/test scan dated 2026-05-24] | Phase 84 should plan closure and hardening, not a net-new DPoP feature build. [VERIFIED: local focused test runs] |
| Docs posture saying nonce-backed protected-resource support is still out of scope | Public docs must now describe the shipped nonce-backed surface narrowly and provably. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: docs/supported-surface.md] | Required for Phase 84 milestone closure. [VERIFIED: .planning/ROADMAP.md] | Most remaining work is support-truth and release-fence alignment. [VERIFIED: docs/supported-surface.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| Duplicate challenge-rendering logic in separate adapters | Shared internal protected-resource challenge helper is the right current approach. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md] | Phase 84 target. [VERIFIED: 84-CONTEXT.md] | Reduces drift risk without moving validation out of protocol code. [VERIFIED: 84-CONTEXT.md] |

**Deprecated/outdated:**

- Broad wording like `Generic API gateway, service-mesh, or third-party issuer protected-resource middleware remains out of scope` is still factually true about unsupported breadth, but it is insufficient alone after the shipped nonce-backed host-route surface exists; Phase 84 must replace or qualify it with the exact supported phrase. [VERIFIED: docs/supported-surface.md] [VERIFIED: .planning/REQUIREMENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| None | All material claims in this research were verified against the repo, official docs, or the RFC sources used here. [VERIFIED: research trace] | — | — |

## Open Questions (RESOLVED)

1. **Is any Phase 84 implementation already present in unarchived working-tree changes beyond the currently passing proof?**
   - Resolution: yes. The current tree already contains meaningful Phase 84 behavior, including nonce-aware host-route handling in the canonical generated-host proof and green focused adapter/release-contract suites on 2026-05-24. Phase 84 should therefore be planned as closure and drift-control work, not as a greenfield feature build. [VERIFIED: local focused test runs] [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] [VERIFIED: test/lockspire/plug/enforce_sender_constraints_test.exs] [VERIFIED: test/lockspire/plug/require_token_test.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
   - Planning consequence: the first implementation task should audit the current tree against the exact Phase 84 acceptance criteria, then limit code changes to any remaining helper, docs, or proof drift rather than rebuilding the nonce slice. [VERIFIED: current repo state]

2. **Should the shared protected-resource challenge helper use policy-aware DPoP algorithm lists for host routes, or preserve the current profile-agnostic `RequireToken` output?**
   - Resolution: the shared helper should use the same policy-aware algorithm sourcing as `/userinfo` so both protected-resource adapters emit the same DPoP challenge contract, including FAPI-effective `algs` values when the profile is active. This matches locked Decision D-10, which requires shared transport-shape semantics between `/userinfo` and the host plug pipeline. [VERIFIED: .planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md] [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [VERIFIED: lib/lockspire/plug/require_token.ex] [VERIFIED: lib/lockspire/protocol/dpop.ex]
   - Planning consequence: the host-route alignment plan should explicitly pass the effective server policy into the shared helper and lock the resulting `algs` behavior with local tests on both adapters. [VERIFIED: test/lockspire/plug/require_token_test.exs] [VERIFIED: test/lockspire/web/userinfo_controller_test.exs]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix compile/test workflow [VERIFIED: mix.exs] | ✓ [VERIFIED: local `elixir --version`] | `1.19.5` [VERIFIED: local `elixir --version`] | — |
| Mix | Phase-local test and docs workflow [VERIFIED: mix.exs] | ✓ [VERIFIED: local `mix --version`] | `1.19.5` [VERIFIED: local `mix --version`] | — |
| PostgreSQL server | Generated-host integration tests and Ecto-backed proof [VERIFIED: test/integration/phase81_generated_host_route_protection_e2e_test.exs] | ✓ [VERIFIED: local `pg_isready`] | `14.17` client; server accepting on `/tmp:5432` [VERIFIED: local `psql --version`] [VERIFIED: local `pg_isready`] | — |
| Node / npm / npx | Context7 CLI fallback and ancillary tooling [VERIFIED: docs lookup instructions] | ✓ [VERIFIED: local `node --version`] [VERIFIED: local `npm --version`] [VERIFIED: local `npx --version`] | `22.14.0` / `11.1.0` [VERIFIED: local `node --version`] [VERIFIED: local `npm --version`] | Official docs via web when Context7 quota blocks CLI. [VERIFIED: local `npx --yes ctx7@latest ...` quota failure] |
| Context7 CLI quota | Library docs lookup [VERIFIED: docs lookup instructions] | ✗ for this session [VERIFIED: local `npx --yes ctx7@latest ...`] | quota exceeded [VERIFIED: local `npx --yes ctx7@latest ...`] | Use official docs via HexDocs and RFC sources. [CITED: https://hexdocs.pm/plug/1.14.2/Plug.Builder.html] [CITED: https://hexdocs.pm/phoenix/Phoenix.ConnTest.html] [CITED: https://www.rfc-editor.org/rfc/rfc9449] |

**Missing dependencies with no fallback:**

- None for planning or focused repo proof on this machine. [VERIFIED: environment probes]

**Missing dependencies with fallback:**

- Context7 documentation quota is exhausted in this session, but official docs were reachable through HexDocs and RFC sources, so research is not blocked. [VERIFIED: local `npx --yes ctx7@latest ...`] [CITED: https://hexdocs.pm/plug/1.14.2/Plug.Builder.html] [CITED: https://hexdocs.pm/phoenix/Phoenix.ConnTest.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.ConnTest [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/phoenix/Phoenix.ConnTest.html] |
| Config file | none; test aliases and contributor lane are defined in `mix.exs`. [VERIFIED: mix.exs] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs` [VERIFIED: local successful run on 2026-05-24] |
| Full suite command | `mix ci` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NONCE-RS-01 | Host-route nonce failure returns `401`, DPoP challenge, and `DPoP-Nonce`. [VERIFIED: .planning/REQUIREMENTS.md] | unit + integration [VERIFIED: current tests] | `MIX_ENV=test mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs` [VERIFIED: local successful runs] | ✅ [VERIFIED: filesystem] |
| NONCE-RS-02 | Host-route retry succeeds with the supplied nonce. [VERIFIED: .planning/REQUIREMENTS.md] | integration [VERIFIED: current tests] | `MIX_ENV=test mix test test/integration/phase81_generated_host_route_protection_e2e_test.exs` [VERIFIED: local successful run] | ✅ [VERIFIED: filesystem] |
| NONCE-RS-03 | Replay, missing proof, wrong scheme, MTLS, and `401`/`403` semantics remain unchanged. [VERIFIED: .planning/REQUIREMENTS.md] | unit + integration [VERIFIED: current tests] | `MIX_ENV=test mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs test/lockspire/web/userinfo_controller_test.exs` [VERIFIED: local successful runs] | ✅ [VERIFIED: filesystem] |
| NONCE-TRUTH-01 | Supported-surface wording reflects the shipped nonce-backed surface narrowly. [VERIFIED: .planning/REQUIREMENTS.md] | release contract [VERIFIED: current tests] | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` [VERIFIED: local successful run] | ✅ [VERIFIED: filesystem] |
| NONCE-TRUTH-02 | Host-route docs describe the nonce challenge/retry contract truthfully. [VERIFIED: .planning/REQUIREMENTS.md] | release contract + docs review [VERIFIED: current tests/docs] | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` [VERIFIED: local successful run] | ✅ [VERIFIED: filesystem] |
| NONCE-TRUTH-03 | `/token`, `/userinfo`, and generated-host protected route all have repo-native nonce proof. [VERIFIED: .planning/REQUIREMENTS.md] | integration + unit [VERIFIED: current tests] | `MIX_ENV=test mix test test/lockspire/web/token_controller_test.exs test/lockspire/web/userinfo_controller_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs` [VERIFIED: file presence; partial local runs for `/userinfo` and host-route] | ✅ [VERIFIED: filesystem] |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs` [VERIFIED: recommended from current adapter seams]
- **Per wave merge:** `MIX_ENV=test mix test test/lockspire/web/userinfo_controller_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs test/lockspire/release_readiness_contract_test.exs` [VERIFIED: requirement coverage map]
- **Phase gate:** `mix ci` plus the Phase 84-targeted test subset above before `/gsd-verify-work`. [VERIFIED: mix.exs] [VERIFIED: phase scope]

### Wave 0 Gaps

- None in framework/infrastructure; the existing repo already has the right proof files and the focused Phase 84 subset is passing. [VERIFIED: filesystem] [VERIFIED: local focused test runs]
- Add assertions inside existing files if the shared rendering helper changes challenge details or docs wording; do not create parallel proof files unless a new public seam appears. [VERIFIED: current test layout] [VERIFIED: 84-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: phase scope] | DPoP proof validation and token verification in `VerifyToken` + `ProtectedResourceDPoP`. [VERIFIED: lib/lockspire/plug/verify_token.ex] [VERIFIED: lib/lockspire/protocol/protected_resource_dpop.ex] |
| V3 Session Management | no for Lockspire-owned host login session behavior in this phase; host app owns it. [VERIFIED: docs/protect-phoenix-api-routes.md] | Host seam documentation only. [VERIFIED: AGENTS.md] |
| V4 Access Control | yes [VERIFIED: phase scope] | `VerifyToken` scope/audience restrictions plus host-owned post-token business authorization. [VERIFIED: lib/lockspire/plug/verify_token.ex] [VERIFIED: docs/protect-phoenix-api-routes.md] |
| V5 Input Validation | yes [VERIFIED: phase scope] | `NimbleOptions` plug option validation and typed error normalization. [VERIFIED: lib/lockspire/plug/verify_token.ex] [VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex] |
| V6 Cryptography | yes [VERIFIED: phase scope] | JOSE-backed DPoP proof verification and signed nonce issuance via `DPoPNonce`. [VERIFIED: lib/lockspire/protocol/dpop.ex] [VERIFIED: lib/lockspire/protocol/dpop_nonce.ex] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Replayed DPoP proof | Replay | `ProtectedResourceDPoP` records proof use through the replay store and keeps replay failures distinct from nonce failures. [VERIFIED: lib/lockspire/protocol/protected_resource_dpop.ex] [VERIFIED: test/lockspire/protocol/protected_resource_dpop_test.exs] |
| Cross-surface nonce reuse | Tampering | `DPoPNonce` encodes nonce purpose and rejects authorization-server nonces on resource-server surfaces. [VERIFIED: lib/lockspire/protocol/dpop_nonce.ex] [VERIFIED: test/lockspire/protocol/protected_resource_dpop_test.exs] |
| Bearer/DPoP downgrade on sender-constrained tokens | Spoofing | `ProtectedResourceDPoP` requires `Authorization: DPoP` for DPoP-bound access tokens. [VERIFIED: lib/lockspire/protocol/protected_resource_dpop.ex] [VERIFIED: test/lockspire/web/userinfo_controller_test.exs] |
| Transport-shape mismatch between surfaces | Tampering / Repudiation | Shared internal challenge helper plus release-contract and adapter tests. [VERIFIED: 84-CONTEXT.md] [VERIFIED: test/lockspire/plug/require_token_test.exs] [VERIFIED: test/lockspire/web/userinfo_controller_test.exs] |
| Public support overclaim beyond the proven boundary | Repudiation | Keep `docs/supported-surface.md` authoritative and fence exact wording in `release_readiness_contract_test.exs`. [VERIFIED: docs/supported-surface.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |

## Sources

### Primary (HIGH confidence)

- [.planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md](/Users/jon/projects/lockspire/.planning/phases/84-host-plug-pipeline-docs-and-milestone-closure/84-CONTEXT.md) - locked decisions, proof bar, and docs boundary. [VERIFIED: local file]
- [.planning/REQUIREMENTS.md](/Users/jon/projects/lockspire/.planning/REQUIREMENTS.md) - `NONCE-RS-*` and `NONCE-TRUTH-*` requirement text. [VERIFIED: local file]
- [lib/lockspire/protocol/protected_resource_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/protected_resource_dpop.ex) - validator ownership and nonce error typing. [VERIFIED: local file]
- [lib/lockspire/plug/enforce_sender_constraints.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/enforce_sender_constraints.ex) - host-route sender-constraint adapter seam. [VERIFIED: local file]
- [lib/lockspire/plug/require_token.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/require_token.ex) - strict host-route HTTP rendering boundary. [VERIFIED: local file]
- [lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex) - Lockspire-owned protected-resource transport reference. [VERIFIED: local file]
- [docs/protect-phoenix-api-routes.md](/Users/jon/projects/lockspire/docs/protect-phoenix-api-routes.md) - current shipped guide wording. [VERIFIED: local file]
- [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md) - authoritative support contract that still needs narrowing. [VERIFIED: local file]
- [test/integration/phase81_generated_host_route_protection_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase81_generated_host_route_protection_e2e_test.exs) - generated-host host-route nonce retry proof. [VERIFIED: local file]
- [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs) - docs/release truth fences. [VERIFIED: local file]
- `MIX_ENV=test mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs` - 17 tests, 0 failures on 2026-05-24. [VERIFIED: local test run]
- `MIX_ENV=test mix test test/lockspire/web/userinfo_controller_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs` - 18 tests, 0 failures on 2026-05-24. [VERIFIED: local test run]
- `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` - 21 tests, 0 failures on 2026-05-24. [VERIFIED: local test run]
- https://www.rfc-editor.org/rfc/rfc9449 - DPoP nonce challenge/retry contract for authorization server and resource server surfaces. [CITED: https://www.rfc-editor.org/rfc/rfc9449]
- https://hexdocs.pm/plug/1.14.2/Plug.Builder.html - plug execution order guarantees. [CITED: https://hexdocs.pm/plug/1.14.2/Plug.Builder.html]
- https://hexdocs.pm/phoenix/Phoenix.ConnTest.html - endpoint-testing guidance for routed Phoenix behavior. [CITED: https://hexdocs.pm/phoenix/Phoenix.ConnTest.html]
- Hex package API (`https://hex.pm/api/packages/<name>`) - current package versions and release dates for `phoenix`, `phoenix_live_view`, `ecto_sql`, `bandit`, `oban`, `plug`. [VERIFIED: live Hex API queries on 2026-05-24]

### Secondary (MEDIUM confidence)

- None needed; primary codebase, RFC, official HexDocs, and registry sources were sufficient. [VERIFIED: research trace]

### Tertiary (LOW confidence)

- None. [VERIFIED: assumptions log contains only one low-risk implementation-behavior assumption]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repo-local stack, Hex registry version checks, and official Plug/Phoenix docs all agree. [VERIFIED: mix.exs] [VERIFIED: Hex API queries] [CITED: https://hexdocs.pm/plug/1.14.2/Plug.Builder.html] [CITED: https://hexdocs.pm/phoenix/Phoenix.ConnTest.html]
- Architecture: HIGH - locked CONTEXT decisions align with current code seams and passing focused tests. [VERIFIED: 84-CONTEXT.md] [VERIFIED: local focused test runs]
- Pitfalls: HIGH - derived from concrete duplication and wording drift in the current tree, not from generic ecosystem folklore. [VERIFIED: lib/lockspire/plug/require_token.ex] [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [VERIFIED: docs/supported-surface.md]

**Research date:** 2026-05-24 [VERIFIED: local system date]
**Valid until:** 2026-06-23 for repo-state planning; recheck package registry currency sooner if this phase is delayed or broadened into dependency upgrades. [VERIFIED: repo-local focus] [VERIFIED: Hex API queries]
