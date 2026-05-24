# Phase 57: RAR Introspection & Verification - Research

**Researched:** 2026-05-06
**Domain:** OAuth 2.0 RAR introspection, consent-surface proof, and verification strategy for Lockspire's embedded Phoenix/Elixir stack. [VERIFIED: codebase read] [CITED: https://www.rfc-editor.org/rfc/rfc9396.html] [CITED: https://www.rfc-editor.org/rfc/rfc7662.html]
**Confidence:** HIGH [VERIFIED: codebase read]

<user_constraints>
## User Constraints (from CONTEXT.md)

Source: `.planning/phases/57-rar-introspection-and-verification/57-CONTEXT.md`. [VERIFIED: .planning/phases/57-rar-introspection-and-verification/57-CONTEXT.md]

### Locked Decisions
- **D-01:** `/introspection` will return the stored **normalized granted** `authorization_details` array taken from the bound `ConsentGrant`, not raw request input and not token-embedded JSON. This preserves Phase 56's validator output as the durable truth.
- **D-02:** The default response shape is the **full normalized granted array**, not a reduced Lockspire-owned projection and not omission-by-default. This matches RFC 9396's introspection example and keeps the phase honest to `RAR-04`.
- **D-03:** Phase 57 will **not** add a new host-facing projection/configuration seam yet. Keep the public surface narrow for this phase. Implementation should still isolate formatting behind a small internal boundary so a future caller-aware filter/override can be added without reworking the core join path.
- **D-04:** Inactive introspection responses remain unchanged: return only `active: false` with no additional RAR data, consistent with RFC 7662 privacy guidance.
- **D-05:** Active introspection responses for both lifecycle token types Lockspire already supports here, `:access_token` and `:refresh_token`, will include the same granted `authorization_details` payload when a `consent_grant_id` is present.
- **D-06:** The semantic guardrail is `token_type`, not divergent payload shape. For access tokens, `authorization_details` represents the resource authorization carried by the token. For refresh tokens, it represents the durable granted authorization context bound to the refresh family and reused on rotation.
- **D-07:** No new per-token-type config knob in Phase 57. Current Lockspire introspection is already client-bound and opaque-token oriented; adding policy branching now would create more surface area than value.
- **D-08:** Phase 57 verification uses the repo's established three-layer pattern:
  1. focused protocol tests for introspection shaping and grant lookup,
  2. endpoint/controller tests for HTTP behavior,
  3. one golden-path integration test proving PAR/authorize -> consent -> token issuance -> introspection.
- **D-09:** Add **narrow** regression assertions for refresh rotation and FAPI-compatible RAR usage, but do not build a new combinatorial matrix. This phase proves the new seam; it does not re-certify the milestone.
- **D-10:** Verification must explicitly prove Success Criterion 2 from ROADMAP: tokens stay compact and introspection recovers RAR by reference through `consent_grant_id`, rather than by stuffing full RAR JSON into token records or token material.
- **D-11:** Phase 57 requires **structural** consent-surface proof only. The host-facing consent flow must visibly receive generic RAR data in a host-consumable shape, but Lockspire does not take ownership of per-type semantic rendering or policy wording in this phase.
- **D-12:** Acceptable proof is generic display/assertion of RAR presence, type, and/or normalized summary through the existing consent path. Do not introduce a type-aware renderer registry, semantic formatter behavior, or built-in domain-specific copy in v1.14.
- **D-13:** The end-to-end proof must show that the data approved through the consent path is the same normalized granted payload later returned by introspection.
- **D-14:** Downstream research/planning/execution should default to **strong recommendations with sensible defaults chosen proactively**, rather than surfacing broad option sets back to the user.
- **D-15:** Only escalate questions back to the user when the decision is genuinely high-impact on product shape, security posture, or public API. Minor implementation tradeoffs should be resolved by agents in the direction of least surprise, tight boundaries, strong DX, and truthful docs/tests.

### Claude's Discretion
- Internal naming for the consent-grant lookup/helper used by introspection.
- Whether the protocol layer fetches the `ConsentGrant` directly through the token store or via a small repository helper, as long as boundaries remain clear and planning justifies the seam.
- Exact generic consent-surface assertion format for tests, provided it stays structural and host-owned.

### Deferred Ideas (OUT OF SCOPE)
- Host-facing introspection projection/filter seam for caller-aware RAR shaping.
- Per-introspecting-client or per-resource-server RAR filtering policy.
- Semantic/type-aware consent rendering hooks or generator-backed RAR consent presenters.
- Broader FAPI/RAR combinatorial test matrix and certification-style hardening.
- Discovery/docs/public API work for RAR metadata and custom consent guidance belongs to Phase 58.
</user_constraints>

<phase_requirements>
## Phase Requirements

