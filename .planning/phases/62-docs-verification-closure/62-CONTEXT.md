# Phase 62: Docs, Verification & Closure - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 62 closes v1.15 by making the shipped `jwks_uri` + `private_key_jwt` slice understandable, executable, and release-truthful. This phase covers integrator-facing documentation, repo-owned proof for positive and negative behavior, and milestone-close contract alignment across docs, metadata, tests, and release surfaces.

This phase does **not** broaden Lockspire into new client-auth methods, a generic remote metadata platform, a sample app program, or a broad repo-wide editorial cleanup. It closes the shipped direct-client auth slice with the same narrow, truthful, embedded-library posture established in Phases 59-61.

</domain>

<decisions>
## Implementation Decisions

### Decisioning posture

- **D-01:** Downstream Phase 62 work should default to research-first, recommendation-heavy decisions. Escalate only for choices that materially change public API, security posture, release claims, or Lockspire's embedded-library shape.
- **D-02:** Carry the user's preference left into Phase 62 planning and execution: prefer decisive, coherent defaults over menus of medium-value options. Ask again only for genuinely high-impact choices the user is likely to care about.
- **D-03:** Optimize for least surprise across docs, tests, and runtime truth. If a doc or metadata surface says the slice is supported, the repo must provide a realistic, executable path that proves it.

### Documentation packaging

- **D-04:** Use a layered documentation package, not scattered edits only and not a broad cookbook/sample-app approach.
- **D-05:** Keep `docs/supported-surface.md` as the single canonical public support contract for shipped capability claims.
- **D-06:** Keep `README.md` as a concise summary surface that points to the canonical support contract and focused docs instead of trying to become the full auth-method matrix.
- **D-07:** Keep `SECURITY.md` limited to security boundary, disclosure posture, guarded remote-fetch constraints, issuer-bound audience expectations, replay/redaction posture, and explicit exclusions.
- **D-08:** Add one focused integrator/host guide for this slice rather than burying the material across unrelated docs. The guide should explain:
  - registration shape for `private_key_jwt` clients
  - `jwks` xor `jwks_uri`
  - `jwks_uri` fetch constraints
  - accepted signing algorithms as derived from issuer security posture
  - issuer-identifier `aud` requirement
  - key-rotation behavior through cached fetch plus one bounded refresh path
  - representative Lockspire-owned endpoint usage
- **D-09:** Keep `docs/install-and-onboard.md` narrow. It should link to the focused client-auth guide rather than absorb the full narrative.
- **D-10:** Do not create a broad sample app, generic client-auth manual, or operator-console-heavy doc story in this phase.

### Documentation content truth

- **D-11:** State plainly that issuer-string `aud` is a deliberate security choice for this slice, not an incidental implementation detail.
- **D-12:** State plainly that remote JWKS retrieval is a narrow, guarded Lockspire-owned fetch path, not a generic outbound metadata ingestion feature.
- **D-13:** Describe support as limited to Lockspire-owned direct-client auth surfaces. Avoid wording that implies generic JWT client-auth support everywhere.
- **D-14:** Update stale negative claims in maintainer and security docs that still say Lockspire does not support `private_key_jwt` or `jwks_uri` fetch behavior.

### Verification breadth

- **D-15:** Use a representative HTTP proof set plus dense protocol/integration coverage. Do **not** build a full endpoint-by-endpoint E2E matrix.
- **D-16:** Add a small number of high-signal HTTP/E2E proofs that demonstrate real request parsing and runtime behavior at Lockspire-owned boundaries:
  - one positive inline-`jwks` `private_key_jwt` flow on a representative direct-client endpoint
  - one positive `jwks_uri` flow that proves remote fetch plus rotation recovery through a real HTTP seam
  - one negative HTTP proof that confirms generic `invalid_client` wire behavior without leaking verifier internals
- **D-17:** Keep the full verifier matrix in lower-level tests where the logic actually lives:
  - signature failure
  - `alg=none`
  - symmetric or unsupported algorithms
  - issuer/sub mismatch
  - wrong audience
  - expiration/skew
  - replay ordering and replay-store failure
  - telemetry/audit/redaction
  - remote JWKS safety, TTL, forced refresh, and preserve-last-known-good behavior
- **D-18:** Keep shared-surface consistency proof for introspection, revocation, device authorization, and CIBA mostly in protocol/integration tests rather than duplicating those flows as full E2Es.
- **D-19:** E2E should stop at Lockspire-owned protocol boundaries. Do not expand Phase 62 into browser automation, host-login permutations, or unrelated host-owned UX seams.

