<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions


### the agent's Discretion


### Deferred Ideas (OUT OF SCOPE)

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTHZ-01 | Add RSA/EC encryption keypairs (`enc`) to `Storage.KeyStore` and JWKS endpoints. | Confirmed `lockspire_signing_keys` table uses `text` for `:use`. We only need to update the Ecto.Enum in `SigningKeyRecord` and add `:enc` specific querying to `Repository`. |
| AUTHZ-02 | Implement nested JWT validation (Sign-then-Encrypt) in `Protocol.Jar` using `JOSE.JWE` and `JOSE.JWS`. | `JOSE.JWK.block_decrypt/2` effectively extracts the inner JWS from a JWE, allowing reuse of existing JWS verification pipelines. |
</phase_requirements>

# Phase 40: JWE Support for Request Objects - Research

**Researched:** 2024-05-18
**Domain:** Protocol / Cryptography
**Confidence:** HIGH

## Summary

This phase requires supporting nested encrypted JWTs (JWE) containing signed JWTs (JWS) as Request Objects for JAR. The AS needs to generate and publish encryption keys (`use: "enc"`) in its JWKS, receive encrypted Request Objects, decrypt them using the corresponding server-side private key, and finally pass the inner signed JWT to the existing `Jar.verify_signature` pipeline.

**Primary recommendation:** Broaden the `SigningKey` domain to support `use: :enc`, add a `list_decryption_keys` function to `KeyStore`, and introduce a pre-processing decryption step in `RequestObject.consume` before `Jar` verification.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Publish `enc` keys | API / Backend (`Protocol.Jwks`) | Database (`KeyStore`) | The server publishes `use: "enc"` alongside `"sig"` keys in the `/jwks` endpoint. |
| Decrypt JAR | API / Backend (`Protocol.RequestObject`) | `Protocol.Jar` | Encrypted JWTs (5-part) are intercepted, decrypted with server keys, and converted to JWS (3-part). |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `jose` | ~> 1.11 | JWT/JWE/JWS handling | Built-in project standard for all cryptographic token operations. |

## Architecture Patterns

### Pattern 1: Nested JWT Decryption Before Verification
**What:** Intercept the JWT in `RequestObject.consume/3` and attempt decryption if it's a JWE.
**When to use:** Whenever parsing a JWT that could optionally be encrypted (like JAR).
**Example:**
```elixir
def consume(params, client, opts \\ []) do
  with {:ok, jwt} <- fetch_request(params),
       {:ok, decryption_keys} <- KeyStore.list_decryption_keys(),
       {:ok, jws_string} <- Jar.decrypt(jwt, decryption_keys),
       {:ok, %Jar{} = jar} <- decode_and_verify(jws_string, client) do
    # ...
  end
end
```

### Pattern 2: Structuring `enc` keys in KeyStore
The `lockspire_signing_keys` schema is flexible. The `:use` field is a `text` column in PostgreSQL. We do not need a database migration for the enum.

We need to:
1. Update `Lockspire.Storage.Ecto.SigningKeyRecord`'s `:use` field definition: `field(:use, Ecto.Enum, values: [:sig, :enc])`.
2. Update `Lockspire.Domain.SigningKey`'s `use_type` type to `:sig | :enc`.
3. Fix `Repository.fetch_active_signing_key/0` to explicitly filter `key.use == :sig`. Otherwise, it might return an `:enc` key for signing ID tokens.
4. Add a new `Repository.list_decryption_keys/0` that returns `key.use == :enc and key.status in [:active, :retiring]`.
5. `Protocol.Jwks.public_jwk_set/1` uses `list_publishable_keys/0`, which currently ignores `:use`. This is perfect—it will naturally include published `:enc` keys.

## Common Pitfalls

### Pitfall 1: Blindly treating all JWTs as JWEs
**What goes wrong:** Calling `JOSE.JWK.block_decrypt` on a JWS will fail or raise.
**Why it happens:** JAR allows both signed-only and encrypted-then-signed objects.
**How to avoid:** Check if the string is a JWE (e.g., checking if `length(String.split(jwt, ".")) == 5`) before attempting decryption, or rescue gracefully.

### Pitfall 2: Using `:enc` keys for signing
**What goes wrong:** ID Tokens or Logout Tokens are signed with an `:enc` key.
**Why it happens:** `Repository.fetch_active_signing_key/0` only checks for `status == :active`, assuming all keys are `:sig`.
**How to avoid:** Explicitly add `and key.use == :sig` to `fetch_active_signing_key/0`.

## Code Examples

### JWE Decryption with `jose`
```elixir
# In Protocol.Jar
def decrypt(jwt, decryption_keys) do
  if is_jwe?(jwt) do
    Enum.reduce_while(decryption_keys, {:error, :decryption_failed}, fn key, _acc ->
      jwk = parse_private_jwk(key.private_jwk_encrypted)
      case JOSE.JWK.block_decrypt(jwt, jwk) do
        {plain_text, _jwe} -> {:halt, {:ok, plain_text}}
        _ -> {:cont, {:error, :decryption_failed}}
      end
    end)
  else
    {:ok, jwt}
  end
end

defp is_jwe?(jwt) when is_binary(jwt) do
  length(String.split(jwt, ".")) == 5
end

defp parse_private_jwk(binary) do
  binary
  |> Jason.decode!()
  |> JOSE.JWK.from_map()
end
```

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None | None |

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
| AUTHZ-01 | Keys can have `use: :enc` and show in JWKS | unit | `mix test test/lockspire/storage/repository_test.exs` | ✅ Wave 0 |
| AUTHZ-02 | Nested JWE request objects are correctly decrypted | unit | `mix test test/lockspire/protocol/request_object_test.exs` | ✅ Wave 0 |

## Sources

### Primary (HIGH confidence)
- `lib/lockspire/storage/ecto/signing_key_record.ex` - Schema structure for keys
- `lib/lockspire/protocol/request_object.ex` - Where the JAR consumption happens
- Local `test_jwe.exs` script output confirming `JOSE.JWK.block_decrypt` returns the plain JWS text.