Source: `.planning/REQUIREMENTS.md`. [VERIFIED: .planning/REQUIREMENTS.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| RAR-04 | Expose RAR details in the `/introspection` response for Resource Servers. [VERIFIED: .planning/REQUIREMENTS.md] | Return `ConsentGrant.authorization_details` for active `:access_token` and `:refresh_token` responses after client-binding and activity checks, using `Token.consent_grant_id` plus `ConsentStore.fetch_consent_grant/1`. [VERIFIED: lib/lockspire/domain/token.ex] [VERIFIED: lib/lockspire/domain/consent_grant.ex] [VERIFIED: lib/lockspire/storage/consent_store.ex] [VERIFIED: lib/lockspire/protocol/introspection.ex] |
| V-01 | Deliver e2e test suite for RAR-scoped consent and targeted token issuance. [VERIFIED: .planning/REQUIREMENTS.md] | Add one new golden-path integration test that drives PAR -> authorize -> consent -> code exchange -> refresh -> introspection and asserts the same normalized payload is visible in consent and introspection while tokens remain reference-based. [VERIFIED: test/integration/phase56_rar_validation_storage_e2e_test.exs] [VERIFIED: test/lockspire/web/live/consent_live_test.exs] |
| V-02 | Verify FAPI 2.0 compatibility when RAR is used (exact matching, PAR enforcement). [VERIFIED: .planning/REQUIREMENTS.md] | Add narrow regressions that reuse existing FAPI enforcement posture: direct RAR `/authorize` under `:fapi_2_0_security` still fails without PAR, and PAR-backed RAR still succeeds with the canonical redirect URI. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: test/integration/phase43_fapi_milestone_e2e_test.exs] |
</phase_requirements>

## Summary

