# Phase 36: End-to-End Proof and Milestone Closure - Research

**Researched:** 2026-04-28
**Domain:** DPoP end-to-end proof, introspection truth, and milestone closure
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### End-to-End Proof Strategy

- **D-01:** Phase 36 should extend Lockspire's existing repo-native integration-test style for
  DPoP proof rather than introduce a second acceptance harness or external demo-app layer.
- **D-02:** The browser-style proof should be an authorization-code DPoP flow that exercises the
  existing Phoenix/host-owned interaction path through real HTTP seams, not a protocol-only
  unit test.
- **D-03:** The CLI/device-oriented proof should build on the existing generated-host device-flow
  integration seam and keep device redemption proof in the same end-to-end style already used by
  Phase 32.
- **D-04:** Planner should prefer reuse and extension of the existing integration fixtures,
  helpers, and endpoint setup patterns before inventing new test scaffolding.

### Introspection Truth

- **D-05:** Introspection should expose durable DPoP binding truth for active DPoP-bound tokens by
  including `cnf` when present on the stored token.
- **D-06:** Introspection must preserve the current inactive-response collapse and confidential
  caller gate; Phase 36 extends the active-response truth only, not the authorization model or
  inactive semantics.
- **D-07:** The source of introspection DPoP truth remains the persisted token record, not client
  policy lookups or request-local assumptions.

### Public Surface Boundaries

- **D-08:** Phase 36 must keep the public DPoP support contract narrow: `/token` issuance,
  Lockspire-owned `userinfo`, and truthful introspection visibility for active bound tokens.
- **D-09:** Do not let docs, tests, or milestone-closure wording imply generic host
  protected-resource DPoP support or any broader sender-constrained surface than the repo proves.
- **D-10:** Release/support contract tests remain the enforcement backstop for public DPoP wording
  and should be extended only to reflect the shipped Phase 36 truth.

### Milestone Closure Discipline

- **D-11:** Phase 36 should treat `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`,
  `.planning/STATE.md`, `.planning/PROJECT.md`, and `.planning/EPIC.md` as the authoritative
  milestone-truth set that must close in sync.
- **D-12:** DPoP-12, DPoP-13, and DPoP-14 should not be marked complete until code proof, public
  docs, and planning artifacts all agree on the shipped slice and milestone outcome.
- **D-13:** `.planning/EPIC.md` should be updated as a milestone-boundary artifact that reflects
  what v1.7 delivered and preserves the current next-milestone selection logic grounded in repo
  truth.

### the agent's Discretion

- Exact file split for new integration tests may be chosen during planning as long as the proof
  stays in the repo-native integration suite and keeps browser/device coverage explicit.
- Exact active introspection response shape beyond adding `cnf` may be refined during planning if
  it remains standards-shaped and does not widen the public support claim.
- Exact milestone-close wording across docs and planning artifacts may evolve during planning so
  long as the narrow DPoP support contract remains truthful.

### Deferred Ideas (OUT OF SCOPE)

- Generic host protected-resource middleware or Plug helpers for DPoP enforcement outside
  Lockspire-owned endpoints
