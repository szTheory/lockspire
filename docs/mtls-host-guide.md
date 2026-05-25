# Mutual TLS (RFC 8705) Host Guide

Lockspire supports Mutual TLS (mTLS) for client authentication (`tls_client_auth` and `self_signed_tls_client_auth`) and certificate-bound access tokens.

Because Lockspire is embedded inside your Phoenix application, it relies on your application (or your reverse proxy) to terminate the TLS connection and extract the client certificate. Lockspire then verifies the certificate against the client's registered configuration.

## 1. Configuring the MTLS Extractor

You must tell Lockspire how to extract the client certificate from the incoming request. Lockspire provides a behaviour (`Lockspire.MTLS.Extractor`) with two shipped implementations:

### Cowboy Direct (`Lockspire.MTLS.Extractor.CowboyDirect`)

Use this if your Phoenix application is directly terminating the TLS connection (e.g., via `plug_cowboy` with `https` configuration).

```elixir
# config/runtime.exs
config :lockspire,
  mtls_extractor: Lockspire.MTLS.Extractor.CowboyDirect
```

### Proxy Header (`Lockspire.MTLS.Extractor.ProxyHeader`)

Use this if your Phoenix application is behind a reverse proxy (e.g., Nginx, HAProxy) that terminates TLS and forwards the client certificate in an HTTP header.

```elixir
# config/runtime.exs
config :lockspire,
  mtls_extractor: {Lockspire.MTLS.Extractor.ProxyHeader, header: "x-client-cert"}
```

**⚠️ CRITICAL SECURITY WARNING: PROXY HEADER SPOOFING ⚠️**

If you use `Lockspire.MTLS.Extractor.ProxyHeader`, your reverse proxy **MUST** unconditionally strip or overwrite the configured header on all incoming requests from the public internet. If the proxy fails to do this, a malicious client could send their own `x-client-cert` header and spoof the mTLS authentication, completely bypassing your security.

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

## 3. Client Registration

Clients can register to use mTLS authentication by setting their `token_endpoint_auth_method` to either:

- `tls_client_auth`: Requires the client to register a `tls_client_auth_subject_dn`, `tls_client_auth_san_dns`, `tls_client_auth_san_uri`, `tls_client_auth_san_ip`, or `tls_client_auth_san_email`.
- `self_signed_tls_client_auth`: Requires the client to register a `jwks` or `jwks_uri` containing the public key of their self-signed certificate.

When a client uses these methods, Lockspire will extract the certificate using your configured `mtls_extractor`, verify it according to the client's registered constraints, and securely bind any issued access tokens to the certificate's thumbprint (RFC 8705).
