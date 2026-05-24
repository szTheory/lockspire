# Phase 41 Context: FAPI 2.0 Profile Configuration and Strict Enforcement

## Goal
Introduce a `security_profile: :fapi_2_0_security` option that aggressively rejects requests missing PAR, lacking DPoP/mTLS, or using non-S256 PKCE at the Plug boundary.

## Discussion & Alignment

Based on research into Elixir/Phoenix idiomatic patterns, ecosystem precedents (Keycloak, Auth0), and developer ergonomics, the following architectural direction has been decided for Phase 41:

### 1. Configuration Strategy: Durable Database Fields
`security_profile` will be managed as durable state rather than static app config.
- **ServerPolicy (Global):** Add `security_profile: :default | :fapi_2_0_security` (defaulting to `:default`).
- **Client (Overrides):** Add `security_profile: :inherit | :default | :fapi_2_0_security` (defaulting to `:inherit`).
- **Rationale:** Lockspire already manages `par_policy` and `dpop_policy` via durable Ecto schemas. Reusing this pattern respects the principle of least surprise, provides maximum ergonomics, and avoids split-brain configuration (DB vs `config.exs`). It cleanly supports mixed OIDC ecosystems where some clients require strict FAPI 2.0 compliance while others do not.

### 2. Enforcement Architecture: Dedicated Boundary Enforcer Plug
Strict FAPI rules will be enforced at the Plug pipeline boundary rather than scattered across domain modules.
- **Plug:** Create a centralized `Lockspire.Protocol.FAPI20EnforcerPlug` that sits early in the pipeline, immediately after client resolution.
- **Behavior:** The Plug will resolve the effective `security_profile` for the request. If `:fapi_2_0_security`, it will execute the strict checks:
  - Must use PAR (FAPI-02)
  - Must use DPoP or mTLS (FAPI-03)
  - Strict redirect URI matching (FAPI-05, to be built out further in Phase 42)
  - Preemptive rejection of invalid cryptography (FAPI-04, Phase 42)
- **Rationale:** FAPI 2.0 is a highly restrictive subset. Scattering `if client.fapi_enabled?` across existing domain modules like `ParPolicy` violates the Open/Closed Principle and makes security audits nearly impossible. A dedicated Plug acts as a centralized, fail-fast gateway, keeping base OIDC modules clean while aggressively rejecting non-compliant requests.

## Requirements Addressed
- **FAPI-01:** Provide a single `security_profile: :fapi_2_0_security` option to enable strict mode globally or per-client.
- **FAPI-02:** Reject requests that do not use PAR when the profile is active.
- **FAPI-03:** Reject token requests and `userinfo` access without DPoP (or mTLS) when the profile is active.