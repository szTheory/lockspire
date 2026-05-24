# Phase 41 Architectural Recommendations

**Phase:** Phase 41: FAPI 2.0 Profile Configuration and Strict Enforcement
**Context:** Research and decisions from the Discuss phase regarding FAPI 2.0 implementation.

## 1. Configuration Placement: The Macro-Policy Pattern
**Decision:** Add `security_profile` (defaulting to `:default`, with option `:fapi_2_0_security`) to **BOTH** `Lockspire.Domain.Client` and `Lockspire.Domain.ServerPolicy`.

**Rationale:**
- **Granular Rollout:** FAPI 2.0 is an extremely aggressive security posture. Forcing it globally on all clients overnight is a non-starter for existing deployments. By placing it on both schemas, developers can enforce a global baseline via `ServerPolicy`, while permitting piecemeal upgrades of individual `Client`s. This perfectly mirrors Lockspire's existing `par_policy` and `dpop_policy` architecture, adhering to the **Principle of Least Surprise**.
- **Macro-Policy Behavior:** When `security_profile` resolves to `:fapi_2_0_security`, it acts as an immutable macro-policy. It logically overrides or strictly asserts that `par_policy` is `:required`, `dpop_policy` is `:required`, and PKCE is forced to `S256`.

## 2. Boundary Enforcement Location: Context-Aware Protocol Layer Validation
**Decision:** Enforce the FAPI 2.0 strict rejection logic early inside the existing protocol layer modules (e.g., `Lockspire.Protocol.AuthorizationRequest.validate/1` and `Lockspire.Protocol.ParPolicy`), **not** in a new, isolated `FapiPlug`.

**Rationale:**
- **Context is King:** A standalone `FapiPlug` cannot enforce per-client FAPI profiles without first parsing the request and querying the database for the `Client`—logic that already exists in the protocol layer. Duplicating client fetching in a Plug violates DRY and wastes database cycles.
- **Idiomatic Elixir Validation:** In Elixir, business logic boundaries are defined by modules and pure functions. The protocol modules are the true boundary. By using pattern matching and `with` pipelines inside the protocol layer to check the resolved `Client`/`ServerPolicy` combination, we instantly return structured errors like `{:error, :invalid_request, "FAPI 2.0 requires PAR"}`.
- **Aggressive Plug Rejection:** The Web layer (Controllers) takes this structured error and immediately halts the Plug pipeline with a `400 Bad Request`. This fulfills the success criteria of failing aggressively at the HTTP boundary, keeping the complex OAuth context cleanly encapsulated in `Lockspire.Protocol`.

## 3. DPoP vs mTLS: The Exclusive DPoP Mandate
**Decision:** Strictly require DPoP for sender-constrained tokens when the FAPI 2.0 profile is active, and **entirely ignore mTLS for now**. Reject any FAPI 2.0 request missing a DPoP proof.

**Rationale:**
- **Deployment Realities:** FAPI 2.0 requires either mTLS or DPoP. Embedded Phoenix applications typically sit behind reverse proxies (Fly.io, AWS ALBs) that terminate TLS. Forwarding mTLS client certificates through to Cowboy or Bandit is notoriously brittle and a massive DevOps burden.
- **Developer Ergonomics:** DPoP operates entirely at the application layer via HTTP headers. It survives load balancers and CDNs flawlessly. By mandating DPoP when `security_profile == :fapi_2_0_security`, Lockspire provides a hardened, compliant FAPI 2.0 implementation that "just works" out-of-the-box.
- **Future-Proofing:** If mTLS is introduced in a later phase, the protocol validation can easily be updated to allow *either* DPoP or mTLS. For now, failing fast when DPoP is absent guarantees FAPI 2.0 compliance without compromising the developer experience.