<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| JARM-01 | Implement `response_mode=jwt` and composite modes (`query.jwt`, `fragment.jwt`, `form_post.jwt`) | `Protocol.Jarm.sign/2` merges `iss` into `params` and signs via `:jose`. `AuthorizationFlow` formats redirect based on mode. |
| JARM-02 | The JWT is signed using the private key matching the client's `authorization_signed_response_alg` | `AuthorizationFlow` fetches key via `KeyStore.fetch_active_signing_key(alg: alg_str)`. `Jarm` validates algorithm. |
</phase_requirements>

# Phase 71: JARM Core - Research

**Researched:** 2024-05-18
**Domain:** Protocol / OAuth 2.0 & OIDC
**Confidence:** HIGH

## Summary

This phase implements JWT Secured Authorization Response Mode (JARM) per RFC 9207. JARM improves authorization response integrity and confidentiality by wrapping standard response parameters (`code`, `state`, `iss`) inside a signed JSON Web Token (JWT). The issuer (`iss`) parameter is properly injected into the JWT claims to prevent authorization response mix-up attacks.

The server generates the JARM response using the `:jose` library within a dedicated `Lockspire.Protocol.Jarm` module. The signing algorithm dynamically matches the client's registered `authorization_signed_response_alg` preference, with keys fetched via `Lockspire.Storage.KeyStore`. JARM parameters (`response_mode=jwt`, `query.jwt`, `fragment.jwt`, `form_post.jwt`) are properly validated by `Lockspire.Protocol.AuthorizationRequest` and mapped to their appropriate delivery mechanisms in `Lockspire.Protocol.AuthorizationFlow`.

**Primary recommendation:** Use `Lockspire.Protocol.Jarm.sign/2` to encapsulate authorization response claims. Rely on the `:jose` library for cryptographic operations and ensure `iss` is forcefully merged into the claims set.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| **Response Mode Validation** | API / Backend | — | `AuthorizationRequest` must validate `response_mode` parameter and allow `.jwt` composite modes. |
| **JARM Client Metadata** | Database / Storage | API / Backend | `Client` schema persists `authorization_signed_response_alg` to guide the signing algorithm selection. |
| **Interaction Lifecycle** | Database / Storage | API / Backend | `Interaction` stores the requested `response_mode` so it survives the login/consent lifecycle. |
| **JARM JWT Generation** | API / Backend | — | `Lockspire.Protocol.Jarm` orchestrates `:jose` to sign the payload. |
| **Response Formatting** | API / Backend | Browser / Client | `AuthorizationFlow` formats the redirect URI (`?response=...` or `#response=...`) or handles `form_post.jwt`. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:jose` | ~> 1.11 | JWS/JWT creation and signing | Elixir ecosystem standard for Javascript Object Signing and Encryption; already heavily utilized in Lockspire. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Ecto` | ~> 3.10 | Database migrations | For extending `Client` and `Interaction` tables with `authorization_signed_response_alg` and `response_mode`. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Lockspire.Protocol.Jarm` | Inline in `AuthorizationFlow` | JARM signing requires fetching keys and building claims. A dedicated module keeps `AuthorizationFlow` maintainable and allows isolated testing. |

**Installation:**
```bash
# None required. :jose is already a dependency.
```

## Architecture Patterns

### System Architecture Diagram

```mermaid
flowchart TD
    Client[Client App] -->|1. Request with response_mode=jwt| AuthReq[AuthorizationRequest]
    AuthReq -->|2. Validate JARM mode| InteractionDB[(Interaction Store)]
    InteractionDB -->|3. User Consent| AuthFlow[AuthorizationFlow]
    AuthFlow -->|4. Build params (code, state, iss)| Jarm[Protocol.Jarm]
    Jarm -->|5. Fetch Client alg preference| KeyStore[(Storage.KeyStore)]
    KeyStore -->|6. Return JWK| Jarm
    Jarm -->|7. Sign JWT with :jose| AuthFlow
    AuthFlow -->|8. Format Redirect URI/Form| Client
```

### Recommended Project Structure
```
lib/lockspire/
├── domain/
│   ├── client.ex                 # Adds authorization_signed_response_alg
│   └── interaction.ex            # Adds response_mode
├── protocol/
│   ├── jarm.ex                   # JWS signing utility for JARM
│   ├── authorization_request.ex  # Validates response_mode
│   ├── authorization_flow.ex     # Wraps response code/state in JWT
│   └── discovery.ex              # Advertises supported JARM algs/modes
└── storage/
    └── ecto/
        ├── client_record.ex      # Maps authorization_signed_response_alg
        └── interaction_record.ex # Maps response_mode
```

### Pattern 1: JWT Signing Delegation
**What:** Extracted pure signing logic into a `Jarm` module with clean error boundaries.
**When to use:** When building the final authorization code/state response.
**Example:**
```elixir
def sign(params, context) do
  # Fetches keys, parses JWK, merges base_claims (iss, aud, exp) and signs via :jose
  base_claims = %{"iss" => issuer, "aud" => client_id, "exp" => now + @jarm_ttl}
  claims = Map.merge(params, base_claims)
  
  JOSE.JWT.sign(jwk, %{"alg" => alg, "kid" => kid}, claims)
  |> JOSE.JWS.compact()
