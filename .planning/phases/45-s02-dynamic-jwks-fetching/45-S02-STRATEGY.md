# Phase 45 (S02): Dynamic JWKS Fetching & Caching Strategy

**Decided:** 2026-05-03
**Status:** Ready for planning

## Goal
Implement a robust, non-blocking, multi-node-safe caching layer for remote JSON Web Key Sets (JWKS) to support Private Key JWT Client Authentication (FAPI 2.0).

## Core Architectural Decisions

### 1. Caching Mechanism: Native `:ets` + `GenServer`
- **Decision:** We will use a native `:ets` table managed by a `Lockspire.JwksCache` GenServer.
- **Rationale:** JWKS payloads are small and public, making local per-node caching architecturally superior to distributed caching (like Redis or Nebulex) by avoiding inter-node serialization and network bottlenecks. `:ets` provides extremely fast local reads. Choosing native `:ets` avoids introducing new transitive dependencies (like `Cachex` or `Nebulex`), which is critical for minimizing version conflicts in an embedded library like Lockspire.

### 2. Refresh Strategy & TTL: Fixed TTL with Stampede Protection
- **Decision:** We will implement a fixed TTL (e.g., 15 minutes) with background refreshing upon expiration/miss, rather than relying on HTTP `Cache-Control` headers from the remote JWKS.
- **Rationale:** Upstream IdP cache headers are notoriously unreliable or missing. A fixed TTL provides predictable memory and network behavior. To prevent cache stampedes (where multiple concurrent requests to an unknown/expired key trigger simultaneous HTTP fetches), cache misses will be routed through `GenServer.call` queues or a Registry, ensuring only a single process performs the fetch for a specific URI while others wait.

### 3. HTTP Client: `Req` (Finch)
- **Decision:** Fetching will be executed via `Req` (which uses `Finch` under the hood), heavily constrained by a strict timeout (e.g., 5 seconds max).
- **Rationale:** `Req` is already a dependency (`~> 0.5`) in `mix.exs`. Reusing it avoids adding `HTTPoison` or `Mint`. `Finch` natively provides excellent connection pooling and timeout handling, mitigating the risk of the "Network Tar Pit" mentioned in the milestone roadmap.

### 4. Stored Format: Parsed `JOSE.JWKSet`
- **Decision:** The fetched JSON payload will be parsed into a `JOSE.JWKSet` struct *before* insertion into the `:ets` cache.
- **Rationale:** Private Key JWT validation happens on every token and PAR request. Storing raw JSON would force the provider to pay the JSON decoding and JWK struct allocation overhead on every single request. Storing the parsed `JOSE.JWKSet` directly in `:ets` ensures the validation engine can consume the keys instantaneously.

## Boundary Contract
- **Input:** A `jwks_uri` string.
- **Output:** A `JOSE.JWKSet` or `{:error, reason}`.
- **Side Effects:** Hits the network ONLY on a cache miss or expired TTL.

This strategy finalizes the gray areas for Phase 45 (S02). The phase is ready for execution planning.
