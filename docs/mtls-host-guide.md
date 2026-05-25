# Mutual TLS (RFC 8705) Host Guide

Lockspire supports Mutual TLS (mTLS) for client authentication (`tls_client_auth` and `self_signed_tls_client_auth`) and certificate-bound access tokens.

Because Lockspire is embedded inside your Phoenix application, the mTLS setup story starts with your host app or deployment. Lockspire ships exactly two first-class extraction patterns:

- `Lockspire.MTLS.Extractor.CowboyDirect` when your Phoenix app terminates TLS directly
- `Lockspire.MTLS.Extractor.ProxyHeader` when a trusted reverse proxy terminates TLS and forwards the certificate

The host app or infrastructure owns TLS termination, trusted forwarding, and unconditional stripping or overwriting of forwarded certificate headers before the request reaches Phoenix. After the certificate has been extracted from the request seam, Lockspire owns certificate verification against the client's registered configuration plus token binding enforcement.

For the canonical advanced-setup support contract, see [Supported Surface](supported-surface.md). This guide stays focused on how to satisfy the shipped extractor prerequisites without implying that Lockspire hides your deployment responsibilities.

## 1. Configuring the MTLS Extractor

You must tell Lockspire how to extract the client certificate from the incoming request. Lockspire provides the `Lockspire.MTLS.Extractor` behaviour, but the default supported story is the two shipped extractor patterns below.

### Cowboy Direct (`Lockspire.MTLS.Extractor.CowboyDirect`)

Use this if your Phoenix application is directly terminating the TLS connection (e.g., via `plug_cowboy` with `https` configuration).

```elixir
# config/runtime.exs
config :lockspire,
  mtls_extractor: Lockspire.MTLS.Extractor.CowboyDirect
```

### Proxy Header (`Lockspire.MTLS.Extractor.ProxyHeader`)

Use this if your Phoenix application is behind a reverse proxy (e.g., Nginx, HAProxy, Envoy) that terminates TLS and forwards the client certificate in an HTTP header. Your deployment must ensure the proxy is trusted and that only the proxy can supply the forwarded certificate header.

```elixir
# config/runtime.exs
config :lockspire,
  mtls_extractor: {Lockspire.MTLS.Extractor.ProxyHeader, header: "x-client-cert"}
```

**⚠️ CRITICAL SECURITY WARNING: PROXY HEADER SPOOFING ⚠️**

If you use `Lockspire.MTLS.Extractor.ProxyHeader`, your reverse proxy **MUST** unconditionally strip or overwrite the configured header on all incoming requests from the public internet. If the proxy fails to do this, a malicious client could send their own `x-client-cert` header and spoof the mTLS authentication, completely bypassing your security.

Lockspire does not hide or absorb this deployment risk. The anti-spoofing guarantee belongs to the host app and infrastructure boundary, not to the embedded library.

**Nginx Example:**
```nginx
server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate /path/to/server.crt;
    ssl_certificate_key /path/to/server.key;

    # Enable mTLS
    ssl_verify_client optional_no_ca;

    location / {
        # Unconditionally clear the header first to prevent spoofing!
        proxy_set_header X-Client-Cert "";

        # If a client certificate was provided, set the header
        if ($ssl_client_cert) {
            proxy_set_header X-Client-Cert $ssl_client_cert;
        }

        proxy_pass http://localhost:4000;
    }
}
```

## 2. Configuring the MTLS Issuer and Discovery

To advertise your mTLS endpoints in the OIDC Discovery document (`/.well-known/openid-configuration`), you must configure the `mtls_issuer`. This is typically on a different subdomain or port (e.g., `https://mtls.example.com` or `https://example.com:8443`) that requires client certificates, while your standard `issuer` remains open to the public internet for browser flows.

```elixir
# config/runtime.exs
config :lockspire,
  issuer: "https://example.com/lockspire",
  mtls_issuer: "https://mtls.example.com/lockspire"
```

When `mtls_issuer` is set, Lockspire will automatically publish the `mtls_endpoint_aliases` block in your discovery document, directing mTLS-capable clients to the correct endpoints for token, revocation, introspection, and other direct-client interactions.

## 3. Host Responsibilities Versus Lockspire Responsibilities

Before you advertise or accept mTLS clients, confirm the ownership split is explicit in your deployment:

- The host app or infrastructure owns TLS termination, client-certificate forwarding, proxy trust boundaries, and header anti-spoofing.
- Lockspire owns validating the extracted certificate against registered client metadata and enforcing certificate-bound token checks once the certificate reaches the request.
- Custom `Lockspire.MTLS.Extractor` implementations remain available as an escape hatch for unusual deployments, but they are not first-class peers to the shipped Cowboy direct and trusted proxy-header patterns in the support contract.

## 4. Client Registration

Clients can register to use mTLS authentication by setting their `token_endpoint_auth_method` to either:

- `tls_client_auth`: Requires the client to register a `tls_client_auth_subject_dn`, `tls_client_auth_san_dns`, `tls_client_auth_san_uri`, `tls_client_auth_san_ip`, or `tls_client_auth_san_email`.
- `self_signed_tls_client_auth`: Requires the client to register a `jwks` or `jwks_uri` containing the public key of their self-signed certificate.

When a client uses these methods, Lockspire will extract the certificate using your configured `mtls_extractor`, verify it according to the client's registered constraints, and securely bind any issued access tokens to the certificate's thumbprint (RFC 8705).
