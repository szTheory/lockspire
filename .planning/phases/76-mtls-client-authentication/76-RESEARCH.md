# Phase 76: MTLS Client Authentication - Research

**Researched:** 2024-05-24
**Domain:** Protocol Authentication / Ecto / Plug
**Confidence:** HIGH

## Summary

This phase adds support for `tls_client_auth` and `self_signed_tls_client_auth` as defined in RFC 8705. The primary architectural shift involves extracting MTLS certificates presented by the load balancer via `conn.private[:lockspire_mtls_cert]` and threading them into the authentication core.

**Primary recommendation:** Use Erlang's `:public_key.pkix_decode_cert/2` wrapped in a clean Elixir facade for zero-dependency certificate parsing, and expand the `Client` schema with all 5 RFC-defined PKI attributes immediately to prevent future technical debt.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Certificate Parsing | API / Backend | — | The application logic needs a clean Elixir struct representing the X.509 cert. |
| Configuration Schema | Database / Storage | — | Adding `tls_client_auth_subject_dn`, etc. to Ecto immediately ensures full compliance without technical debt. |
| Plug Integration | Frontend Server | API / Backend | The TokenController passes the extracted certificate from `conn.private` to the domain logic via options. |
| Auth Validation | API / Backend | — | `Lockspire.Protocol.ClientAuth` needs to dynamically pivot to MTLS based on client configuration, even if standard credentials are missing. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:public_key` | (OTP) | X.509 certificate decoding | Robust, battle-tested standard library with zero external dependencies. |
| `JOSE` | (Project) | JWK creation/manipulation | Needed for extracting standard JWK structures from parsed public keys for self-signed verification. |
| `Ecto` | (Project) | DB schema | Adding the 5 PKI SAN fields and extending the enum. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `:public_key` | `x509` (Hex) | `x509` is cleaner but adds an external dependency. The strategy specifically requires wrapping `:public_key` natively. |

## Architecture Patterns

### System Architecture Diagram

```mermaid
flowchart TD
    A[Client Request] --> B[Plug / Router]
    B -->|Extracts conn.private[:lockspire_mtls_cert]| C[TokenController]
    C -->|opts[:mtls_cert]| D[Protocol.ClientAuth Core]
    D --> E{Client Auth Method?}
    E -->|tls_client_auth| F[MTLS Validator (PKI)]
    E -->|self_signed_tls_client_auth| G[MTLS Validator (JWKS)]
    
    F --> H[MTLS Certificate Facade]
    G --> H
    H -->|Parses via :public_key| I[Elixir Struct]
    
    I --> J{Validation}
    J -->|Matches Client Record| K[Authentication Success]
    J -->|Mismatch| L[Authentication Failed]
```

### Pattern 1: Certificate Parsing Facade
**What:** Using Erlang records in Elixir via `Record.extract/2`
**When to use:** When leveraging Erlang's `:public_key` ASN.1 decoding natively.
**Example:**
```elixir
defmodule Lockspire.MTLS.Certificate do
  require Record
  @public_key_hrl "public_key/include/public_key.hrl"
  Record.defrecord(:otp_cert, :OTPCertificate, Record.extract(:OTPCertificate, from_lib: @public_key_hrl))
  Record.defrecord(:otp_tbs_cert, :OTPTBSCertificate, Record.extract(:OTPTBSCertificate, from_lib: @public_key_hrl))
  
  def parse(der) do
    cert = :public_key.pkix_decode_cert(der, :otp)
    tbs = otp_cert(cert, :tbsCertificate)
    # Extracts to simple struct
  end
