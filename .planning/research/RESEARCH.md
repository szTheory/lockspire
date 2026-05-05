# Phase 51: Core Protocol & Poll Mode (CIBA) - Research

**Researched:** 2024-05-24
**Domain:** OpenID Connect / CIBA Specification & Token Endpoint
**Confidence:** HIGH

## Summary

The OpenID Connect Client-Initiated Backchannel Authentication (CIBA) Core 1.0 specification defines a decoupled authentication flow where the Consumption Device (which initiates the request) is separate from the Authentication Device (where the user approves it). 

This research confirms that the Lockspire architecture can natively support the CIBA Poll Mode without introducing external dependencies (like Redis) by leveraging the exact same Ecto-backed state machine currently used for the Device Authorization Grant (`DeviceAuthorizationRecord`). The `/bc-authorize` endpoint validates the client request, strictly enforces exactly one user identification hint (`login_hint`, `id_token_hint`, or `login_hint_token`), and issues an `auth_req_id`. The client then polls the `/token` endpoint using `grant_type=urn:openid:params:grant-type:ciba`. The `slow_down` error mechanism is cleanly handled by tracking `effective_poll_interval_seconds` and `next_poll_allowed_at` in the database, updating the polling threshold transactionally when the client polls too fast.

**Primary recommendation:** Implement CIBA Poll Mode mirroring the `DeviceAuthorization` domain model, utilizing `Lockspire.Storage.CibaAuthorizationStore` backed by a new `lockspire_ciba_authorizations` Ecto schema to durably track poll intervals and transaction states.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Backchannel Auth (`/bc-authorize`) | API / Backend | — | Validates CIBA specific constraints (user hints), authenticates the client, and returns `auth_req_id` alongside `interval`. |
| CIBA Token Polling (`/token`) | API / Backend | Database (Ecto) | Evaluates the `auth_req_id`, compares current time against `next_poll_allowed_at`, and returns tokens, `authorization_pending`, or `slow_down`. |
| CIBA State & Poll Tracking | Database / Storage | — | Persists `auth_req_id_hash`, status, and poll intervals using Ecto to satisfy Lockspire's embedded constraint without requiring Redis. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | Current | Durable State & Poll tracking | Embedded systems require persistent state across restarts without external cache dependencies. |

## Architecture Patterns

### Recommended Project Structure
```
lib/lockspire/
├── domain/
│   └── ciba_authorization.ex           # Domain entity for CIBA
├── storage/
│   ├── ciba_authorization_store.ex     # Behaviour for DB operations
│   └── ecto/
│       └── ciba_authorization_record.ex # Ecto schema tracking state and intervals
├── protocol/
│   └── backchannel_authentication.ex   # Validation and issuance logic
└── web/
    └── controllers/
        └── bc_authorize_controller.ex  # HTTP entry point for CIBA
```

### Pattern 1: Ecto-Backed Polling Interval Enforcement
**What:** Tracking `effective_poll_interval_seconds` and `next_poll_allowed_at` durably in the database.
**When to use:** Whenever managing polling endpoints (`/token`) in an embedded/no-Redis architecture.
**Example:**
```elixir
# Based on existing Device Authorization patterns
defp slow_down_ciba_authorization(record, _now) do
  next_interval = record.effective_poll_interval_seconds + 5
  next_poll_allowed_at = DateTime.add(record.next_poll_allowed_at, next_interval, :second)

  record
  |> CibaAuthorizationRecord.update_changeset(%{
    effective_poll_interval_seconds: next_interval,
    next_poll_allowed_at: next_poll_allowed_at,
    updated_at: DateTime.utc_now()
  })
  |> repo_update()
  # Return `slow_down` to the client
end
```

### Pattern 2: Secret Hashing for Authorization IDs
**What:** Hashing the `auth_req_id` prior to database storage.
**When to use:** Always. `auth_req_id` is a high-entropy bearer token sent to the client. It must be stored as `auth_req_id_hash` to prevent database compromise from exposing active authorizations.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| In-memory caching for `slow_down` limits | GenServer or ETS cache | Ecto `next_poll_allowed_at` tracking | ETS caches disappear on server restart. CIBA requests can last minutes/hours; Ecto guarantees durable state across reboots. |

## Common Pitfalls

