# Phase 41: FAPI 2.0 Profile Configuration - Research

**Researched:** 2024-05-18
**Domain:** Elixir/Phoenix, OAuth 2.0 / FAPI 2.0 Protocol Enforcement
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Configuration Strategy:** Durable Database Fields.
  - **ServerPolicy (Global):** Add `security_profile: :default | :fapi_2_0_security` (defaulting to `:default`).
  - **Client (Overrides):** Add `security_profile: :inherit | :default | :fapi_2_0_security` (defaulting to `:inherit`).
- **Enforcement Architecture:** Dedicated Boundary Enforcer Plug.
  - Create a centralized `Lockspire.Protocol.FAPI20EnforcerPlug` that sits early in the pipeline, immediately after client resolution.
  - If `:fapi_2_0_security`, it must enforce PAR (FAPI-02) and DPoP/mTLS (FAPI-03).

### the agent's Discretion
None explicitly stated, but the exact mechanism for resolving the client within the Plug pipeline requires architectural discretion.

### Deferred Ideas (OUT OF SCOPE)
- Strict redirect URI matching (FAPI-05) - handled in Phase 42
- Preemptive rejection of invalid cryptography (FAPI-04) - handled in Phase 42
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FAPI-01 | Provide a single `security_profile: :fapi_2_0_security` option. | Schema additions to `ServerPolicy` and `Client` mapped successfully. |
| FAPI-02 | Reject requests that do not use PAR when the profile is active. | Checked via `request_uri` presence at the Plug boundary. |
| FAPI-03 | Reject token requests and `userinfo` access without DPoP (or mTLS) when the profile is active. | Checked via `dpop` header presence at the Plug boundary. |
</phase_requirements>

## Summary

Phase 41 introduces strict FAPI 2.0 enforcement based on durable configuration rather than static application config. This requires extending the `Lockspire.Domain.ServerPolicy` and `Lockspire.Domain.Client` Ecto schemas with a new `security_profile` field. The enforcement mechanism is a new Phoenix Plug (`Lockspire.Protocol.FAPI20EnforcerPlug`) designed to fail-fast at the API boundary before hitting core protocol logic.

**Primary recommendation:** Introduce a lightweight client resolution plug that runs immediately *before* `FAPI20EnforcerPlug` on specific routes, injecting `conn.assigns.client` and `conn.assigns.server_policy`, to avoid the plug duplicating complex parameter parsing logic, or have the Enforcer plug independently fetch the client. Special handling is required for `/userinfo` where the client is embedded in the token.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Configuration Storage | Database / Storage | — | `security_profile` state must live in durable Ecto schemas alongside `par_policy` and `dpop_policy`. |
| Protocol Enforcement | API / Backend | — | FAPI checks belong at the Phoenix Plug pipeline boundary (early request rejection). |
| Admin Configuration UI | Frontend Server (SSR) | — | Exposing `security_profile` options via Phoenix LiveView (`Admin.ClientsLive` and `Admin.PoliciesLive`). |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | (existing) | Web layer / Plugs | Native framework for Lockspire's host interfaces. |
| Ecto | (existing) | Database schema & migrations | Durable storage for ServerPolicy and Client tables. |

## Architecture Patterns

### Recommended Project Structure
```
lib/lockspire/
├── domain/
│   ├── client.ex                # Add :security_profile
│   └── server_policy.ex         # Add :security_profile
├── protocol/
│   └── fapi20_enforcer_plug.ex  # NEW: Plug boundary enforcer
└── web/
    ├── controllers/             # Wire up the new Plug
    └── live/admin/
        ├── clients_live/        # Update forms
        └── policies_live/
            └── security_profile.ex # NEW: Global profile manager
priv/repo/migrations/
└── [timestamp]_add_security_profile_fields.exs # NEW
```

### Pattern 1: Protocol Enforcer Plug
**What:** A standard Phoenix Plug placed in the controllers or router to intercept non-compliant requests before protocol execution.
**When to use:** To enforce FAPI 2.0 boundary rules (PAR presence, DPoP presence) without polluting inner domain modules (`TokenExchange`, `AuthorizationRequest`).
**Example:**
```elixir
defmodule Lockspire.Protocol.FAPI20EnforcerPlug do
  import Plug.Conn
  alias Lockspire.Protocol.FAPI20EnforcerPlug.ErrorResponse

  def init(opts), do: opts

  def call(conn, _opts) do
    # Assuming client and server_policy are resolved and assigned
    profile = resolve_effective_profile(conn.assigns.client, conn.assigns.server_policy)
    
    if profile == :fapi_2_0_security do
      conn
      |> enforce_par()
      |> enforce_dpop()
    else
      conn
    end
  end
end
```