end
```

### Pattern 2: Context Passing for MTLS
**What:** Extracting the out-of-band cert from connection options instead of parsing it as primary credentials.
**When to use:** In controllers where MTLS might be used as the auth fallback mechanism.
**Example:**
```elixir
# TokenController.ex
opts = [mtls_cert: conn.private[:lockspire_mtls_cert]]
TokenExchange.exchange(Map.put(params, :opts, opts))
```

### Anti-Patterns to Avoid
- **Mixed Methods:** Allowing both standard credentials (`client_secret`) and MTLS certificates for authentication in the same request. If MTLS is configured, fail strictly if no cert is present or if mixed credentials appear.
- **Leaking Erlang Records:** Leaking `:OTPCertificate` or `:Extension` records into standard business logic instead of converting them immediately into Elixir structs.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ASN.1 Decoding | Custom binary matching | `:public_key.pkix_decode_cert/2` | X.509 ASN.1 structures are extremely complex and brittle to parse manually. |
| Public Key to JWK | Custom map builders | `JOSE.JWK.from_key/1` | Converting Erlang public key records to JWKS involves exact mapping of modulus/exponent which JOSE already handles robustly. |

## Common Pitfalls

### Pitfall 1: Ignoring SAN extraction structure
**What goes wrong:** Failing to correctly extract SANs (Subject Alternative Names) from the OTP records.
**Why it happens:** The SAN extension is buried in a list of extensions under the OID `{2, 5, 29, 17}`.
**How to avoid:** Specifically loop over `otp_tbs_cert(cert, :extensions)` to find the OID, and unpack the `extnValue`.

### Pitfall 2: Confusing `conn.private` states
**What goes wrong:** Passing a `nil` certificate into the authenticator, expecting it to be handled gracefully when the client strictly requires it.
**Why it happens:** Local dev environments or misconfigured load balancers might not set `conn.private[:lockspire_mtls_cert]`.
**How to avoid:** Fail-closed design. If auth method is MTLS and cert is `nil`, fail explicitly with a 401 and log it.

## Code Examples

Verified patterns from official sources:

### Erlang Certificate Parsing to Elixir
```elixir
# Source: Erlang public_key docs and community patterns
@san_oid {2, 5, 29, 17}

defp extract_sans(extensions) do
  extensions
  |> Enum.find(fn ext -> otp_extension(ext, :extnID) == @san_oid end)
  |> case do
    nil -> %{dns: [], uri: [], ip: [], email: []}
    ext -> 
      # extnValue will contain a list of tags like [dNSName: 'example.com', uniformResourceIdentifier: '...']
      parse_san_list(otp_extension(ext, :extnValue))
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Third-party libraries (`x509`) | Native `:public_key` facade | 2024 Strategy | Zero external dependencies, cleaner audit surface for security-critical functions. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | JOSE.JWK.from_key/1 perfectly supports the public key records output by pkix_decode_cert. | Don't Hand-Roll | We would need to manually assemble the JWK map from Erlang's `:RSAPublicKey` record. |

## Open Questions (RESOLVED)

1. **Self-signed JWKS matching method**
   - What we know: RFC 8705 says the self-signed certificate's public key must match a key in the client's JWKS.
   - What's unclear: Should we compare the raw public key DER bytes, or convert the cert's public key to a JWK thumbprint and compare thumbprints?
   - Resolution: We will convert the public key to a JWK thumbprint and rely on Lockspire's existing `JWKS` matching logic for consistency.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / OTP | Core Application | ✓ | 28 / 1.19.5 | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test {file}` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | Evaluate `tls_client_auth` | unit | `mix test test/lockspire/protocol/client_auth/mtls_test.exs` | ❌ Wave 0 |
| REQ-02 | Evaluate `self_signed_tls_client_auth` | unit | `mix test test/lockspire/protocol/client_auth/mtls_test.exs` | ❌ Wave 0 |
| REQ-03 | Extract certificate correctly | unit | `mix test test/lockspire/mtls/certificate_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test {file}`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/lockspire/mtls/certificate_test.exs` — covers parsing
- [ ] `test/lockspire/protocol/client_auth/mtls_test.exs` — covers auth evaluation

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | `Lockspire.Protocol.ClientAuth.MTLS` strict fail-closed |
| V3 Session Management | no | — |
| V4 Access Control | yes | Token Endpoint access validation |
| V5 Input Validation | yes | Ecto changesets & SAN value parsing |
| V6 Cryptography | yes | `:public_key` / `JOSE` |

### Known Threat Patterns for Elixir / Erlang X.509

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unhandled Exceptions in Parsing | Denial of Service | Wrapping `pkix_decode_cert` in `try/rescue` or checking for valid DER binaries before calling it. |
| Mixed Auth Bypass | Spoofing | Strictly reject requests containing both `client_secret` and MTLS certificates if configured for MTLS. |
| Incomplete SAN validation | Elevation of Privilege | Ensure the URI, DNS, and Email SAN comparisons use exact, case-normalized matches according to RFC 8705. |

## Sources

### Primary (HIGH confidence)
- Erlang OTP Documentation - `:public_key` extraction and record types
- Lockspire `.planning/phases/76-mtls-client-authentication/Phase76-STRATEGY.md`

### Secondary (MEDIUM confidence)
- Web search verified with Erlang headers for OID `{2, 5, 29, 17}` matching Subject Alternative Names.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Strategy explicitly defines tools to use
- Architecture: HIGH - Fits precisely into the mapped analogs
- Pitfalls: HIGH - Elixir/Erlang record mapping is a known, verifiable challenge

**Research date:** 2024-05-24
**Valid until:** 2024-06-24
