# Architecture Research

**Domain:** Embedded OAuth/OIDC authorization server library for Phoenix/Elixir
**Researched:** 2026-04-22
**Confidence:** HIGH

## Standard Architecture

### System Overview

```text
┌───────────────────────────────────────────────────────────────┐
│                    Host Phoenix Application                   │
├───────────────────────────────────────────────────────────────┤
│  Router mounts Lockspire endpoints and LiveView surfaces      │
│  Host owns accounts, login UX, branding, layouts, policy      │
├───────────────────────────────────────────────────────────────┤
│                     Lockspire Web Layer                       │
│  /authorize  /token  /userinfo  /revoke  /introspect         │
│  discovery   jwks    admin      consent     installers        │
├───────────────────────────────────────────────────────────────┤
│                   Lockspire Protocol Core                     │
│  client validation  interaction flow  token issuance          │
│  consent logic       OIDC metadata   rotation/revocation      │
├───────────────────────────────────────────────────────────────┤
│                 Storage + Adapter Boundaries                  │
│  clients  consents  codes  refresh families  keys  audit      │
│  default Ecto/Postgres adapters with explicit behaviours      │
├───────────────────────────────────────────────────────────────┤
│               Runtime Services and Observability              │
│  Oban jobs  Telemetry/OpenTelemetry  PubSub hints  caches     │
└───────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Protocol core | OAuth/OIDC validation, authorization state machine, token rules, issuer semantics | Pure Elixir modules with clear service boundaries and transaction-aware orchestration |
| Web layer | Endpoint adapters, controller/live routing, error surfaces, generated host modules | Phoenix controllers, plugs, LiveViews, and function components |
| Host seam | Resolve accounts, claims, login redirection, consent handoff | Behaviour modules implemented by the host app |
| Storage layer | Durable truth for clients, grants, keys, and token records | Ecto schemas, changesets, repos, and adapter behaviours |
| Runtime services | Scheduled rotation, cleanup, redaction-safe telemetry, cache invalidation hints | Oban workers, Telemetry handlers, PubSub, bounded ETS caches |

## Recommended Project Structure

```text
lib/
├── lockspire.ex                       # Narrow public API
├── lockspire/
│   ├── application.ex                # Supervisor and runtime boot
│   ├── protocol/                     # OAuth/OIDC core services and validators
│   ├── domain/                       # Clients, consents, tokens, keys, interactions
│   ├── storage/                      # Behaviours + Ecto default adapters
│   ├── web/                          # Controllers, plugs, LiveViews, components
│   ├── generators/                   # Install/update generators and templates
│   ├── telemetry/                    # Event emission and audit integration
│   └── support/                      # Shared helpers, config, redaction
priv/
├── repo/migrations/                  # Library-owned storage primitives
├── templates/                        # Generator templates copied into host apps
└── gettext/                          # If UI copy becomes localized later
test/
├── integration/                      # End-to-end flows against host fixtures
├── lockspire/                        # Unit and service tests
└── support/                          # Test helpers, fixtures, generated app harness
```

### Structure Rationale

- **`protocol/`:** keeps OAuth/OIDC rules isolated from Phoenix delivery details.
- **`storage/`:** makes the Ecto default explicit while preserving future adapter seams.
- **`web/`:** contains host-facing delivery code and operator surfaces without leaking into the core.
- **`generators/`:** treats install DX as a first-class product area rather than scattered scripts.
- **`telemetry/`:** makes observability and audit contracts visible and testable.

## Architectural Patterns

### Pattern 1: Protocol Core Behind Explicit Services

**What:** represent authorization, token, consent, and key operations as explicit service modules with small inputs and tuple-based returns.
**When to use:** for every protocol action that must be testable outside Phoenix request handling.
**Trade-offs:** adds more modules up front, but makes negative-path testing and audits much easier.

**Example:**
```elixir
with {:ok, client} <- Clients.fetch_authorize_client(params),
     {:ok, interaction} <- Authorize.start_interaction(client, params, ctx),
     {:ok, result} <- Authorize.finish(interaction, account_ctx) do
  {:ok, result}
end
```

### Pattern 2: Narrow Host-Owned Behaviour Seams

**What:** the host app implements explicit behaviours for account lookup, claims, login redirect decisions, and optionally policy hooks.
**When to use:** whenever Lockspire needs user truth or product policy that it should not own.
**Trade-offs:** constrains extension points, but that constraint is a strength because it prevents Lockspire from absorbing the host's auth model.

**Example:**
```elixir
@callback resolve_current_account(conn_or_socket, context) ::
  {:ok, account, claims_context} | {:redirect, path}
