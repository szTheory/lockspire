# Phase 76: MTLS Client Authentication Strategy

**Goal**: Support mTLS client authentication methods (`tls_client_auth` and `self_signed_tls_client_auth`) at the token and introspection endpoints, as defined in RFC 8705.

## Context and Requirements
We need to support two new token endpoint authentication methods:
1. **`tls_client_auth`**: PKI/CA-based validation. The client must match a registered Subject DN or SAN (DNS, URI, IP, or Email).
2. **`self_signed_tls_client_auth`**: The client's self-signed certificate public key must match a key in the client's registered JWKS.

We must shift the design decisions left, favoring cohesive, complete, and idiomatic approaches that provide the best developer experience (DX) and align with the project's vision of maximum security by default.

## 1. Domain Model Extensions

**Recommendation**: Add all 5 PKI matching methods to the Ecto schema immediately.
- **Why**: RFC 8705 defines 5 attributes (`tls_client_auth_subject_dn`, `tls_client_auth_san_dns`, `tls_client_auth_san_uri`, `tls_client_auth_san_ip`, `tls_client_auth_san_email`). Implementing all of them from the start prevents "partial compliance" and eliminates technical debt if OIDF conformance tests require specific SANs. Ecto schema columns are cheap to add and provide a complete API.
- **Implementation**:
  - Add to `Lockspire.Domain.Client`:
    - `tls_client_auth_subject_dn: :string`
    - `tls_client_auth_san_dns: :string`
    - `tls_client_auth_san_uri: :string`
    - `tls_client_auth_san_ip: :string`
    - `tls_client_auth_san_email: :string`
  - Ensure validations enforce that at most one of these is set, as per RFC 8705.
  - Update `Lockspire.Security.Policy` to include `:tls_client_auth` and `:self_signed_tls_client_auth` in `@supported_token_endpoint_auth_methods`.

## 2. Certificate Parsing Engine

**Recommendation**: Build a clean Elixir facade `Lockspire.MTLS.Certificate` over Erlang's `:public_key.pkix_decode_cert/2`.
- **Why**: Erlang OTP provides robust, battle-tested X.509 parsing, meaning zero external dependencies. However, interacting with Erlang records directly in protocol logic is poor DX and leaks abstraction.
- **Implementation**:
  - `Lockspire.MTLS.Certificate.parse(der_binary)` returns an easy-to-use struct `%{subject_dn: string, sans: %{dns: [], uri: [], ip: [], email: []}, public_key: binary}`.
  - **Pros**: The rest of the codebase works with simple Elixir structs, completely isolated from Erlang's ASN.1 decoding nuances.

## 3. Client Authentication Core (`ClientAuth`)

**Recommendation**: Treat MTLS certificates as out-of-band context rather than explicit credentials to parse in the initial step.
- **Why**: The token endpoint can receive just a `client_id` in the body. If `opts[:mtls_cert]` is populated from the Plug connection, the actual authentication method depends on the client's registered settings.
- **Implementation**:
  - Update Plug endpoints (e.g., `TokenExchange`, `Introspection`, `Revocation`) to pass `opts[:mtls_cert] = conn.private[:lockspire_mtls_cert]` into `ClientAuth.authenticate/3`.
  - Modify `evaluate_client_credentials` to return a unified `{:ok, :implicit_client_id, id, nil}` when only a `client_id` is provided in the body.
  - In the validation phase, if the client has `token_endpoint_auth_method: :tls_client_auth`, look for `opts[:mtls_cert]` and validate it against the client's registered Subject/SANs.
  - If it's `:self_signed_tls_client_auth`, extract the public key from `opts[:mtls_cert]` and verify it exists within the client's JWKS.
  - **Pros**: The protocol state machine stays elegant. Authentication resolution natively supports fallback to MTLS if standard credentials are intentionally omitted.

## 4. Developer Ergonomics and Safety

- **Fail-closed**: If a client is registered for MTLS but no certificate is provided by the load balancer (meaning `conn.private[:lockspire_mtls_cert]` is empty), the authentication strictly fails.
- **Telemetry**: Emit explicit telemetry events (`[:lockspire, :client_auth, :mtls, :success]`, etc.) to provide observability into MTLS binding outcomes.
- **No mixed methods**: We will explicitly reject requests that include both an MTLS cert and a `client_secret` (unless required for future Phase 77 cert-bound tokens, but for auth, we will keep it strict).

## Summary
By front-loading the 5 standard PKI attributes and wrapping the Erlang `:public_key` API in a clean Elixir struct, Lockspire provides full RFC 8705 compliance out-of-the-box. Passing the extracted certificate through the controller layer into the authentication core via options ensures the architecture remains cleanly layered and decoupled from HTTP concerns.
