# Phase 55: RAR Protocol Intake - Research

**Researched:** 2026-05-06
**Domain:** Rich Authorization Requests (RFC 9396)
**Confidence:** HIGH

## Summary

This research phase defines the intake mechanism for Rich Authorization Requests (RAR) as specified in RFC 9396. The goal is to enable Lockspire to accept, parse, and persist the `authorization_details` parameter within the Pushed Authorization Request (PAR) and direct Authorization pipelines. 

RAR is a JSON-based alternative to the space-delimited `scope` parameter, allowing for complex, structured authorization data (e.g., payment details, medical record access with specific filters). Phase 55 focuses on the "Protocol Intake" — ensuring the bits move from the wire into durable storage (PAR/Interaction) — while subsequent phases will handle host-defined validation and introspection.

**Primary recommendation:** Extend the core authorization models (`AuthorizationRequest.Validated`, `PushedAuthorizationRequest`, and `Interaction`) to support an `authorization_details` field stored as a JSON array of maps, and implement a URI length safeguard for direct GET requests.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| RAR Parameter Parsing | API / Backend | — | Handled by `AuthorizationRequest` protocol logic. |
| PAR Persistence | Database / Storage | API / Backend | RAR details must be durably stored in `lockspire_pushed_authorization_requests`. |
| Interaction State | Database / Storage | API / Backend | RAR details must be carried forward into the `lockspire_interactions` record for consent. |
| URI Length Protection | API / Backend | — | Security check to nudge large RAR payloads toward PAR. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `jason` | 1.4.4 | JSON Parsing | Standard Elixir JSON library, used for `authorization_details` decoding. [VERIFIED: mix.lock] |
| `ecto_sql` | 3.13.5 | Data Persistence | Handles storage of maps/arrays in PostgreSQL. [VERIFIED: mix.lock] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|--------------|
| `phoenix` | 1.8.5 | Web Routing | Handles inbound `/authorize` and `/par` params. [VERIFIED: mix.lock] |

## Architecture Patterns

### Recommended Project Structure
```
lib/lockspire/
├── protocol/
│   ├── authorization_request.ex     # Update Validated struct and parsing logic
│   └── pushed_authorization_request.ex # Pass RAR to storage
├── domain/
│   ├── pushed_authorization_request.ex # Add field to domain struct
│   └── interaction.ex               # Add field to domain struct
└── storage/ecto/
    ├── pushed_authorization_request_record.ex # Add field to Ecto schema
    └── interaction_record.ex        # Add field to Ecto schema
```

### Pattern 1: JSON Array Storage
Use Ecto's `{:array, :map}` for PostgreSQL compatibility. While RAR is defined as a JSON array, storing it as an array of maps in Ecto allows for clean idiomatic access in Elixir.

### Pattern 2: PAR-First Enforcement for RAR
RFC 9396 Section 13.2 recommends PAR for large requests. For FAPI 2.0 clients, PAR is already mandatory in Lockspire. For non-FAPI clients, we should implement a length check on the raw `authorization_details` string.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON Parsing | Custom regex/split | `Jason.decode/1` | RAR is complex JSON; hand-rolling parsing is error-prone and insecure. |
| Map Storage | String serialization | Ecto `:map` or `{:array, :map}` | Native DB support for JSONB (Postgres) is more efficient and queryable. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Runtime | ✓ | 1.18.1 | — |
| PostgreSQL | Persistence | ✓ | 16.x | — |
| Jason | JSON Parsing | ✓ | 1.4.4 | — |

## Common Pitfalls

### Pitfall 1: Double Decoding
**What goes wrong:** Attempting to decode `authorization_details` multiple times or in the wrong place.
**How to avoid:** Decode once in `AuthorizationRequest.validate/1` and pass the decoded list of maps through the `Validated` struct.

### Pitfall 2: URI Length Exhaustion
**What goes wrong:** Clients send huge RAR payloads via GET, causing 414 Request-URI Too Large or truncated parameters.
**How to avoid:** Implement a protocol-level check in `AuthorizationRequest` that rejects raw string payloads over a certain threshold (e.g., 2048 chars), forcing clients to use PAR.

## Code Examples

### RAR Structure (RFC 9396)
```json
// Example authorization_details
[
  {
    "type": "payment_initiation",
    "actions": ["create"],
    "locations": ["https://api.bank.com"],
    "datatypes": ["payment-v1"],
    "intent_id": "92s823a"
  }
]
```

### AuthorizationRequest Update Pattern
```elixir
defmodule Lockspire.Protocol.AuthorizationRequest.Validated do
  # ... existing fields
  field :authorization_details, [map()], default: []
end

defp validate_authorization_details(params) do
  case Map.get(params, "authorization_details") do
    nil -> {:ok, []}
    details when is_binary(details) ->
      # Direct GET / POST form-encoded
      case Jason.decode(details) do
        {:ok, list} when is_list(list) -> {:ok, list}
        _ -> {:redirect_error, ...}
      end
    list when is_list(list) -> 
      # Already parsed (e.g. from a Request Object / JSON body)
      {:ok, list}
  end
end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/lockspire/protocol/authorization_request_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RAR-01 | Accepts `authorization_details` in PAR | Integration | `mix test test/lockspire/protocol/pushed_authorization_request_test.exs` | ✅ |
| RAR-01 | Rejects malformed JSON in RAR | Unit | `mix test test/lockspire/protocol/authorization_request_test.exs` | ✅ |
| RAR-01 | Rejects huge RAR in GET requests | Unit | `mix test test/lockspire/protocol/authorization_request_test.exs` | ❌ Wave 0 |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | `Jason.decode` + subsequent schema validation (Phase 56) |
| V12 Communications | yes | Enforce PAR for large payloads to avoid URI leakage/truncation |

### Known Threat Patterns for RAR

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed JSON Denial of Service | Denial of Service | Use a robust parser (`jason`) and limit input length. |
| Authorization Bypass via RAR Type | Elevation of Privilege | Ensure `type` is validated against a whitelist (Phase 56). |

## Sources

### Primary (HIGH confidence)
- [RFC 9396](https://datatracker.ietf.org/doc/html/rfc9396) - Rich Authorization Requests
- [Lockspire Codebase] - `lib/lockspire/protocol/authorization_request.ex`

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir/Phoenix/Ecto patterns.
- Architecture: HIGH - Follows existing Lockspire patterns for PAR and Interaction storage.
- Pitfalls: MEDIUM - URI length is the main "gotcha" for RAR intake.

**Research date:** 2026-05-06
**Valid until:** 2026-06-05
