# Phase 72: JARM Encryption & Metadata - Architectural Research & Recommendations

This document details deep architectural research and recommendations for JARM (JWT Secured Authorization Response Mode) Encryption & Metadata in the Lockspire OpenID Connect provider. The focus is on robust security, excellent developer ergonomics (DX/UX), idiomatic Elixir/Plug design, and the principle of least surprise.

## 1. JWE Nesting & Elixir JOSE Ergonomics

**The Challenge:**
JARM requires that authorization responses be signed and then encrypted (Nested JWT) if the client specifies `authorization_encrypted_response_alg` and `authorization_encrypted_response_enc`. The Erlang/Elixir `jose` library is powerful but highly technical, operating on raw keys, JWKs, JWS, and JWE structures. Leaking these low-level `jose` primitives into business logic causes friction and makes the codebase brittle.

### Approaches

**Approach A: Raw `jose` Calls in the Business Logic**
*   **Pros:** Minimal abstraction; full access to `jose` features.
*   **Cons:** Extremely poor ergonomics. Code becomes cluttered with `JOSE.JWS`, `JOSE.JWE`, and `JOSE.JWK` module calls. High risk of messing up the strict "Sign THEN Encrypt" order.
*   **Tradeoffs:** Trades developer experience for explicitness, violating the principle of least surprise for future maintainers.

**Approach B: Dedicated `Lockspire.JARM` Encapsulation Module (Recommended)**
Create a clear, high-level API boundary (e.g., `Lockspire.JARM.encode/3`) that takes the raw response payload, the OP's signing key, and the Client's public key (if encryption is required).

*   **Pros:**
    *   **Idiomatic:** Elixir favors Context-like modules with intention-revealing APIs.
    *   **Safety:** The module enforces the strict "Sign THEN Encrypt" order. The output of `JOSE.JWT.sign/3` (a compact string) is correctly passed as the plain text payload to `JOSE.JWE.block_encrypt/3`.
    *   **Testability:** Easy to mock or test in isolation without setting up full HTTP flows.
*   **Cons:** Introduces a small abstraction layer to maintain.
*   **Lessons Learned:** Libraries like `joken` wrap `jose` specifically to hide its sharp edges. For JARM, a focused module that specifically models `Lockspire.JARM.Response` to a String is the most successful pattern in the Elixir ecosystem.

**Recommendation:**
Build a focused `Lockspire.JARM` module. The internal flow must guarantee:
1.  Construct JWT claims.
2.  Sign the claims using the OP's private key (`JOSE.JWT.sign`).
3.  Compact the JWS into a string.
4.  If encryption metadata exists, encrypt the JWS string using the Client's public key (`JOSE.JWE.block_encrypt`).
5.  Compact the JWE into the final string.

## 2. Guarded Remote JWKS Resolution Strategy

**The Challenge:**
To encrypt the JARM response, Lockspire needs the client's public key. If the client registered a `jwks_uri`, Lockspire must fetch it. Doing this synchronously during the user's redirect path introduces severe risks: latency (degrading UX), DoS (client server is slow/down), and SSRF (client registers an internal OP IP).

### Approaches

**Approach A: Synchronous Fetching on the Critical Path**
*   **Pros:** Conceptually simple. Always gets the freshest key.
*   **Cons:** Disastrous for performance and reliability. A slow client JWKS endpoint directly degrades the OP's authorization redirect speed. High SSRF risk if not guarded.

**Approach B: Background Sync via GenServer/Oban with Fallback (Recommended)**
*   **Pros:** Removes network I/O from the critical authorization path.
*   **Cons:** Potential (though small) window of stale keys if a client rotates keys rapidly without caching headers.
*   **Lessons Learned:** Standard OIDC relying party libraries (like Go's `coreos/go-oidc` or Node's `openid-client`) aggressively cache JWKS based on HTTP caching headers and refresh in the background. In Elixir, leveraging ETS (via Cachex or a custom GenServer) is highly idiomatic for fast, concurrent read access.

**Recommendation & Security Posture (The "Guarded" Strategy):**
1.  **Read-Through Cache with ETS:** At the time of the JARM response, Lockspire queries an ETS-based cache (e.g., `Lockspire.ClientJWKSCache`).
2.  **Strictly Bounded Synchronous Fallback:** If the key is missing (cache miss), attempt a synchronous fetch, but heavily guard it:
    *   **Hard Timeout:** Use Finch or HTTPoison with a brutal timeout (e.g., max 500ms).
    *   **Size Limits:** Cap the response size (e.g., max 50KB) to prevent memory exhaustion.
    *   **SSRF Protection:** Use a custom connection option or network-level egress filtering (e.g., blocking `10.0.0.0/8`, `169.254.169.254`, `localhost`) to prevent internal network scanning. If using `Finch`, you can plug in a custom DNS resolver that rejects private IPs.
3.  **Proactive Refresh:** When a client is updated or a JWKS is nearing its TTL (Cache-Control), trigger an async refresh (e.g., a background Task or an Oban job) to keep the ETS cache warm.

## 3. Plug/Pipeline Architecture for JARM

**The Challenge:**
The authorization controller generates a response (code, state, etc.). JARM dictates that this response is packaged into a JWT and sent via query or fragment. Where should this transformation happen?

### Approaches

**Approach A: A "Magic" Response Plug**
A Plug at the end of the pipeline that intercepts the `conn.assigns` and rewrites the redirect URL if the client requested JARM.
*   **Pros:** Keeps the controller completely ignorant of JARM.
*   **Cons:** "Magic" Plugs that alter the fundamental response type (from standard OAuth redirect to JARM redirect) violate the principle of least surprise. It makes debugging difficult because the Controller's output does not match the actual HTTP response sent to the browser.

**Approach B: Explicit Controller/Response Rendering (Recommended)**
The Controller explicitly determines the response mode. Phoenix/Plug idiomatic design strongly favors explicit data transformations.

*   **Pros:**
    *   **Principle of Least Surprise:** A developer looking at the Authorization Controller can see exactly where the response is formatted and dispatched.
    *   **Clear Data Flow:** The controller handles HTTP, delegates to a core Context for the OAuth logic, and then uses a Presentation/Response module to format the redirect.
*   **Cons:** Slightly more verbose controller code.
*   **Lessons Learned:** In Elixir, hiding side-effects or fundamental data transformations in Plugs often leads to maintainability nightmares. Explicit mapping functions (e.g., `Lockspire.Response.build_redirect(conn, client, auth_data)`) are vastly preferred.

**Recommendation:**
Do not use a Plug for the encryption logic. Instead, introduce a dedicated response formatter, e.g., `Lockspire.Authorization.ResponseBuilder`.
1.  The Controller calls the core context to get the authorization result (e.g., `%AuthResult{code: "...", state: "..."}`).
2.  The Controller passes this result and the Client configuration to the `ResponseBuilder`.
3.  The `ResponseBuilder` inspects the Client's requested `response_mode` (or defaults to query/fragment based on `response_type`).
4.  If JARM is required (e.g., `response_mode=jwt`), the `ResponseBuilder` calls `Lockspire.JARM.encode/3`.
5.  The `ResponseBuilder` returns the final redirect URI to the Controller, which explicitly calls `redirect(conn, external: uri)`.

This keeps the Controller clean, avoids hidden Plug side-effects, and creates highly testable pure functions in `ResponseBuilder` and `JARM`.