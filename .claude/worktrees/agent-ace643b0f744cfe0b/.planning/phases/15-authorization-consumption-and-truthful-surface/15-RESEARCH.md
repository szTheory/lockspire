# Phase 15: Authorization Consumption and Truthful Surface - Research

**Researched:** 2026-04-24 [VERIFIED: system date]
**Domain:** PAR-backed `/authorize` consumption, discovery metadata truth, and support-surface truth for Lockspire's embedded OAuth/OIDC flow. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
**Confidence:** HIGH [VERIFIED: repo code inspection] [CITED: https://www.rfc-editor.org/rfc/rfc9126] [CITED: https://www.rfc-editor.org/rfc/rfc8414.html]

## User Constraints

- No separate `CONTEXT.md` exists for Phase 15, so the active planning constraints come from the user request, `AGENTS.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md`. [VERIFIED: gsd-sdk init.phase-op 15 output] [VERIFIED: AGENTS.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
- Keep Phase 15 narrowly scoped to safe `/authorize` consumption of PAR-issued `request_uri`, expiry, client-binding, replay-resistant single use, and truthful discovery/docs surface. [VERIFIED: user prompt] [VERIFIED: .planning/ROADMAP.md]
- Keep v1.2 out of JAR-by-value, generic external `request_uri`, dynamic client registration, and device flow. [VERIFIED: user prompt] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: AGENTS.md]
- Preserve the embedded-library shape, strong internal boundaries, host-owned login/account seam, and secure defaults such as exact redirect matching and PKCE S256. [VERIFIED: AGENTS.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAR-02 | OAuth clients can complete the existing authorization code + PKCE flow by presenting a PAR-issued `request_uri`, and Lockspire enforces expiry, client binding, and replay-resistant single use for that reference. [VERIFIED: .planning/REQUIREMENTS.md] | Resolve PAR references inside `Lockspire.Protocol.AuthorizationRequest`, consume them transactionally through the pushed-request store, reject expired/replayed/wrong-client references before host handoff, and feed the existing `Validated` contract into `AuthorizationFlow`. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex] [VERIFIED: lib/lockspire/storage/pushed_authorization_request_store.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9126] |
| PAR-03 | Integrators can discover PAR support through truthful metadata and docs that advertise only the implemented PAR slice and do not imply request-object-by-value, dynamic registration, or device-flow support. [VERIFIED: .planning/REQUIREMENTS.md] | Publish `pushed_authorization_request_endpoint` in discovery, keep `require_pushed_authorization_requests` absent, and update the preview/support docs plus contract tests together so the repo claims only PAR-backed request references. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/web/discovery_controller_test.exs] [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: SECURITY.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [CITED: https://www.rfc-editor.org/rfc/rfc9126] [CITED: https://www.rfc-editor.org/rfc/rfc8414.html] |
</phase_requirements>

## Summary

Phase 14 already delivered the hard prerequisite for Phase 15: Lockspire now issues opaque PAR URNs, stores only their hashes at rest, persists the validated authorization payload in a dedicated table, and exposes a shared `AuthorizationRequest.validate_pushed/2` seam instead of forking validation rules. [VERIFIED: lib/lockspire/domain/pushed_authorization_request.ex] [VERIFIED: lib/lockspire/protocol/pushed_authorization_request.ex] [VERIFIED: lib/lockspire/storage/ecto/pushed_authorization_request_record.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [VERIFIED: .planning/phases/14-pushed-request-intake/14-RESEARCH.md]

The safest Phase 15 implementation is to keep `/authorize` thin and teach `Lockspire.Protocol.AuthorizationRequest` to resolve a PAR-issued `request_uri` into the same `Validated` struct the rest of the authorization pipeline already consumes. That resolution should be transactional and one-time-use, should require the browser request `client_id` to match the stored PAR client binding, and should reject any extra raw authorization parameters that would conflict with the pushed payload. [VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9126]

The truth-surface work is equally important because the repo currently proves the opposite claim: discovery tests assert the PAR metadata key is absent, `README.md` says PAR is unsupported, `docs/supported-surface.md` lists PAR as out of scope, `SECURITY.md` excludes PAR from the supported surface, and `test/lockspire/release_readiness_contract_test.exs` locks those statements in place. Phase 15 should update those surfaces in the same change set that makes the feature true. [VERIFIED: test/lockspire/web/discovery_controller_test.exs] [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: SECURITY.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

**Primary recommendation:** Implement PAR consumption as a transactional store-backed resolution path inside `AuthorizationRequest`, keep `AuthorizationFlow` unchanged, publish only `pushed_authorization_request_endpoint` in discovery, and update README/support/security contract tests in lockstep with the feature. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [CITED: https://www.rfc-editor.org/rfc/rfc9126]

## Project Constraints (from AGENTS.md)

- Lockspire remains a separate companion library, not a Sigra module. [VERIFIED: AGENTS.md]
- Keep the embedded-library shape; do not turn this into a required standalone auth service. [VERIFIED: AGENTS.md]
- Keep strong boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Keep the host seam narrow: accounts, login UX, branding, and product policy stay in the host app. [VERIFIED: AGENTS.md]
- Preserve secure defaults including PKCE S256, exact redirect matching, single-use short-lived authorization artifacts, hashed secrets at rest, no implicit flow, and no `alg=none`. [VERIFIED: AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Resolve PAR-issued `request_uri` into validated authorization state | API / Backend | Database / Storage | The browser-facing `/authorize` endpoint should delegate to protocol logic that loads and validates the durable PAR record before any host interaction begins. [VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Enforce expiry, client binding, and single use | Database / Storage | API / Backend | Expiry and one-time use depend on durable state and row-level atomicity, not controller-local flags or process memory. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [VERIFIED: lib/lockspire/storage/pushed_authorization_request_store.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9126] |
| Continue the existing consent/login/code flow once the request is validated | API / Backend | Frontend Server (Phoenix controller adapter) | `AuthorizationFlow` already consumes a `Validated` authorization request and should remain the owner of interaction/consent/code orchestration. [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex] |
| Publish truthful PAR metadata | API / Backend | Frontend Server (JSON controller adapter) | Discovery metadata is assembled in `Lockspire.Protocol.Discovery` and delivered unchanged by `DiscoveryController`/`DiscoveryJSON`. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: lib/lockspire/web/controllers/discovery_controller.ex] [VERIFIED: lib/lockspire/web/controllers/discovery_json.ex] |
| Publish truthful support posture to humans | Docs / Support Surface | Test / Contract Layer | README, supported-surface docs, security docs, and release-readiness contract tests are the repo's current public truth source. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: SECURITY.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `1.8.5` [VERIFIED: mix.lock] | Mounted HTTP delivery for `/authorize`, `/par`, and discovery. [VERIFIED: lib/lockspire/web/router.ex] | The existing web boundary is already Phoenix controllers and router-mounted JSON/HTML endpoints. [VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex] [VERIFIED: lib/lockspire/web/controllers/discovery_controller.ex] |
| Ecto SQL | `3.13.5` [VERIFIED: mix.lock] | Durable, transactional persistence for interactions, tokens, and PAR records. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] | Phase 15 needs row-level atomicity for consume-once semantics, which fits the current repository pattern. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| PostgreSQL | `14+` target, local `14.17` available [VERIFIED: AGENTS.md] [VERIFIED: local psql --version] | Backing store for Ecto Sandbox tests and durable PAR state. [VERIFIED: config/test.exs] | PAR replay resistance belongs in durable storage, not ETS or process state. [VERIFIED: .planning/PROJECT.md] [VERIFIED: AGENTS.md] |
| Lockspire in-repo protocol modules | in-repo [VERIFIED: lib/lockspire/protocol/authorization_request.ex] | Shared authorization validation and flow orchestration. [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] | Reusing the existing `Validated` contract avoids a parallel PAR-specific authorization flow. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix LiveView | `1.1.28` [VERIFIED: mix.lock] | Existing consent/admin surfaces remain downstream of authorization validation. [VERIFIED: lib/lockspire/web/router.ex] | No new LiveView work is needed for PAR consumption; keep it unchanged unless a consent redirect regression appears. [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] |
| ExUnit + Ecto SQL Sandbox | in-repo test stack [VERIFIED: test/test_helper.exs] [VERIFIED: config/test.exs] | Protocol, controller, and integration proof for PAR consumption and truth-surface drift. [VERIFIED: test/lockspire/protocol/authorization_request_test.exs] [VERIFIED: test/lockspire/web/authorize_controller_test.exs] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] | Use targeted file runs for Phase 15 and `mix test.fast` as the phase gate. [VERIFIED: mix.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Transactional consume in the repository | Stateless ETS cache or controller-session tracking | This would break the repo's durable-state posture and weaken replay guarantees across nodes or restarts. [VERIFIED: .planning/PROJECT.md] [VERIFIED: AGENTS.md] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Reusing `AuthorizationRequest.Validated` | A separate PAR-only validation/result struct | This would duplicate downstream flow wiring for no security gain and raise drift risk between `/authorize` paths. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] |
| Publishing only `pushed_authorization_request_endpoint` | Publishing extra request-object or DCR metadata | Extra metadata would imply support for features this milestone explicitly excludes. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: test/lockspire/web/discovery_controller_test.exs] [CITED: https://www.rfc-editor.org/rfc/rfc9126] |

**Installation:** No new Hex dependencies are needed for Phase 15; reuse the current project stack. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

**Version verification:** Phoenix `1.8.5`, Phoenix LiveView `1.1.28`, Ecto SQL `3.13.5`, Oban `2.21.1`, and `opentelemetry_api` `1.5.0` are the versions currently locked in this repo. [VERIFIED: mix.lock]

## Architecture Patterns

### System Architecture Diagram

```text
OAuth client
  |
  | 1. POST /par with validated authz params
  v
PAR protocol + repository
  |
  | 2. store durable PAR row (hash only at rest, short TTL)
  v
Postgres
  |
  | 3. GET /authorize?client_id=...&request_uri=...
  v
AuthorizationRequest resolver
  |
  |-- lock + load PAR row
  |-- reject expired / replayed / wrong-client / conflicting raw params
  |-- consume row once
  |-- rebuild Validated struct
  v
AuthorizationFlow
  |
  |-- existing login handoff / consent / code issuance
  v
Host app + consent surface + redirect back to client

Discovery + docs truth
  |
  |-- publish pushed_authorization_request_endpoint
  |-- update README / supported-surface / SECURITY / contract tests
  v
Integrator-facing truthful surface
```

The primary data flow stays inside existing Lockspire boundaries: Phoenix controllers remain thin adapters, protocol modules own validation and orchestration, and the repository owns durable state transitions. [VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex] [VERIFIED: lib/lockspire/web/controllers/discovery_controller.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

### Recommended Project Structure

```text
lib/lockspire/protocol/              # PAR resolution and discovery assembly
lib/lockspire/storage/               # store contract changes for one-time consume
lib/lockspire/storage/ecto/          # transactional repository and optional PAR schema update
lib/lockspire/web/controllers/       # thin authorize/discovery adapters only
test/lockspire/protocol/             # request-resolution and replay tests
test/lockspire/web/                  # authorize/discovery contract tests
test/integration/                    # PAR-backed auth-code + PKCE end-to-end proof
docs/                                # support posture truth
```

### Likely File Targets

- `lib/lockspire/protocol/authorization_request.ex` should become the single entrypoint for both direct browser params and PAR-backed `request_uri` resolution into `%Validated{}`. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex]
- `lib/lockspire/storage/pushed_authorization_request_store.ex` should gain a narrow consume-once callback instead of exposing generic mutable PAR state. [VERIFIED: lib/lockspire/storage/pushed_authorization_request_store.ex]
- `lib/lockspire/storage/ecto/repository.ex` should implement transactional PAR consumption with `FOR UPDATE` locking and replay-safe state transition semantics. [VERIFIED: lib/lockspire/storage/ecto/repository.ex]
- `lib/lockspire/storage/ecto/pushed_authorization_request_record.ex` is the likely schema-mapper touchpoint if Phase 15 chooses to preserve consumed rows with a `consumed_at` timestamp instead of deleting them. [VERIFIED: lib/lockspire/storage/ecto/pushed_authorization_request_record.ex]
- `lib/lockspire/web/controllers/authorize_controller.ex` should only change enough to pass repository opts into authorization validation and keep the controller thin. [VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex]
- `lib/lockspire/protocol/discovery.ex` should add `pushed_authorization_request_endpoint` and continue omitting unsupported adjacent metadata. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/web/discovery_controller_test.exs]
- `README.md`, `docs/supported-surface.md`, `SECURITY.md`, and `test/lockspire/release_readiness_contract_test.exs` should be updated together because they currently encode "PAR unsupported" as repo truth. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: SECURITY.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
- `test/lockspire/protocol/authorization_request_test.exs`, `test/lockspire/web/authorize_controller_test.exs`, `test/lockspire/web/discovery_controller_test.exs`, and `test/integration/phase6_onboarding_e2e_test.exs` are the most natural existing files to extend for Phase 15 proof. [VERIFIED: test/lockspire/protocol/authorization_request_test.exs] [VERIFIED: test/lockspire/web/authorize_controller_test.exs] [VERIFIED: test/lockspire/web/discovery_controller_test.exs] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]

### Pattern 1: Resolve PAR Inside `AuthorizationRequest`

**What:** Detect `request_uri` in the browser request, load the pushed request through the store, rebuild the canonical authorization params from stored state, and return the same `%Validated{}` shape used by the rest of the authorization flow. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9126]

**When to use:** Use this for `/authorize` requests that carry a PAR-issued `request_uri`; keep the current direct-parameter validation path for non-PAR authorization requests because Phase 15 does not require PAR-only policy. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9126]

**Example:** [VERIFIED: repo architecture] [CITED: https://www.rfc-editor.org/rfc/rfc9126]
```elixir
# Source pattern: existing AuthorizationRequest.validate/1 + Phase 14 PAR store
def validate(params, opts \\ []) when is_map(params) do
  case normalize_par_request(params, opts) do
    {:ok, normalized_params} ->
      validate_plain_authorization_params(normalized_params)

    {:browser_error, %Error{} = error} ->
      {:browser_error, error}

    {:redirect_error, %Error{} = error} ->
      {:redirect_error, error}
  end
end
```

### Pattern 2: Transactional One-Time PAR Consumption

**What:** Add a repository-backed consume operation that locks the PAR row, verifies it is active, verifies the browser `client_id` matches the stored client binding, and marks the row consumed exactly once before returning its payload. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [VERIFIED: lib/lockspire/storage/pushed_authorization_request_store.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9126]

**When to use:** Use this whenever `/authorize` resolves a `request_uri`; replay resistance depends on atomic consume semantics rather than on read-then-write application logic. [CITED: https://www.rfc-editor.org/rfc/rfc9126] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

**Example:** [VERIFIED: repo transaction patterns] [CITED: https://www.rfc-editor.org/rfc/rfc9126]
```elixir
# Source pattern: Repository.transition_interaction/3 and token redemption helpers
@callback consume_pushed_authorization_request(String.t(), String.t(), DateTime.t()) ::
            {:ok, PushedAuthorizationRequest.t()}
            | {:error, :not_found | :expired | :client_mismatch | :already_consumed | term()}

def consume_pushed_authorization_request(request_uri_hash, client_id, now) do
  transact(fn ->
    request_uri_hash
    |> locked_pushed_request_query()
    |> repo().one()
    |> consume_pushed_request_record(client_id, now)
  end)
end
```

### Pattern 3: Strict PAR Query Merge Policy

**What:** When `request_uri` is present, accept only the small query shape needed to identify the request, then derive the rest of the authorization parameters from the stored pushed request instead of merging caller-supplied values opportunistically. [VERIFIED: .planning/research/SUMMARY.md] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9126]

**When to use:** Apply this to all PAR-backed `/authorize` requests so the browser query cannot override stored `redirect_uri`, `scope`, `prompt`, `nonce`, or PKCE data. [VERIFIED: lib/lockspire/domain/pushed_authorization_request.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9126]

**Example:** [VERIFIED: repo behavior goals]
```elixir
# Source pattern: repo research recommendation for Phase 15
@allowed_par_authorize_params MapSet.new(["client_id", "request_uri"])

defp reject_conflicting_par_query_params(params) do
  extras =
    params
    |> Map.keys()
    |> Enum.reject(&MapSet.member?(@allowed_par_authorize_params, &1))

  case extras do
    [] -> :ok
    _ -> {:browser_error, browser_error(:invalid_request, "request_uri must stand alone", :par_query_conflict)}
  end
end
```

### Pattern 4: Truthful Discovery and Support Surface

**What:** Publish `pushed_authorization_request_endpoint` because `/par` is mounted and supported, but do not publish `require_pushed_authorization_requests`, request-object metadata, DCR metadata, or device-flow metadata because those features are not implemented in v1.2. [VERIFIED: lib/lockspire/web/router.ex] [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://www.rfc-editor.org/rfc/rfc9126] [CITED: https://www.rfc-editor.org/rfc/rfc8414.html]

**When to use:** Update discovery and docs in the same plan wave as the feature becomes true so repo truth never says both "PAR unsupported" and "PAR supported" at once. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: SECURITY.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

### Anti-Patterns to Avoid

- **Do not accept generic external `request_uri` values:** Phase 15 is only for PAR-issued references Lockspire created itself, not arbitrary remote request objects. [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://www.rfc-editor.org/rfc/rfc9126]
- **Do not let `/authorize` accept `request_uri` plus a second set of raw authorization parameters:** This creates ambiguity about which request data is authoritative. [VERIFIED: .planning/research/SUMMARY.md] [VERIFIED: lib/lockspire/protocol/authorization_request.ex]
- **Do not implement replay protection as read-then-delete outside a transaction:** Replay safety depends on atomic lock-and-consume behavior. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9126]
- **Do not broaden discovery with request-object, DCR, or device-flow metadata:** That would create false support claims. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: test/lockspire/web/discovery_controller_test.exs]
- **Do not fork a second authorization flow module for PAR:** The flow after validation should still be the existing interaction/consent/code path. [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PAR consumption orchestration | A new parallel authorization pipeline | `AuthorizationRequest` resolution feeding the existing `AuthorizationFlow` | Lockspire already has a typed validated-request contract and a durable authorization flow. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] |
| Replay resistance | Controller-local flags, Plug assigns, or session markers | Repository transaction with row lock and consume-once semantics | Replay protection must survive concurrent requests and process restarts. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9126] |
| Discovery truth | Hand-maintained controller JSON | `Lockspire.Protocol.Discovery` plus contract tests | The current discovery controller is intentionally a thin adapter over protocol output. [VERIFIED: lib/lockspire/web/controllers/discovery_controller.ex] [VERIFIED: lib/lockspire/web/controllers/discovery_json.ex] |
| Public support claims | Ad hoc README edits only | Coordinated README + docs + SECURITY + release-readiness contract updates | The repo already uses those files as the public support contract. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: SECURITY.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |

**Key insight:** The risky part of Phase 15 is not generating a code path for `request_uri`; it is preserving one authoritative request payload, one authorization flow, and one truthful support surface while enforcing consume-once behavior durably. [VERIFIED: .planning/research/SUMMARY.md] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

## Common Pitfalls

### Pitfall 1: Reconstructing Only Part of the Authorization Request

**What goes wrong:** The PAR row is loaded, but the code still trusts browser-supplied `scope`, `redirect_uri`, `prompt`, or PKCE fields. [VERIFIED: lib/lockspire/domain/pushed_authorization_request.ex] [VERIFIED: .planning/research/SUMMARY.md]
**Why it happens:** The implementation treats `request_uri` as additive instead of authoritative. [CITED: https://www.rfc-editor.org/rfc/rfc9126]
**How to avoid:** Rebuild the normalized request from stored PAR state and accept at most `client_id` plus `request_uri` in the browser query. [VERIFIED: .planning/research/SUMMARY.md]
**Warning signs:** `/authorize` tests still pass when conflicting raw query params are present alongside `request_uri`. [VERIFIED: test/lockspire/web/authorize_controller_test.exs]

### Pitfall 2: Read-Then-Consume Replay Windows

**What goes wrong:** Two concurrent `/authorize` requests can both see the same PAR row as active before either one marks it consumed. [CITED: https://www.rfc-editor.org/rfc/rfc9126]
**Why it happens:** The repository only exposes fetch semantics today and the planner forgets to add a transactional consume path. [VERIFIED: lib/lockspire/storage/pushed_authorization_request_store.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]
**How to avoid:** Add a dedicated consume callback implemented with `FOR UPDATE` locking and a terminal state transition. [VERIFIED: lib/lockspire/storage/ecto/repository.ex]
**Warning signs:** The implementation calls `fetch_active_pushed_authorization_request/1` from the controller or protocol and then updates/deletes in a second step. [VERIFIED: lib/lockspire/storage/pushed_authorization_request_store.ex]

### Pitfall 3: Discovery Truth Moving Ahead of Behavior

**What goes wrong:** Discovery advertises PAR support before `/authorize` can actually consume the issued `request_uri`, or docs still say PAR is unsupported after the feature lands. [VERIFIED: test/lockspire/web/discovery_controller_test.exs] [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md]
**Why it happens:** Discovery/docs live in separate files and contract tests from the protocol change. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
**How to avoid:** Treat discovery, support docs, and the release-readiness contract as one truth-surface work item. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
**Warning signs:** A PR updates `lib/lockspire/protocol/discovery.ex` without corresponding README/support/security/test changes. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md]

### Pitfall 4: Expanding the Milestone Accidentally

**What goes wrong:** Phase 15 starts adding request objects by value, client metadata policy switches, or generic remote `request_uri` handling. [VERIFIED: .planning/REQUIREMENTS.md]
**Why it happens:** RFC 9126 references adjacent specs, and the metadata names can tempt broader implementation. [CITED: https://www.rfc-editor.org/rfc/rfc9126]
**How to avoid:** Keep the only new truth claims to PAR-issued request references and `pushed_authorization_request_endpoint`. [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://www.rfc-editor.org/rfc/rfc9126]
**Warning signs:** New code touches request-object signing metadata, DCR routes, or device-flow docs. [VERIFIED: test/lockspire/web/discovery_controller_test.exs] [VERIFIED: .planning/REQUIREMENTS.md]

## Code Examples

Verified patterns from official sources and this repo:

### PAR `request_uri` Consumption Before Authorization Flow

The existing authorize controller already expects a `%Validated{}` contract and forwards it into `AuthorizationFlow.start_authorization/3`, so Phase 15 should preserve that seam. [VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex]

```elixir
# Source: existing repo contract in authorize_controller.ex
case AuthorizationRequest.validate(params, pushed_authorization_request_store: Repository) do
  {:ok, %Validated{} = validated} ->
    AuthorizationFlow.start_authorization(validated, subject_context, protocol_store_opts())

  {:browser_error, %Error{} = error} ->
    render_browser_error(conn, error, :bad_request)

  {:redirect_error, %Error{} = error} ->
    redirect(conn, external: redirect_location(error))
end
```

### Discovery Metadata Addition Without Scope Creep

RFC 9126 says the presence of `pushed_authorization_request_endpoint` is enough for clients to know PAR is usable and that this works regardless of other request-URI metadata. [CITED: https://www.rfc-editor.org/rfc/rfc9126]

```elixir
# Source: Discovery endpoint metadata pattern in lib/lockspire/protocol/discovery.ex
@endpoint_paths %{
  "authorization_endpoint" => "/authorize",
  "token_endpoint" => "/token",
  "userinfo_endpoint" => "/userinfo",
  "jwks_uri" => "/jwks",
  "revocation_endpoint" => "/revoke",
  "introspection_endpoint" => "/introspect",
  "pushed_authorization_request_endpoint" => "/par"
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `/authorize` rejects `request_uri` as unsupported. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] | `/authorize` should accept only PAR-issued `request_uri` values and resolve them through durable server-owned state. [VERIFIED: .planning/ROADMAP.md] [CITED: https://www.rfc-editor.org/rfc/rfc9126] | Phase 15 target. [VERIFIED: .planning/ROADMAP.md] | Enables PAR-backed auth-code + PKCE without adding a second flow shape. [VERIFIED: .planning/REQUIREMENTS.md] |
| Discovery omits PAR metadata even though `/par` is now mounted. [VERIFIED: lib/lockspire/web/router.ex] [VERIFIED: lib/lockspire/protocol/discovery.ex] | Discovery should publish `pushed_authorization_request_endpoint` and continue omitting unrelated unsupported metadata. [CITED: https://www.rfc-editor.org/rfc/rfc9126] [VERIFIED: test/lockspire/web/discovery_controller_test.exs] | Phase 15 target. [VERIFIED: .planning/ROADMAP.md] | Makes machine-readable metadata match the implemented PAR slice. [VERIFIED: .planning/REQUIREMENTS.md] |
| Public docs and contract tests say PAR is unsupported. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: SECURITY.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] | Public docs and contract tests should say Lockspire supports PAR-issued request references only, not JAR-by-value, DCR, or device flow. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: user prompt] | Phase 15 target. [VERIFIED: .planning/ROADMAP.md] | Prevents support-posture drift once the feature becomes real. [VERIFIED: .planning/PROJECT.md] |

**Deprecated/outdated:**

- Treating PAR as "future only" in public docs is outdated once Phase 15 lands because Phase 14 already mounted `/par` and Phase 15 is the roadmap phase that makes the end-to-end flow true. [VERIFIED: lib/lockspire/web/router.ex] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: README.md]

## Assumptions Log

All material claims in this research were verified against repo files, local environment checks, or official RFC text in this session. [VERIFIED: repo inspection] [CITED: https://www.rfc-editor.org/rfc/rfc9126] [CITED: https://www.rfc-editor.org/rfc/rfc8414.html]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| None | No unverified assumptions remain. [VERIFIED: this file review] | All sections | No extra user confirmation is required before planning. [VERIFIED: this file review] |

## Open Questions

1. **Should consumed PAR rows be preserved with `consumed_at` or removed after use?**
   - What we know: replay resistance requires one-time-use semantics, and the repo generally prefers durable audit-friendly state over transient deletion. [VERIFIED: .planning/PROJECT.md] [VERIFIED: AGENTS.md] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9126]
   - What's unclear: the Phase 14 schema does not yet include a consumed marker, so Phase 15 can choose between a minimal delete-on-consume path and a more audit-friendly `consumed_at` transition. [VERIFIED: lib/lockspire/storage/ecto/pushed_authorization_request_record.ex]
   - Recommendation: prefer `consumed_at` and a transactional consume callback because it preserves forensic truth while still rejecting replays. [VERIFIED: project constraints synthesis] [CITED: https://www.rfc-editor.org/rfc/rfc9126]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | Running protocol/controller/integration tests | ✓ [VERIFIED: local command check] | `1.19.5` [VERIFIED: local mix --version] | — |
| Elixir | Compiling and testing Phase 15 changes | ✓ [VERIFIED: local command check] | `1.19.5` runtime reported during `elixir --version` boot output. [VERIFIED: local command output] | — |
| PostgreSQL CLI/runtime | Ecto SQL Sandbox tests in `config/test.exs` | ✓ [VERIFIED: local command check] | `14.17` [VERIFIED: local psql --version] | — |
| Docker | Optional local infra fallback if the test database is not running directly on the host | ✓ [VERIFIED: local command check] | `29.3.1` [VERIFIED: local docker --version] | Use host Postgres first. [VERIFIED: config/test.exs] |

**Missing dependencies with no fallback:** None detected for planning purposes. [VERIFIED: local command checks]

**Missing dependencies with fallback:** None detected for planning purposes. [VERIFIED: local command checks]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL Sandbox-backed repository and integration tests. [VERIFIED: test/test_helper.exs] [VERIFIED: config/test.exs] |
| Config file | `test/test_helper.exs`, `config/test.exs`. [VERIFIED: test/test_helper.exs] [VERIFIED: config/test.exs] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/web/discovery_controller_test.exs` [VERIFIED: mix.exs] |
| Full suite command | `MIX_ENV=test mix test.fast` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PAR-02 | PAR-issued `request_uri` completes the existing auth-code + PKCE flow and rejects expired, wrong-client, and replayed references. [VERIFIED: .planning/REQUIREMENTS.md] | protocol + controller + integration | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs test/integration/phase6_onboarding_e2e_test.exs` [VERIFIED: repo files exist] | ✅ [VERIFIED: repo files exist] |
| PAR-03 | Discovery metadata and human-facing support docs advertise only the implemented PAR slice. [VERIFIED: .planning/REQUIREMENTS.md] | controller + contract | `MIX_ENV=test mix test test/lockspire/web/discovery_controller_test.exs test/lockspire/release_readiness_contract_test.exs` [VERIFIED: repo files exist] | ✅ [VERIFIED: repo files exist] |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/web/discovery_controller_test.exs` [VERIFIED: repo test layout]
- **Per wave merge:** `MIX_ENV=test mix test.fast` [VERIFIED: mix.exs]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: .planning/config.json]

### Wave 0 Gaps

- None — the natural Phase 15 protocol, controller, integration, and truth-surface contract test files already exist and can be extended instead of created from scratch. [VERIFIED: test/lockspire/protocol/authorization_request_test.exs] [VERIFIED: test/lockspire/web/authorize_controller_test.exs] [VERIFIED: test/lockspire/web/discovery_controller_test.exs] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: PAR client-binding and client-auth rules] | Reuse existing client authentication rules for PAR issuance and require browser `client_id` to match the stored PAR client binding on consumption. [VERIFIED: lib/lockspire/protocol/pushed_authorization_request.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9126] |
| V3 Session Management | no [VERIFIED: phase scope] | Host-owned login/session state remains outside Lockspire's Phase 15 scope. [VERIFIED: AGENTS.md] |
| V4 Access Control | yes [VERIFIED: phase scope] | Enforce client-bound request references and exact redirect URI reuse through the existing authorization validation path. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: AGENTS.md] |
| V5 Input Validation | yes [VERIFIED: current authorization validator] | Continue to use `AuthorizationRequest` validation for redirect URI, scopes, nonce, prompt, response type, PKCE, and unsupported parameter handling. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] |
| V6 Cryptography | yes [VERIFIED: current PAR/token generation patterns] | Keep cryptographically strong random `request_uri` references and hashed-at-rest storage using existing policy helpers; do not hand-roll weaker identifiers. [VERIFIED: lib/lockspire/domain/pushed_authorization_request.ex] [VERIFIED: test/lockspire/protocol/pushed_authorization_request_test.exs] [CITED: https://www.rfc-editor.org/rfc/rfc9126] |

### Known Threat Patterns for Lockspire's PAR Slice

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Guessing a valid `request_uri` | Spoofing | Require strong random URNs, hash-at-rest lookup, short TTL, and client binding. [VERIFIED: lib/lockspire/domain/pushed_authorization_request.ex] [VERIFIED: test/lockspire/protocol/pushed_authorization_request_test.exs] [CITED: https://www.rfc-editor.org/rfc/rfc9126] |
| Replay of a captured `request_uri` | Replay / Elevation | Use transactional consume-once semantics and reject expired or already-consumed references. [CITED: https://www.rfc-editor.org/rfc/rfc9126] [VERIFIED: phase recommendation] |
| `request_uri` swapping between clients | Tampering | Require browser `client_id` to match the stored PAR client binding before validation proceeds. [CITED: https://www.rfc-editor.org/rfc/rfc9126] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] |
| Query-parameter confusion at `/authorize` | Tampering | Reject extra raw authorization params when `request_uri` is present and rebuild the request from stored PAR state. [VERIFIED: .planning/research/SUMMARY.md] |
| Drift between behavior and published support claims | Repudiation / Integrity | Update discovery, docs, and contract tests in the same wave as the feature. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: test/lockspire/web/discovery_controller_test.exs] |

## Sources

### Primary (HIGH confidence)

- `https://www.rfc-editor.org/rfc/rfc9126` — verified PAR request rules, successful response fields, single-use guidance, expiry guidance, client binding, and PAR metadata semantics. [CITED: https://www.rfc-editor.org/rfc/rfc9126]
- `https://www.rfc-editor.org/rfc/rfc8414.html` — verified general authorization-server metadata semantics and well-known discovery behavior. [CITED: https://www.rfc-editor.org/rfc/rfc8414.html]
- `AGENTS.md` — verified project boundaries, stack targets, and security defaults. [VERIFIED: AGENTS.md]
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` — verified milestone scope, active requirements, and current planning posture. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/STATE.md]
- `.planning/research/*.md` and Phase 14 artifacts — verified milestone-level architecture, pitfalls, and the exact Phase 14 PAR decisions Phase 15 must build on. [VERIFIED: .planning/research/SUMMARY.md] [VERIFIED: .planning/research/ARCHITECTURE.md] [VERIFIED: .planning/research/FEATURES.md] [VERIFIED: .planning/research/PITFALLS.md] [VERIFIED: .planning/research/STACK.md] [VERIFIED: .planning/phases/14-pushed-request-intake/14-RESEARCH.md] [VERIFIED: .planning/phases/14-pushed-request-intake/14-PATTERNS.md] [VERIFIED: .planning/phases/14-pushed-request-intake/14-VALIDATION.md]
- Current implementation and tests under `lib/lockspire/**` and `test/lockspire/**` — verified actual seams, current behavior, and likely extension points. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/protocol/pushed_authorization_request.ex] [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: lib/lockspire/web/controllers/discovery_json.ex] [VERIFIED: lib/lockspire/storage/pushed_authorization_request_store.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [VERIFIED: lib/lockspire/domain/pushed_authorization_request.ex] [VERIFIED: test/lockspire/protocol/pushed_authorization_request_test.exs] [VERIFIED: test/lockspire/web/discovery_controller_test.exs] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]

### Secondary (MEDIUM confidence)

- Local environment checks for `mix`, PostgreSQL, Docker, and a passing targeted PAR/discovery test slice. [VERIFIED: local mix --version] [VERIFIED: local psql --version] [VERIFIED: local docker --version] [VERIFIED: `MIX_ENV=test mix test test/lockspire/protocol/pushed_authorization_request_test.exs test/lockspire/web/discovery_controller_test.exs`]

### Tertiary (LOW confidence)

- None. [VERIFIED: source review]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — Phase 15 reuses the locked project stack and current repo dependencies; no new external library choice is needed. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: AGENTS.md]
- Architecture: HIGH — the repo already exposes the exact controller/protocol/repository seams needed for PAR consumption and truthful discovery updates. [VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [VERIFIED: lib/lockspire/protocol/discovery.ex]
- Pitfalls: HIGH — the main risks are directly evidenced by current repo truth (`request_uri` currently rejected; PAR currently documented as unsupported) and by RFC 9126's single-use/client-binding guidance. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [CITED: https://www.rfc-editor.org/rfc/rfc9126]

**Research date:** 2026-04-24 [VERIFIED: system date]
**Valid until:** 2026-05-24 for repo-structure planning and 2026-05-01 for public truth-surface wording if Phase 15 execution changes support claims sooner. [VERIFIED: repo state and milestone timing]
