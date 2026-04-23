# Phase 05: Security and Observability Hardening - Research

**Researched:** 2026-04-23
**Domain:** Phoenix/Elixir OAuth/OIDC security hardening, durable audit design, redaction, and negative-path testing
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Phase 5 should use a mixed enforcement model: boot-time hard failure for deployment invariants, runtime hard failure for protocol/security invariants, and only narrow explicit escape hatches for non-core host-policy-adjacent behavior.
- **D-02:** Boot-time validation should remain strict for required embedded-library configuration such as `repo`, host seam modules, issuer/mount-path consistency, and any signing configuration needed for truthful runtime behavior.
- **D-03:** Runtime protocol behavior must hard-reject downgrade or ambiguity paths rather than warn-and-continue. This includes exact redirect matching, PKCE S256 enforcement, truthful discovery metadata, supported client-auth method rules, no implicit flow, and no `alg=none`.
- **D-04:** Lockspire must not introduce broad “insecure mode”, dev-only redirect relaxations, wildcard redirects, global PKCE opt-out, or silent fallback from strict to permissive behavior in Phase 5.
- **D-05:** Any escape hatch that survives Phase 5 must be scarce, explicit, deliberately named, and auditable. It must sit at a host-policy seam, not inside core protocol guarantees.
- **D-06:** Telemetry is not sufficient as the audit story. Phase 5 should keep `:telemetry` for observability and add a durable append-only domain audit model for security-relevant and operator-relevant lifecycle transitions.
- **D-07:** Audit records should be written inside the same transactional mutation boundary as the underlying state change whenever the event reflects durable domain truth.
- **D-08:** The audit model should be domain-event-oriented, not generic row-versioning. Capture transitions such as client created/rotated/disabled, consent revoked, token revoked, token-family revoked, refresh reuse detected, key published/activated/retired, and other security-relevant outcomes.
- **D-09:** Phase 5 should avoid generic “revert” semantics, full row snapshots, or table-versioning approaches for token/code tables. If limited change summaries are useful for clients or keys, store selective redacted summaries such as changed field names rather than full before/after representations.
- **D-10:** Durable audit payloads should stay small and explainable: actor, resource refs, action, outcome, reason code, and a compact redacted metadata map.
- **D-11:** Phase 5 should use a layered redaction model by surface rather than one universal visibility rule.
- **D-12:** Logs and telemetry metadata should never contain raw access tokens, refresh tokens, authorization codes, code verifiers, client secrets, or full request/response representations.
- **D-13:** Logs and telemetry should prefer stable redacted correlation fields such as fingerprints or short handles instead of full canonical identifiers where practical.
- **D-14:** Operator/admin surfaces should be support-usable but conservative by default: show human-friendly names plus masked or partial identifiers, keep secrets redacted, and avoid exposing raw token-family or bearer-material values in ordinary views.
- **D-15:** Durable audit records may retain canonical resource identifiers needed for truthful incident reconstruction, but they must still exclude bearer artifacts, secrets, and large raw payloads.
- **D-16:** Redaction policy must be centralized in shared helpers rather than scattered denylist logic so new protocol/admin code paths do not accidentally leak sensitive material.
- **D-17:** Phase 5 should use a layered negative-path test strategy rather than one exhaustive end-to-end matrix.
- **D-18:** The backbone should be protocol-level rejection tests around `Lockspire.Protocol.*` services, asserting reason codes, lifecycle outcomes, and telemetry/audit emission for malformed, replayed, mismatched, denied, and downgrade-oriented inputs.
- **D-19:** Add a small threat-driven scenario layer for high-blast-radius stories that span multiple phases, such as authorization-code replay, refresh-token reuse, wrong-client token actions, downgrade attempts, and consent denial behavior.
- **D-20:** Keep controller and LiveView negative-path coverage intentionally thin and focused on delivery semantics: first-party error page vs redirect behavior, JSON error envelopes, operator confirmation gates, and redaction in rendered/admin-visible surfaces.
- **D-21:** Property-style tests may be used sparingly for dense invariants with many permutations, but they should supplement rather than replace explicit protocol tests.
- **D-22:** Phase 5 should preserve the established architecture: protocol/core services and domain commands own the security and audit rules; Phoenix controllers and LiveViews stay thin adapters over those decisions.
- **D-23:** Audit and redaction behavior should be exposed through shared internal boundaries so protocol flows, admin workflows, and future jobs all reuse the same safety rules.
- **D-24:** Operator UX should remain calm and exact. Security hardening should improve trust and explainability, not add noisy consoles, broad dashboards, or fear-driven copy.

