# Phase 45: Observability & Operator Seams - Research

**Researched:** 2024-05-15
**Domain:** Observability, Telemetry, Operator UI
**Confidence:** HIGH

## Summary

The goal of Phase 45 is to ensure telemetry and operator workflows are consistent and reliable across the Lockspire domain. This research identifies gaps in telemetry emission, missing Operator LiveView panels, and missing documentation.

**Primary recommendation:** Add `Observability.emit/4` calls to the `DeviceAuthorization` and `DeviceVerification` lifecycles, build missing LiveView operator panels for Device Authorizations, Interactions, and Logout Deliveries, and create a user-facing `docs/telemetry.md` describing all emitted events and their specific metadata payloads.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Telemetry Emission | API / Backend | — | Domain and protocol layers must emit standard `:telemetry` events on core actions. |
| Operator Panels | Frontend Server (SSR) | API / Backend | Admin UIs are rendered via Phoenix LiveView and interface with backend contexts. |
| Documentation | Static | — | Configuration and telemetry guides belong in the standard `docs/` Markdown suite. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:telemetry` | ~> 1.0 | Event emission | The established standard for event emission in the Elixir ecosystem and Lockspire codebase. |
| `Phoenix.LiveView` | ~> 0.20 | Operator UI | Existing Lockspire operator panels are built on LiveView. |

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STAB-03 | Telemetry event consistency | Identified gaps in `DeviceAuthorization` and `DeviceVerification` telemetry. |
| STAB-04 | Operator workflows & seams | Identified missing LiveViews for Interactions, Device Authorizations, and Logout. |

## Gap Analysis: Telemetry

Which critical domain actions are NOT currently emitting standardized telemetry events?

| Domain Context | Emits Telemetry? | Files Verified |
|----------------|------------------|----------------|
| Clients | Yes | `admin/clients.ex` |
| Initial Access Tokens | Yes | `admin/initial_access_tokens.ex`, `protocol/initial_access_token.ex` |
| Dynamic Registration | Yes | `protocol/registration.ex`, `protocol/registration_management.ex` |
| Authorization (Flows) | Yes | `protocol/authorization_flow.ex`, `protocol/authorization_request.ex` |
| Tokens | Yes | `admin/tokens.ex`, `protocol/token_exchange.ex` |
| Consents | Yes | `admin/consents.ex` |
| Keys | Yes | `admin/keys.ex` |
| **Device Authorization** | **NO** | `protocol/device_authorization.ex`, `protocol/device_verification.ex` |

**Action Required:**
- `Lockspire.Protocol.DeviceAuthorization` needs telemetry for device code/user code creation.
- `Lockspire.Protocol.DeviceVerification` needs telemetry for `approve_device_authorization/3` and `deny_device_authorization/3` actions.

## Gap Analysis: Operator Panels

What core data and state are NOT currently reflected in Operator LiveView panels?

| Core Data Concept | Existing LiveView Panel | Missing / Needed |
|-------------------|-------------------------|------------------|
| `Client` | `clients_live` | — |
| `ConsentGrant` | `consents_live` | — |
| `InitialAccessToken`| `iat_live` | — |
| `ServerPolicy` | `policies_live` | — |
| `SigningKey` | `keys_live` | — |
| `Token` | `tokens_live` | — |
| **`DeviceAuthorizationState`** | **None** | `device_authorizations_live` to view active/pending device flow requests and their expiration. |
| **`Interaction`** | **None** | `interactions_live` to view active user login/consent interactions and debugging states. |
| **`LogoutDelivery` / `LogoutEvent`**| **None** | `logout_deliveries_live` to track backchannel logout propagation state and history. |

## Gap Analysis: Documentation

Where is the telemetry documentation currently located, and what is its structure?

Currently, there is **no user-facing telemetry documentation** in the `docs/` directory.

The only existing file related to telemetry design is an internal AI prompt/guideline located at `prompts/lockspire-telemetry-audit-and-introspection.md`. Its structure contains high-level design constraints:
- Observability stance
- Telemetry event families (high-level bullet list of event ideas)
- Audit trail requirements
- Introspection product goals
- Logging rules
- Metrics expectations
- Operator payoff

**Action Required:**
- Create a formal `docs/telemetry.md` file that exhaustively documents the actual `[:lockspire, entity, action]` events emitted by `Lockspire.Observability.emit/4`. It should detail the measurements (e.g., `%{count: 1}`) and the metadata maps available to operators for dashboards.

## Common Pitfalls

### Pitfall 1: Silent Failures in New Flows
**What goes wrong:** Device Authorization flows fail silently or have high drop-off rates, but operators cannot debug them due to missing metrics.
**Why it happens:** Telemetry was skipped in new protocol module implementations like `DeviceVerification`.
**How to avoid:** Ensure every critical state transition (`pending` -> `approved` -> `consumed` -> `issued`) has an accompanying `Observability.emit` event.

### Pitfall 2: Telemetry Drift
**What goes wrong:** Documentation states an event is emitted, but the codebase emits a different name or payload structure.
**Why it happens:** Telemetry events use untyped maps and lists. Refactoring renames the event but not the docs.
**How to avoid:** Create a centralized `docs/telemetry.md` and keep it updated in tandem with `Lockspire.Observability` calls. Verify telemetry payloads in tests using `:telemetry.attach`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STAB-03 | Device Auth telemetry emitted on transitions | unit | `mix test test/lockspire/protocol/device_verification_test.exs` | ❌ Wave 0 |
| STAB-04 | Operator LiveViews accessible | integration | `mix test test/lockspire/web/live/admin/interactions_live_test.exs` | ❌ Wave 0 |

## Sources

### Primary (HIGH confidence)
- Code Audit (`grep_search`): Verified missing `Observability.emit` calls in `lib/lockspire/protocol/device_authorization.ex` and `lib/lockspire/protocol/device_verification.ex`.
- Code Audit (`glob`): Verified missing LiveView files for interactions, device authorizations, and logouts in `lib/lockspire/web/live/admin/`.
- File System (`grep_search`/`find`): Verified `docs/` contains no telemetry guides and that `prompts/lockspire-telemetry-audit-and-introspection.md` is the only source of telemetry guidelines.
