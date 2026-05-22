# Domain Pitfalls

**Domain:** Embedded OAuth/OIDC Provider (Phoenix/Elixir)
**Researched:** 2026-05-22

## Critical Pitfalls

### Pitfall 1: Proxy Header Spoofing
**What goes wrong:** Attackers inject `X-Forwarded-Client-Cert` headers into standard internet requests, bypassing mTLS client authentication entirely.
**Why it happens:** The edge proxy (Nginx/ALB) is configured to append the header upon successful mTLS, but is *not* configured to strip the header from incoming requests.
**Consequences:** Complete bypass of client authentication and sender-constrained token spoofing.
**Prevention:**
1. Lockspire must NOT ship a default, implicitly-trusted header parser.
2. The host app MUST explicitly configure an extractor behaviour.
3. Lockspire's documentation MUST loudly mandate header stripping at the edge proxy, preferably with example proxy configuration.

### Pitfall 2: Direct Cowboy Termination Conflicts
**What goes wrong:** The host app configures Cowboy `verify: :verify_peer`, but fails to configure the CA trust store (`cacerts`), causing Cowboy to reject all connections.
**Why it happens:** Erlang `:ssl` mTLS is notoriously finicky to configure correctly.
**Prevention:** Keep Lockspire out of the business of configuring Cowboy's Endpoint. Lockspire's documentation should point to official Phoenix/Plug guides for TLS termination, and only concern itself with extracting the cert from `Plug.Conn.get_peer_data/1` once the connection is established.

## Moderate Pitfalls

### Pitfall 1: x.509 Parsing Complexity
**What goes wrong:** Hand-rolled PEM extraction fails on valid edge cases (e.g., URL-encoded PEMs from Nginx vs. structured XFCC from Envoy).
**Prevention:** Use standard libraries (e.g., `x509`) and lean on the host app to provide the correct parsing logic for their specific infrastructure via the Extractor behaviour.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Token Binding | Overwriting existing DPoP bindings | Ensure the token pipeline supports both `jkt` (DPoP) and `x5t#S256` (MTLS) in the `cnf` claim, but explicitly reject requests that attempt to use both simultaneously to avoid ambiguity in validation. |