### Claude's Discretion
- Exact audit event names, schema field names, and helper-module boundaries, as long as telemetry and durable audit stay clearly separated and aligned.
- The precise fingerprint/handle format for redacted identifiers, as long as it is stable enough for correlation and never exposes bearer material.
- The exact split between service-layer, controller-layer, LiveView-layer, and property-based negative-path tests, as long as the protocol boundary remains the primary coverage asset.

### Deferred Ideas (OUT OF SCOPE)
- Generic row-versioning or “time travel” history across all tables.
- Broad insecure compatibility modes, redirect-relaxation modes, or ambient downgrade toggles.
- A full audit browser or SIEM-style analytics console.
- Heavyweight compliance/export features beyond the minimal durable audit trail needed for v1 operator trust.
- Exhaustive end-to-end negative-path matrices that duplicate service-layer coverage.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SECU-01 | Lockspire enforces secure defaults including PKCE by default, hashed client secrets, short-lived single-use codes, no implicit flow, and no `alg=none` | Strict boot-time config, protocol-level hard rejection, exact redirect matching, PKCE S256-only handling, and signing-alg allowlists are covered below. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/rfc9700/] [CITED: https://datatracker.ietf.org/doc/html/rfc7636.txt] [CITED: https://openid.net/specs/openid-connect-core-1_0-18.html] |
| SECU-02 | Lockspire emits telemetry and audit events for authorization, token, client, key, consent, and security-relevant actions | The research recommends keeping `:telemetry` for observability and adding a transactional append-only `audit_events` path at the repository/domain-command boundary. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/telemetry/telemetry.html] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| SECU-03 | Lockspire redacts secrets and sensitive token material in logs and operator-visible surfaces | The research recommends one shared redaction boundary with surface-specific renderers, and it calls out current admin/token and SQL-log exposure risks. [VERIFIED: codebase grep] [VERIFIED: mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/live/admin/tokens_live_test.exs] |
| SECU-04 | Lockspire has negative-path coverage for malformed, replayed, mismatched, denied, and downgrade-oriented requests | The research maps a protocol-first rejection matrix, thin controller/LiveView delivery tests, and optional property tests for dense invariants only. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
</phase_requirements>

## Summary

Lockspire already enforces part of the desired Phase 05 posture: `Lockspire.Config` raises on missing required config, `AuthorizationRequest` only accepts `response_type=code` with exact redirect matching and `code_challenge_method=:S256`, `TokenExchange` rejects replay, redirect mismatch, and PKCE mismatch, and the admin surfaces already avoid rendering raw bearer tokens in ordinary views. [VERIFIED: codebase grep]

