# Project Research Summary

**Project:** Lockspire
**Domain:** Embedded OAuth/OIDC Authorization Server
**Researched:** 2025-03-08
**Confidence:** HIGH

## Executive Summary

Lockspire is an embedded OAuth/OIDC Authorization Server built in Elixir. Recent research highlights that Lockspire must focus on OIDC Core Conformance, Back-Channel Logout, and optionally Front-Channel Logout and JAR Decryption (JWE) for financial-grade deployments. The recommended approach relies heavily on Lockspire's existing Elixir/Phoenix and Ecto/Postgres stack while introducing `req` for reliable server-to-server webhooks and utilizing the OpenID Foundation (OIDF) Conformance Suite to prove strict specification adherence. The architectural strategy strictly enforces a Host-Owned Session Clearing Seam, avoiding stateful session management within Lockspire itself. 

The most critical risk involves session management and single sign-out (SLO). Modern browsers aggressively block third-party cookies, fundamentally breaking Front-Channel Logout for cross-domain relying parties. To mitigate this, Lockspire must prioritize Back-Channel Logout (stateless server-to-server JWTs) requiring robust `sid` (Session ID) tracking across tokens and the database. Additionally, achieving official OIDC Core Conformance demands rigorous enforcement of JSON types (e.g., integer timestamps) and nested JWTs for secure JAR decryption to prevent common security traps.

## Key Findings

### Recommended Stack

Lockspire will build upon its existing Phoenix and Ecto foundations, adding specific tools for outgoing requests and spec validation.

**Core technologies:**
- **Phoenix (~> 1.8.5):** OP Web Surface — Natively handles Front-Channel Logout iframes, redirects, and session handoffs.
- **Ecto/Postgres (~> 3.13):** State Management — Tracks logout status and session bindings (`sid`) required for back/front-channel logout.
- **OIDF Conformance Suite:** OIDC Core Testing — The official "referee" tool to verify edge cases, type strictness, and OpenID Certification.
- **req (~> 0.5):** Back-Channel Logout POSTs — Standard Elixir HTTP client for reliable, automated retries and JSON encoding for outbound webhooks.
- **erlang-jose (~> 1.11):** JAR Decryption — Already in the project, natively supports `JOSE.JWE` for block/key decryption.

### Expected Features

**Must have (table stakes):**
- **OIDC Core Conformance (Strict)** — Exact behaviors for parameters and integer data types to ensure off-the-shelf client compatibility.
- **Back-Channel Logout** — Reliable Single Sign-Out (SLO) via direct server-to-server JWT webhooks, bypassing fragile browser cookie restrictions.

**Should have (competitive):**
- **JAR Decryption (JWE)** — Protects sensitive PII via encrypted authorization requests, required for high-security / FAPI profiles.
- **Front-Channel Logout** — HTML/iframe-based logout for legacy RPs or SPAs, though inherently fragile in modern browser environments.

**Defer (v2+):**
- **Implicit Flow / Form Post** — Deprecated by OAuth 2.1 BCPs due to token leakage. 
- **Stateful OP Sessions in Lockspire Core** — The host app must manage the Phoenix session; Lockspire relies on a handoff seam.
- **Custom Logout Protocols** — Avoid proprietary webhooks.

### Architecture Approach

The architecture isolates protocol processing from host session state, leveraging a handoff seam to clear cookies.

**Major components:**
1. **`Protocol.Jar`** — Decrypts JWE using AS private keys, then verifies the inner JWS signature (Sign-then-Encrypt pattern).
2. **`Protocol.BackChannelLogout`** — Orchestrates async HTTP POSTs to client `backchannel_logout_uri`s without blocking web requests.
3. **`Host.AccountResolver` / `Web.EndSessionController`** — The seam where Lockspire passes control back to the Host Phoenix App to clear the actual web session cookie.

### Critical Pitfalls

1. **Front-Channel Logout Broken by Third-Party Cookies** — Browsers block cross-domain iframe cookie access. Prioritize Back-Channel Logout and clearly document Front-Channel limitations.
2. **The Back-Channel Logout "Cookie Trap"** — The RP receives a webhook, not a browser request. RPs must invalidate the session in their backend store via `sid` instead of trying to clear a browser cookie.
3. **The JWE "Encryption-Only" Trap** — Encryption does not guarantee source authentication. Enforce the nested "Sign-then-Encrypt" pattern, verifying an inner JWS after decrypting the outer JWE.
4. **OIDC Conformance Type Strictness** — The OIDF Suite strictly fails string timestamps. Ensure `iat`, `exp`, and other numeric claims are strictly encoded as integers.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Domain & Storage Foundation
**Rationale:** Database tracking is a prerequisite for generating correct tokens and issuing webhooks.
**Delivers:** Ecto schema updates for `sid` on Tokens/Interactions, and configuration fields for Back/Front-Channel URIs on Client records.
**Addresses:** Back-Channel Logout, Front-Channel Logout.
**Avoids:** Global logout mistakes by strictly tying sessions to an identifiable `sid`.

