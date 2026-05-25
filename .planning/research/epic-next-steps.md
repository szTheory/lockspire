# Epic Next Steps: The Path Forward for Lockspire

**Context:** Evaluating the next major milestones for Lockspire (Embedded OAuth/OIDC for Elixir).
**Candidates:** RFC 9328 (RAR), RFC 8705 (mTLS), RFC 8693 (Token Exchange), OpenID Connect CIBA, 1.0 GA Release.

---

## 1. Evaluation of Candidate Milestones

### Candidate 1: 1.0 GA Release (Stabilization)
A 1.0 GA release focuses on solidifying the massive feature set Lockspire has already shipped (Auth Code, PAR, JAR, DCR, Device Flow, DPoP, FAPI 2.0).
*   **Pros:** Establishes trust. Enterprise adopters will not integrate a pre-1.0 security library. Forces a cleanup of public APIs, robust documentation, and security audits.
*   **Cons:** Not a "shiny new protocol feature". Requires tedious documentation and testing work.
*   **Idiomatic Elixir:** Finalizing `@moduledoc`, `@doc`, and Typespecs. Ensuring telemetry events are consistent.
*   **Lessons Learned:** Libraries like Doorkeeper and IdentityServer thrived because of their rock-solid core APIs and extensive documentation.
*   **Recommendation:** **Absolute highest priority.** All subsequent protocol additions must be built on a stable, semantic-versioned contract to prevent host-app churn.

### Candidate 2: RFC 8693 OAuth 2.0 Token Exchange
Allows clients to exchange tokens (impersonation, delegation). Essential for microservices.
*   **Pros:** High demand for API gateways and service meshes. Relatively straightforward protocol addition (new grant type).
*   **Cons:** Requires careful validation of *who* is allowed to exchange *what* (security risks if too permissive).
*   **Idiomatic Elixir:** Excellent fit for Elixir backends that serve as BFFs (Backend-for-Frontend) or internal orchestrators. Host apps can provide an implementation of a `Lockspire.TokenExchangeValidator` behaviour to handle domain-specific delegation logic.
*   **Lessons Learned:** Keycloak enables this via a simple configuration but relies heavily on policies. Duende uses highly extensible interfaces. Lockspire should avoid hardcoding logic and instead provide a Behaviour for host apps to validate the `subject_token` and `actor_token`.
*   **Recommendation:** **High priority.** A natural extension of token issuing that provides massive utility to enterprise users.

### Candidate 3: OpenID Connect CIBA (Client Initiated Backchannel Auth)
Decoupled authentication (e.g., POS terminal initiates, user approves on mobile app).
*   **Pros:** Elixir/Phoenix is the *best ecosystem in the world* for CIBA. The asynchronous nature of CIBA (Push, Ping, Poll modes) maps perfectly to Phoenix Channels, PubSub, and Oban background jobs.
*   **Cons:** Requires the host app to build out the "Authentication Device" UI and notification mechanism.
*   **Lessons Learned:** Duende restricts this to Enterprise tiers due to its complexity. Keycloak requires external services (ExtAuth). Lockspire can offer an incredibly ergonomic experience by emitting native Phoenix PubSub events that host apps listen to in their LiveViews.
*   **Ergonomics (DX):**
    ```elixir
    # Host app simply subscribes to the user's CIBA topic
    Lockspire.PubSub.subscribe("ciba:user_123")
    
    # In a LiveView, handle the prompt
    def handle_info({:ciba_request, req}, socket) do
       {:noreply, assign(socket, :pending_ciba, req)}
    end
    ```
*   **Recommendation:** **Medium/High priority.** A massive differentiator for Lockspire that plays perfectly to Elixir's strengths.

### Candidate 4: RFC 8705 Mutual TLS (mTLS)
mTLS for client auth and sender-constrained tokens.
*   **Pros:** Required for ultimate FAPI 2.0 compliance and high-security financial environments.
*   **Cons:** Exceptionally hostile deployment environment in Elixir. Standard Phoenix apps sit behind TLS-terminating proxies (AWS ALB, Nginx, Fly.io). The proxy must forward the certificate via HTTP headers.
*   **Idiomatic Elixir:** Requires a Plug that reads headers (like `X-Forwarded-Client-Cert`).
*   **Footguns:** If the reverse proxy does not strip incoming certificate headers, malicious actors can spoof mTLS certificates.
*   **Lessons Learned:** The `apiac_auth_mtls` Elixir library handles this by allowing configurable header names and encodings. Lockspire must adopt this pattern and document the proxy security requirements extensively.
*   **Recommendation:** **Medium priority.** Essential for FAPI but introduces significant infrastructural friction. Defer until after 1.0.

### Candidate 5: RFC 9328 Rich Authorization Requests (RAR)
JSON-based, fine-grained authorization details replacing standard string scopes.
*   **Pros:** Incredibly powerful for complex domains (Open Banking, healthcare).
*   **Cons:** Very bleeding edge. Ory Hydra lacks native support. Keycloak is still iterating on it. Complex UI/UX for the consent screen.
*   **Idiomatic Elixir:** Host apps could provide Ecto `embedded_schema` modules to validate incoming `authorization_details` JSON payloads, making validation robust and type-safe.
*   **Recommendation:** **Low priority.** The ecosystem is not entirely settled here. Wait for standard patterns to emerge.

---

## 2. Proposed DAG of Work

To avoid diminishing returns and prioritize high-impact development, Lockspire should sequence its milestones as follows:

### Step 1: The Stabilization Epoch
**Goal: 1.0 GA Release**
*   **Why:** You cannot build a house on shifting sand. Lockspire has massive capabilities (DPoP, FAPI 2.0). It needs a stable API contract, security audits, and comprehensive documentation.
*   **Impact:** Unblocks cautious enterprise adopters.

### Step 2: The Microservices & Real-Time Epoch
**Goal: Token Exchange (RFC 8693) → OIDC CIBA**
*   **Why:** Token Exchange solves the immediate backend-to-backend authorization problem. CIBA leverages Phoenix PubSub to deliver a killer feature that competitor frameworks in Go/Ruby struggle to implement gracefully.
*   **Impact:** Showcases the Elixir ecosystem's inherent advantages. CIBA becomes the "wow" feature for demos.

### Step 3: The Ultimate Security Epoch
**Goal: Mutual TLS (RFC 8705)**
*   **Why:** Completes the FAPI 2.0 Advanced security profile.
*   **Impact:** Niche, but mandatory for Open Banking environments. Best tackled when the core framework is stable and community feedback on deployment infra (Fly/AWS) is mature.

### Step 4: The Advanced Authorization Epoch
**Goal: Rich Authorization Requests (RAR) (RFC 9328)**
*   **Why:** Once standard string scopes break down for host apps, RAR provides the solution.
*   **Impact:** Future-proofing for next-gen authorization paradigms.

---
**Conclusion:** 
Do not chase RAR or mTLS immediately. Lock down the `1.0 GA` release to secure your current feature set. Follow it up with `Token Exchange` and `CIBA`, both of which are highly requested, practically useful, and highlight the architectural superiority of the Elixir/Phoenix stack.