Phase 57 does not need a new storage join abstraction to satisfy `RAR-04`. Lockspire already persists normalized granted RAR payloads on `ConsentGrant.authorization_details`, already persists `Token.consent_grant_id`, already threads that ID through authorization-code issuance and refresh rotation, and already exposes a narrow introspection protocol that classifies active vs. inactive tokens before formatting the response. The smallest truthful implementation is to keep `Lockspire.Protocol.Introspection` as the orchestrator, fetch the lifecycle token as it does today, and, only for active responses, resolve `consent_grant_id -> ConsentGrant.authorization_details` through the existing `ConsentStore.fetch_consent_grant/1` boundary. [VERIFIED: lib/lockspire/protocol/introspection.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] [VERIFIED: lib/lockspire/storage/consent_store.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

That approach matches RFC 9396's minimal support guidance: store consented authorization details as part of a grant and make them available to resource servers through access-token content or introspection, including across `authorization_code` and `refresh_token` flows. It also preserves RFC 7662 privacy semantics because inactive responses should stay `active: false` only. [CITED: https://www.rfc-editor.org/rfc/rfc9396.html] [CITED: https://www.rfc-editor.org/rfc/rfc7662.html]

The consent proof should stay structural. `ConsentLive` already renders host-owned consent data from durable `Interaction` state; Phase 57 only needs to surface generic RAR visibility such as type names or the normalized JSON payload. Do not introduce type-aware renderer registries, new host configuration seams, or token-schema changes. Verification should stay narrow: extend protocol and controller tests, add one phase-specific golden E2E, and add one or two RAR-aware FAPI regressions rather than reopening the whole milestone matrix. [VERIFIED: lib/lockspire/web/live/consent_live.ex] [VERIFIED: test/lockspire/web/live/consent_live_test.exs] [VERIFIED: test/integration/phase56_rar_validation_storage_e2e_test.exs] [VERIFIED: test/integration/phase43_fapi_milestone_e2e_test.exs]

**Primary recommendation:** Add an internal `maybe_put_authorization_details/2` path in `Lockspire.Protocol.Introspection` backed by the existing `ConsentStore`, wire `consent_store: Repository` through the controller/tests, expose generic RAR visibility in `ConsentLive`, and prove the behavior with one new phase-specific E2E plus narrow refresh/FAPI regressions. [VERIFIED: lib/lockspire/protocol/introspection.ex] [VERIFIED: lib/lockspire/storage/consent_store.ex] [VERIFIED: lib/lockspire/web/controllers/introspection_controller.ex] [VERIFIED: lib/lockspire/web/live/consent_live.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token introspection classification | API / Backend | Database / Storage | `Lockspire.Protocol.Introspection` already authenticates the caller, loads the token, applies active/inactive rules, and formats the response; the database only provides durable token/grant state. [VERIFIED: lib/lockspire/protocol/introspection.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Granted RAR lookup by `consent_grant_id` | API / Backend | Database / Storage | The protocol layer should decide when RAR can be disclosed; storage should remain a generic fetch boundary over tokens and consent grants. [VERIFIED: lib/lockspire/storage/token_store.ex] [VERIFIED: lib/lockspire/storage/consent_store.ex] |
| Inactive-response privacy | API / Backend | — | RFC 7662 privacy semantics are response-shaping rules, not storage concerns. [CITED: https://www.rfc-editor.org/rfc/rfc7662.html] [VERIFIED: lib/lockspire/protocol/introspection.ex] |
| Consent-surface structural visibility | Frontend Server (SSR) | API / Backend | `ConsentLive` is the host-facing rendered seam over durable interaction state; protocol remains responsible for interaction validity and persisted normalized data. [VERIFIED: lib/lockspire/web/live/consent_live.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] |
| Refresh-family RAR continuity | API / Backend | Database / Storage | `RefreshExchange` already preserves `consent_grant_id` during rotation, so introspection continuity is a protocol/storage collaboration already in place. [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| FAPI/RAR regression enforcement | API / Backend | Frontend Server (SSR) | PAR-required and exact-match redirect enforcement already live in authorization validation and the Phase 43 integration proof; Phase 57 only needs narrow RAR-aware regression coverage on that path. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: test/integration/phase43_fapi_milestone_e2e_test.exs] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | Project pin `~> 1.8.5`; current Hex release `1.8.7` verified 2026-05-06. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: hex.pm api phoenix] | HTTP endpoint/controller delivery for `/introspect` and test harness routing. [VERIFIED: lib/lockspire/web/controllers/introspection_controller.ex] | It is the host framework Lockspire is explicitly built to embed into; Phase 57 should stay inside that delivery model. [VERIFIED: AGENTS.md] |
| Phoenix LiveView | Project pin `~> 1.1.28`; current Hex release `1.1.30` verified 2026-05-06. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: hex.pm api phoenix_live_view] | Host-owned consent surface proof. [VERIFIED: lib/lockspire/web/live/consent_live.ex] | `ConsentLive` already owns the reference consent UI surface; no new UI stack is needed. [VERIFIED: lib/lockspire/web/live/consent_live.ex] |
| Ecto SQL | Project pin `~> 3.13.5`; current Hex release `3.13.5` verified 2026-05-06. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: hex.pm api ecto_sql] | Repository boundary for durable token and grant state. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] | Existing repository seams already cover the data Phase 57 needs. [VERIFIED: lib/lockspire/storage/consent_store.ex] [VERIFIED: lib/lockspire/storage/token_store.ex] |
| PostgreSQL | `14+` project requirement. [VERIFIED: AGENTS.md] | Durable token/grant persistence backing the Ecto repository. [VERIFIED: AGENTS.md] | Required project datastore; no phase-specific storage technology change is warranted. [VERIFIED: AGENTS.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jason | Project pin `~> 1.4`; latest prerelease visible on Hex, current stable lock `1.4.4`. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: hex.pm api jason] | JSON response encoding and `authorization_details` assertions in controller/E2E tests. [VERIFIED: lib/lockspire/web/controllers/introspection_controller.ex] [VERIFIED: test/lockspire/web/introspection_controller_test.exs] | Use for introspection response assertions and any structural consent JSON rendering. [VERIFIED: test/lockspire/web/introspection_controller_test.exs] |
| ExUnit + Phoenix.ConnTest + Phoenix.LiveViewTest | Shipped with the project test stack. [VERIFIED: test/lockspire/protocol/introspection_test.exs] [VERIFIED: test/lockspire/web/introspection_controller_test.exs] [VERIFIED: test/lockspire/web/live/consent_live_test.exs] | Protocol, controller, and LiveView verification layers. [VERIFIED: test files] | Use the existing layered test pattern instead of inventing a new harness. [VERIFIED: test files] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Protocol-layer two-step lookup (`fetch_lifecycle_token` then `fetch_consent_grant`) | New repository helper or joined lookup method | The join helper would reduce one repository call but would widen the storage API for a single current caller; the two-step path is smaller and already fully supported by existing domain seams. [VERIFIED: lib/lockspire/protocol/introspection.ex] [VERIFIED: lib/lockspire/storage/token_store.ex] [VERIFIED: lib/lockspire/storage/consent_store.ex] |
| Generic consent visibility in `ConsentLive` | Type-aware consent rendering registry | RFC 9396 allows deployment-specific presentation, but Phase 57 only needs structural proof and Lockspire's product boundary explicitly keeps product semantics in the host app. [CITED: https://www.rfc-editor.org/rfc/rfc9396.html] [VERIFIED: AGENTS.md] [VERIFIED: .planning/phases/57-rar-introspection-and-verification/57-CONTEXT.md] |

**Installation:** No new runtime dependencies are recommended for Phase 57. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