```

### Pattern 3: Durable Truth + Bounded Runtime Helpers

**What:** keep critical state in Postgres while using ETS/PubSub/Oban only for bounded acceleration and coordination.
**When to use:** token lineage, key state, revocation, and audit should always be reconstructible from durable records.
**Trade-offs:** slightly more persistence work than a mostly in-memory design, but far better operability and recovery characteristics.

## Data Flow

### Request Flow

```text
Third-party client
    ↓
Host router mount
    ↓
Lockspire controller / plug
    ↓
Protocol service
    ↓
Storage adapters + host seam
    ↓
Result tuple
    ↓
Redirect / token response / LiveView handoff
```

### State Management

```text
Postgres durable records
    ↓
Protocol services
    ↓
Telemetry + audit events
    ↓
Admin/consent LiveViews and operator workflows
```

### Key Data Flows

1. **Authorization flow:** client request enters Lockspire, host login and consent are resolved through explicit seams, and the protocol core returns a redirect or code issuance result.
2. **Token lifecycle flow:** code exchange or refresh request creates durable token records, emits audit/telemetry events, and updates admin-visible lineage.
3. **Operator flow:** admin actions mutate clients, grants, or key state through service modules so UI and API paths share the same safeguards.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k integrators / low-volume early adoption | Single app node, Postgres durable store, simple Oban queues, minimal caching |
| 1k-100k integrators / sustained partner usage | Add bounded caches, explicit revocation/key invalidation hints, heavier audit retention, background maintenance jobs |
| 100k+ or enterprise-heavy usage | Introduce stronger tenant partitioning, more deliberate observability pipelines, and evaluate specialized storage seams only where proven necessary |

### Scaling Priorities

1. **First bottleneck:** token and audit write paths — solve with schema design, indexing, and Oban-backed maintenance before inventing new infrastructure.
2. **Second bottleneck:** operator visibility and incident workflows — solve with strong filters, pagination, and clear lineage models rather than ad hoc shell tooling.

## Anti-Patterns

### Anti-Pattern 1: Web Handlers Owning Protocol Rules

**What people do:** bury validation and token logic directly in controllers or plugs.
**Why it's wrong:** makes the security-critical flow hard to test and impossible to reason about without HTTP context.
**Do this instead:** keep Phoenix delivery thin and route everything through explicit protocol services.

### Anti-Pattern 2: Library Owns the Host's Authentication System

**What people do:** let the provider library absorb user schemas, login UX, or session policy.
**Why it's wrong:** destroys interoperability with real Phoenix apps and turns the library into a competing auth framework.
**Do this instead:** keep the host seam narrow and explicit, and generate host-owned glue code.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Host app auth system | Behaviour-based seam | Must work with Sigra, `phx.gen.auth`, Ash Authentication, Pow, or custom systems without biasing the public API too hard toward one host. |
| PostgreSQL | Ecto repo + migrations | Source of truth for durable protocol and operator state. |
| OpenTelemetry backend | `:telemetry` plus bridge instrumentation | Keep emission native and bridge traces where operators want them. |
| Job execution | Oban workers | Use for key lifecycle and cleanup work that must survive restarts. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `protocol ↔ storage` | Behaviour contracts and explicit service calls | Keeps protocol logic portable and easier to test. |
| `protocol ↔ host seam` | Behaviour callbacks | The most important product boundary. |
| `web ↔ protocol` | Tuple-returning services | Avoids duplicate validation paths across UI and API delivery. |
| `telemetry ↔ operator UI` | Events and queryable records | Operator visibility should reflect the same truth emitted by the core. |

## Sources

- `lockspire-idea.md`
- `prompts/Embedding an OAuth-OIDC server in Phoenix the case for a new Elixir library.md`
- `prompts/lockspire-oauth-oidc-implementation-playbook.md`
- `prompts/lockspire-host-app-integration-seam.md`
- `prompts/lockspire-operator-admin-ia-and-workflows.md`
- `prompts/lockspire-security-posture-and-threat-model.md`

---
*Architecture research for: Embedded OAuth/OIDC authorization server library for Phoenix/Elixir*
*Researched: 2026-04-22*