- DPoP nonce support or broader sender-constrained protocol breadth beyond the v1.7 core
- New acceptance infrastructure separate from the repo-native integration suite
- Reprioritizing the next milestone away from the current adoption-hardening vs protocol-depth
  selection logic before v1.7 closes
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DPoP-12 | End-to-end tests prove at least one authorization-code DPoP flow and one public/CLI-oriented DPoP flow. | Use one dedicated browser auth-code DPoP integration test built from the Phase 15 authorize/consent/token pattern and one dedicated device/CLI DPoP integration test built from the Phase 32 `/device/code -> /verify -> /token` pattern. [VERIFIED: test/integration/phase15_par_authorization_e2e_test.exs, test/integration/phase32_device_flow_token_exchange_e2e_test.exs, .planning/REQUIREMENTS.md] |
| DPoP-13 | Introspection and related runtime surfaces expose truthful DPoP-bound token state where needed, including `cnf` on active DPoP-bound tokens. | Extend `Lockspire.Protocol.Introspection.active_response/1` to include stored `token.cnf` when present, then cover it at protocol, controller, and device-issued-token integration levels. [VERIFIED: lib/lockspire/protocol/introspection.ex, test/lockspire/protocol/introspection_test.exs, test/lockspire/web/introspection_controller_test.exs, .planning/REQUIREMENTS.md] |
| DPoP-14 | The v1.7 milestone closes with synchronized docs, traceability, and an updated epic-arc record so future milestone selection builds from current repo truth. | Close the live planning set together (`ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `PROJECT.md`, `EPIC.md`), then archive the milestone and record the shipped outcome in `MILESTONES.md`. [VERIFIED: .planning/ROADMAP.md, .planning/REQUIREMENTS.md, .planning/STATE.md, .planning/PROJECT.md, .planning/EPIC.md, .planning/MILESTONES.md] |
</phase_requirements>

## Summary

Phase 36 should stay narrow: prove the already-shipped DPoP slice end to end, expose persisted `cnf` truth through introspection, and close the milestone artifacts without widening the supported resource-server surface. The repo already has the three seams this phase needs: browser-host auth-code proof in the Phase 15 integration style, device/CLI proof in the Phase 32 generated-host flow, and centralized introspection response shaping in `Lockspire.Protocol.Introspection`. [VERIFIED: .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md, test/integration/phase15_par_authorization_e2e_test.exs, test/integration/phase32_device_flow_token_exchange_e2e_test.exs, lib/lockspire/protocol/introspection.ex]

The main implementation risk is not protocol complexity; it is proof drift. The current device-flow DPoP end-to-end test stops at `token_type == "DPoP"` and replay collapse, the current browser auth-code end-to-end tests do not cover DPoP at all, and current introspection responses omit `cnf` entirely even though Phase 34 made `cnf` the durable binding carrier on both access and refresh tokens. [VERIFIED: test/integration/phase32_device_flow_token_exchange_e2e_test.exs, test/integration/phase3_oidc_token_lifecycle_e2e_test.exs, lib/lockspire/protocol/introspection.ex, .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md]

Milestone closure should follow the repo’s established pattern: executable proof first, support-surface wording second, then planning truth synchronized across the live milestone files and finally archived into `MILESTONES.md` and milestone archive files. The repo already uses release-contract tests to pin public wording and prior milestone records to capture shipped accomplishments and archive references. [VERIFIED: test/lockspire/release_readiness_contract_test.exs, docs/supported-surface.md, .planning/MILESTONES.md]

**Primary recommendation:** implement Phase 36 as three plans: a dedicated browser auth-code DPoP integration proof, a device/CLI DPoP proof plus introspection `cnf` exposure, and a final planning/docs/archive synchronization pass. [VERIFIED: .planning/ROADMAP.md, .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Browser-style DPoP auth-code proof | Frontend Server (SSR) | API / Backend | The repo’s real browser proof traverses `/authorize`, consent redirects, and `/token` through Phoenix router/controller seams before protocol code issues tokens. [VERIFIED: test/integration/phase15_par_authorization_e2e_test.exs, lib/lockspire/protocol/token_exchange.ex] |
| Device/CLI DPoP proof | API / Backend | Frontend Server (SSR) | The primary behavior is `/device/code` and `/token` issuance/redeem logic, while the host-owned `/verify` browser seam only approves the device authorization. [VERIFIED: test/integration/phase32_device_flow_token_exchange_e2e_test.exs, lib/lockspire/protocol/token_exchange.ex] |
| Introspection `cnf` truth | API / Backend | Database / Storage | `Lockspire.Protocol.Introspection` shapes active responses and reads durable token state from repository-backed token records. [VERIFIED: lib/lockspire/protocol/introspection.ex, lib/lockspire/domain/token.ex] |
| Support-surface wording and release contract | CDN / Static | API / Backend | Public truth lives in checked-in docs and release-contract tests that assert wording against the repo-supported endpoint surface. [VERIFIED: docs/supported-surface.md, test/lockspire/release_readiness_contract_test.exs] |
| Milestone closure and epic synchronization | Frontend Server (SSR) | — | This work is planning-document synchronization, not runtime protocol logic. [VERIFIED: .planning/ROADMAP.md, .planning/REQUIREMENTS.md, .planning/PROJECT.md, .planning/EPIC.md] |

## Execution Plan Split

### 36-01: Add auth-code DPoP end-to-end proof

**Recommendation:** add a new dedicated integration test file instead of extending Phase 3 or overloading Phase 15. Phase 3 seeds authorization codes directly and is best kept as the canonical OIDC surface sweep, while Phase 15 already demonstrates the stronger browser-host interaction path this phase needs. [VERIFIED: test/integration/phase3_oidc_token_lifecycle_e2e_test.exs, test/integration/phase15_par_authorization_e2e_test.exs]

**Recommended scenario:** register a DPoP-mode public client, complete the real `/authorize -> /lockspire/consent/:interaction_id -> client callback -> /token` flow, exchange the authorization code with a DPoP proof, then call `/userinfo` with `Authorization: DPoP` plus a second proof carrying `ath`. This proves both issuance and owned-endpoint consumption on the browser-style path without inventing a new harness. [VERIFIED: test/integration/phase15_par_authorization_e2e_test.exs, test/lockspire/web/userinfo_controller_test.exs, .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md]

**Likely file touch set:** `test/integration/phase36_auth_code_dpop_e2e_test.exs` (new, recommended), plus `mix.exs` only if a dedicated alias is added for faster reruns. [VERIFIED: test/integration/, mix.exs]

**Verification target:** `MIX_ENV=test mix test --include integration test/integration/phase36_auth_code_dpop_e2e_test.exs` should prove `token_type == "DPoP"`, DPoP proof usage on `/token`, and successful DPoP-authenticated `userinfo` access on the issued access token. [VERIFIED: test/integration/phase32_device_flow_token_exchange_e2e_test.exs, test/lockspire/protocol/protected_resource_dpop_test.exs]

### 36-02: Add device/CLI DPoP end-to-end proof and introspection alignment

**Recommendation:** keep the generated-host device verification seam and extend the proof beyond current token issuance to introspection truth. The existing Phase 32 DPoP device test already proves `/device/code -> /verify -> /token`; Phase 36 should reuse that shape and add introspection of the issued DPoP-bound access token from an authorized confidential caller. [VERIFIED: test/integration/phase32_device_flow_token_exchange_e2e_test.exs, test/lockspire/web/introspection_controller_test.exs]

**Implementation center:** add `cnf` to `active_response/1` in `lib/lockspire/protocol/introspection.ex`, sourcing it directly from `token.cnf`, and preserve all existing inactive collapse behavior and confidential-caller gating. The current classifier already restricts active responses to non-revoked, non-expired access and refresh tokens that belong to the authenticated confidential client. [VERIFIED: lib/lockspire/protocol/introspection.ex]

**Likely file touch set:** `lib/lockspire/protocol/introspection.ex`, `test/lockspire/protocol/introspection_test.exs`, `test/lockspire/web/introspection_controller_test.exs`, and either `test/integration/phase36_device_dpop_introspection_e2e_test.exs` (recommended) or `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` if the team prefers extending the existing device-flow proof file. [VERIFIED: lib/lockspire/protocol/introspection.ex, test/lockspire/protocol/introspection_test.exs, test/lockspire/web/introspection_controller_test.exs, test/integration/phase32_device_flow_token_exchange_e2e_test.exs]

**Verification target:** `MIX_ENV=test mix test --include integration test/integration/phase36_device_dpop_introspection_e2e_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs` should prove that an active DPoP-issued token returns `active: true` and `cnf: %{"jkt" => ...}` while expired, revoked, mismatched, or public-caller cases still collapse to `active: false`. [VERIFIED: lib/lockspire/protocol/introspection.ex, test/lockspire/protocol/introspection_test.exs, test/lockspire/web/introspection_controller_test.exs]

### 36-03: Close docs, traceability, and milestone verification

**Recommendation:** keep runtime-surface wording changes narrow and centralize them in `docs/supported-surface.md` plus release-contract assertions. Then synchronize the live milestone truth set before archiving the milestone. [VERIFIED: docs/supported-surface.md, test/lockspire/release_readiness_contract_test.exs, .planning/ROADMAP.md, .planning/REQUIREMENTS.md, .planning/STATE.md, .planning/PROJECT.md, .planning/EPIC.md]

**Likely file touch set:** `docs/supported-surface.md`, `test/lockspire/release_readiness_contract_test.exs`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/EPIC.md`, and `.planning/MILESTONES.md`; if the milestone is archived in the same pass, also create `milestones/v1.7-ROADMAP.md`, `milestones/v1.7-REQUIREMENTS.md`, and preferably `milestones/v1.7-MILESTONE-AUDIT.md` to match recent closure patterns. [VERIFIED: docs/supported-surface.md, test/lockspire/release_readiness_contract_test.exs, .planning/MILESTONES.md]

**Verification target:** `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` should stay green, `DPoP-12` through `DPoP-14` should flip to completed in `REQUIREMENTS.md`, Phase 36 should mark complete in `ROADMAP.md` and `STATE.md`, and `EPIC.md` should describe v1.7 as shipped context rather than only future scope. [VERIFIED: test/lockspire/release_readiness_contract_test.exs, .planning/REQUIREMENTS.md, .planning/ROADMAP.md, .planning/STATE.md, .planning/EPIC.md]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.18` in repo, local `1.19.5` available. [VERIFIED: mix.exs, `elixir --version`] | Test/runtime platform for protocol, Phoenix, and ExUnit execution. [VERIFIED: mix.exs] | Phase 36 is pure Elixir/Phoenix work with no new runtime family required. [VERIFIED: mix.exs, lib/lockspire/protocol/introspection.ex, test/integration/phase32_device_flow_token_exchange_e2e_test.exs] |
| Phoenix | `~> 1.8.5`. [VERIFIED: mix.exs] | Real HTTP router/controller seams for `/authorize`, `/token`, `/userinfo`, `/introspect`, and generated-host `/verify`. [VERIFIED: mix.exs, test/integration/phase15_par_authorization_e2e_test.exs, test/integration/phase32_device_flow_token_exchange_e2e_test.exs] | Existing end-to-end proof already runs through Phoenix `ConnTest`; Phase 36 should reuse that. [VERIFIED: test/integration/phase3_oidc_token_lifecycle_e2e_test.exs, test/integration/phase15_par_authorization_e2e_test.exs] |
| Ecto SQL | `~> 3.13.5`. [VERIFIED: mix.exs] | Durable token/client/device state and sandboxed integration tests. [VERIFIED: mix.exs, lib/lockspire/domain/token.ex, test/integration/phase32_device_flow_token_exchange_e2e_test.exs] | `cnf` truth and introspection classification both depend on repository-backed token records. [VERIFIED: lib/lockspire/protocol/introspection.ex, .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] |
| JOSE | `~> 1.11`. [VERIFIED: mix.exs] | DPoP proof signing/verification and JWK material in tests. [VERIFIED: mix.exs, test/integration/phase32_device_flow_token_exchange_e2e_test.exs] | Existing DPoP fixtures and validator tests already use JOSE/JWK helpers; Phase 36 should keep that path. [VERIFIED: test/lockspire/protocol/protected_resource_dpop_test.exs, test/integration/phase32_device_flow_token_exchange_e2e_test.exs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix ConnTest | bundled via Phoenix. [VERIFIED: test/integration/phase3_oidc_token_lifecycle_e2e_test.exs, test/integration/phase15_par_authorization_e2e_test.exs] | Drive repo-native end-to-end HTTP flows without a separate demo harness. [VERIFIED: test/integration/phase15_par_authorization_e2e_test.exs] | Use for both Phase 36 integration proofs. [VERIFIED: .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md] |
| ExUnit | bundled via Elixir. [VERIFIED: mix.exs, test files] | Unit, controller, and integration verification. [VERIFIED: test/lockspire/protocol/introspection_test.exs, test/lockspire/release_readiness_contract_test.exs] | Use for all new proof and contract coverage in this phase. [VERIFIED: current test suite layout] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dedicated Phase 36 browser/device integration tests | Extend Phase 3 and Phase 32 only | Reusing existing files is possible, but new Phase 36-specific files keep DPoP proof intent explicit and avoid mixing milestone-close proof with older canonical flow sweeps. [VERIFIED: test/integration/phase3_oidc_token_lifecycle_e2e_test.exs, test/integration/phase32_device_flow_token_exchange_e2e_test.exs, .planning/ROADMAP.md] |
| Protocol-only DPoP proof | More unit/controller tests only | The phase requirement is specifically end-to-end proof through real HTTP seams, so unit coverage alone would not satisfy DPoP-12. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md] |

**Installation:** no new dependency installation is recommended for Phase 36. [VERIFIED: mix.exs, repo test patterns]

## Architecture Patterns

### System Architecture Diagram

```text
Browser Client
  -> GET /authorize
  -> consent redirect + approval
  -> client callback with code
  -> POST /token + DPoP proof
  -> GET /userinfo + DPoP proof(ath)
  -> assertions on token_type/userinfo

CLI / Device Client
  -> POST /device/code
  -> Host /verify approval
  -> POST /token + DPoP proof
  -> POST /introspect from confidential caller
  -> assertions on active + cnf

Planning / Docs Close
  -> docs/supported-surface.md
  -> release_readiness_contract_test.exs
  -> ROADMAP/REQUIREMENTS/STATE/PROJECT/EPIC
  -> MILESTONES archive entry
```

### Recommended Project Structure

```text
lib/lockspire/protocol/          # Runtime truth shaping; Phase 36 should touch introspection here
test/integration/                # Repo-native end-to-end proof; add browser and device DPoP scenarios here
test/lockspire/protocol/         # Protocol contract tests for cnf/introspection behavior
test/lockspire/web/              # HTTP contract tests for introspection and wording surfaces
docs/                            # Supported-surface truth for the public preview contract
.planning/                       # Milestone traceability, state, project, and epic synchronization
```

### Pattern 1: Dedicated Phase-End Integration Proof
**What:** Add one focused integration test per cross-flow proof target instead of hiding milestone proof inside unrelated older sweeps. [VERIFIED: test/integration/milestone_v1_3_verification_test.exs, .planning/ROADMAP.md]
**When to use:** When the requirement is “repo-native executable proof” for a completed slice rather than a new runtime abstraction. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md]
**Example:**
```elixir
# Source: test/integration/phase15_par_authorization_e2e_test.exs
conn = build_conn(:get, "/authorize", params)
conn = Lockspire.Web.Router.call(conn, Lockspire.Web.Router.init([]))
```

### Pattern 2: Protocol-Owned Active Introspection Shaping
**What:** Keep the controller thin and add active-response fields in `Lockspire.Protocol.Introspection`, because that module already owns token lookup, caller authorization, and inactive collapse. [VERIFIED: lib/lockspire/protocol/introspection.ex, test/lockspire/web/introspection_controller_test.exs]
**When to use:** Any time introspection response truth changes without changing the confidential-caller or inactive-token policy. [VERIFIED: .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md]
**Example:**
```elixir
# Source: lib/lockspire/protocol/introspection.ex
%{active: true, client_id: token.client_id}
|> maybe_put(:cnf, token.cnf)
```

### Anti-Patterns to Avoid
- **New acceptance harness:** The phase context explicitly rejects a demo app or second acceptance layer; stay inside the existing ExUnit integration suite. [VERIFIED: .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md]
- **Policy-derived introspection `cnf`:** `cnf` truth already lives on persisted token records, so rebuilding it from client/server DPoP policy would be wrong for refreshed or rotated families. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md, lib/lockspire/domain/token.ex, lib/lockspire/protocol/introspection.ex]
- **Docs broader than proof:** Current support docs and release-contract tests intentionally claim DPoP only on `/token` and Lockspire-owned `userinfo`; Phase 36 should add introspection truth without implying generic host protected-resource support. [VERIFIED: docs/supported-surface.md, test/lockspire/release_readiness_contract_test.exs, .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser DPoP proof | A separate demo Phoenix app or custom acceptance runner | The existing `ConnTest` integration pattern from Phase 15. [VERIFIED: test/integration/phase15_par_authorization_e2e_test.exs] | The repo already proves browser interaction flows through real router/controller seams. [VERIFIED: test/integration/phase15_par_authorization_e2e_test.exs] |
| Device/CLI DPoP proof | A synthetic protocol-only redeem test | The generated-host `/verify` + `/token` integration pattern from Phase 32. [VERIFIED: test/integration/phase32_device_flow_token_exchange_e2e_test.exs] | The host-owned verification seam is part of the shipped device contract and should remain visible in proof. [VERIFIED: docs/supported-surface.md, .planning/ROADMAP.md] |
| Introspection DPoP truth | Controller-local JSON shaping | `Lockspire.Protocol.Introspection.active_response/1`. [VERIFIED: lib/lockspire/protocol/introspection.ex] | Protocol-owned response shaping already centralizes active/inactive semantics. [VERIFIED: lib/lockspire/protocol/introspection.ex] |
| Public support wording | New ad hoc docs file | `docs/supported-surface.md` plus `ReleaseReadinessContractTest`. [VERIFIED: docs/supported-surface.md, test/lockspire/release_readiness_contract_test.exs] | That pair is already the canonical public contract and drift backstop. [VERIFIED: docs/supported-surface.md, test/lockspire/release_readiness_contract_test.exs] |

**Key insight:** Phase 36 is mostly composition work across seams the repo already trusts; introducing new harnesses or truth sources would add risk without adding capability. [VERIFIED: required code/test corpus]

## Common Pitfalls

### Pitfall 1: Using the wrong auth-code precedent
**What goes wrong:** An implementation extends Phase 3 only, proves token issuance, and misses the real host-owned authorize/consent/browser path required by the phase. [VERIFIED: test/integration/phase3_oidc_token_lifecycle_e2e_test.exs, .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md]
**Why it happens:** Phase 3 is the older canonical lifecycle sweep, but it seeds authorization codes directly in storage. [VERIFIED: test/integration/phase3_oidc_token_lifecycle_e2e_test.exs]
**How to avoid:** Base the browser proof on the Phase 15 redirect/consent pattern, not on direct authorization-code seeding alone. [VERIFIED: test/integration/phase15_par_authorization_e2e_test.exs]
**Warning signs:** No assertions on consent redirects, callback code delivery, or real `/authorize` traffic in the new DPoP browser test. [VERIFIED: test/integration/phase15_par_authorization_e2e_test.exs]

### Pitfall 2: Exposing inferred rather than stored DPoP binding
**What goes wrong:** Introspection emits DPoP truth from current client policy or request headers instead of stored token `cnf`. [VERIFIED: .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md, lib/lockspire/domain/token.ex]
**Why it happens:** It is tempting to reuse client DPoP policy because the active introspection response currently omits `cnf`. [VERIFIED: lib/lockspire/protocol/introspection.ex]
**How to avoid:** Add `cnf` only from `token.cnf` in `active_response/1` and prove it with seeded token records and device-issued integration tokens. [VERIFIED: lib/lockspire/protocol/introspection.ex, test/lockspire/protocol/introspection_test.exs]
**Warning signs:** New code reaches for client/server policy inside introspection, or controller tests pass without seeded `cnf` records. [VERIFIED: lib/lockspire/protocol/introspection.ex, test/lockspire/web/introspection_controller_test.exs]

### Pitfall 3: Closing the milestone before the public contract is truthful
**What goes wrong:** Planning docs are marked complete before supported-surface wording and release-contract assertions reflect the final DPoP claim. [VERIFIED: .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md, test/lockspire/release_readiness_contract_test.exs]
**Why it happens:** The planning files and docs live in different parts of the repo, so it is easy to update one side first. [VERIFIED: docs/supported-surface.md, .planning/ROADMAP.md]
**How to avoid:** Treat `docs/supported-surface.md`, release-contract tests, and the planning truth set as one closing batch. [VERIFIED: .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md]
**Warning signs:** `DPoP-14` is marked complete while release-contract strings still describe only token + userinfo DPoP without introspection visibility. [VERIFIED: test/lockspire/release_readiness_contract_test.exs, docs/supported-surface.md, .planning/REQUIREMENTS.md]

## Code Examples

Verified patterns from the repo:

### Browser-host authorize/consent/token proof
```elixir
# Source: test/integration/phase15_par_authorization_e2e_test.exs
authorize_conn = build_conn(:get, "/authorize", %{"client_id" => client.client_id})
consent_complete_conn = build_conn(:post, "/interactions/#{interaction_id}/complete", %{"decision" => "approve"})
token_conn = build_conn(:post, "/token", token_params)
```

### Device verification + token redemption proof
```elixir
# Source: test/integration/phase32_device_flow_token_exchange_e2e_test.exs
device_code_conn = build_conn() |> post("/lockspire/device/code", %{"client_id" => client.client_id})
approve_conn = submit_from(review_conn, "/verify/#{handle}/approve", %{})
first_token_conn = build_conn() |> put_req_header("dpop", proof) |> post("/lockspire/token", params)
```

### Introspection active-response seam
```elixir
# Source: lib/lockspire/protocol/introspection.ex
%{active: true, client_id: token.client_id, token_type: Atom.to_string(token.token_type)}
|> maybe_put(:jti, token.jti)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Grant-level or endpoint-level DPoP proof only | Shared DPoP issuance context across auth-code and device flows, plus durable `cnf` persistence. [VERIFIED: lib/lockspire/protocol/token_endpoint_dpop.ex, lib/lockspire/protocol/token_exchange.ex, .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] | Phase 34. [VERIFIED: .planning/ROADMAP.md] | Phase 36 can focus on proof and visibility instead of new binding storage. [VERIFIED: current codebase] |
| Userinfo-only DPoP runtime consumption | Userinfo proof plus introspection visibility for stored `cnf` on active tokens. [VERIFIED: test/lockspire/protocol/protected_resource_dpop_test.exs, .planning/REQUIREMENTS.md] | Userinfo in Phase 35, introspection visibility scheduled for Phase 36. [VERIFIED: .planning/ROADMAP.md, .planning/REQUIREMENTS.md] | The public support contract becomes truthful about inspection without widening generic host-resource support. [VERIFIED: docs/supported-surface.md, .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md] |

**Deprecated/outdated:**
- Relying on Phase 32 as the only DPoP end-to-end proof is outdated for milestone closure because it proves device issuance and replay behavior but not browser auth-code DPoP or introspection `cnf` truth. [VERIFIED: test/integration/phase32_device_flow_token_exchange_e2e_test.exs, .planning/REQUIREMENTS.md]

## Assumptions Log

All claims in this research were verified from the repo or local runtime during this session. [VERIFIED: required reading corpus, `mix test`, local tool probes]

## Open Questions (RESOLVED)

1. **Should the team add a dedicated `mix test.phase36` alias?**
   - Resolution: no dedicated alias is required for planning or initial execution. The phase should use direct file-scoped commands unless repeated reruns during execution prove that ergonomics are materially worse than the existing pattern. [VERIFIED: mix.exs, current recommended touch sets]
   - Why: the planned touch set stays small enough that direct commands remain readable and already fit the repo's current verification style. [VERIFIED: mix.exs, 36-01-PLAN.md, 36-02-PLAN.md, 36-03-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All protocol and test execution | ✓ | `1.19.5` locally, repo requires `~> 1.18`. [VERIFIED: `elixir --version`, mix.exs] | — |
| Mix | All test commands | ✓ | `1.19.5`. [VERIFIED: `mix --version`] | — |
| PostgreSQL client/server | Sandbox-backed repo tests and token/device persistence | ✓ | client `14.17`; local server accepting on `/tmp:5432`. [VERIFIED: `psql --version`, `pg_isready`] | — |
| Node.js | Release/docs tooling only if docs or workflows are touched beyond Elixir tests | ✓ | `v22.14.0`. [VERIFIED: `node --version`] | Not required for the Phase 36 Elixir test commands themselves. [VERIFIED: mix.exs, current test commands] |

**Missing dependencies with no fallback:** None. [VERIFIED: local tool probes]

**Missing dependencies with fallback:** None. [VERIFIED: local tool probes]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix `ConnTest` and Ecto sandbox. [VERIFIED: test/integration/phase15_par_authorization_e2e_test.exs, test/integration/phase32_device_flow_token_exchange_e2e_test.exs] |
| Config file | none; the repo uses Mix aliases plus per-file commands. [VERIFIED: mix.exs] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/release_readiness_contract_test.exs` [VERIFIED: current test layout] |
| Full suite command | `MIX_ENV=test mix test --include integration test/integration/phase36_auth_code_dpop_e2e_test.exs test/integration/phase36_device_dpop_introspection_e2e_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/release_readiness_contract_test.exs` [VERIFIED: recommended Phase 36 touch set] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DPoP-12 | Browser auth-code DPoP flow completes through real authorize/consent/token seams and succeeds on owned DPoP consumption. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `MIX_ENV=test mix test --include integration test/integration/phase36_auth_code_dpop_e2e_test.exs` | ❌ Wave 0 |
| DPoP-12 | Device/CLI DPoP flow completes through `/device/code -> /verify -> /token` and exposes issued-token truth to later verification. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `MIX_ENV=test mix test --include integration test/integration/phase36_device_dpop_introspection_e2e_test.exs` | ❌ Wave 0 |
| DPoP-13 | Introspection returns `cnf` for active bound tokens and still collapses inactive or unauthorized cases. [VERIFIED: .planning/REQUIREMENTS.md] | unit + controller | `MIX_ENV=test mix test test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs` | ✅ |
| DPoP-14 | Public support wording and release contract stay truthful after milestone close. [VERIFIED: .planning/REQUIREMENTS.md] | contract | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` | ✅ |

### Sampling Rate
- **Per task commit:** run the requirement-local command for the files touched in that plan. [VERIFIED: current test layout]
- **Per wave merge:** run the full Phase 36 command set above. [VERIFIED: recommended validation map]
- **Phase gate:** all Phase 36 tests plus green release-contract assertions before marking DPoP-12 through DPoP-14 complete. [VERIFIED: .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md]

### Wave 0 Gaps
- [ ] `test/integration/phase36_auth_code_dpop_e2e_test.exs` — covers browser-side half of DPoP-12. [VERIFIED: test/integration directory]
- [ ] `test/integration/phase36_device_dpop_introspection_e2e_test.exs` — covers device/introspection half of DPoP-12 plus an end-to-end anchor for DPoP-13. [VERIFIED: test/integration directory]
- [ ] `test/lockspire/protocol/introspection_test.exs` — add active-`cnf` assertions for DPoP-bound access and refresh tokens. [VERIFIED: current file content]
- [ ] `test/lockspire/web/introspection_controller_test.exs` — add HTTP-level `cnf` response assertions for authorized confidential callers. [VERIFIED: current file content]
- [ ] `test/lockspire/release_readiness_contract_test.exs` — update supported-surface wording assertions if introspection visibility is added to the public contract. [VERIFIED: current file content]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Introspection caller authentication is already handled by confidential client auth and is not expanded in this phase. [VERIFIED: lib/lockspire/protocol/introspection.ex] |
| V3 Session Management | no | Phase 36 does not add browser-session ownership; host login/session remains outside scope. [VERIFIED: .planning/PROJECT.md, docs/supported-surface.md] |
| V4 Access Control | yes | Preserve confidential-caller gate and client/token ownership checks in introspection. [VERIFIED: lib/lockspire/protocol/introspection.ex] |
| V5 Input Validation | yes | Reuse existing DPoP proof validation and controller/protocol request normalization. [VERIFIED: lib/lockspire/protocol/token_endpoint_dpop.ex, test/lockspire/protocol/protected_resource_dpop_test.exs] |
| V6 Cryptography | yes | Keep JOSE/DPoP proof validation and durable `cnf.jkt` binding; do not hand-roll token-binding logic. [VERIFIED: lib/lockspire/protocol/token_endpoint_dpop.ex, lib/lockspire/domain/token.ex] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| DPoP proof replay | Tampering | Continue using durable replay recording for proof `jti` use on token and protected-resource paths. [VERIFIED: lib/lockspire/protocol/token_endpoint_dpop.ex, test/lockspire/protocol/protected_resource_dpop_test.exs] |
| Token-binding over-disclosure in introspection | Information Disclosure | Emit `cnf` only for active tokens returned to authorized confidential callers, while all inactive or unauthorized paths still collapse to `active: false`. [VERIFIED: lib/lockspire/protocol/introspection.ex, .planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md] |
| Support-contract drift | Repudiation | Keep `docs/supported-surface.md` and `ReleaseReadinessContractTest` synchronized. [VERIFIED: docs/supported-surface.md, test/lockspire/release_readiness_contract_test.exs] |
| Browser/device proof bypass through fake harnesses | Spoofing | Use the existing router-driven integration suite so proof exercises the mounted Phoenix surface and generated-host `/verify` seam. [VERIFIED: test/integration/phase15_par_authorization_e2e_test.exs, test/integration/phase32_device_flow_token_exchange_e2e_test.exs] |

## Milestone-Closure Artifact Guidance

1. Update `docs/supported-surface.md` first so the public contract explicitly matches the final Phase 36 truth and still states that generic host protected-resource middleware remains out of scope. [VERIFIED: docs/supported-surface.md, .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md]
2. Keep `test/lockspire/release_readiness_contract_test.exs` in lockstep with the supported-surface wording; do not update planning files if the contract test still describes the pre-Phase-36 claim set. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
3. Mark `DPoP-12`, `DPoP-13`, and `DPoP-14` completed in `.planning/REQUIREMENTS.md` only after the new integration proof and introspection tests are green. [VERIFIED: .planning/REQUIREMENTS.md, local `mix test` baseline]
4. Mark Phase 36 complete in `.planning/ROADMAP.md` and update the active-milestone summary so the file no longer shows v1.7 as an open execution milestone. [VERIFIED: .planning/ROADMAP.md]
5. Update `.planning/STATE.md` from “Ready to plan” into milestone-closed state, including final completed plan counts and the next-action pointer away from Phase 36. [VERIFIED: .planning/STATE.md]
6. Update `.planning/PROJECT.md` so the “Current State,” “Current Milestone,” and validated milestones text reflects shipped v1.7 outcomes rather than planned DPoP scope. [VERIFIED: .planning/PROJECT.md]
7. Update `.planning/EPIC.md` so v1.7 is recorded as delivered context and the next-milestone selection rule still points to adoption-hardening vs protocol-depth from that shipped base. [VERIFIED: .planning/EPIC.md]
8. Add a new top entry to `.planning/MILESTONES.md` summarizing v1.7 accomplishments and archive references, matching the structure used for v1.6 and v1.4. [VERIFIED: .planning/MILESTONES.md]
9. If the repo archives the milestone in the same change, create `milestones/v1.7-ROADMAP.md`, `milestones/v1.7-REQUIREMENTS.md`, and preferably `milestones/v1.7-MILESTONE-AUDIT.md` because recent milestone closes use an audit artifact when traceability and verification posture matter. [VERIFIED: .planning/MILESTONES.md, .planning/ROADMAP.md]

## Sources

### Primary (HIGH confidence)
- `.planning/ROADMAP.md` - Phase 36 goal, plan split, and success criteria. [VERIFIED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - DPoP-12 through DPoP-14 traceability targets. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/EPIC.md`, `.planning/MILESTONES.md` - live milestone truth and closure pattern. [VERIFIED: those files]
- `.planning/phases/36-end-to-end-proof-and-milestone-closure/36-CONTEXT.md` - locked decisions and out-of-scope boundaries. [VERIFIED: context file]
- `.planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md` and `.planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md` - carry-forward `cnf` and DPoP surface constraints. [VERIFIED: those files]
- `lib/lockspire/protocol/introspection.ex`, `lib/lockspire/protocol/token_exchange.ex`, `lib/lockspire/protocol/token_endpoint_dpop.ex`, `lib/lockspire/domain/token.ex` - runtime seams to extend or preserve. [VERIFIED: source files]
- `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs`, `test/integration/phase15_par_authorization_e2e_test.exs`, `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` - current end-to-end proof patterns. [VERIFIED: test files]
- `test/lockspire/protocol/introspection_test.exs`, `test/lockspire/web/introspection_controller_test.exs`, `test/lockspire/protocol/protected_resource_dpop_test.exs`, `test/lockspire/release_readiness_contract_test.exs` - current contract and DPoP enforcement coverage. [VERIFIED: test files]
- Local command verification: `MIX_ENV=test mix test --include integration test/integration/phase32_device_flow_token_exchange_e2e_test.exs`, `MIX_ENV=test mix test test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs`, and `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` all passed on 2026-04-28. [VERIFIED: local test runs]

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended tools and versions come from `mix.exs` plus local runtime probes. [VERIFIED: mix.exs, local `elixir --version`, `mix --version`, `psql --version`, `pg_isready`, `node --version`]
- Architecture: HIGH - recommendations map directly onto existing repo-native integration and protocol seams. [VERIFIED: required source/test corpus]
- Pitfalls: HIGH - each pitfall is tied to a concrete mismatch between current code/tests and Phase 36 requirements. [VERIFIED: current test files, Phase 36 context, roadmap/requirements]

**Research date:** 2026-04-28
**Valid until:** 2026-05-28
