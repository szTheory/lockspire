# v1.20 Mutual TLS (RFC 8705) Requirements

## MTLS Extraction (MTLS-EXT)
- **MTLS-EXT-01**: Lockspire MUST define a `Lockspire.MTLS.Extractor` behaviour for retrieving client certificates.
- **MTLS-EXT-02**: Lockspire MUST provide a `CowboyDirectExtractor` for extracting certificates natively from Cowboy `:ssl` connections.
- **MTLS-EXT-03**: Lockspire MUST provide a `ProxyHeaderExtractor` for extracting URL-encoded PEM certificates from headers (e.g., `X-Forwarded-Client-Cert`).
- **MTLS-EXT-04**: Extraction MUST require explicit host configuration in the Plug pipeline; Lockspire MUST NOT implicitly trust proxy headers without host opt-in.

## Client Authentication (MTLS-AUTH)
- **MTLS-AUTH-01**: Lockspire MUST support the `tls_client_auth` client authentication method using a registered CA subject DN.
- **MTLS-AUTH-02**: Lockspire MUST support the `self_signed_tls_client_auth` client authentication method using the client's registered JWKS.
- **MTLS-AUTH-03**: The Token Endpoint MUST reject requests if the extracted certificate does not match the registered client credentials.

## Certificate-Bound Tokens (MTLS-BIND)
- **MTLS-BIND-01**: Lockspire MUST embed the `x5t#S256` claim within the `cnf` (confirmation) claim of access tokens when mTLS is used.
- **MTLS-BIND-02**: Protected endpoints (like Userinfo) MUST reject tokens if the presented client certificate does not match the `x5t#S256` thumbprint.

## Discovery & Documentation (MTLS-DOC)
- **MTLS-DOC-01**: The OIDC Discovery endpoint MUST advertise `mtls_endpoint_aliases` for relevant endpoints.
- **MTLS-DOC-02**: The OIDC Discovery endpoint MUST list `tls_client_auth` and `self_signed_tls_client_auth` in `token_endpoint_auth_methods_supported`.
- **MTLS-DOC-03**: Security documentation MUST explicitly warn operators about proxy header spoofing and the necessity of stripping headers at the edge proxy.