end
```

### Anti-Patterns to Avoid
- **Implicit response_mode loss:** Relying purely on the `Validated` struct in `AuthorizationRequest` and forgetting to persist `response_mode` on the `Interaction` struct. The redirect happens later, so the interaction *must* remember how the client asked to receive the code.
- **Missing `iss` parameter:** Failing to inject `iss` into the JARM response. RFC 9207 dictates that `iss`, `aud`, and `exp` claims MUST be present in the JWT to prevent mix-up attacks.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JWS Serialization | Custom base64 concatenations | `:jose` (`JOSE.JWT.sign` / `JOSE.JWS.compact`) | `jose` handles headers, signatures, and safe URL-encoding out of the box. |
| Key Decoding | Custom Erlang term decoding | Existing `decode_private_jwk` | Avoid security bugs with parsing potentially unsafe binaries; copy the exact decoder from `IdToken`. |

## Common Pitfalls

### Pitfall 1: Incorrect Default Delivery Mode
**What goes wrong:** A client requests `response_mode=jwt` but the server appends the JWT to the query string when the `response_type` dictated fragment, exposing sensitive data to server logs.
**Why it happens:** Implementing `jwt` as a static alias for `query.jwt`.
**How to avoid:** JARM states that if only `jwt` is requested, the default delivery mode depends on the `response_type`. `code` defaults to `query.jwt` natively, but if combined with implicit types, it should default to `fragment.jwt`.

### Pitfall 2: Missing Key Store Fallback / Crash
**What goes wrong:** Client registers with an exotic algorithm and `KeyStore.fetch_active_signing_key` returns nothing, crashing the authorization completion.
**Why it happens:** Assuming `authorization_signed_response_alg` maps 1:1 to available tenant keys without verification.
**How to avoid:** Validate `authorization_signed_response_alg` during client registration to ensure it's supported, and handle `:missing_signing_key` gracefully in `AuthorizationFlow` by issuing an OAuth error to the redirect URI instead of a 500 crash.

## Code Examples

### Constructing JARM Redirects
```elixir
defp format_jarm_redirect(interaction, mode, jwt) do
  jarm_params = %{"response" => jwt}

  case mode do
    "form_post.jwt" ->
      {:ok, {:form_post, interaction.redirect_uri, jarm_params}}

    "fragment.jwt" ->
      {:ok, build_redirect(interaction.redirect_uri, jarm_params, "fragment")}
      
    _other -> # "jwt" or "query.jwt"
      {:ok, build_redirect(interaction.redirect_uri, jarm_params, "query")}
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Plain query parameters (`?code=x&state=y`) | Signed JWT responses (`?response=eyJ...`) | RFC 9207 (JARM) | Prevents authorization response parameter injection and tampering. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Existing `form_post` mechanics handle `form_post.jwt` seamlessly. | Code Examples | [ASSUMED] If the controller logic doesn't correctly render an auto-submitting form when returned `{:form_post, ...}`, JARM form posts will fail or timeout. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / OTP | Core runtime | ✓ | — | — |
| PostgreSQL | Ecto (DB changes) | ✓ | — | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs` / `test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| JARM-01 | Default `jwt` correctly based on `response_type` | unit | `mix test test/lockspire/protocol/authorization_request_test.exs` | ✅ Wave 0 |
| JARM-01 | Encapsulate params in JWS and format output | unit | `mix test test/lockspire/protocol/jarm_test.exs` | ✅ Wave 0 |
| JARM-01 | Inject `?response=...` in redirect | integration | `mix test test/lockspire/web/controllers/authorize_controller_test.exs` | ✅ Wave 0 |
| JARM-02 | Advertise `authorization_signing_alg_values_supported` | unit | `mix test test/lockspire/protocol/discovery_test.exs` | ✅ Wave 0 |

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements, and `jarm_test.exs` is already present.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | `AuthorizationRequest` strict matching of `@allowed_response_modes` |
| V6 Cryptography | yes | `:jose` library handles secure JWT construction. Hand-rolling JWS headers or payload encoding is strictly forbidden. |

### Known Threat Patterns for Elixir / OAuth

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Algorithm confusion (`alg: none`) | Spoofing | Explicitly pass the expected `alg` string to `:jose` validation or enforce a strict allowlist. Lockspire `Jarm.sign/2` ensures `ensure_allowed_alg/2`. |
| Mix-up Attacks | Spoofing | Inject `iss` parameter into the JARM response payload so the client can definitively identify the issuing authorization server. |

## Sources

### Primary (HIGH confidence)
- Lockspire Elixir Source Code - `lib/lockspire/protocol/jarm.ex`, `authorization_flow.ex`
- Official Docs: [RFC 9207 - JARM](https://datatracker.ietf.org/doc/html/rfc9207)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Relies completely on existing `jose` usage.
- Architecture: HIGH - Identified correct insertion points for schema (`Interaction` & `Client`) and redirects (`AuthorizationFlow`).
- Pitfalls: HIGH - Standard JARM implementation traps are accounted for.

**Research date:** 2024-05-18
**Valid until:** Stable