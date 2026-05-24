# Phase 28: Operator Admin UI and Telemetry - Research

**Researched:** 2024-04-26
**Domain:** Phoenix LiveView (Admin UI), Telemetry, OAuth2 DCR Operator Workflows
**Confidence:** HIGH

## Summary

Phase 28 introduces the operator-facing admin UI for Dynamic Client Registration (DCR), Initial Access Tokens (IAT), and Client Provenance/Rotation. It also completes the observability surface by firing telemetry events across the full DCR and IAT lifecycles.

**Primary recommendation:** Use an embedded `Ecto.Schema` for the DCR policy LiveView form to handle complex JSONB field validation, and strictly rely on transient LiveView `assigns` (with explicit clearing actions) for "copy-once" secret display (IATs and rotated RATs) to prevent sensitive data lingering in memory or session cookies.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **DCR Policy Configuration UX:** Use a dedicated UI-only `Ecto.Schema` (Form Object) for type casting, atom-keyed safety, and clear validation boundaries.
- **"Copy-Once" Secret Display:** Use a Dedicated Modal relying strictly on LiveView assigns with an explicit "I have copied this" button that actively clears the assign (`assign(socket, iat_secret: nil)`).
- **Client Provenance & RAT Rotation UX:** Unified Client Index with a Faceted Filter (`:operator_created` vs `:self_registered`). Rotation occurs on the Client Detail page via an explicit Confirmation Modal using the identical "Copy-Once" mechanism designed for IAT minting.
- **Telemetry Emission:** Adhere strictly to the existing `Lockspire.Observability` patterns, emitting at the domain/protocol boundary completely decoupled from the LiveView UI layer.

### the agent's Discretion
None explicitly declared in discussion log.

### Deferred Ideas (OUT OF SCOPE)
None explicitly declared in discussion log.
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| DCR Policy Management | Frontend Server (SSR) | API / Backend | LiveView form leverages embedded `Ecto.Schema` for validation before calling core `Lockspire.Admin.ServerPolicy` API. |
| IAT Lifecycle & Copy-Once | Frontend Server (SSR) | API / Backend | Transient secret display belongs strictly in LiveView socket memory; minting/revocation is persisted by the API layer. |
| Provenance Filtering & RAT Rotation | Frontend Server (SSR) | API / Backend | UI filter and explicit confirmation modal live in LiveView; actual token generation and swap happens securely in the API domain. |
| DCR/IAT Lifecycle Telemetry | API / Backend | — | Fired at the protocol and admin boundaries via `Lockspire.Observability` to guarantee emission regardless of entry vector (HTTP vs UI). |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | ~> 0.20 | Admin UI interactions | Core framework for the project; handles real-time UI without custom JS. |
| Ecto | ~> 3.11 | DCR Policy Form Schema | Provides robust casting, validation, and error translation for complex JSON-backed maps. |
| :telemetry | ~> 1.2 | Event emission | Erlang standard for tracing and metrics, already adopted in `Lockspire.Observability`. |

**Version verification:** (Verified locally via project `mix.exs` and lockfile context)
Versions are inherited from the existing Lockspire ecosystem setup.

## Architecture Patterns

### Pattern 1: Embedded Ecto.Schema for Complex LiveView Forms
**What:** Wrapping opaque JSONB data in a schemaless Ecto changeset to leverage `Phoenix.HTML` and `to_form/1` affordances safely.
**When to use:** Managing configuration like DCR policies that consist of multiple lists, booleans, and nested values.
**Example:**
```elixir
defmodule Lockspire.Web.Live.Admin.PoliciesLive.Dcr.PolicyForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :registration_policy, Ecto.Enum, values: [:disabled, :initial_access_token, :open]
    field :dcr_allowed_scopes, {:array, :string}
    # ... other DCR fields
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:registration_policy, :dcr_allowed_scopes])
    |> validate_required([:registration_policy])
  end
end
```

