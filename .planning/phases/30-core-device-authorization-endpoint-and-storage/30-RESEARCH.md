# Phase 30: Core Device Authorization Endpoint & Storage - Research

**Researched:** 2024
**Domain:** Protocol / Endpoints / Storage
**Confidence:** HIGH

## Summary

This phase introduces the foundational elements for the OAuth 2.0 Device Authorization Grant (RFC 8628). It requires a new `POST /device/code` endpoint, code generation logic (a high-entropy `device_code` and a short Base20 `user_code`), an Ecto schema representing pending device codes, and the storage protocol definitions to persist and query these codes.

**Primary recommendation:** Build a dedicated `Lockspire.Protocol.DeviceAuthorization` handler and `Lockspire.Storage.DeviceCodeStore` behaviour, mirroring the structure used for `PushedAuthorizationRequest`, to keep device flow state strictly separated from standard tokens.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Endpoint `/device/code` | API | — | Receives and validates client requests |
| Client Authentication | API | — | Reuses `Lockspire.Protocol.ClientAuth` |
| Code Generation | API | — | Requires secure randomness for `device_code` and Base20 encoding for `user_code` |
| Code Persistence | Database | API | Uses Ecto schemas to durably track pending authorizations and enforce TTLs |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Plug.Crypto` | (transitive) | Hash comparison | `Plug.Crypto.secure_compare/2` is already standard across Lockspire for timing-safe hash checks |
| `:crypto` | (Erlang) | Entropy & Hashing | Used for `device_code` generation and securely hashing codes before DB storage |

## Architecture Patterns

### Recommended Project Structure
```
lib/lockspire/web/
└── controllers/
    ├── device_authorization_controller.ex     # Web intake adapter for /device/code
    └── device_authorization_json.ex           # JSON formatting

lib/lockspire/protocol/
└── device_authorization.ex                # Core protocol logic

lib/lockspire/storage/
└── device_code_store.ex                   # Behaviour contract for Device Codes

lib/lockspire/storage/ecto/
└── device_code_record.ex                  # Ecto Schema

lib/lockspire/domain/
└── device_code.ex                         # Pure domain struct
```

### Pattern 1: Protocol Handling
**What:** Separation of Phoenix controllers and protocol logic.
**When to use:** All OAuth/OIDC protocol endpoints.
**Example:**
```elixir
# In lib/lockspire/web/controllers/device_authorization_controller.ex
def create(conn, params) do
  authorization = List.first(get_req_header(conn, "authorization"))

  case DeviceAuthorization.authorize(%{
         params: params,
         authorization: authorization,
         opts: [client_store: Repository, device_code_store: Repository]
       }) do
    {:ok, %Success{} = success} ->
      conn |> put_status(:ok) |> json(DeviceAuthorizationJSON.success_response(success))
    {:error, %Error{} = error} ->
      # handle standard oauth error response
  end
end
```

### Pattern 2: Hash-Only Code Storage
**What:** Storing only hashes of `device_code` and `user_code`.
**When to use:** Security requirement; codes can grant access so their plaintext forms should never be stored.
**Example:**
The `device_code` and `user_code` must be passed back to the client/user in plaintext, but only `:crypto.hash(:sha256, code)` should be saved to the database.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Client Auth | Custom secret validation | `Lockspire.Protocol.ClientAuth.authenticate/3` | Unified error handling, securely supports all auth methods (Basic/Post/None) |
| Secure comparison | `==` or `===` | `Plug.Crypto.secure_compare/2` | Prevents timing attacks when validating codes later |

## Common Pitfalls

### Pitfall 1: Unhashed Database Storage
**What goes wrong:** The plaintext `device_code` or `user_code` is written directly to the database.
**Why it happens:** Developer forgets that these codes are effectively bearer tokens in transit.
**How to avoid:** Apply `Lockspire.Security.Policy.hash_token/1` to the plaintext outputs prior to inserting into `DeviceCodeRecord`.

### Pitfall 2: Ambiguous Base20 Alphabet
**What goes wrong:** The generated user code uses standard Base32 or includes ambiguous characters (I, O, 0, 1).
**Why it happens:** Not referencing RFC 8628 guidelines.
**How to avoid:** Strictly use the `BCDFGHJKLMNPQRSTVWXZ` alphabet for the user code and omit dashes from storage (only add them in presentation).

## Code Examples

### Base20 User Code Generation
```elixir
defmodule Lockspire.Security.DeviceCode do
  @base20_alphabet String.codepoints("BCDFGHJKLMNPQRSTVWXZ")

  @doc "Generates an 8-character Base20 user code (e.g., 'WDJB-MJHT')"
  def generate_user_code do
    1..8
    |> Enum.map(fn _ -> Enum.random(@base20_alphabet) end)
    |> Enum.join()
  end

  @doc "Generates a high-entropy device code"
  def generate_device_code do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end
