# Phase 133: Clean-Room SaaS Journey - Context

**Gathered:** 2026-08-26 (assumptions mode, autonomous)
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove, over real HTTP and distinct origins, that a clean Phoenix/Ecto host can consume Lockspire through the packaged public installation surface, act as an embedded OAuth/OIDC provider and protected resource server, and serve a separately booted confidential SaaS client. The journey covers authorization code plus S256 PKCE, state and nonce integrity, discovery/JWKS/ID-token/userinfo validation, audience/scope protection, refresh rotation and reuse containment, introspection, revocation, and durable DPoP replay rejection. Exact pre-publish and post-publish Hex artifact verification remains Phase 137.

</domain>

<decisions>
## Implementation Decisions

### Clean-Room Harness and Package Boundary
- **D-01:** Build an isolated black-box acceptance harness with two separately booted applications on distinct HTTP origins: a generated Phoenix/Ecto provider host that embeds Lockspire and owns the protected API, and a small confidential-client Phoenix application that consumes it.
- **D-02:** The provider host must use the packaged installer, generated migrations/configuration/router seams, `mix lockspire.verify`, and documented host-owned edits. It must not import `Lockspire.Protocol.*`, `Lockspire.Storage.*`, replace Lockspire protocol routes, or rely on test-support modules.
- **D-03:** Phase 133 may consume a locally built package/path artifact through the public package surface. It must prove the boundary is package-clean, but exact Hex tarball checksums and pre-/post-publish installation remain Phase 137.
- **D-04:** Exercise the journey through actual listeners and HTTP clients, not only `ConnTest` or direct protocol calls. Keep the harness deterministic, headless, CI-capable, and self-cleaning without requiring browser automation.

### Confidential Client Transaction and OIDC Validation
- **D-05:** Persist independently random `state`, `nonce`, and PKCE verifier server-side for each authorization transaction. Use S256, compare callback state before exchanging the code, and consume or invalidate the transaction on every terminal callback outcome.
- **D-06:** Register a real confidential client through a supported host/admin-facing setup seam with authorization code, refresh token, `client_secret_basic`, OIDC scopes, a protected-resource scope, and the intended resource audience. Plaintext secret material may exist only during bootstrap and client-server configuration and must never enter logs or retained evidence.
- **D-07:** The external client must fetch discovery and JWKS from advertised HTTP endpoints, select keys by `kid`, restrict algorithms to the advertised supported set, and validate ID-token signature, issuer, audience, expiration, and original nonce.
- **D-08:** Fetch userinfo with the issued access token and require its `sub` to exactly match the validated ID-token subject before treating login as complete.

### Protected API and Lifecycle Truth
- **D-09:** The provider host protects its SaaS API through the documented `VerifyToken -> EnforceSenderConstraints -> RequireToken` path and the Phase 132 semantic `Lockspire.AccessToken` readers. Lockspire owns protocol checks; host code separately owns its illustrative tenant/product authorization decision.
- **D-10:** The successful client journey must call a route requiring the intended audience and scope and assert only the documented HTTP and semantic response contract.
- **D-11:** Prove refresh-token rotation succeeds once, reuse of the previous refresh token revokes the token family, authenticated introspection reports durable server-side lifecycle truth, and authenticated revocation behaves idempotently.
- **D-12:** Keep JWT lifetime semantics truthful: revocation and family state are immediately visible to Lockspire lifecycle endpoints, but an already-issued self-contained JWT is not claimed to become instantly invalid at an offline resource server before expiry.

### Negative Matrix and DPoP Durability
- **D-13:** Reject, over real HTTP, callback-state mismatch, redirect drift, authorization-code reuse, nonce mismatch, missing access token, wrong audience, insufficient scope, invalid or missing DPoP nonce, and replay of the identical accepted DPoP proof.
- **D-14:** Assert stable wire outcomes—status, OAuth/OIDC error, and authentication challenge where documented—rather than internal structs, repository rows, or private reason codes.
- **D-15:** Run DPoP through the same confidential-client/provider journey: obtain a DPoP-bound access token, receive the resource-server nonce challenge, retry with a new proof carrying that nonce, then replay that exact successful proof and observe rejection.
- **D-16:** Use the configured Ecto repository for DPoP replay recording, with no test-only in-memory or custom replay override. Prove persistence through externally observable behavior and, where necessary, a bounded host-owned verification command rather than internal application calls.
- **D-17:** Redact authorization codes, access/refresh tokens, client secrets, PKCE verifiers, DPoP private keys/proofs, and cookies from logs, failure messages, snapshots, and retained CI artifacts. Negative tests should use sentinels to make leakage failures explicit.
- **D-18:** Keep the acceptance harness narrow and reference-quality; it is executable proof, not a new hosted service, client SDK, general OAuth client library, or replacement adoption demo.