**Version verification:** The current Hex releases checked on 2026-05-06 are Phoenix `1.8.7`, Phoenix LiveView `1.1.30`, Ecto SQL `3.13.5`, Bandit `1.11.0`, Oban `2.22.1`, JOSE `1.11.12`, and Req `0.5.17`; the project remains pinned to the versions documented in `mix.exs` and `AGENTS.md`, so Phase 57 should not couple itself to an upgrade. [VERIFIED: hex.pm api phoenix] [VERIFIED: hex.pm api phoenix_live_view] [VERIFIED: hex.pm api ecto_sql] [VERIFIED: hex.pm api bandit] [VERIFIED: hex.pm api oban] [VERIFIED: hex.pm api jose] [VERIFIED: hex.pm api req] [VERIFIED: mix.exs] [VERIFIED: AGENTS.md]

## Architecture Patterns

### System Architecture Diagram

Diagram derived from the current code path and the locked Phase 57 scope. [VERIFIED: lib/lockspire/protocol/introspection.ex] [VERIFIED: lib/lockspire/web/controllers/introspection_controller.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex]

```text
POST /introspect
  -> IntrospectionController.create/2
  -> Protocol.Introspection.introspect/1
     -> fetch token hash
     -> authenticate confidential caller
     -> fetch lifecycle token by hash
     -> classify active/inactive
        -> inactive => %{active: false}
        -> active
           -> if consent_grant_id present, fetch ConsentGrant
           -> read normalized granted authorization_details
           -> merge into active response
  -> JSON response (no-store, no-cache)

PAR/authorize/consent/code/token/refresh path
  -> AuthorizationRequest validates and normalizes authorization_details
  -> AuthorizationFlow persists Interaction.authorization_details
  -> ConsentGrant persists normalized authorization_details
  -> Token issuance stores only consent_grant_id reference
  -> Introspection resolves RAR by reference later
```

### Recommended Project Structure

```text
lib/
├── lockspire/protocol/        # Introspection orchestration and active-response shaping
├── lockspire/storage/         # Existing token/consent fetch contracts
└── lockspire/web/             # Controller delivery and consent LiveView surface

test/
├── lockspire/protocol/        # Focused introspection join/privacy tests
├── lockspire/web/             # Controller + ConsentLive visibility tests
└── integration/              # Single golden-path phase57 RAR introspection proof
```

### Pattern 1: Active-Only Enrichment