### Release-contract and closure posture

- **D-20:** Use a narrow canonical truth-surface set for milestone closure:
  - `docs/supported-surface.md` as the public contract
  - `README.md` as summary
  - `SECURITY.md` as security boundary
  - `docs/maintainer-conformance.md` and `docs/maintainer-release.md` as maintainer runbooks
  - `test/lockspire/release_readiness_contract_test.exs` as the executable drift gate
- **D-21:** Closure coupling should be strict for those claim-bearing surfaces only. Update them in the same pass as the proof/tests that justify the claims.
- **D-22:** Do not perform a broad editorial sweep across unrelated docs unless a concrete truth mismatch blocks milestone closure.
- **D-23:** `release_readiness_contract_test.exs` should enforce the documentation hierarchy and current runtime truth, not preserve stale milestone-era strings.
- **D-24:** Fix already-visible truth drift during this phase, including stale claims about unsupported `private_key_jwt`, stale exclusions around `jwks_uri` fetch, and any old release-posture wording that contradicts the shipped supported surface.

### Ecosystem lessons to carry forward

- **D-25:** Follow the strongest adjacent pattern from mature auth libraries: one shared capability source in code, one canonical support contract for humans, one narrow security boundary doc, and one executable drift fence in tests.
- **D-26:** Avoid the common footguns visible in adjacent ecosystems:
  - sample apps or broad cookbooks becoming the de facto contract
  - maintainer docs accidentally becoming product-truth docs
  - stale negative claims lingering after a feature ships
  - conformance-plan pins being mistaken for runtime support
  - exhaustive E2E duplication of behavior already proven at the shared verifier seam

### the agent's Discretion

- Exact filename for the focused client-auth guide.
- Whether the `jwks_uri` HTTP proof rides through token only or uses one additional representative direct-client endpoint such as PAR, as long as the final proof set stays small and high-signal.
- Exact contract-test wording and assertion shape, provided the test enforces current truth and respects the canonical doc hierarchy.

</decisions>

<specifics>
## Specific Ideas

- The coherent recommendation bundle for Phase 62 is:
  - layered contract docs plus one focused guide,
  - two or three high-signal HTTP proofs,
  - dense lower-level verifier and fetcher coverage carrying the matrix,
  - narrow claim-bearing surfaces updated together,
  - no sample-app sprawl and no exhaustive E2E endpoint matrix.
- This matches the repo's strongest existing closure pattern:
  - milestone-close phases use one or a few high-signal integration proofs,
  - discovery/support truth is carried by docs plus contract tests,
  - protocol-detail matrices live close to shared behavior modules instead of being re-proven through every route.
- The adjacent ecosystem lessons are consistent:
  - OpenIddict is a positive model for issuer-bound `aud` hardening and clear assertion-auth docs,
  - Phoenix testing guidance supports router-boundary proof plus deeper lower-level matrices,
  - Spring Authorization Server reinforces the “shared capability, many consuming endpoints” architecture,
  - `oidc-provider` is useful as a crisp capability-doc reference but too broad a config matrix to copy,
  - Keycloak is the cautionary case for console sprawl and remote-key footguns.
- Explicit wording traps already visible in the repo:
  - `SECURITY.md` still says `jwks_uri` outbound fetch is out of scope
  - `SECURITY.md` still lists device flow as unsupported
  - `docs/maintainer-conformance.md` still says Lockspire does not support `private_key_jwt`
  - `docs/maintainer-release.md` contains older release-posture wording that no longer matches shipped support
  - `test/lockspire/release_readiness_contract_test.exs` still pins some stale milestone-era claims
- Great DX for this phase means:
  - an integrator can learn the supported slice without reverse-engineering tests,
  - the docs explain the exact security boundaries that matter,
  - the proof story is short, real, and hard to drift,
  - downstream GSD work no longer re-asks medium-value choices for this phase.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Lockspire planning artifacts
- `.planning/PROJECT.md` — v1.15 goal, embedded-library boundary, and current support posture
- `.planning/REQUIREMENTS.md` — `DOC-01`, `V-01`, `V-02`, `V-03`, plus carried-forward security and truth constraints
- `.planning/ROADMAP.md` — Phase 62 goal, plans, and success criteria
- `.planning/STATE.md` — current milestone position and closure target
- `.planning/METHODOLOGY.md` — recommendation-first workflow preference and least-surprise host seam lens
- `.planning/phases/58-milestone-closure-discovery/58-CONTEXT.md` — prior milestone-close truth/docs strategy
- `.planning/phases/59-registration-policy-metadata-truth/59-CONTEXT.md` — registration, metadata, and narrow-scope truth constraints
- `.planning/phases/60-guarded-remote-jwks-resolution/60-CONTEXT.md` — guarded remote JWKS fetch contract
- `.planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md` — shared verifier behavior, issuer-bound `aud`, and observability/redaction rules