### the agent's Discretion
- Exact fixture directory layout and process supervisor, provided the two applications remain separately booted and package-clean.
- Whether the confidential-client transaction store uses Ecto or another durable server-side store, provided concurrency, one-time consumption, and restart-safe behavior are executable.
- How bootstrap credentials and ports are passed between processes, provided the channel is ephemeral, redacted, deterministic, and CI-safe.
- How ID-token/JWKS verification is factored inside the fixture, provided all required validation steps are explicit and independently testable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md` — embedded-library boundary and v1.37 compatibility posture.
- `.planning/REQUIREMENTS.md` — E2E-01 through E2E-06 and explicit out-of-scope claims.
- `.planning/ROADMAP.md` — Phase 133 success criteria and Phase 137 artifact boundary.
- `.planning/phases/131-executable-installation/131-CONTEXT.md` — executable generated-host/install contract.
- `.planning/phases/132-public-api-and-resource-server-truth/132-CONTEXT.md` — semantic token, registration, DPoP, and host-authorization contracts.
- `priv/templates/lockspire.install/` — supported generated host integration surface.
- `lib/mix/tasks/lockspire.install.ex` and `lib/mix/tasks/lockspire.verify.ex` — package install and verification entry points.
- `examples/adoption_demo/` and `scripts/demo/adoption_smoke.py` — reusable lifecycle ideas and known same-origin/public-client limitations.
- `test/integration/install_generator_test.exs` — generated package boundary proof.
- `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` — existing in-process OIDC and lifecycle behavior.
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs` — generated host protected-route and DPoP nonce flow.
- `test/integration/protected_resource_dpop_default_store_test.exs` — configured repository replay behavior.
- `docs/protect-phoenix-api-routes.md` — canonical resource-server pipeline and host boundary.
- `docs/upgrading/v1.37.md` — additive public API guidance.
- `docs/supported-surface.md` — supported public surface and compatibility claims.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 131 installer fixtures already prove generated routes, migrations, configuration, consent, verification, and default/FAPI smoke behavior.
- The adoption demo contains useful HTTP sequencing and lifecycle helpers, but is intentionally same-origin and public-client shaped; Phase 133 should extract patterns without mutating its product purpose.
- Existing integration suites already demonstrate ID-token signing/verification, userinfo, refresh rotation, code replay rejection, DPoP nonce retry, protected-route scope/audience checks, and durable replay behavior in narrower contexts.

### Established Patterns
- Public package seams and generated host code are the acceptance boundary; protocol/storage internals are implementation details.
- Security-negative evidence uses real wire behavior and sentinel redaction checks.
- Self-contained JWT acceptance is expiry-bound, while introspection/revocation expose durable authorization-server state.

### Integration Points
- Mix package/build/install tasks, generated provider host, provider Repo migrations, host account/consent seam, client bootstrap, discovery/JWKS, authorization callback, token/userinfo/lifecycle endpoints, Phoenix protected-route plugs, DPoP nonce/replay state, process orchestration, and CI entry points.

</code_context>

<specifics>
## Specific Ideas

- Treat the harness as an acceptance lab with one command that builds, provisions, boots, exercises, redacts, and tears down both origins.
- Make every security claim visible at the HTTP boundary; use internal inspection only for setup or bounded assertions that have no wire representation.
- Prefer small, named journey steps and failure cases over a monolithic smoke script so a maintainer can diagnose a failure quickly.

</specifics>

<deferred>
## Deferred Ideas

- Exact Hex package checksum, immutable published-version installation, and release evidence manifests belong to Phase 137.
- Dependency topology restructuring belongs to Phase 134; storage/token decomposition belongs to Phase 135.
- Browser UI acceptance, admin visual review, hosted OAuth service behavior, general client SDKs, and new grants remain outside this phase.

</deferred>