### Pattern 2: "Copy-Once" Reveal with Explicit Acknowledgment
**What:** Rendering a minted secret in a conditional block driven by socket assigns, accompanied by a button that clears the state.
**When to use:** Minting Initial Access Tokens (IAT) or rotating Registration Access Tokens (RAT).
**Example:**
```elixir
# LiveView controller
def handle_event("clear_secret", _params, socket) do
  {:noreply, assign(socket, revealed_secret: nil)}
end

# HEEx Template
<div :if={@revealed_secret} class="lockspire-admin-secret-reveal">
  <h3>Token Generated</h3>
  <p>Copy this now; it will not be shown again:</p>
  <code>{@revealed_secret}</code>
  <button phx-click="clear_secret">I have copied this</button>
</div>
```

### Anti-Patterns to Avoid
- **Anti-pattern:** Using `put_flash` for sensitive secrets.
  - **Why:** Flash messages are typically encoded into session cookies. Secrets must never leave server memory or strictly controlled secure channels. Use transient LiveView assigns.
- **Anti-pattern:** Emitting telemetry from inside LiveView controllers.
  - **Why:** If telemetry is bound to the UI, identical operations invoked via HTTP APIs will be silent. Emit from the core domain (e.g., `Lockspire.Protocol.*` or `Lockspire.Admin.*`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Form Validation | Raw map pattern matching | `Ecto.Changeset` | LiveView integrates seamlessly with `Ecto.Changeset` to show field-level errors; manual map validation lacks this UI interoperability. |
| Event Tracking | Custom PubSub/Logger | `:telemetry` | Project already uses standard Erlang `:telemetry` which integrates cleanly with ExUnit testing (`:telemetry.attach_many/4`). |

## Common Pitfalls

### Pitfall 1: Retaining Secrets in Memory
**What goes wrong:** A rotated token or newly minted IAT remains visible on the page or in the socket state indefinitely.
**Why it happens:** The LiveView assign is not actively cleared after the operator acknowledges it.
**How to avoid:** Force the operator to click an "I have copied this" button that sends a `clear_secret` event, aggressively setting the assign back to `nil`.

### Pitfall 2: Silent API Telemetry Gaps
**What goes wrong:** Metrics show DCR registrations occurring but lack corresponding token usage or rotation events.
**Why it happens:** The telemetry event for rotation was incorrectly placed in the LiveView layer instead of the domain boundary.
**How to avoid:** Ensure all `[:lockspire, :dcr, ...]` and `[:lockspire, :iat, ...]` events flow through `Lockspire.Observability.emit/3` within the core context modules.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test {file_path}` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-1 | DCR Policy Form mirrors PAR shape | unit | `mix test test/lockspire/web/live/admin/policies_live/dcr_test.exs` | ❌ Wave 0 |
| REQ-2 | IAT Minting with copy-once UI | integration | `mix test test/lockspire/web/live/admin/iat_live_test.exs` | ❌ Wave 0 |
| REQ-3 | Client Provenance filter & RAT rotate UI | integration | `mix test test/lockspire/web/live/admin/clients_live_test.exs` | ✅ Existing (needs modification) |
| REQ-4 | Telemetry emission across full DCR/IAT lifecycle | e2e | `mix test test/integration/phase28_e2e_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test {file_path}`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/lockspire/web/live/admin/policies_live/dcr_test.exs` — covers REQ-1
- [ ] `test/lockspire/web/live/admin/iat_live_test.exs` — covers REQ-2
- [ ] `test/integration/phase28_e2e_test.exs` — covers REQ-4

## Sources

### Primary (HIGH confidence)
- `28-PATTERNS.md` - Verified analog mapping for `policies_live/dcr.ex` and `iat_live/*` against `par.ex` and `clients_live/index.ex`.
- `28-DISCUSSION-LOG.md` - Confirmed architectural decisions regarding UI Ecto schemas, strict transient memory bounds for secrets, unified provenence indexing, and domain-layer telemetry.
- Project Source - Inspected `clients_live/show.ex` for existing rotation pattern and `server_policy.ex` for data struct shapes.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Dictated by the existing, mature Phoenix LiveView ecosystem of Lockspire.
- Architecture: HIGH - Derived directly from the explicitly negotiated discussion log decisions and pattern analogs.
- Pitfalls: HIGH - Documented standard security practices around session state and observability patterns.

**Research date:** 2024-04-26
**Valid until:** 2024-05-26