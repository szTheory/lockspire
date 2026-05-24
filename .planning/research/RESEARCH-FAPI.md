# Research: FAPI Conformance and Certification Profiles

## Executive Summary & Recommendation

**Recommendation:** **Target FAPI 2.0 Security Profile as the NEXT milestone.**

Lockspire is uniquely positioned to achieve FAPI 2.0 Security Profile with relatively low effort because the heaviest prerequisites—PAR (Pushed Authorization Requests), DPoP (Demonstrating Proof-of-Possession), and JAR (JWT Secured Authorization Requests)—have already been delivered in prior phases. FAPI 2.0 provides an enormous leap in "real-integrator trust" without requiring the infrastructural complexity of FAPI 1.0 Advanced (specifically mTLS). Achieving FAPI 2.0 solidifies Lockspire's standing as a serious, enterprise-ready provider while preserving the simple embedded-library ergonomics.

## Context

The Financial-grade API (FAPI) profiles, maintained by the OpenID Foundation, are strict, highly secure subsets of OAuth 2.0 and OpenID Connect designed to protect high-value APIs (like open banking, healthcare, and e-government).

*   **FAPI 1.0 Advanced:** Relies heavily on Mutual TLS (mTLS) for client authentication and sender-constrained tokens, detached signatures (JWS in ID tokens), and JARM (JWT Secured Authorization Response Mode).
*   **FAPI 2.0 Security Profile:** A modernized, simplified standard that deprecates many FAPI 1.0 complexities. It enforces strong sender-constraining by requiring PAR and DPoP or mTLS. Because DPoP and PAR are supported as first-class alternatives to mTLS in FAPI 2.0, it is highly attractive for web-based IdPs where terminating mTLS at the application layer is painful.

## Feasibility in Elixir/Phoenix

**High Feasibility for FAPI 2.0.**

*   **The mTLS Constraint:** In Elixir/Phoenix, the application typically runs behind a reverse proxy (Nginx, HAProxy, AWS ALB). Terminating mTLS at the proxy and passing client certificates down to Plug via headers is fraught with operational risk, misconfiguration vectors, and infrastructure dependency. This violates Lockspire's goal of being a zero-friction embedded library.
*   **The DPoP/PAR Advantage:** FAPI 2.0 allows DPoP for sender-constrained tokens and PAR for secure request transmission. Lockspire has already shipped DPoP (v1.7) and PAR (v1.2). The heavy lifting is already done.
*   **Implementation Gap:** To reach FAPI 2.0, Lockspire primarily needs to implement **Profile Enforcement** (e.g., rejecting requests without PAR, rejecting public clients for certain scopes, strictly enforcing DPoP, strongly enforcing exact redirect URI matching).

## Lessons Learned from Ecosystem Precedents

1.  **node-oidc-provider:**
    *   *Lesson:* It achieves incredible conformance but at a massive cost to developer ergonomics. The configuration object is notoriously complex. Host developers often struggle to know which combinations of flags are secure or valid.
    *   *Takeaway for Lockspire:* Do not expose 50 individual boolean flags. Expose a single `security_profile: :fapi_2_0_security` configuration that internally enforces the strict ruleset. Let the library handle the internal assertions.

2.  **OpenIddict (C#/.NET):**
    *   *Lesson:* OpenIddict uses fluent builders and explicit opt-in for features. It effectively separates the core protocol engine from the host framework.
    *   *Takeaway for Lockspire:* Keep the host integration seams simple. When a profile is enabled, provide clear, actionable error messages in the server logs when a client misbehaves, so the Phoenix developer doesn't have to guess why a FAPI-compliant request was rejected.

## Developer Ergonomics and the Principle of Least Surprise

Lockspire's core value is allowing a Phoenix team to become a trustworthy provider *without* assembling dangerous pieces by hand. FAPI adoption must not disrupt this.

*   **Opt-in by Profile:** The UX for the host developer should be setting a single atom in their config, e.g., `security_profile: :fapi_2_0_security`.
*   **Fail-fast Configuration:** If the host developer enables FAPI 2.0 but has not enabled the requisite underlying features (like DPoP or PAR), Lockspire should fail to start or raise a clear warning at compile/boot time.
*   **Operator Tooling:** The LiveView admin UI should visually indicate if a client is operating under a strict FAPI profile or if the entire server is running in a locked-down mode.

## Pros, Cons, and Tradeoffs

### Pros
*   **Massive Trust Signal:** FAPI compliance is the gold standard for OAuth security. It proves Lockspire is not just a toy library and fulfills the mandate of "raising real-client trust."
*   **Leverages Existing Investment:** Capitalizes immediately on the hard work done in v1.2 (PAR) and v1.7 (DPoP).
*   **Avoids mTLS Infrastructure Burden:** By targeting FAPI 2.0 via DPoP, we avoid forcing Phoenix developers to reconfigure their reverse proxies.

### Cons
*   **Protocol Rigidity:** Strict profiles reject "sloppy" OAuth clients. This might cause friction for host developers trying to onboard legacy third-party clients.
*   **Testing Complexity:** Running the OIDF FAPI conformance suite locally requires significant setup and maintenance overhead.

### Tradeoffs
*   We choose to target **FAPI 2.0** over **FAPI 1.0 Advanced**. FAPI 1.0 is currently more widely mandated in some specific regional open banking laws, but FAPI 2.0 is the undeniable future of the spec and maps perfectly to Lockspire's DPoP/PAR capabilities. We trade immediate legacy regional compliance for modern, ergonomic security that fits the Elixir ecosystem.

## Conclusion

The strategic priority defined in `EPIC.md` is to "Raise real-client trust on the surfaces already shipped." Adding FAPI 2.0 Security Profile validation is the ultimate multiplier for the features Lockspire has built over the last several milestones. It wraps existing capabilities (PAR, DPoP, JAR) into an industry-recognized certification target. It aligns perfectly with the embedded-library shape, avoids infrastructure sprawl, and proves the serious posture of the provider. **It should absolutely be the next milestone.**