```

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | `Lockspire.Protocol.ClientAuth` for client auth |
| V3 Session Management | no | — |
| V4 Access Control | yes | `device_code` binds to the originating `client_id` |
| V5 Input Validation | yes | Ecto `validate_required` and standard param normalizations |
| V6 Cryptography | yes | `:crypto.strong_rand_bytes/1` for entropy, `Plug.Crypto.secure_compare/2` for lookups, `Policy.hash_token/1` for storage |

### Known Threat Patterns for OAuth Device Flow

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Timing Attacks | Information Disclosure | `Plug.Crypto.secure_compare/2` when matching codes |
| Brute forcing User Code | Spoofing | Short TTL (5-10 minutes max), rate limit polling (Phase 31) |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `MIX_ENV=test mix test.phase30` |
| Full suite command | `MIX_ENV=test mix test.integration` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEV-01 | Handle `POST /device/code` | controller + mounted-route integration | `MIX_ENV=test mix test.phase30` | ✅ `test/lockspire/web/controllers/device_authorization_controller_test.exs`, `test/integration/phase30_device_authorization_e2e_test.exs` |
| DEV-02 | Generate codes securely | unit + protocol | `MIX_ENV=test mix test.phase30` | ✅ `test/lockspire/security/device_code_test.exs`, `test/lockspire/protocol/device_authorization_test.exs` |
| DEV-03 | Store codes in Ecto | domain + repository + integration | `MIX_ENV=test mix test.phase30` | ✅ `test/lockspire/domain/device_authorization_test.exs`, `test/lockspire/storage/ecto/repository_device_authorization_test.exs`, `test/integration/phase30_device_authorization_e2e_test.exs` |

### Sampling Rate
- **Per task commit:** `MIX_ENV=test mix test.phase30`
- **Per wave merge:** `MIX_ENV=test mix test.integration`
- **Phase gate:** `MIX_ENV=test mix test.phase30` and `MIX_ENV=test mix test.integration`

### Wave 0 Gaps
- [x] `test/lockspire/web/controllers/device_authorization_controller_test.exs` — covers DEV-01
- [x] `test/lockspire/protocol/device_authorization_test.exs` — covers DEV-02
- [x] `test/lockspire/storage/ecto/repository_device_authorization_test.exs` — covers DEV-03
- [x] `test/integration/phase30_device_authorization_e2e_test.exs` — mounted-route proof closing the last manual-UAT gap

## Sources

### Primary (HIGH confidence)
- `lib/lockspire/protocol/client_auth.ex` - Checked for client authentication reuse.
- `lib/lockspire/storage/ecto/pushed_authorization_request_record.ex` - Reference for storing temporary, hashed URI/codes with a strict expiration.
- RFC 8628 - Checked for Base20 character set (`BCDFGHJKLMNPQRSTVWXZ`).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir crypto and Plug modules already verified in Lockspire.
- Architecture: HIGH - Mirrored identical patterns used in `PushedAuthorizationRequestController` and `Repository`.
- Pitfalls: HIGH - Standard OAuth best practices for ephemeral tokens.

**Research date:** 2024
**Valid until:** 30 days