### Pitfall 1: Incorrect "Exactly One" Hint Validation
**What goes wrong:** Allowing the client to omit a hint, or provide multiple hints in the `/bc-authorize` request.
**Why it happens:** Misreading the CIBA spec, treating all hints as purely optional.
**How to avoid:** Enforce that `Enum.count([login_hint, id_token_hint, login_hint_token], &not_nil?/1) == 1`. Return `invalid_request` if this fails.

### Pitfall 2: Resetting `next_poll_allowed_at` from `DateTime.utc_now()` on `slow_down`
**What goes wrong:** The client gets a `slow_down` penalty that is too lenient.
**Why it happens:** Calculating the penalty interval from the current time.
**How to avoid:** Add the new interval to the *existing* `next_poll_allowed_at`, not `now`. (e.g., `DateTime.add(record.next_poll_allowed_at, interval + 5, :second)`).

### Pitfall 3: Missing `openid` Scope Validation
**What goes wrong:** Treating the backchannel request as a standard OAuth request without OIDC scope.
**Why it happens:** Treating it exactly like a Device flow.
**How to avoid:** Explicitly require the `openid` scope at the `/bc-authorize` endpoint per the CIBA Core specification.

## Code Examples

### Hint Validation Logic
```elixir
def validate_hints(attrs) do
  provided_hints =
    [:login_hint, :id_token_hint, :login_hint_token]
    |> Enum.filter(fn key -> Map.has_key?(attrs, key) and not is_nil(Map.get(attrs, key)) end)

  case length(provided_hints) do
    1 -> {:ok, attrs}
    _ -> {:error, :invalid_request, "Exactly one of login_hint, id_token_hint, or login_hint_token is required"}
  end
end
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No external cache dependencies exist in the system (e.g., Redis). | Summary | Re-engineering `slow_down` logic. (Verified: Lockspire utilizes embedded Ecto). |

## Open Questions

1. **User Identifier Resolution** (RESOLVED)
   - What we know: The server receives an identifier (e.g. `login_hint`).
   - What's unclear: How exactly Lockspire maps this hint to a `subject_id` internally without the browser interaction.
   - RESOLUTION: This is handled by the account resolution logic used in the bc-authorize endpoint, leveraging the existing `AccountResolver` infrastructure.

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
| CIBA-01 | `/bc-authorize` endpoint returns `auth_req_id` and enforces exact hint rules | integration | `mix test test/integration/phase51_ciba_poll_mode_e2e_test.exs` | ❌ Wave 0 |
| CIBA-02 | `/token` validates `grant_type=urn:openid:params:grant-type:ciba` and retrieves authorization | integration | `mix test test/integration/phase51_ciba_poll_mode_e2e_test.exs` | ❌ Wave 0 |
| CIBA-03 | `slow_down` returned if polling occurs before `next_poll_allowed_at` | unit/integration | `mix test test/lockspire/protocol/token_exchange_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test <specific_test_file>`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/integration/phase51_ciba_poll_mode_e2e_test.exs` — covers CIBA-01, CIBA-02, CIBA-03

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | OpenID CIBA Specification |
| V3 Session Management | no | (Stateless token issuance) |
| V4 Access Control | yes | Client authentication requirement at `/bc-authorize` |
| V5 Input Validation | yes | Validation of hints (`login_hint` etc) and scopes |
| V6 Cryptography | yes | `Policy.hash_token/1` for `auth_req_id` before persistence |

### Known Threat Patterns for CIBA

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Leaked `auth_req_id` from DB | Information Disclosure | Hash the `auth_req_id` at creation; store only `auth_req_id_hash`. |
| Denial of Service via Polling | Denial of Service | Enforce `slow_down` errors strictly and exponentially increase polling interval. |
| Identity Spoofing | Spoofing | Strictly authenticate the RP at the `/bc-authorize` endpoint using registered client credentials. |

## Sources

### Primary (HIGH confidence)
- Official docs URL - OpenID Connect CIBA Core 1.0 (https://openid.net/specs/openid-client-initiated-backchannel-authentication-core-1_0.html)
- Source code analysis: `lib/lockspire/storage/device_authorization_store.ex` (Polling interval design patterns)
- Source code analysis: `lib/lockspire/domain/device_authorization.ex` (Domain logic)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Ecto is perfectly capable of stateful poll interval tracking.
- Architecture: HIGH - Lockspire's Device Authorization flow provides an exact blueprint for the required state machine.
- Pitfalls: HIGH - CIBA spec rigidly defines hint requirements and interval enforcement.

**Research date:** 2024-05-24
**Valid until:** Indefinitely (Protocol specs do not change fundamentally).
