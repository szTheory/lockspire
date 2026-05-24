<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Separate token extraction/verification from authorization enforcement. `Lockspire.Plug.VerifyToken` acts as a "soft" plug (assigns but never halts).
- `Lockspire.Plug.RequireToken` acts as the "strict" enforcer (halts with `401 Unauthorized` and `WWW-Authenticate: Bearer` if necessary).
- Use `%Lockspire.AccessToken{}` struct to encapsulate token state (`token`, `claims`, `client_id`, `binding_type`, `binding_thumbprint`, `error`).
- Key Resolution Bypassing Database: Introduce `Lockspire.KeyCache` GenServer storing active signing keys in an ETS table (`read_concurrency: true`), fetched on boot and periodically refreshed. `VerifyToken` reads exclusively from ETS.
</user_constraints>

# Phase 79: Core Validation Plug - Research

**Researched:** 2024-05-23
**Domain:** Elixir/Phoenix Plug Auth, GenServer, ETS caching
**Confidence:** HIGH

## Summary
The phase establishes the `Lockspire.Plug.VerifyToken` plug, a core component for resource server API protection in the Lockspire ecosystem. Following the "Two-Plug" pattern standard in Elixir auth (similar to Guardian and `phx.gen.auth`), it relies on a soft verification plug that assigns an encapsulated token struct (`%Lockspire.AccessToken{}`) into `conn.assigns`, which is later strictly enforced by a separate plug. To handle the high volume of incoming token validations without exhausting database connections, it uses a background GenServer (`Lockspire.KeyCache`) caching active JWKs into an ETS table.

**Primary recommendation:** Use `:ets.new(:lockspire_keys, [:set, :named_table, :public, read_concurrency: true])` in `Lockspire.KeyCache.init/1` and delegate cryptographic validation to the existing JWS parsing utilities in Lockspire, resolving signing keys from the cache.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token Extraction | API / Backend | — | Plug extracting `authorization: Bearer` header. |
| Key Resolution Cache | API / Backend | Database | `GenServer` memory (ETS) cache to shield DB load, synced from `KeyStore`. |
| Soft Validation | API / Backend | — | Validation plug assigns `%Lockspire.AccessToken{}` regardless of validity. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Plug` | 1.15.x | HTTP Request Pipeline | Standard HTTP middleware for Phoenix/Elixir. |
| `ETS` | OTP native | Memory caching | Microsecond lookup, `read_concurrency: true` handles zero-bottleneck key lookups. |

## Architecture Patterns

### System Architecture Diagram
```text
[HTTP Request] 
      │ (authorization header)
      ▼
[Plug.VerifyToken] ─── (fetch active keys) ───► [ETS: :lockspire_keys]
      │                                                ▲
      │ (validate sig + time claims)                   │ (async periodic refresh)
      ▼                                         [KeyCache GenServer]
[Assign %AccessToken{}]                                │
      │                                                ▼
      ▼                                         [Storage.KeyStore (DB)]
[Downstream Controllers]
```

### Pattern 1: Soft Validation Plug
**What:** A plug that never halts the pipeline, instead mutating state (assigns) to denote success or specific failure.
**When to use:** Plugs that represent the "authentication attempt" vs the "authorization requirement".
**Example:**
```elixir
def call(conn, _opts) do
  with {:ok, token} <- extract_bearer(conn),
       {:ok, claims} <- verify_token(token) do
    Plug.Conn.assign(conn, :access_token, %AccessToken{token: token, claims: claims})
  else
    {:error, reason} -> 
      Plug.Conn.assign(conn, :access_token, %AccessToken{error: reason})
  end
end
```

### Pattern 2: ETS Cache via GenServer
**What:** GenServer creating a public ETS table in `init` for highly concurrent reads, while being the sole writer to keep data synced.
**Example:**
```elixir
def init(_opts) do
  :ets.new(:lockspire_keys, [:set, :named_table, :public, read_concurrency: true])
  send(self(), :refresh)
  {:ok, %{}}
end

def handle_info(:refresh, state) do
  case Lockspire.Storage.Ecto.Repository.list_active_keys() do
    {:ok, keys} -> 
      # Update ETS table safely
      :ets.insert(:lockspire_keys, {:active_keys, keys})
    _ -> :ok
  end
  Process.send_after(self(), :refresh, @refresh_interval)
  {:noreply, state}
end
```

### Anti-Patterns to Avoid
- **Halt in VerifyToken:** Do not `halt(conn)` or put a status code in `VerifyToken`. Leave error presentation to the `RequireToken` plug.
- **Calling Ecto in Plug:** Calling `KeyStore.list_active_keys/0` inside the Plug pipeline per-request will destroy DB pool throughput.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| In-memory caching | Custom Map/Agent | `:ets` | ETS with `read_concurrency: true` handles concurrent reads at scale natively without mailbox bottlenecks. |

## Common Pitfalls

### Pitfall 1: ETS Table Ownership
**What goes wrong:** ETS table disappears if the GenServer crashes.
**Why it happens:** The ETS table is owned by the GenServer process.
**How to avoid:** The GenServer must recreate the table in `init/1`. Any code reading from ETS must gracefully handle `:ets.lookup` failures (e.g., table missing) as an authentication failure or internal server error.

## Code Examples

### WWW-Authenticate Header Error Structure
```elixir
# (To be used in RequireToken, but good to know for structure)
conn
|> put_status(:unauthorized)
|> put_resp_header("www-authenticate", "Bearer error=\"invalid_token\"")
|> json(%{error: "invalid_token"})
|> halt()
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test.fast` / `mix test.integration` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-79-1 | Extract token from header and set assigns | unit | `mix test test/lockspire/plug/verify_token_test.exs` | ❌ Wave 0 |
| REQ-79-2 | KeyCache caches keys to ETS and refreshes | unit | `mix test test/lockspire/key_cache_test.exs` | ❌ Wave 0 |
| REQ-79-3 | Strictly enforce token presence and halt | unit | `mix test test/lockspire/plug/require_token_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test <specific_test_file>`
- **Per wave merge:** `mix test.fast`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/lockspire/plug/verify_token_test.exs`
- [ ] `test/lockspire/key_cache_test.exs`
- [ ] `test/lockspire/access_token_test.exs`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | `VerifyToken` soft-plug pattern |
| V3 Session Management | yes | Bearer Token Validation (exp, nbf, sig) |
| V4 Access Control | yes | Assigned `%AccessToken{}` downstream |
| V5 Input Validation | yes | JWT structure parsing and claim validation |
| V6 Cryptography | yes | Validate JWS signature against trusted keys |

### Known Threat Patterns for Elixir/Plug

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| JWT Signature Bypass | Spoofing | Validate algorithm is not `none` and signature strictly matches the trusted JWK. |
| Time-of-check bypass | Elevation of Priv | Validate `exp` and `nbf` time-based claims precisely using standardized time comparators. |
| DoS via Database connection exhaustion | Denial of Service | Isolate DB calls by reading strictly from memory (ETS cache) on hot API paths. |
