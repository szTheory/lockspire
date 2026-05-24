# Research: mTLS Client Authentication and Certificate-Bound Access Tokens (RFC 8705)

## Executive Summary & Recommendation

**Recommendation: DO NOT make mTLS the next milestone. Keep it deferred to Post-1.0.**

Lockspire’s core value is being an *embedded* OAuth/OIDC provider that Phoenix teams can drop into existing applications. While mTLS (RFC 8705) provides robust sender-constrained tokens and client authentication, it fundamentally conflicts with the operational reality of modern Phoenix deployments. Phoenix apps almost universally sit behind reverse proxies or PaaS load balancers (Fly.io, AWS ALB, Heroku, Cloudflare) that terminate TLS. 

Supporting mTLS requires the host app developer to configure their infrastructure to terminate mTLS and securely forward the client certificate (or its thumbprint) to the Erlang VM via HTTP headers. This violates the principle of least surprise, destroys the "drop-in library" developer ergonomics, and introduces severe infrastructure complexity. 

Furthermore, Lockspire just shipped DPoP (v1.7), which solves the exact same security requirement (sender-constrained tokens and proof-of-possession) entirely at the application layer, completely bypassing the TLS proxy problem.

## Feature Overview (RFC 8705)

RFC 8705 defines two distinct features:
1. **mTLS Client Authentication (`tls_client_auth`):** Clients authenticate to the token endpoint using a mutual TLS certificate instead of a shared secret or JWT assertion.
2. **Certificate-Bound Access Tokens:** The authorization server embeds the SHA-256 thumbprint of the client's TLS certificate (`x5t#S256`) in the access token. Protected resources then verify that the client presenting the token is using the same TLS certificate.

## Feasibility in Elixir / Phoenix (The Proxy Problem)

In a raw Cowboy environment, accepting client certificates is feasible via `Transport` options in `Plug.Cowboy`. 

However, in the real world, Phoenix apps do not expose Cowboy directly to the internet. They run behind:
* Fly.io Anycast proxies
* AWS Application Load Balancers
* Cloudflare
* Nginx / HAProxy

When TLS is terminated at the proxy, Cowboy receives plain HTTP. To make mTLS work, the infrastructure must be configured to:
1. Request and validate the client certificate at the edge.
2. Inject the certificate (often PEM-encoded or just the thumbprint) into a trusted HTTP header (e.g., `X-Forwarded-Client-Cert`).
3. Ensure the proxy strips any user-injected instances of this header to prevent spoofing.

**Feasibility:** Technically possible, but operationally hostile. It pushes protocol correctness out of the Elixir codebase and into the host's infrastructure configuration.

## Pros, Cons, and Tradeoffs

### Pros
* **High Security:** Cryptographically binds tokens to the client's TLS session. Prevents token theft and replay attacks.
* **B2B / OpenBanking Standard:** Highly requested in Enterprise and Financial ecosystems (e.g., FAPI).
* **No App-Layer Crypto for Clients:** Unlike DPoP, clients don't need to sign every request; the TLS stack handles the crypto automatically.

### Cons
* **Infrastructure Tax:** Ruptures the "embedded library" promise. Host developers must master edge TLS termination and header forwarding.
* **Spoofing Risks:** If the host developer misconfigures the proxy and fails to strip spoofed `X-Client-Cert` headers, the auth server is compromised.
* **Certificate Management:** Managing, rotating, and revoking client certificates is a heavy operational burden compared to standard JWKS.

## Lessons Learned from the Ecosystem

* **node-oidc-provider:** Supports mTLS but explicitly warns developers about the reverse proxy problem. It requires configuring specific trusted headers and strictly validating proxy boundaries. 
* **OpenIddict:** Also supports mTLS and offers extensions for extracting certs from headers. However, integration tickets frequently show developers struggling with IIS/Nginx/Kestrel misconfigurations where the cert is dropped or headers are insecure.

Both libraries show that while the protocol code is easy to write, the support burden and developer UX suffer heavily due to infrastructure variance.

## DPoP vs. mTLS (The Case for DPoP)

Lockspire recently delivered DPoP (RFC 9449) in Phase 33-36 (see `lib/lockspire/protocol/dpop.ex`). 
* **Layer:** DPoP operates at Layer 7 (Application). mTLS operates at Layer 4/6 (Transport).
* **Ergonomics:** DPoP passes through load balancers natively. mTLS gets stripped.
* **Security Outcome:** Both provide sender-constrained tokens and replay protection.
* **Lockspire Context:** Since Lockspire already has DPoP, we already offer a top-tier security mechanism for preventing token theft. Adding mTLS right now offers diminishing marginal returns at a massive cost to host integration simplicity.

## Conclusion

Adding mTLS should remain parked in the **Post-1.0 / Advanced Security and Conformance** bucket as defined in `EPIC.md`. It is the wrong choice for the next milestone. The next milestone should continue focusing on features that compound on the existing application-layer trust surface (like completing JAR decryption) without requiring host apps to re-architect their infrastructure.