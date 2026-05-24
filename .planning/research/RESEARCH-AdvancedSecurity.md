# Research: Advanced Security & Authorization (RAR, CIBA, CAEP)

## Executive Summary & Recommendation

This document evaluates three advanced OAuth/OIDC extensions for Lockspire: **Rich Authorization Requests (RAR)**, **Client Initiated Backchannel Authentication (CIBA)**, and **Continuous Access Evaluation Profile (CAEP)**. 

**Recommendation:** **Rich Authorization Requests (RAR - RFC 9396) should be the next milestone** if the project is moving into advanced authorization capabilities. 

**Rationale:** RAR directly aligns with Lockspire's strategic priority to provide "real integrator leverage" without violating the embedded library thesis. It allows Phoenix SaaS apps (especially in fintech, healthcare, and complex B2B domains where Elixir thrives) to offer fine-grained, transaction-specific consent (e.g., "Transfer $50" vs. "Write access to all accounts"). Ecto and Elixir pattern matching make handling RAR's structured JSON idiomatic and highly ergonomic for host apps. 

Conversely, CIBA requires complex, host-owned out-of-band notification infrastructure (push/SMS) that pollutes the clean host seam, and CAEP pushes Lockspire towards enterprise workforce identity (an explicit non-goal) by requiring complex event streaming architectures.

---

## 1. Rich Authorization Requests (RAR - RFC 9396)

### Overview
RAR replaces coarse-grained OAuth scopes (e.g., `payment:write`) with structured, fine-grained JSON objects detailing exactly what is being authorized (e.g., `{"type": "payment_initiation", "amount": "50.00", "currency": "USD"}`).

### Pros, Cons, and Tradeoffs
*   **Pros:** 
    *   Unlocks FAPI (Financial-grade API) compliance and complex B2B use cases.
    *   Provides high-fidelity consent screens, drastically improving end-user trust and security.
    *   Fits perfectly with PAR (Pushed Authorization Requests), which Lockspire already supports (RAR objects can be large and are best pushed via PAR).
*   **Cons:**
    *   Increases the complexity of the host app's consent UI. The host must parse arbitrary JSON to render meaningful consent screens.
*   **Tradeoffs:** Adds schema validation overhead to the authorization pipeline, but delivers massive value to integrators who need transaction-level authorization.

### Elixir/Phoenix Idioms & Ergonomics
*   **Ecto & Postgres:** Ecto's `embeds_many` and Postgres `jsonb` are perfectly suited for storing RAR objects in `Consent` and `Token` records.
*   **Pattern Matching:** Elixir's pattern matching makes evaluating RAR objects against policy rules elegant and performant. 
*   **Host UX:** Lockspire can provide a clean struct (e.g., `Lockspire.RAR.AuthorizationDetail`) to the host app's Phoenix LiveView consent screen, maintaining the principle of least surprise. The host app developer receives a parsed, validated list of structs to render, rather than raw JSON.

---

## 2. Client Initiated Backchannel Authentication (CIBA)

### Overview
CIBA decouples the device where the user consumes the service from the device where they authenticate. A client (like a smart speaker or point-of-sale terminal) initiates a request, and the user receives a push notification on their phone to authenticate and consent.

### Pros, Cons, and Tradeoffs
*   **Pros:** Excellent for physical point-of-sale, call centers, or IoT devices.
*   **Cons:** Fundamentally requires out-of-band (OOB) communication (Push Notifications, SMS, Email). 
*   **Tradeoffs:** Lockspire, as an embedded library, does not own the host app's notification infrastructure. Implementing CIBA requires forcing a complex new seam onto the host app developer ("Implement this behaviour to send a push notification"). This creates high friction.

### Elixir/Phoenix Idioms & Ergonomics
While Elixir/OTP is excellent for the async polling/pinging required by CIBA, the developer ergonomics for the host app are poor. Successful libraries in this space (like Auth0 or Keycloak) succeed with CIBA because they are standalone services that *already own* the MFA/Push notification pipeline. Lockspire intentionally does not. Furthermore, Lockspire already shipped the **Device Authorization Grant (v1.6)**, which solves many of the same CLI/IoT use cases with much lower host-app integration burden.

---

## 3. Continuous Access Evaluation Profile (CAEP) / Shared Signals

### Overview
CAEP (part of the Shared Signals Framework) allows Identity Providers and Relying Parties to share real-time security events (e.g., "User's session was revoked", "Device became non-compliant") so access can be terminated immediately rather than waiting for token expiration.

### Pros, Cons, and Tradeoffs
*   **Pros:** The gold standard for Zero Trust architectures. Immediate revocation across federated systems.
*   **Cons:** Requires a robust event-delivery architecture (Webhooks, SSE, Polling), retry queues, and complex state management across distributed systems.
*   **Tradeoffs:** CAEP is an enterprise/workforce identity feature. `EPIC.md` explicitly lists "Becoming a full workforce identity or enterprise federation suite" as a Non-Goal. Adding CAEP pulls Lockspire away from its core thesis of being a simple, embedded B2B SaaS provider.

### Elixir/Phoenix Idioms & Ergonomics
Phoenix PubSub and Oban (which Lockspire already uses) would make the technical implementation of CAEP robust. However, the conceptual weight placed on the host app to configure webhook endpoints, manage cryptographic trust for event streams, and handle delivery failures violates the principle of keeping the operator experience simple and focused.

---

## Detailed Recommendation & Rationale

**Proceed with Rich Authorization Requests (RAR) as the next major feature milestone (post-1.0 stabilization).**

1.  **Synergy with Existing Milestones:** RAR compounds on existing investments. Lockspire has already shipped PAR (v1.2) and JAR (v1.4, v1.9). RAR naturally pairs with PAR/JAR because rich authorization requests are often too large for query strings and require integrity protection.
2.  **Domain Match:** Elixir is highly over-represented in fintech, blockchain, and complex healthcare systems—industries where coarse-grained scopes (`write:all`) are security dealbreakers. RAR gives Phoenix teams a competitive advantage by allowing them to offer transaction-level APIs to their partners safely.
3.  **Preserving the Seam:** RAR does not require Lockspire to take over new domains (like push notifications for CIBA or cross-domain event routing for CAEP). It strictly enhances the existing `Consent` and `Token` domain boundaries, keeping the embedded thesis intact.
4.  **Developer Experience (DX):** We can design the host seam such that the host's `ConsentController` or LiveView simply receives `conn.assigns.rich_authorizations`. By leveraging Ecto and Elixir structs, we turn a complex spec into a boring, typed data structure that Phoenix developers already know how to render. 

**Next Steps for RAR:**
*   Define the Ecto schema changes required for `Consent` and `Token` to store `jsonb` array of authorization details.
*   Design the host application seam (how the Phoenix LiveView consent screen receives and interacts with RAR data).
*   Ensure policy enforcement at the token endpoint correctly matches RAR objects attached to the grant against the requested RAR objects.