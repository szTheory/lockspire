# Domain Pitfalls

**Domain:** Token Exchange (RFC 8693)
**Researched:** 2026-05-XX

## Critical Pitfalls

Mistakes that cause rewrites or major security incidents.

### Pitfall 1: Privilege Escalation (Token Upgrading)
**What goes wrong:** A client exchanges a token intended for a low-security resource (or with limited scopes) and receives a token with broader scopes or targeting a high-security resource.
**Why it happens:** The Authorization Server implicitly trusts the `scope` and `audience` parameters in the exchange request, failing to restrict them to a subset of the `subject_token`.
**Consequences:** A compromised frontend or edge service can arbitrarily pivot to become an admin in backend systems.
**Prevention:** Lockspire MUST default to strict downscoping (the intersection of requested scopes and original scopes). Any expansion MUST require explicit authorization from the host-implemented `Lockspire.TokenExchangeValidator` Behaviour.
**Detection:** Security audits showing exchanged tokens possessing scopes not present in the original subject token without explicit policy logs.

### Pitfall 2: Silent Impersonation (Erasing the Actor)
**What goes wrong:** A middle-tier service exchanges a user's token for a new token to call a backend service. The new token only contains the user's `sub`, dropping all evidence that the middle-tier service was involved.
**Why it happens:** Implementing "Impersonation" semantics when "Delegation" semantics were required.
**Consequences:** The backend service has no audit trail. If the middle-tier service goes rogue, logs only show the user performing malicious actions.
**Prevention:** Guide integrators toward Delegation by making the generation of the `act` (actor) claim ergonomic and default when an `actor_token` is provided in the exchange request.

## Moderate Pitfalls

### Pitfall 3: Poorly Typed Token URIs
**What goes wrong:** Failing to correctly validate or emit the standard RFC 8693 URNs (e.g., `urn:ietf:params:oauth:token-type:jwt`).
**Prevention:** Use strictly matched Elixir string literals or module attributes for the required URNs. Return `invalid_request` if the client requests an unsupported token type.

## Minor Pitfalls

### Pitfall 4: Infinite Exchange Loops
**What goes wrong:** Exchanged tokens are exchanged again indefinitely, creating massive nested `act` claims or bypassing TTL reductions.
**Prevention:** The host application should be able to inspect the original token's `act` chain in the `validate_exchange` Behaviour and reject excessive depth.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Host Behaviour API Design | Making the context struct too opaque, preventing the host from making safe policy decisions. | Ensure `Lockspire.TokenExchange.Context` clearly exposes the original token claims, the requesting client, and the requested scopes/audience. |
| Token Minting | Forgetting to transfer critical standard claims (like `jti` bindings or `cnf` DPoP keys) to the new token. | Ensure the token exchange minter respects the DPoP and security profiles established in earlier Lockspire milestones. |

## Sources

- [RFC 8693 Security Considerations (Section 6)](https://datatracker.ietf.org/doc/html/rfc8693) (HIGH confidence)