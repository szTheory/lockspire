<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Add complete and accurate `@spec` definitions to all public modules (`Lockspire`, `Lockspire.Admin`, `Lockspire.Clients`, `Lockspire.Config`).
- Fix 4 existing Dialyzer errors (in `dpop.ex` and `backchannel_logout_delivery_worker.ex`).
- Lock the signatures for `Lockspire.Host.AccountResolver` by replacing `term()` and `map()` with a formal `%Lockspire.Host.Context{}` struct and union types.
- Validate and finalize all options loaded by `Lockspire.Config`.

### the agent's Discretion
- Approach to defining the strict types for the connection/socket (e.g., `Plug.Conn.t() | Phoenix.LiveView.Socket.t() | term()`).
- Documenting config accessors to avoid string vs atom footguns.

### Deferred Ideas (OUT OF SCOPE)
- No config key renames are required; current keys (`:repo`, `:account_resolver`, `:issuer`, `:mount_path`, etc.) are considered idiomatic and final.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STAB-01 | Finalize and strictly type the public API contract | Supported by identifying missing specs in `Lockspire.Admin`, identifying dialyzer errors, and designing `%Lockspire.Host.Context{}`. |
</phase_requirements>

# Phase 44: API Stabilization & Typespecs - Research

**Researched:** 2024-05-04
**Domain:** Elixir Typespecs, Dialyzer, Public API Design
**Confidence:** HIGH

## Summary

The goal of Phase 44 is to stabilize the public API surface of Lockspire in preparation for a 1.0 GA release. This entails ensuring 100% accurate `@spec` definitions on all public-facing modules, fixing existing Dialyzer warnings, and locking down the host integration callbacks.

Currently, the primary facade `Lockspire.Admin` delegates completely lack `@spec` definitions, while `Lockspire` itself has incomplete coverage. Furthermore, the `Lockspire.Host.AccountResolver` callbacks rely heavily on `term()` and `map()`, which harms developer experience (DX) and weakens Dialyzer checks. We will introduce a `%Lockspire.Host.Context{}` struct to resolve this.

**Primary recommendation:** Define explicit `@spec` for all `defdelegate` functions in `Lockspire.Admin`, resolve the 4 Dialyzer pattern matching errors, and introduce `%Lockspire.Host.Context{}` for all host callbacks.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public API Facades | API / Backend | — | `Lockspire`, `Lockspire.Admin`, and `Lockspire.Clients` act as the entry points to the domain layer. |
| Host Integration Callbacks | API / Backend | — | `Lockspire.Host.AccountResolver` defines the contract the host application must implement. |
| Configuration Validation | API / Backend | — | `Lockspire.Config` orchestrates environment-specific startup state. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Dialyzer | (Current) | Static analysis | Native to Elixir, enforces the `@spec` contracts we are stabilizing. |

## Architecture Patterns

### Recommended Project Structure
N/A - This phase modifies existing files within the `lib/lockspire` directory without changing the project structure.

### Pattern 1: Explicit Facade Typespecs
**What:** When using `defdelegate`, redefine the `@spec` on the facade module.
**When to use:** On public boundaries like `Lockspire.Admin`.
**Example:**
```elixir
@spec list_clients(keyword()) :: [Lockspire.Domain.Client.t()]
defdelegate list_clients(opts \\ []), to: Clients
```

### Pattern 2: Explicit Context Structs
**What:** Replacing untyped `map()` parameters with explicit structs.
**When to use:** In host callbacks to provide auto-complete and strict typing.
**Example:**
```elixir
defmodule Lockspire.Host.Context do
  defstruct [:return_to, :client_id, :scopes, :interaction_type]
  @type t :: %__MODULE__{
    return_to: String.t() | nil,
    client_id: String.t() | nil,
    scopes: [String.t()] | nil,
    interaction_type: :login | :consent | :logout | nil
  }
end
```

### Anti-Patterns to Avoid
- **Untyped Callbacks:** Using `term()` or `map()` in `@callback` definitions forces host applications to guess the structure and disables Dialyzer's ability to verify data flow.
- **Missing Facade Specs:** Omitting `@spec` on `defdelegate` means ElixirLS and ExDoc cannot show the signature to the user without them diving into internal modules.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Connection typing | Custom union types | `Plug.Conn.t() | Phoenix.LiveView.Socket.t()` | Standard ecosystem types that hosts are already using. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None - verified by domain analysis | none |
| Live service config | None - verified by domain analysis | none |
| OS-registered state | None - verified by domain analysis | none |
| Secrets/env vars | None - verified by domain analysis | none |
| Build artifacts | None - verified by domain analysis | none |

## Common Pitfalls

### Pitfall 1: Breaking Host Implementations
**What goes wrong:** Existing host applications pattern-matching on `%{} ` in `AccountResolver` callbacks will fail when passed a struct.
**Why it happens:** `%Lockspire.Host.Context{}` does not match `%{} ` unless explicitly handled or if the host implementation relies on specific map functions.
**How to avoid:** Clearly document this breaking change in the CHANGELOG.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `context :: map()` | `context :: Lockspire.Host.Context.t()` | Phase 44 | Drastically improved DX and type safety for host apps. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No new config keys are required, only stabilization of existing ones. | User Constraints | We miss typing a recently added configuration option. |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix dialyzer && mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STAB-01 | Dialyzer passes cleanly | static | `mix dialyzer` | ✅ Wave 0 |
| STAB-01 | Context struct is passed to callbacks | unit | `mix test test/lockspire/host/account_resolver_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix dialyzer`
- **Per wave merge:** `mix dialyzer && mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `lib/lockspire/host/context.ex` — New struct module needed.
- [ ] Tests need to be updated to pass `%Lockspire.Host.Context{}` instead of maps to callbacks.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Context strict typing prevents malformed auth requests. |
| V3 Session Management | yes | Context strict typing. |
| V4 Access Control | yes | Typed callbacks. |
| V5 Input Validation | yes | Dialyzer statically validates internal type boundaries. |
| V6 Cryptography | no | — |

## Sources

### Primary (HIGH confidence)
- `mix dialyzer` output - verified 4 errors in `dpop.ex` and `backchannel_logout_delivery_worker.ex`.
- Codebase inspection - verified missing `@spec` attributes in `Lockspire.Admin`.
- `44-STRATEGY.md` - Verified the plan for `Lockspire.Host.Context`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - native Elixir tooling.
- Architecture: HIGH - well-understood Elixir patterns.
- Pitfalls: HIGH - breaking change on map to struct is a known Elixir property.

**Research date:** 2024-05-04
**Valid until:** Next major version change.
