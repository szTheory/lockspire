# Research Summary: Lockspire Next Epic Milestones

**Domain:** Embedded OAuth/OIDC Provider for Elixir/Phoenix
**Researched:** 2025-05-24
**Overall confidence:** HIGH

## Executive Summary

Lockspire has already shipped a formidable foundational layer (Auth Code, PAR, JAR, DCR, Device Flow, DPoP, Session Management, FAPI 2.0 Draft). Evaluating the next "giant leaps" requires balancing advanced protocol features against ecosystem readiness, developer ergonomics (DX), and the stabilization necessary for broad adoption. 

The five candidate milestones vary wildly in complexity and immediate value. A 1.0 GA release offers the highest return on investment by establishing a stable contract for early adopters. Token Exchange (RFC 8693) and CIBA offer high utility and showcase the strengths of the Elixir ecosystem (concurrency, PubSub). mTLS (RFC 8705) is crucial for true high-security (FAPI) setups but introduces severe infrastructural footguns for Phoenix deployments. Rich Authorization Requests (RAR) is powerful but remains a bleeding-edge specification with sparse native support across standard Identity Providers, though Keycloak and Duende are paving the way.

## Key Findings

**Stack:** Phoenix/Elixir/Plug architecture makes CIBA exceptionally idiomatic due to Channels/PubSub, but complicates mTLS due to reverse-proxy TLS termination.
**Architecture:** Token Exchange and RAR require exposing highly extensible plugin systems for host apps to define domain-specific validation logic.
**Critical pitfall:** Implementing mTLS without robustly warning and educating developers on reverse-proxy header stripping (e.g., `X-Client-Cert` spoofing).

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Phase: 1.0 GA Release (Stabilization)** - Lockspire has massive surface area. Securing public APIs, auditing, and guaranteeing a stable contract will drive adoption faster than adding more niche RFCs.
   - Addresses: Public APIs, Documentation, Audit, Migration paths.
   - Avoids: Churning host app codebases with constant breaking changes.

2. **Phase: OAuth 2.0 Token Exchange (RFC 8693)** - Highly requested feature in microservices architectures.
   - Addresses: Service-to-service impersonation and delegation.

3. **Phase: OpenID Connect CIBA** - Showcases Elixir's concurrency and PubSub strengths perfectly.
   - Addresses: Decoupled authentication flows.

4. **Phase: Mutual TLS (mTLS) (RFC 8705)** - FAPI 2.0 requires it for full compliance, but it relies heavily on infrastructure layers outside Lockspire's control.

5. **Phase: Rich Authorization Requests (RAR) (RFC 9328)** - Defer until standard patterns emerge more fully in the ecosystem.

**Phase ordering rationale:**
- Stabilization (1.0 GA) is paramount after shipping FAPI 2.0. Users need a stable base. Token Exchange is standard for microservices. CIBA is an architectural win for Phoenix. mTLS is complex and infrastructural, best added when enterprise demand arises. RAR is too bleeding-edge and complex to prioritize over a 1.0 release.

**Research flags for phases:**
- Phase mTLS: Needs deep research on how Fly.io, Gigalixir, and AWS handle client cert forwarding.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Validated via `apiac_auth_mtls` patterns in Elixir. |
| Features | HIGH | Cross-referenced Keycloak, Duende, Ory Hydra support levels. |
| Architecture | HIGH | Clear separation of concerns required for host extensibility. |
| Pitfalls | HIGH | mTLS reverse proxy header spoofing is a well-documented critical risk. |