### Phase 2: OIDC Session Tracking & RP-Initiated Logout
**Rationale:** The `GET /end_session` endpoint is the trigger for all subsequent logout workflows.
**Delivers:** The `Web.EndSessionController`, ID Token `sid` claim injection, and the `Host.AccountResolver.redirect_for_logout` seam.
**Uses:** Phoenix redirects.
**Implements:** The Host-Owned Session Clearing Seam (Architecture Component).
**Avoids:** Anti-Pattern 1: Lockspire directly managing or clearing the host app's session cookie.

### Phase 3: Back-Channel & Front-Channel Logout Delivery
**Rationale:** Implements the core SLO logic now that the session trigger and data models exist.
**Delivers:** Asynchronous `Protocol.LogoutToken` generation, HTTP POST dispatch via `req`, and synchronous Front-Channel `<iframe>` rendering.
**Addresses:** Back-Channel Logout, Front-Channel Logout.
**Avoids:** Blocking HTTP requests by using `Task.Supervisor` or an async queue for outbound Back-Channel POSTs.

### Phase 4: JAR Decryption (JWE) Core
**Rationale:** Essential for FAPI but conceptually independent from SLO.
**Delivers:** Updates to `Storage.KeyStore` for asymmetric encryption keys, `JOSE.JWE` decryption logic, and nested JWT validation in `Protocol.Jar`.
**Addresses:** JAR Decryption (JWE).
**Avoids:** JWE "Encryption-Only" Trap and asymmetric key rotation lockout via overlap windows.

### Phase 5: Core Conformance & Final Polish
**Rationale:** "Death by a thousand cuts" spec compliance, best handled once core features are functionally complete.
**Delivers:** Type strictness fixes (integer timestamps), exact redirect URI matching enforcement, and rigorous testing against the OIDF Conformance Suite.
**Addresses:** OIDC Core Conformance (Strict).
**Avoids:** OIDC Conformance Type Strictness pitfall.

### Phase Ordering Rationale
- **Dependencies:** Schema (`sid`) → End Session Trigger → Logout Execution. This logical flow prevents regressions during development.
- **Architecture:** Ensuring the Host Seam is built early clarifies the boundary between Lockspire protocol logic and Host authentication state.
- **Pitfalls:** Phasing Conformance at the end focuses purely on spec edge cases without blocking the foundational protocol work.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Logout Delivery):** Needs research on the preferred async task execution strategy in Elixir context (e.g., `Task.Supervisor` vs Oban) for high-scale environments.
- **Phase 5 (Conformance):** Needs research on automating the OIDF Conformance Suite via Docker for integration into CI pipelines.

Phases with standard patterns (skip research-phase):
- **Phase 1 & 2:** Standard Ecto and Phoenix Controller/LiveView patterns.
- **Phase 4:** Standard `JOSE` library implementations; nested JWT logic is well-documented.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Based on verified Elixir/Phoenix ecosystem standards and official foundation tools. |
| Features | HIGH | Directly maps to OpenID Connect Core and Logout specifications. |
| Architecture | HIGH | Clear, idiomatic separation between OP logic and Host web session state. |
| Pitfalls | HIGH | Sourced from known industry realities regarding modern browsers and OIDC security. |

**Overall confidence:** HIGH

### Gaps to Address

- **Async Task Queuing:** Determine if `Task.Supervisor` is sufficient for Back-Channel webhooks or if a durable queue like Oban must be a required host dependency for production-scale reliability.

## Sources

### Primary (HIGH confidence)
- OpenID Connect Core 1.0 Specification — OIDC Core Conformance and Signatures/Encryption
- OpenID Connect Back-Channel Logout 1.0 — Logout implementation standard
- OpenID Connect Front-Channel Logout 1.0 — Limitations and iframe implementation
- RFC 9101 (JWT-Secured Authorization Request - JAR) — Nested JWT requirements
- Official OIDF Conformance Suite documentation — Type strictness and certification

### Secondary (MEDIUM confidence)
- req Elixir Library Documentation — Standard HTTP client features and integrations

---
*Research completed: 2025-03-08*
*Ready for roadmap: yes*