### Claim-bearing docs and runbooks
- `README.md` — top-level public summary that must stay aligned with the shipped slice
- `docs/supported-surface.md` — canonical public support contract
- `SECURITY.md` — security boundary and exclusion wording
- `docs/install-and-onboard.md` — canonical Phoenix host onboarding path that should link to the focused guide
- `docs/maintainer-conformance.md` — maintainer conformance lane wording that currently contains stale `private_key_jwt` disclaimers
- `docs/maintainer-release.md` — maintainer release-truth surface that currently contains stale posture wording

### Code and tests
- `test/lockspire/protocol/client_auth_test.exs` — shared verifier matrix
- `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs` — shared direct-client endpoint behavior sampling
- `test/lockspire/jwks_fetcher_test.exs` — guarded fetch, cache, and rotation behavior
- `test/lockspire/jwks_fetcher/target_safety_test.exs` — unsafe-target rejection behavior
- `test/lockspire/protocol/discovery_test.exs` — metadata truth coverage
- `test/lockspire/release_readiness_contract_test.exs` — executable support-truth and release-contract drift gate
- `test/integration/phase29_dcr_e2e_test.exs` — prior milestone pattern for one focused HTTP proof
- `test/integration/phase37_protocol_strictness_e2e_test.exs` — prior milestone pattern for meaningful boundary E2E proof
- `test/integration/phase57_rar_introspection_verification_e2e_test.exs` — prior milestone-close proof style for focused integration rather than exhaustive UI testing

### External references that shaped these decisions
- `OpenIddict assertion-based client authentication docs` — shared assertion-auth capability posture
- `OpenIddict 6.0 -> 7.0 migration guide` — issuer-bound `aud` hardening after the 2025 disclosure
- `Phoenix.ConnTest` and Phoenix controller-testing guidance — idiomatic router-boundary testing shape in Phoenix
- `Spring Authorization Server` reference docs — shared client-auth capability consumed across multiple direct-client surfaces
- `OpenID Foundation January 2025 private_key_jwt disclosure notice` — security rationale for issuer-bound `aud`
- `FAPI 2.0 Security Profile` — security posture and wording constraints relevant to this slice

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `test/lockspire/protocol/client_auth_test.exs` already provides dense proof for signature verification, claims, replay ordering, and fetch integration; planning should extend it only where true gaps remain.
- `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs` already proves shared behavior across representative direct-client surfaces without needing full HTTP duplication everywhere.
- `test/lockspire/jwks_fetcher_test.exs` and `test/lockspire/jwks_fetcher/target_safety_test.exs` already carry most of the remote-fetch hardening and rotation matrix.
- `test/lockspire/release_readiness_contract_test.exs` already acts as the repo's claim-bearing docs gate and should remain the primary drift fence for closure truth.

### Established Patterns

- Lockspire milestone-close phases prefer focused high-signal integration proof plus lower-level depth where the behavior actually lives.
- Support-truth claims are enforced by narrow docs plus tests, not by sprawling example programs.
- Host-owned seams stay explicit; Lockspire-owned protocol/security behavior gets the deeper proof burden.
- Discovery/runtime/docs drift is treated as a bug, not tolerated flexibility.

### Integration Points

- Phase 62 planning should likely center around:
  - one new focused doc for the shipped client-auth slice
  - claim-bearing doc updates
  - one or two new HTTP/integration proofs
  - contract-test updates
- The likely proof anchor is the token endpoint, with one additional representative direct-client seam only if it materially improves runtime truth without creating matrix bloat.
- Maintainer docs need careful wording cleanup so conformance-plan references do not overclaim or underclaim current runtime support.

</code_context>

<deferred>
## Deferred Ideas

- Full sample app or cookbook for all client-auth methods
- Broad operator-console or key-management workflow expansion
- Exhaustive E2E coverage for every direct-client endpoint
- Generic outbound metadata-ingestion docs or future trust-chain stories
- Broader auth-method expansion such as `client_secret_jwt`, mTLS, or federation-aligned trust models
- Repo-wide editorial cleanup beyond concrete truth mismatches needed to close v1.15

</deferred>

---

*Phase: 62-docs-verification-closure*
*Context gathered: 2026-05-06*