**What:** Keep token classification unchanged, then enrich only the already-active response with grant-backed `authorization_details`. [VERIFIED: lib/lockspire/protocol/introspection.ex] [CITED: https://www.rfc-editor.org/rfc/rfc7662.html]

**When to use:** Any introspection field that should exist only for authorized, active callers and should never leak on inactive outcomes. [CITED: https://www.rfc-editor.org/rfc/rfc7662.html]

**Example:**

```elixir
# Source: lib/lockspire/protocol/introspection.ex + existing ConsentStore seam
defp classify_token(client, token, now, request) do
  case basic_activity_check(client, token, now) do
    {:ok, true} -> {:ok, active_response(token, request)}
    {:ok, false} -> inactive_response()
  end
end

defp active_response(token, request) do
  base_response(token)
  |> maybe_put_authorization_details(token, request)
end
```

### Pattern 2: Grant Truth, Token Reference

**What:** Treat `ConsentGrant.authorization_details` as durable truth and `Token.consent_grant_id` as the compact linkage. [VERIFIED: lib/lockspire/domain/consent_grant.ex] [VERIFIED: lib/lockspire/domain/token.ex] [VERIFIED: test/integration/phase56_rar_validation_storage_e2e_test.exs]

**When to use:** Access-token introspection, refresh-token introspection, and any future operator view that wants the granted RAR payload without duplicating it into token rows. [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] [VERIFIED: lib/lockspire/storage/ecto/token_record.ex]

**Example:**

```elixir
# Source: lib/lockspire/protocol/authorization_flow.ex
%ConsentGrant{
  authorization_details: interaction.authorization_details,
  authorization_details_fingerprint: Fingerprint.compute(interaction.authorization_details)
}

# Source: lib/lockspire/protocol/token_exchange.ex / refresh_exchange.ex
%Token{consent_grant_id: authorization_code.consent_grant_id}
```

### Pattern 3: Structural Consent Proof, Not Semantic Rendering

**What:** Render generic RAR presence, type names, or normalized JSON in `ConsentLive` without teaching Lockspire the business semantics of each RAR type. [VERIFIED: lib/lockspire/web/live/consent_live.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9396.html] [VERIFIED: AGENTS.md]

**When to use:** Phase 57 tests that need to prove the consent path sees normalized RAR data. [VERIFIED: .planning/phases/57-rar-introspection-and-verification/57-CONTEXT.md]

**Example:**

```elixir
# Source: recommended Phase 57 extension of ConsentLive assigns
assigns = %{
  requested_scopes: interaction.scopes_requested,
  authorization_details: interaction.authorization_details,
  authorization_detail_types: Enum.map(interaction.authorization_details, & &1["type"])
}
```

### Anti-Patterns to Avoid

- **Grant join in the controller:** Keep HTTP delivery thin; the controller should continue passing stores/options into protocol code, not reimplement token/grant logic. [VERIFIED: lib/lockspire/web/controllers/introspection_controller.ex]
- **Token bloat by duplicating `authorization_details` onto token rows or token material:** The current schema stores `consent_grant_id` but no `authorization_details` field on tokens; keep it that way. [VERIFIED: lib/lockspire/storage/ecto/token_record.ex] [VERIFIED: lib/lockspire/domain/token.ex]
- **Type-aware consent framework work in Phase 57:** The phase boundary explicitly excludes it and RFC 9396 leaves presentation deployment-specific. [VERIFIED: .planning/phases/57-rar-introspection-and-verification/57-CONTEXT.md] [CITED: https://www.rfc-editor.org/rfc/rfc9396.html]
- **Fetching consent data before active/client checks:** That creates unnecessary lookup work and increases the chance of accidental over-disclosure logic drift. [VERIFIED: lib/lockspire/protocol/introspection.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token/grant correlation | Custom token-embedded RAR blob or ad hoc join structs | Existing `Token.consent_grant_id` + `ConsentStore.fetch_consent_grant/1` | The codebase already persists the exact durable reference needed for compact tokens and refresh continuity. [VERIFIED: lib/lockspire/domain/token.ex] [VERIFIED: lib/lockspire/storage/consent_store.ex] [VERIFIED: test/integration/phase56_rar_validation_storage_e2e_test.exs] |
| Consent rendering semantics | Renderer registry for each RAR `type` | Generic host-owned LiveView rendering of normalized data | The product boundary assigns branding and policy wording to the host app, and Phase 57 only requires structural proof. [VERIFIED: AGENTS.md] [VERIFIED: lib/lockspire/web/live/consent_live.ex] |
| New FAPI matrix | Fresh conformance suite for RAR | One or two narrow regressions against the existing Phase 43 proof base | The existing FAPI milestone already proves the broad contract; Phase 57 only needs to verify that RAR did not bypass it. [VERIFIED: test/integration/phase43_fapi_milestone_e2e_test.exs] |

**Key insight:** The hard part was already solved in Phase 56: normalized RAR persistence and consent-grant linkage. Phase 57 should consume that truth, not redesign it. [VERIFIED: test/integration/phase56_rar_validation_storage_e2e_test.exs] [VERIFIED: .planning/STATE.md]

## Common Pitfalls

### Pitfall 1: Enriching inactive responses

**What goes wrong:** `authorization_details` leaks on expired, revoked, reused, public-client, or client-mismatched tokens. [CITED: https://www.rfc-editor.org/rfc/rfc7662.html] [VERIFIED: lib/lockspire/protocol/introspection.ex]

**Why it happens:** The enrichment step runs before or alongside the active/inactive classification instead of after it. [VERIFIED: lib/lockspire/protocol/introspection.ex]

**How to avoid:** Gate the consent-grant fetch behind the final active branch only. [VERIFIED: lib/lockspire/protocol/introspection.ex]

**Warning signs:** Any controller/protocol test for inactive outcomes starts asserting keys other than `active`. [VERIFIED: test/lockspire/protocol/introspection_test.exs] [VERIFIED: test/lockspire/web/introspection_controller_test.exs]

### Pitfall 2: Widening the storage boundary too early

**What goes wrong:** A new repository helper such as `fetch_lifecycle_token_with_consent/1` gets added even though the existing token and consent store seams already cover the need. [VERIFIED: lib/lockspire/storage/token_store.ex] [VERIFIED: lib/lockspire/storage/consent_store.ex]

**Why it happens:** Optimization instinct outruns the current feature scope. [ASSUMED]

**How to avoid:** Start with the two existing fetches and only add a repository helper if planning later identifies a second caller or measurable query pain. [VERIFIED: lib/lockspire/storage/token_store.ex] [VERIFIED: lib/lockspire/storage/consent_store.ex]

**Warning signs:** New public repository functions appear without a second consumer outside introspection. [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

### Pitfall 3: Turning consent proof into a UI framework phase

**What goes wrong:** Phase 57 starts inventing type-specific copy, semantic cards, or extension registration for RAR rendering. [VERIFIED: .planning/phases/57-rar-introspection-and-verification/57-CONTEXT.md]

**Why it happens:** RFC 9396 mentions customization for presentation, but that is a deployment concern, not a v1.14 Lockspire obligation. [CITED: https://www.rfc-editor.org/rfc/rfc9396.html]

**How to avoid:** Limit the shipped surface to generic lists or JSON previews backed by normalized data. [VERIFIED: lib/lockspire/web/live/consent_live.ex]

**Warning signs:** New behaviours, registries, or generator work appear under `lib/lockspire/web/live` or host install docs. [VERIFIED: lib/lockspire/web/live/consent_live.ex] [VERIFIED: docs/install-and-onboard.md]

### Pitfall 4: Proving only storage and not the end-to-end seam

**What goes wrong:** Tests assert the database rows but never prove that the host consent surface saw the same normalized RAR later returned by introspection. [VERIFIED: test/integration/phase56_rar_validation_storage_e2e_test.exs]

**Why it happens:** Phase 56 already had strong storage proof, so Phase 57 can accidentally stop one step short. [VERIFIED: test/integration/phase56_rar_validation_storage_e2e_test.exs]

**How to avoid:** The golden E2E should assert consent visibility and then introspection equality against the same normalized payload. [VERIFIED: .planning/phases/57-rar-introspection-and-verification/57-CONTEXT.md]

**Warning signs:** E2E coverage introspects successfully but never inspects consent HTML. [VERIFIED: test/lockspire/web/live/consent_live_test.exs]

## Code Examples

Verified patterns from official sources and the current codebase:

### Introspection merge point

```elixir
# Source: lib/lockspire/protocol/introspection.ex
with {:ok, true} <- validate_confidential_caller(client),
     {:ok, token} <- fetch_lifecycle_token(token_hash, request) do
  classify_token(client, token, now(request))
end
```

Recommendation: keep that flow and add grant-backed enrichment inside the active path only. [VERIFIED: lib/lockspire/protocol/introspection.ex] [CITED: https://www.rfc-editor.org/rfc/rfc7662.html]

### Grant-backed RAR durability

```elixir
# Source: lib/lockspire/protocol/authorization_flow.ex
grant = %ConsentGrant{
  authorization_details: interaction.authorization_details,
  authorization_details_fingerprint: Fingerprint.compute(interaction.authorization_details)
}
```

This is the canonical truth source for introspection in Phase 57. [VERIFIED: lib/lockspire/protocol/authorization_flow.ex]

### Refresh continuity

```elixir
# Source: lib/lockspire/protocol/refresh_exchange.ex
%Token{
  access_token
  | consent_grant_id: source_token.consent_grant_id
}
```

This is why refresh-token introspection can expose the same granted payload without token bloat. [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Coarse scope-only authorization to RSs | RAR grant truth with normalized `authorization_details` stored as part of the grant and exposed to RSs through token responses or introspection. [CITED: https://www.rfc-editor.org/rfc/rfc9396.html] | RFC 9396 published May 2023. [CITED: https://www.rfc-editor.org/rfc/rfc9396.html] | Resource servers can make richer authorization decisions without overloading `scope`. [CITED: https://www.rfc-editor.org/rfc/rfc9396.html] |
| Embedding every authorization nuance into token material | Compact token record plus durable grant reference via `consent_grant_id`. [VERIFIED: lib/lockspire/storage/ecto/token_record.ex] [VERIFIED: lib/lockspire/storage/ecto/consent_grant_record.ex] | Lockspire Phase 56 completed on 2026-05-06. [VERIFIED: .planning/STATE.md] | Introspection can recover full grant context while token rows stay narrow and refresh rotation stays consistent. [VERIFIED: test/integration/phase56_rar_validation_storage_e2e_test.exs] |

**Deprecated/outdated:**
- Using inactive introspection responses to expose extra token state is contrary to RFC 7662 privacy guidance. [CITED: https://www.rfc-editor.org/rfc/rfc7662.html]
- Treating consent UI rendering as authorization-server-global semantics is out of step with Lockspire's embedded-library boundary and Phase 57 scope. [VERIFIED: AGENTS.md] [VERIFIED: .planning/phases/57-rar-introspection-and-verification/57-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Widening the storage boundary now is optimization instinct rather than a proven need. [ASSUMED] | Common Pitfalls | Low; the plan could still choose a helper if implementation evidence shows the two-step lookup is awkward. |

## Open Questions (RESOLVED)

1. **What exact structural consent rendering should Phase 57 ship?**
   - Resolution: Ship the smallest structural proof surface. `ConsentLive` should render a generic RAR section sourced from `Interaction.authorization_details`, including visible `type` values plus one normalized-field assertion path in the HTML tests. [VERIFIED: lib/lockspire/web/live/consent_live.ex] [VERIFIED: test/lockspire/web/live/consent_live_test.exs]
   - Why this is the right fit: It proves normalized data reached the host seam without introducing a type-aware renderer registry, semantic formatter behavior, or new host configuration seam. [VERIFIED: .planning/phases/57-rar-introspection-and-verification/57-CONTEXT.md] [VERIFIED: AGENTS.md]
   - Planning consequence: The execution plan should target generic structural rendering only, and the golden E2E should assert the same normalized payload is visible during consent and later returned by introspection. [VERIFIED: .planning/phases/57-rar-introspection-and-verification/57-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Build and test execution | ✓ [VERIFIED: local command `elixir --version`] | Erlang/OTP 28 / Elixir runtime present. [VERIFIED: local command `elixir --version`] | — |
| Mix | Aliased test commands | ✓ [VERIFIED: local command `mix --version`] | Erlang/OTP 28 / Mix present. [VERIFIED: local command `mix --version`] | — |
| PostgreSQL | Ecto-backed test repo | ✓ [VERIFIED: local command `psql --version`] [VERIFIED: local command `pg_isready`] | `14.17`; local server accepting connections on `/tmp:5432`. [VERIFIED: local command `psql --version`] [VERIFIED: local command `pg_isready`] | — |
| Node | Graph/tooling helpers only | ✓ [VERIFIED: local command `node --version`] | `v22.14.0`. [VERIFIED: local command `node --version`] | Not required for the phase implementation. [VERIFIED: codebase read] |

**Missing dependencies with no fallback:** None found. [VERIFIED: local environment audit]

**Missing dependencies with fallback:** None needed for this phase. [VERIFIED: local environment audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix ConnTest and Phoenix LiveViewTest on the Phoenix `1.8.x` stack. [VERIFIED: test/lockspire/protocol/introspection_test.exs] [VERIFIED: test/lockspire/web/introspection_controller_test.exs] [VERIFIED: test/lockspire/web/live/consent_live_test.exs] |
| Config file | `config/test.exs`, `test/test_helper.exs`. [VERIFIED: config/test.exs] [VERIFIED: test/test_helper.exs] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/web/live/consent_live_test.exs -x` [VERIFIED: mix.exs] |
| Full suite command | `MIX_ENV=test mix test.integration` and `MIX_ENV=test mix test.phase3` for the broader regression gates already defined in aliases. [VERIFIED: mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RAR-04 | Active introspection returns normalized granted `authorization_details` for access and refresh tokens, but inactive responses stay `active: false`. [VERIFIED: .planning/REQUIREMENTS.md] | unit + controller | `MIX_ENV=test mix test test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs -x` | ✅ existing files to extend. [VERIFIED: test files] |
| V-01 | PAR/authorize/consent/token/introspect golden path shows the same normalized payload across consent and introspection, while tokens stay reference-based. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `MIX_ENV=test mix test --include integration test/integration/phase57_rar_introspection_verification_e2e_test.exs -x` | ❌ Wave 0 new file. [VERIFIED: test/integration directory listing] |
| V-02 | RAR under FAPI still obeys PAR-required and exact-match redirect enforcement. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `MIX_ENV=test mix test --include integration test/integration/phase57_rar_introspection_verification_e2e_test.exs test/integration/phase43_fapi_milestone_e2e_test.exs -x` | ⚠️ existing Phase 43 file exists; one narrow new regression test should be added either there or in the new Phase 57 E2E. [VERIFIED: test/integration/phase43_fapi_milestone_e2e_test.exs] |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/web/live/consent_live_test.exs -x` [VERIFIED: test files]
- **Per wave merge:** `MIX_ENV=test mix test --include integration test/integration/phase57_rar_introspection_verification_e2e_test.exs` plus the touched unit/controller files. [VERIFIED: test directory structure]
- **Phase gate:** `MIX_ENV=test mix test.integration` before `/gsd-verify-work`. [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] `test/integration/phase57_rar_introspection_verification_e2e_test.exs` — new golden-path proof for `RAR-04`, `V-01`, and narrow `V-02`. [VERIFIED: test/integration directory listing]
- [ ] `test/lockspire/protocol/introspection_test.exs` — add active access-token and refresh-token RAR assertions plus inactive privacy guards. [VERIFIED: test/lockspire/protocol/introspection_test.exs]
- [ ] `test/lockspire/web/introspection_controller_test.exs` — add HTTP JSON assertions for `authorization_details`. [VERIFIED: test/lockspire/web/introspection_controller_test.exs]
- [ ] `test/lockspire/web/live/consent_live_test.exs` — add structural RAR visibility assertions. [VERIFIED: test/lockspire/web/live/consent_live_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Client authentication behavior is pre-existing; Phase 57 only consumes it. [VERIFIED: lib/lockspire/protocol/introspection.ex] |
| V3 Session Management | no | No browser/session mechanics change in this phase. [VERIFIED: lib/lockspire/web/live/consent_live.ex] |
| V4 Access Control | yes | Client-bound introspection plus active-only enrichment of grant-backed RAR data. [VERIFIED: lib/lockspire/protocol/introspection.ex] [CITED: https://www.rfc-editor.org/rfc/rfc7662.html] |
| V5 Input Validation | yes | Return only normalized persisted RAR payloads that already passed Phase 56 validation; do not introspect raw request input. [VERIFIED: test/integration/phase56_rar_validation_storage_e2e_test.exs] [VERIFIED: .planning/phases/57-rar-introspection-and-verification/57-CONTEXT.md] |
| V6 Cryptography | no | No new cryptographic primitive or key handling is introduced. [VERIFIED: codebase read] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Inactive token over-disclosure | Information Disclosure | Keep inactive response to `active: false` only. [CITED: https://www.rfc-editor.org/rfc/rfc7662.html] |
| Cross-client RAR disclosure | Information Disclosure | Preserve the existing `token.client_id == client.client_id` check before active response shaping. [VERIFIED: lib/lockspire/protocol/introspection.ex] |
| Token-record data bloat | Denial of Service / Information Disclosure | Keep tokens compact and recover RAR by `consent_grant_id` reference only. [VERIFIED: lib/lockspire/storage/ecto/token_record.ex] [VERIFIED: test/integration/phase56_rar_validation_storage_e2e_test.exs] |
| Consent-surface semantic drift | Tampering | Render normalized persisted data rather than re-deriving semantics or revalidating on the UI path. [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [VERIFIED: lib/lockspire/web/live/consent_live.ex] |

## Sources

### Primary (HIGH confidence)

- `https://www.rfc-editor.org/rfc/rfc9396.html` - RFC 9396 sections 9.2, 11.1, and 11.2 on introspection, deployment presentation, and minimal implementation support. [CITED: https://www.rfc-editor.org/rfc/rfc9396.html]
- `https://www.rfc-editor.org/rfc/rfc7662.html` - RFC 7662 sections 2.2 and 5 on introspection extensibility and inactive-response privacy. [CITED: https://www.rfc-editor.org/rfc/rfc7662.html]
- `lib/lockspire/protocol/introspection.ex` - Current active/inactive shaping and caller model. [VERIFIED: lib/lockspire/protocol/introspection.ex]
- `lib/lockspire/protocol/authorization_flow.ex` - Consent-grant storage of normalized `authorization_details`. [VERIFIED: lib/lockspire/protocol/authorization_flow.ex]
- `lib/lockspire/protocol/token_exchange.ex` and `lib/lockspire/protocol/refresh_exchange.ex` - Token issuance and refresh propagation of `consent_grant_id`. [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex]
- `lib/lockspire/storage/consent_store.ex`, `lib/lockspire/storage/token_store.ex`, and `lib/lockspire/storage/ecto/repository.ex` - Existing repository seams. [VERIFIED: storage files]
- `test/integration/phase56_rar_validation_storage_e2e_test.exs` and `test/integration/phase43_fapi_milestone_e2e_test.exs` - Existing RAR/FAPI proof base. [VERIFIED: test files]
- Hex package API for `phoenix`, `phoenix_live_view`, `ecto_sql`, `bandit`, `oban`, `jose`, and `req` checked on 2026-05-06. [VERIFIED: hex.pm api]

### Secondary (MEDIUM confidence)

- `docs/install-and-onboard.md` - Host-owned seam guidance relevant to keeping consent proof structural. [VERIFIED: docs/install-and-onboard.md]
- `docs/ecosystem-overview.md` - Embedded-library boundary and host-owned auth/UI contract. [VERIFIED: docs/ecosystem-overview.md]

### Tertiary (LOW confidence)

- None. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and pins were verified from `mix.exs`, `mix.lock`, `AGENTS.md`, and Hex package APIs on 2026-05-06. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: AGENTS.md] [VERIFIED: hex.pm api]
- Architecture: HIGH - the required seam is already present in protocol/storage code and Phase 56 integration proof. [VERIFIED: codebase read] [VERIFIED: test/integration/phase56_rar_validation_storage_e2e_test.exs]
- Pitfalls: HIGH - privacy, seam widening, and UI scope risks are directly grounded in RFC text and current module responsibilities. [CITED: https://www.rfc-editor.org/rfc/rfc7662.html] [CITED: https://www.rfc-editor.org/rfc/rfc9396.html] [VERIFIED: AGENTS.md]

**Research date:** 2026-05-06
**Valid until:** 2026-06-05 for repo-structure claims; 2026-05-13 for package-latest-version claims. [VERIFIED: research date] [VERIFIED: hex.pm api]