The two biggest planning gaps are durable audit truth and centralized redaction. `Lockspire.Observability.emit/3` currently emits both `[:lockspire, ...]` and `[:lockspire, :audit, ...]` telemetry events, but there is no append-only audit table or transactional audit write path yet; the current `:audit` prefix is only a second telemetry namespace. [VERIFIED: codebase grep] Durable audit therefore needs to be planned as a storage-backed domain concern, not as more event names. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [CITED: https://hexdocs.pm/telemetry/telemetry.html]

The redaction story is also incomplete. `Lockspire.Observability.redact/1` drops a fixed denylist of sensitive keys, but Phase 05’s locked decisions require layered surface-specific visibility, and a representative test run showed Ecto debug SQL logs still printing `client_secret_hash` and `token_hash` bind values during repository operations. [VERIFIED: codebase grep] [VERIFIED: mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/live/admin/tokens_live_test.exs]

**Primary recommendation:** Implement Phase 05 around three shared internal seams: `security policy` for hard rejection, `audit writer` for transactional append-only events, and `redaction helpers` for logs, telemetry, audit payloads, and admin rendering. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Boot-time invariant validation | API / Backend | — | `Lockspire.Config` already owns required runtime config and issuer/mount-path checks. [VERIFIED: codebase grep] |
| Authorization and token downgrade rejection | API / Backend | Database / Storage | The strict checks live in `Lockspire.Protocol.*`, while code/token state is stored durably for replay and mismatch enforcement. [VERIFIED: codebase grep] |
| Durable audit append | Database / Storage | API / Backend | Audit truth must commit inside the same mutation boundary as client, consent, token, and key state changes. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Telemetry emission | API / Backend | Frontend Server (SSR) | Domain services should emit the canonical event stream; controllers and LiveViews should only add delivery context when needed. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/telemetry/telemetry.html] |
| Operator-safe redaction | API / Backend | Frontend Server (SSR) | The masking rules should be centralized in shared helpers, then consumed by LiveView presenters. [VERIFIED: codebase grep] |
| Negative-path delivery semantics | Frontend Server (SSR) | API / Backend | Controller and LiveView tests should verify redirects, first-party errors, confirmation gates, and rendered masking on top of protocol decisions. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `telemetry` | `1.4.1` (published 2026-03-09) | Emit synchronous in-process observability events | Lockspire already emits protocol events through `Observability.emit/3`, and `:telemetry.execute/3` plus `attach_many/4` is the standard Elixir event hook. [VERIFIED: mix hex.info telemetry] [VERIFIED: hex.pm API telemetry] [CITED: https://hexdocs.pm/telemetry/telemetry.html] |
| `ecto_sql` / `Ecto.Multi` | `3.13.5` (published 2026-03-03) | Transactional persistence for state mutation plus append-only audit rows | `Ecto.Multi` is the standard way to atomically group related writes and surface rollback causes. [VERIFIED: mix hex.info ecto_sql] [VERIFIED: hex.pm API ecto_sql] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| `phoenix_live_view` | `1.1.28` (published 2026-03-27) | Thin operator surfaces and rendered redaction checks | Existing admin workflows are already LiveView-based, and `Phoenix.LiveViewTest` is the current official test surface for event/render verification. [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: hex.pm API phoenix_live_view] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| `plug` | `1.19.1` | Constant-time compare and request plumbing | `TokenExchange` already uses `Plug.Crypto.secure_compare/2`; keep security-sensitive comparison on the standard Plug path. [VERIFIED: mix hex.info plug] [VERIFIED: codebase grep] |
| `opentelemetry_api` | `1.5.0` (published 2025-10-17) | Bridge high-value telemetry to traces/attributes when the host app enables OpenTelemetry | The project already depends on it, and official Erlang/Elixir guidance recommends semantic attributes for interoperable instrumentation. [VERIFIED: mix hex.info opentelemetry_api] [VERIFIED: hex.pm API opentelemetry_api] [CITED: https://opentelemetry.io/docs/languages/erlang/instrumentation/] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `opentelemetry_semantic_conventions` | `1.27.0` | Shared attribute keys for trace/event correlation | Add if Phase 05 maps Lockspire telemetry to OTel spans or attributes and wants stable naming instead of ad hoc metadata keys. [VERIFIED: mix hex.info opentelemetry_semantic_conventions] [CITED: https://opentelemetry.io/docs/languages/erlang/instrumentation/] |
| `stream_data` | `1.3.0` (published 2026-03-09) | Property-style invariant tests | Add only for dense invariants such as fingerprint stability or rejection/masking permutations; explicit protocol tests remain the backbone. [VERIFIED: mix hex.info stream_data] [VERIFIED: hex.pm API stream_data] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Ecto.Multi`-backed append-only audit events | Generic row versioning or snapshot history | Conflicts with the locked domain-event audit model and stores more sensitive state than needed. [VERIFIED: codebase grep] |
| Dual-path telemetry plus durable audit | Telemetry only | Easier to wire, but it does not satisfy the requirement for durable incident truth. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/telemetry/telemetry.html] |
| Protocol-first rejection tests | Large e2e-only matrix | Slower, noisier, and less precise about reason codes and lifecycle effects. [VERIFIED: codebase grep] |

**Installation:**
```elixir
# Existing deps already cover the core phase stack.
# Add only if Phase 05 chooses the optional helpers.
{:opentelemetry_semantic_conventions, "~> 1.27"},
{:stream_data, "~> 1.3", only: :test}
```

**Version verification:** Current package versions were verified against Hex during this research session via `mix hex.info` and the Hex package API. [VERIFIED: mix hex.info telemetry] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info plug] [VERIFIED: mix hex.info opentelemetry_api] [VERIFIED: mix hex.info stream_data] [VERIFIED: hex.pm API telemetry] [VERIFIED: hex.pm API ecto_sql] [VERIFIED: hex.pm API phoenix_live_view] [VERIFIED: hex.pm API opentelemetry_api] [VERIFIED: hex.pm API stream_data]

## Architecture Patterns

### System Architecture Diagram

```text
request/admin action
        |
        v
Phoenix Controller / LiveView
  - decode params
  - choose delivery shape
        |
        v
Protocol or Admin Command
  - validate invariant
  - assign reason_code
  - build redacted metadata
        |
        +---------------------------> Telemetry Event
        |                              [:lockspire, ...]
        |
        v
Repository Transaction (Ecto.Multi)
  - mutate durable resource state
  - append audit_events row
        |
        +---------------------------> Durable Audit Truth
        |
        v
result tuple / domain struct
        |
        v
Controller / LiveView renderer
  - first-party error vs redirect
  - JSON envelope
  - masked admin detail
```

The repo already follows the thin-adapter pattern at the web edge and durable truth in `Lockspire.Storage.Ecto.Repository`; Phase 05 should extend that exact shape instead of introducing controller-owned audit or UI-owned masking logic. [VERIFIED: codebase grep]

### Recommended Project Structure
```text
lib/
├── lockspire/security/          # hard-rejection helpers, reason-code policy, escape-hatch checks
├── lockspire/audit/             # audit event schema, writer, actor/resource metadata helpers
├── lockspire/redaction/         # surface-specific masking and fingerprint helpers
├── lockspire/observability.ex   # telemetry entrypoint, now delegating to redaction helpers
└── lockspire/storage/ecto/      # repository transaction helpers and audit persistence

test/
├── lockspire/security/          # unit tests for invariant helpers and redaction fingerprints
├── lockspire/protocol/          # rejection matrix and threat stories
├── lockspire/audit/             # transactional append assertions
└── lockspire/web/live/admin/    # rendered masking and confirmation-gate checks
```

### Pattern 1: Transactional Domain Mutation + Audit Append
**What:** Write the resource mutation and the audit row in one database transaction so durable state and durable audit cannot drift. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]  
**When to use:** Client create/rotate/disable, consent revoke, token revoke/family revoke, refresh reuse detection, key publish/activate/retire. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.update(:client, client_changeset)
|> Ecto.Multi.insert(:audit_event, audit_changeset)
|> Repo.transact()
```

### Pattern 2: One Shared Redaction Boundary, Many Surface Renderers
**What:** Normalize sensitive metadata once, then expose different projections for telemetry, audit rows, and admin views. [VERIFIED: codebase grep]  
**When to use:** Every place that currently passes maps into `Observability.emit/3` or renders token/client/key details. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: project pattern inferred from lib/lockspire/observability.ex plus Phase 05 decisions
metadata
|> Lockspire.Redaction.for_telemetry()
|> Lockspire.Observability.emit(:token_exchange_failed, %{count: 1})
```

### Pattern 3: Protocol-First Negative-Path Tests
**What:** Assert reason codes and state effects at the service boundary, then add thin delivery tests only where redirect/HTML/JSON behavior differs. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]  
**When to use:** Authorization validation, token exchange, refresh reuse, revocation, introspection, and admin confirmation gates. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
view
|> form("form", %{confirm: "true"})
|> render_submit()
```

### Anti-Patterns to Avoid
- **Controller-owned security rules:** It spreads protocol policy across delivery code and makes reason-code coverage weaker. [VERIFIED: codebase grep]
- **Telemetry pretending to be audit:** A second telemetry prefix is not durable truth. [VERIFIED: codebase grep]
- **Denylist redaction per screen:** New fields will leak; centralize redaction and render masked projections. [VERIFIED: codebase grep]
- **Generic row snapshots for tokens/codes:** This conflicts with the locked audit model and stores more sensitive detail than necessary. [VERIFIED: codebase grep]
- **Large end-to-end rejection matrices:** Current code already has strong protocol seams; use them directly. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic mutation + audit | Custom transaction coordinator | `Ecto.Multi` / `Repo.transact` | It is the standard Ecto path for grouped writes and rollback-aware failure handling. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Event fan-out | Homegrown callback registry | `:telemetry.execute/3` plus handlers | Telemetry is already in the dependency graph and is the standard attach/execute abstraction. [CITED: https://hexdocs.pm/telemetry/telemetry.html] |
| LiveView event simulation | Manual `handle_event/3` invocation for form workflows | `Phoenix.LiveViewTest` `form/3`, `render_submit/1`, `render_click/1` | Official helpers preserve DOM/input semantics that direct callback calls skip. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| Audit history | Table-versioning or full snapshots | Append-only domain audit events | The locked posture wants explainable lifecycle events, not time-travel storage. [VERIFIED: codebase grep] |

**Key insight:** Phase 05 should be built by extending existing platform seams, not by inventing new infrastructure. The repo already has protocol services, a central repository adapter, LiveView admin shells, and a telemetry entrypoint. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Treating `[:lockspire, :audit, ...]` telemetry as durable audit
**What goes wrong:** Planning assumes audit is already implemented because event names include an `:audit` prefix. [VERIFIED: codebase grep]  
**Why it happens:** `Lockspire.Observability.emit/3` currently writes two telemetry events, not a database row. [VERIFIED: codebase grep]  
**How to avoid:** Introduce an append-only audit schema and only call a write successful when the state mutation and audit row commit together. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]  
**Warning signs:** No migration for audit events, no repository API for audit append, no tests asserting rollback behavior for audit writes. [VERIFIED: codebase grep]

### Pitfall 2: Relying on app-level redaction while Repo SQL logs still print bind values
**What goes wrong:** Token hashes and secret hashes still reach logs through Ecto SQL debug output. [VERIFIED: mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/live/admin/tokens_live_test.exs]  
**Why it happens:** `Observability.redact/1` only governs telemetry metadata, not Repo query logging. [VERIFIED: codebase grep]  
**How to avoid:** Plan an explicit Repo logging posture for sensitive tables and keep application telemetry separate from raw SQL logging. [VERIFIED: codebase grep]  
**Warning signs:** Debug logs containing `client_secret_hash`, `token_hash`, or full family identifiers during tests or local runs. [VERIFIED: mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/live/admin/tokens_live_test.exs]

### Pitfall 3: Using full canonical identifiers in ordinary admin detail pages
**What goes wrong:** Operator pages remain support-useful but expose more canonical linkage than the locked redaction posture allows. [VERIFIED: codebase grep]  
**Why it happens:** Current token detail pages show `client_id`, `account_id`, and `family_id` directly. [VERIFIED: codebase grep]  
**How to avoid:** Keep canonical IDs in durable audit only, and render masked handles plus human-friendly names in normal operator views. [VERIFIED: codebase grep]  
**Warning signs:** Rendered HTML includes full family or subject identifiers outside explicit reveal workflows. [VERIFIED: codebase grep]

### Pitfall 4: Expanding negative-path coverage through controllers first
**What goes wrong:** Tests become slower and less precise, and reason-code assertions drift away from the real policy boundary. [VERIFIED: codebase grep]  
**Why it happens:** It is tempting to test visible behavior first because Phoenix routes are easy to hit. [VERIFIED: codebase grep]  
**How to avoid:** Put the main rejection matrix under `Lockspire.Protocol.*`, then add only thin delivery tests for redirects, JSON envelopes, and LiveView confirmation/redaction behavior. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]  
**Warning signs:** E2E tests duplicate protocol permutations or assert HTML without asserting reason codes or persisted outcomes. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources:

### Transactional Append with `Ecto.Multi`
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.update(:token, token_changeset)
|> Ecto.Multi.insert(:audit_event, audit_changeset)
|> Repo.transact()
```

### Emitting a Structured Telemetry Event
```elixir
# Source: https://hexdocs.pm/telemetry/telemetry.html
:telemetry.execute(
  [:lockspire, :token_exchange_failed],
  %{count: 1},
  %{reason_code: :authorization_code_replayed, client_handle: "cli_9f3c"}
)
```

### Attaching Test Handlers to Multiple Events
```elixir
# Source: https://hexdocs.pm/telemetry/telemetry.html
:telemetry.attach_many(
  "lockspire-phase5-test-handler",
  [
    [:lockspire, :token_exchange_failed],
    [:lockspire, :audit, :token_exchange_failed]
  ],
  &MyHandler.handle_event/4,
  nil
)
```

### Testing a LiveView Confirmation Flow Through the DOM
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
view
|> form("form", %{family: %{confirm: "true"}})
|> render_submit()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Pattern or wildcard redirect matching | Exact string redirect matching, with localhost port flexibility as the notable native-app exception | RFC 9700, January 2025 | Lockspire should keep exact-match redirect validation and avoid any “developer convenience” relaxation in Phase 05. [CITED: https://datatracker.ietf.org/doc/rfc9700/] |
| Implicit grant as a normal browser flow | Authorization code flow is preferred; implicit is deprecated for leakage/replay reasons | RFC 9700, January 2025 | Lockspire should continue refusing implicit support and keep discovery/config truthful about that. [CITED: https://datatracker.ietf.org/doc/rfc9700/] |
| PKCE `plain` accepted for new deployments | `S256` is MTI on the server and `plain` exists only for compatibility | RFC 7636, September 2015; reinforced by current security guidance | Lockspire’s existing S256-only posture is aligned with modern secure defaults. [CITED: https://datatracker.ietf.org/doc/html/rfc7636.txt] |
| Ad hoc instrumentation keys | Shared semantic attributes for interoperable traces/events | Current OpenTelemetry guidance | If Lockspire exports OTel data, semantic keys are preferable to custom per-event naming drift. [CITED: https://opentelemetry.io/docs/languages/erlang/instrumentation/] |

**Deprecated/outdated:**
- Implicit flow for general client use: RFC 9700 says clients should not use it because access tokens issued in the authorization response are exposed to leakage and replay risks. [CITED: https://datatracker.ietf.org/doc/rfc9700/]
- Treating telemetry as an audit store: this remains insufficient for durable incident reconstruction because telemetry handlers are runtime hooks, not durable state. [CITED: https://hexdocs.pm/telemetry/telemetry.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Adding `opentelemetry_semantic_conventions` would be worth the dependency if Phase 05 wants exported OTel attribute consistency beyond internal telemetry maps. [ASSUMED] | Standard Stack | Low; the phase can still ship with plain telemetry metadata keys. |

## Open Questions

1. **How should actor identity be represented in durable audit rows?**
   - What we know: current admin commands often pass coarse actor markers such as `"operator"` in attrs, while host-owned account identity lives behind the host seam. [VERIFIED: codebase grep]
   - What's unclear: whether audit needs a normalized actor tuple such as `{type, id, display}` to distinguish operator, system, and subject actions consistently. [VERIFIED: codebase grep]
   - Recommendation: settle this in planning before the migration is designed, because it affects audit schema shape and presenter helpers. [VERIFIED: codebase grep]

2. **Should Phase 05 suppress or narrow Repo SQL debug logging for sensitive tables in test/dev?**
   - What we know: the representative test slice emitted `client_secret_hash` and `token_hash` bind values in debug SQL logs. [VERIFIED: mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/live/admin/tokens_live_test.exs]
   - What's unclear: whether the project wants a Repo logging change in Phase 05 or a narrower environment-level policy documented for later release work. [VERIFIED: codebase grep]
   - Recommendation: plan one explicit task to decide and implement the Repo logging posture rather than letting it remain an incidental environment behavior. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks and test execution | ✓ | `1.19.5` | — |
| Mix | Test aliases and compilation | ✓ | `1.19.5` | — |
| PostgreSQL CLI (`psql`) | Local DB inspection and troubleshooting | ✓ | `14.17` | — |
| Test database listener on local port `5432` | ExUnit integration slice | ✗ at idle (`pg_isready` reported no response before `mix test.setup`) | — | `mix test.setup` can create/migrate storage when local Postgres is reachable through configured env vars. [VERIFIED: config/test.exs] |
| Node / npm | Context7 CLI fallback used during research only | ✓ | Node `22.14.0`, npm `11.1.0` | Web docs lookup |

**Missing dependencies with no fallback:**
- None confirmed. [VERIFIED: elixir -v] [VERIFIED: mix --version] [VERIFIED: psql --version]

**Missing dependencies with fallback:**
- `pg_isready` showed no listener at `localhost:5432` before tests, but the existing `mix test.setup` task is the project-standard bootstrap path once PostgreSQL is available. [VERIFIED: pg_isready] [VERIFIED: config/test.exs] [VERIFIED: lib/mix/tasks/lockspire.test.setup.ex]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL Sandbox and Phoenix LiveView test helpers. [VERIFIED: codebase grep] |
| Config file | `test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/live/admin/tokens_live_test.exs` [VERIFIED: mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/live/admin/tokens_live_test.exs] |
| Full suite command | `mix ci` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SECU-01 | Strict redirect, PKCE, client-auth, replay, and alg/default enforcement | integration | `mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs` | ✅ |
| SECU-02 | Telemetry and durable audit for key lifecycle transitions | unit + integration | `mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/clients_test.exs` for telemetry now; add new audit tests in Wave 0 | ⚠️ telemetry yes, durable audit ❌ Wave 0 |
| SECU-03 | Redaction in telemetry, logs, and operator surfaces | unit + LiveView | `mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/clients_live_test.exs` plus new redaction helper tests | ⚠️ partial |
| SECU-04 | Negative-path coverage for malformed, replayed, mismatched, denied, and downgrade attempts | integration + LiveView | `mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/web/token_controller_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/web/revocation_controller_test.exs` | ✅ with gaps noted below |

### Sampling Rate
- **Per task commit:** run the protocol-focused quick command above, or the narrowest affected subset if only one seam changed. [VERIFIED: mix.exs]
- **Per wave merge:** run `mix ci`. [VERIFIED: mix.exs]
- **Phase gate:** full suite green plus explicit audit/redaction assertions before `/gsd-verify-work`. [VERIFIED: mix.exs] [VERIFIED: codebase grep]

### Wave 0 Gaps
- [ ] `test/lockspire/audit/audit_writer_test.exs` — transactional append and rollback behavior for client/token/key/consent mutations. [VERIFIED: codebase grep]
- [ ] `test/lockspire/redaction/redaction_test.exs` — per-surface masking, fingerprint stability, and forbidden-key assertions. [VERIFIED: codebase grep]
- [ ] `test/lockspire/protocol/security_policy_test.exs` — downgrade/escape-hatch invariant coverage if a shared policy module is introduced. [VERIFIED: codebase grep]
- [ ] Thin controller/LiveView denial-path additions for consent denial and rendered masking where service tests do not prove delivery semantics yet. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | OAuth client authentication remains in `Lockspire.Protocol.ClientAuth` with supported method allowlists. [VERIFIED: codebase grep] |
| V3 Session Management | no | End-user login/session ownership stays with the host app seam; Lockspire should not invent its own session layer here. [VERIFIED: AGENTS.md] |
| V4 Access Control | yes | Client-bound token actions, confidential-caller checks for introspection, and admin confirmation gates are the standard controls already present. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Protocol services validate request shape, redirect equality, PKCE, scopes, and prompts before delivery logic. [VERIFIED: codebase grep] |
| V6 Cryptography | yes | Use JOSE/Plug/Erlang crypto primitives already in the stack; do not hand-roll token comparisons, signing, or hashing formats in Phase 05. [VERIFIED: codebase grep] |

### Known Threat Patterns for Phoenix + OAuth/OIDC provider flows

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Redirect URI manipulation | Tampering | Exact string comparison at authorization time; no wildcard or pattern relaxations. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/rfc9700/] |
| Authorization code replay | Replay | Single-use codes with durable `redeemed_at` checks and explicit replay reason codes. [VERIFIED: codebase grep] |
| PKCE downgrade or mismatch | Tampering | Require `S256`, reject missing verifier, reject mismatch, and avoid `plain`. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/html/rfc7636.txt] |
| Wrong-client token action | Elevation of Privilege | Bind revocation/introspection/refresh actions to authenticated client identity. [VERIFIED: codebase grep] |
| Refresh token reuse | Elevation of Privilege | Revoke the family on reuse detection and emit both telemetry and durable audit. [VERIFIED: codebase grep] |
| Sensitive data leakage in logs/admin | Information Disclosure | Shared redaction helpers, masked operator views, and explicit Repo/logging policy for sensitive tables. [VERIFIED: codebase grep] [VERIFIED: mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/live/admin/tokens_live_test.exs] |

## Sources

### Primary (HIGH confidence)
- `lib/lockspire/config.ex`, `lib/lockspire/observability.ex`, `lib/lockspire/protocol/*.ex`, `lib/lockspire/storage/ecto/repository.ex`, `lib/lockspire/web/live/admin/*` — current implementation posture. [VERIFIED: codebase grep]
- `test/lockspire/protocol/*.exs`, `test/lockspire/web/live/admin/*`, `mix.exs`, `config/test.exs` — current test and execution architecture. [VERIFIED: codebase grep]
- RFC 9700 — redirect matching and implicit-flow guidance: https://datatracker.ietf.org/doc/rfc9700/
- RFC 7636 — PKCE `S256` MTI guidance: https://datatracker.ietf.org/doc/html/rfc7636.txt
- OpenID Connect Core 1.0 — ID token signing requirements: https://openid.net/specs/openid-connect-core-1_0-18.html
- OpenID Connect Discovery 1.0 — token endpoint auth metadata and `none` prohibition for JWT client auth signing algs: https://openid.net/specs/openid-connect-discovery-1_0.html
- `Ecto.Multi` docs: https://hexdocs.pm/ecto/Ecto.Multi.html
- Telemetry docs: https://hexdocs.pm/telemetry/telemetry.html
- Phoenix LiveView test docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
- OpenTelemetry Erlang/Elixir instrumentation docs: https://opentelemetry.io/docs/languages/erlang/instrumentation/

### Secondary (MEDIUM confidence)
- Hex package metadata verified during this session via `mix hex.info` and the Hex package API for `telemetry`, `ecto_sql`, `phoenix_live_view`, `plug`, `opentelemetry_api`, and `stream_data`. [VERIFIED: mix hex.info telemetry] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info plug] [VERIFIED: mix hex.info opentelemetry_api] [VERIFIED: mix hex.info stream_data] [VERIFIED: hex.pm API telemetry] [VERIFIED: hex.pm API ecto_sql] [VERIFIED: hex.pm API phoenix_live_view] [VERIFIED: hex.pm API opentelemetry_api] [VERIFIED: hex.pm API stream_data]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing project deps and current Hex metadata align cleanly with the phase needs. [VERIFIED: mix.exs] [VERIFIED: mix hex.info telemetry] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info phoenix_live_view]
- Architecture: HIGH - the repo already exposes the exact seams Phase 05 should extend. [VERIFIED: codebase grep]
- Pitfalls: HIGH - durable audit absence, redaction drift, and Repo log exposure were all confirmed directly in code or test output. [VERIFIED: codebase grep] [VERIFIED: mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/live/admin/tokens_live_test.exs]

**Research date:** 2026-04-23
**Valid until:** 2026-05-23
