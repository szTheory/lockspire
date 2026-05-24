# Phase 80: Sender-Constraining Integration (DPoP & MTLS)
## Architectural Recommendations

Based on the core OSS guidelines, the Lockspire implementation playbook, and the Elixir/Plug ecosystem’s best practices, here are the architectural recommendations for implementing Phase 80.

### 1. Plug Composition vs. Fat Plug
**Recommendation: Separate, Composable Plugs.**

*   **Rationale:** Elixir developers strongly favor a "thin vertical architecture" where plugs have a single responsibility. Baking sender constraint logic into the existing `Lockspire.Plug.VerifyToken` would create a complex "fat plug" that hides behavior and breaks the principle of least surprise.
*   **Implementation Strategy:**
    *   **`Lockspire.Plug.VerifyToken`**: Update this plug to extract tokens bearing either the `Bearer` or `DPoP` scheme from the `Authorization` header. It should remain strictly focused on cryptographic JWT validation (signature, time bounds) and assign the parsed `Lockspire.AccessToken` struct to the connection.
    *   **`Lockspire.Plug.EnforceSenderConstraints`**: Introduce this as a distinct, composable plug meant to follow `VerifyToken`. This plug will inspect `conn.assigns.access_token`. If the token contains a `cnf` (confirmation) claim (e.g., `jkt` for DPoP or `x5t#S256` for MTLS), this plug enforces the environment bindings against the incoming request.
*   **Developer Ergonomics (DX):** This explicit composition allows developers to secure some endpoints with basic tokens and others with strict sender-constraints without juggling massive, opaque configuration objects.

### 2. DPoP Replay State in the Resource Server
**Recommendation: Ephemeral ETS Cache via Behaviour (Decoupled from Ecto).**

*   **Rationale:** The implementation playbook mandates "strong internal separation" between domain logic and the storage layer. Resource Servers (RS) are frequently distributed microservices that should not be tightly coupled to Lockspire's `Ecto` repo or the Authorization Server's database. Forcing Ecto on an RS just for DPoP replay detection is an anti-pattern.
*   **Implementation Strategy:**
    *   **Stateless Bounds:** Rely heavily on the `iat` and `exp` claims of the DPoP proof to enforce a strict, short validity window (e.g., 5 minutes) without needing persistence.
    *   **Narrow Behaviour:** Define a behaviour (e.g., `Lockspire.Dpop.ReplayCache`) strictly for storing and verifying the `jti` (nonce) within that time window.
    *   **Default ETS Adapter:** Ship a default, zero-dependency `Lockspire.Dpop.ETSReplayCache` with a supervised child spec that prunes expired nonces.
*   **Developer Ergonomics (DX):** Enterprise users horizontally scaling their Resource Servers can swap the ETS cache for a distributed solution like Redis or Nebulex by implementing the behaviour, while the out-of-the-box experience remains lightweight and database-free.

### 3. MTLS Configuration
**Recommendation: Explicit Plug Options over Global Config.**

*   **Rationale:** The OSS guidelines explicitly state to "avoid global application config as the primary interface." Relying on `Application.fetch_env!` makes the library brittle when a single Phoenix app routes traffic from different proxies (e.g., some requiring header extraction, others direct Cowboy TLS).
*   **Implementation Strategy:**
    *   Leverage `NimbleOptions` to validate options supplied directly to the `EnforceSenderConstraints` plug.
    *   Allow the developer to inject the MTLS extractor and its arguments right where the plug is mounted:
      ```elixir
      plug Lockspire.Plug.EnforceSenderConstraints,
        mtls_extractor: {Lockspire.MTLS.ProxyHeaderExtractor, header: "x-forwarded-client-cert"},
        dpop_replay_cache: Lockspire.Dpop.ETSReplayCache
      ```
*   **Developer Ergonomics (DX):** Exposing dependencies at the pipeline level clarifies data flow, avoids cross-contamination in umbrella apps, and provides immediate compiler feedback if configurations are malformed.

### Summary
By separating token verification from sender constraints, avoiding heavy database coupling for Resource Servers, and passing configurations explicitly, Lockspire will deliver a secure, highly composable, and idiomatic integration experience that aligns perfectly with the broader Elixir ecosystem.