## Anti-Patterns to Avoid
- **Scattering FAPI Checks:** Do not place `if client.security_profile == :fapi_2_0_security` inside `TokenExchange.exchange/1` or `AuthorizationRequest.validate/1`. Keep it at the Plug boundary as requested by the Phase constraints.

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None found. Existing DB state does not cache FAPI compliance. | Add `security_profile` column to `clients` and `server_policies`. |
| Live service config | None — verified via grep. | None |
| OS-registered state | None — verified via grep. | None |
| Secrets/env vars | None — verified via grep. | None |
| Build artifacts | None — verified via grep. | None |

## Common Pitfalls

### Pitfall 1: Client Resolution Coupling
**What goes wrong:** The context states the plug should run "immediately after client resolution." However, Lockspire currently resolves clients *inside* its protocol domains (e.g., `ClientAuth.authenticate/3`), not as an upstream Plug.
**Why it happens:** The architecture uses thin controllers that delegate directly to protocol modules, skipping Phoenix pipelines for API routes.
**How to avoid:** Either:
1. Create a `ClientResolutionPlug` that runs before `FAPI20EnforcerPlug` in the controllers.
2. Have `FAPI20EnforcerPlug` perform a fast read-only lookup of the client using `conn.params["client_id"]` (for `/authorize` and `/token`).

### Pitfall 2: Userinfo Endpoint Client Extraction
**What goes wrong:** The `/userinfo` endpoint requires enforcing DPoP for FAPI 2.0 clients, but the request does not contain a `client_id` in the query or body.
**Why it happens:** The client ID is embedded in the access token (Bearer or DPoP), meaning it can only be resolved *after* the token is parsed.
**How to avoid:** `FAPI20EnforcerPlug` must either parse the token to identify the client, OR the userinfo enforcement must be deferred slightly deeper into `Userinfo.fetch_claims` where the token is already decoded, despite the general rule of doing it at the Plug boundary.

## Code Examples

### Migration Pattern
```elixir
defmodule Lockspire.TestRepo.Migrations.AddSecurityProfileFields do
  use Ecto.Migration

  def change do
    alter table(:lockspire_server_policies) do
      add :security_profile, :text, null: false, default: "default"
    end

    alter table(:lockspire_clients) do
      add :security_profile, :text, null: false, default: "inherit"
    end
  end
end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test --stale` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FAPI-01 | Configures schema options | unit | `mix test test/lockspire/domain/client_test.exs` | ❌ Wave 0 |
| FAPI-02 | Plug rejects non-PAR | unit | `mix test test/lockspire/protocol/fapi20_enforcer_plug_test.exs` | ❌ Wave 0 |
| FAPI-03 | Plug rejects non-DPoP | unit | `mix test test/lockspire/protocol/fapi20_enforcer_plug_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/lockspire/protocol/fapi20_enforcer_plug_test.exs` — covers FAPI-02, FAPI-03
- [ ] Ensure database migration test helpers support the new `security_profile` field.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | FAPI 2.0 Strict Profile / DPoP |
| V3 Session Management | yes | PAR enforcement / DPoP Binding |
| V4 Access Control | yes | Client-level security profile |
| V5 Input Validation | yes | Boundary Plug parameter parsing |

### Known Threat Patterns for Elixir/Phoenix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Token Replay | Spoofing | Enforce DPoP headers unconditionally via Plug |
| Parameter Injection | Tampering | Reject non-PAR requests, ignoring raw URL parameters |

## Sources

### Primary (HIGH confidence)
- Context file (`41-CONTEXT.md`) - Verified architecture directives
- `lib/lockspire/domain/server_policy.ex` - Verified schema structure
- `lib/lockspire/web/router.ex` - Verified lack of existing API Plug pipelines

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Ecto and Plug are native.
- Architecture: MEDIUM - The mismatch between the "immediately after client resolution" directive and the actual lack of a client resolution plug means the planner must decide how to bridge the gap.
- Pitfalls: HIGH - Identified critical architectural boundary issues.

**Research date:** 2024-05-18
**Valid until:** 2024-06-18
