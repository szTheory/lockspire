# Phase 75: MTLS Extraction Foundation (Decisions)

Based on Elixir/Plug idioms, ecosystem best practices, and Lockspire's architectural goal of host-owned boundaries, here is the cohesive set of decisions for implementing mTLS extraction.

## 1. Extractor Integration Method: Plug-based (`Lockspire.MTLS.Plug`)
**Decision**: Host applications MUST explicitly opt-in to mTLS extraction by placing `plug Lockspire.MTLS.Plug, extractor: {Mod, opts}` in their router pipeline, *before* forwarding to `Lockspire.Web.Router`. The extracted certificate will be stored in `conn.private[:lockspire_mtls_cert]`.

**Rationale**: 
- **Security & Least Surprise**: Proxy header spoofing is the #1 vulnerability in mTLS setups. By requiring an explicit Plug, Lockspire refuses to implicitly trust headers like `X-Forwarded-Client-Cert`. The host must declare that their infrastructure is correctly stripping headers at the edge and securely forwarding them.
- **Idiomatic Plug/Phoenix**: This mirrors how `Plug.SSL`, remote IP extraction, and `Plug.RequestId` work. It allows the host to conditionally apply extraction (e.g., only on certain routes or ports) using standard Phoenix pipelines.
- **DX**: If a Lockspire endpoint requires mTLS (e.g., due to a bound token) but the `conn.private` key is missing, Lockspire can raise a highly actionable developer error: "mTLS is required but no certificate was extracted. Did you forget to add `plug Lockspire.MTLS.Plug` to your router?"

## 2. Extractor Output Signature: Raw DER Binary
**Decision**: The `Lockspire.MTLS.Extractor` behaviour will define a single callback:
`@callback extract(Plug.Conn.t(), keyword()) :: {:ok, binary()} | {:error, atom()}`
It must return the raw DER-encoded binary of the client certificate (or an error if missing/invalid).

**Rationale**: 
- **Dependency Minimization**: The raw DER binary is the lowest common denominator and is exactly what's needed to compute the `x5t#S256` thumbprint (SHA256 over the DER binary). This avoids introducing heavy dependencies like the `x509` package into Lockspire.
- **Lazy Parsing**: For PKI CA-based client authentication (`tls_client_auth`), where the Subject DN needs to be inspected, Lockspire can lazy-parse the DER binary using Erlang's built-in `:public_key.pkix_decode_cert(der, :otp)` *only* when that specific auth method is invoked, rather than parsing it on every request.

## 3. Proxy Header Formatting: Explicit Format Opt-In
**Decision**: `Lockspire.MTLS.ProxyHeaderExtractor` will not attempt to magically guess the header format. The host must explicitly configure the format. 
Example: `extractor: {Lockspire.MTLS.ProxyHeaderExtractor, header: "x-forwarded-client-cert", format: :url_encoded_pem}`.
We will initially support `:url_encoded_pem` (standard Nginx/HAProxy) and `:envoy_xfcc` (Envoy Proxy).

**Rationale**: 
- **Security**: "Magic" parsing of security headers is a footgun. Envoy's XFCC format is a comma-separated list of key-value pairs (`Hash=...,Cert="..."`), while Nginx often sends raw URL-encoded PEM. Attempting to auto-detect the format risks parsing injection attacks.
- **Ergonomics**: The documentation will clearly provide the one-line configuration for Nginx, Envoy, and AWS API Gateway, making the "right way" the easiest way.

## 4. Native Cowboy Extraction (`CowboyDirectExtractor`)
**Decision**: `Lockspire.MTLS.CowboyDirectExtractor` will use `Plug.Conn.get_peer_data(conn)[:ssl_cert]` natively.

**Rationale**: 
- Plug already does the heavy lifting of extracting the peer certificate from Cowboy's underlying `:ssl` socket. Relying on `get_peer_data/1` ensures compatibility with any Cowboy upgrades or adapter changes without reaching into Cowboy internals.
