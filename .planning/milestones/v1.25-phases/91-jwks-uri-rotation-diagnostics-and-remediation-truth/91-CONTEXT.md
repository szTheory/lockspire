# Phase 91: `jwks_uri` Rotation Diagnostics And Remediation Truth - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Lockspire's shipped remote `jwks_uri` client-key slice diagnosable and supportable without widening the embedded-library boundary or overstating what the current runtime guarantees. Phase 91 should produce one explicit truth for what Lockspire supports on remote JWKS rollover, how operators can distinguish failure classes, and what remediation path follows from each class. This phase does not add background polling, hosted remote-key management, or a broader federation-style metadata subsystem.

</domain>

<decisions>
## Implementation Decisions

### Supported remote-rotation truth
- **D-01:** Lockspire should describe the shipped `jwks_uri` behavior as **bounded reactive rollover support**, not as generic or proactive “rotation support.”
- **D-02:** The support contract should say that Lockspire caches remote JWKS material, attempts one bounded forced refresh when verification indicates stale or unknown key material, preserves the last known good cache entry on refresh failure, and still fails the current authentication attempt closed.
- **D-03:** Lockspire must explicitly avoid claims about background polling, prefetch, grace-window orchestration, or “rotation readiness before first use.” Those behaviors are not part of the current embedded-library runtime and claiming them would raise support burden through false operator expectations.
- **D-04:** Public wording should still acknowledge that this is real supported rollover behavior for the narrow shipped direct-client surfaces; the phrasing should be careful, not apologetic or defensive.

### Primary diagnostics surface
- **D-05:** The primary diagnostic truth should live in a **shared runtime diagnostics subsystem** for remote JWKS-backed client auth, not in docs alone and not in admin UI alone.
- **D-06:** The canonical public contract stays in docs, but the first explicit operational support entrypoint should be a doctor-style surface backed by the shared runtime API, with an intended shape like `Lockspire.Diagnostics.RemoteJwks` plus a support wrapper such as `mix lockspire.doctor remote-jwks --client <client_id>`.
- **D-07:** Do not overload `mix lockspire.verify` with remote JWKS runtime diagnosis. `mix lockspire.verify` remains the install/onboarding wiring diagnostic; Phase 91 should keep runtime incident diagnosis separate from install truth.
- **D-08:** Admin/LiveView should consume the same diagnostic subsystem and show a calm summary, but it must not become a second source of protocol truth or the only place operators can see the diagnosis.

### Failure taxonomy and signal model
- **D-09:** Keep the wire contract generic as `invalid_client`. Lockspire should not become an oracle about remote client key state at the OAuth wire boundary.
- **D-10:** Expose four stable operator-facing remote JWKS diagnostic classes:
  - `remote_jwks_fetch_failed` — Lockspire could not safely obtain fresh JWKS material.
  - `remote_jwks_invalid` — Lockspire fetched content, but the JWKS document was unusable or rejected.
  - `remote_jwks_key_unavailable` — Lockspire had usable JWKS material, but the needed key was still unavailable after one refresh attempt.
  - `remote_jwks_signature_invalid` — candidate key material was available, but cryptographic verification still failed.
- **D-11:** Avoid top-level categories like “unsupported rollover posture” or “cache stale / refresh miss” in the public support contract. Those are better modeled as stage/subreason details because Lockspire often cannot prove the upstream intent, only the observable state.
- **D-12:** The diagnostics subsystem should preserve richer internal detail through safe metadata such as stage, subreason, `jwks_source`, whether a cached entry existed, whether forced refresh ran, whether the requested `kid` was present in cache, and safe fetch metadata like HTTP status or target-safety reason.

### Remediation contract and ownership
- **D-13:** Lockspire should frame `jwks_uri` incidents as **degraded remote key-distribution incidents**, not as generic “switch to inline keys” failures.
- **D-14:** Ownership split should remain explicit:
  - Lockspire owns the guarded fetch/cache/refresh/verify path and the truthful diagnostic/remediation output.
  - The host/operator owns incident handling on the Lockspire side: reading diagnostics, confirming reachability or document-shape issues, and coordinating with the client integrator.
  - The client integrator owns publishing a valid JWKS endpoint, stable HTTPS service, distinct `kid` values, and overlap-based rotation choreography.
- **D-15:** Inline `jwks` is not the default remediation. It is the deliberate deterministic fallback when the client cannot operate a reliable overlap-based `jwks_uri` path or when deterministic cutover is a hard requirement.
- **D-16:** The canonical remediation sequence should be:
  1. classify the failure;
  2. check remote availability and target safety;
  3. confirm overlap-based rollover with old and new keys published concurrently;
  4. allow cache/forced-refresh convergence after correction;
  5. retry with one fresh assertion;
  6. move to inline `jwks` only if deterministic rollover is required or the remote mode cannot be operated safely.

### UX, DX, and support posture
- **D-17:** The support surface should optimize for the operator question from the telemetry prompt: “what happened, why did it happen, and what do I do next?” The answer should be available without reading library internals or reconstructing meaning from logs alone.
- **D-18:** The doctor/admin outputs should be diagnostic and calm, not chatty. They should present exact status, key facts, and one concrete next step rather than a wall of opaque lower-level errors.
- **D-19:** The same truth model should apply across both current remote-key consumers: `private_key_jwt` client authentication and JARM client key resolution. Phase 91 should not create diverging support stories for those two remote JWKS paths.

### Planning and escalation posture
- **D-20:** Downstream research, planning, and execution should keep using the project’s methodology preference to resolve medium-value implementation choices without re-asking the user. The user explicitly wants this preference shifted left for GSD unless a decision materially affects product boundary, public API shape, security posture, or published support claims.
- **D-21:** For this phase, planners/executors should escalate only if a proposed implementation would widen Lockspire into background remote-key management, change the wire contract, alter the narrow embedded-library boundary, or make a materially stronger support claim than the runtime can prove.

### the agent's Discretion
- Exact diagnostic struct/module names, event names, and whether the support wrapper lands as a new `mix lockspire.doctor` task or an adjacent command family
- Exact copy for the docs/admin surfaces, provided it preserves the bounded-reactive support truth and the explicit ownership split
- Whether selective state transitions like “last known good replaced” or “remote JWKS degraded” should be durable audit events or summary-only operator status, provided high-volume transient failures remain telemetry-first
- Exact UI treatment for operator summary badges, sections, and command hints, provided admin stays a consumer of the shared diagnostic truth rather than the authority

</decisions>

<specifics>
## Specific Ideas

- Preferred product truth:
  - “Lockspire supports bounded reactive `jwks_uri` rollover for shipped direct-client JWT verification surfaces.”
  - “Remote JWKS entries are cached and refreshed once on stale or unknown-key verification mismatch; Lockspire does not provide background polling or prefetch-based rotation readiness.”
  - “If remote refresh fails, Lockspire preserves the last known good JWKS cache entry and fails the current authentication attempt closed.”
  - “For zero-surprise rollover, clients should publish the new key before first use and retain the previous key during the transition window.”
- The recommended runtime shape is a library API first, CLI/admin second:
  - `Lockspire.Diagnostics.RemoteJwks` as the authoritative diagnostic module
  - doctor-style wrapper for support and maintainer workflows
  - admin summary that links to the same state model
- Strong ecosystem lessons to carry forward:
  - Doorkeeper got install DX right but left too much app-shaped support burden around operational diagnosis; Lockspire should keep the good onboarding instincts but ship clearer operator truth.
  - `node-oidc-provider` proves the value of embedded-library composability and explicit runtime hooks, but it also shows the support tax when a library leaves too much diagnosis to the host.
  - OpenIddict and Spring Authorization Server are good examples of configuration and boundary clarity; they are less useful as operator-diagnosis models because they stop short of a first-class remote-key incident surface.
  - Keycloak’s UI-first operator model works because Keycloak is a standalone server. Lockspire should learn from its operator legibility, not from its assumption that a bundled admin plane can be the protocol authority.
  - Mature remote-JWKS systems like Microsoft, Okta, Auth0, and Curity all lean on overlap-based rollover, last-known-good behavior, and targeted refresh on unknown key events. That makes overlap-based client guidance the least-surprise recommendation.
- Important footguns to avoid:
  - claiming broad “rotation supported” truth without documenting cache/refresh semantics
  - over-detailed public taxonomies that speculate about upstream intent Lockspire cannot prove
  - making logs the only diagnostic path
  - pushing operators straight to inline `jwks` and thereby turning a supported remote mode into a de facto unsupported one
  - forking the support story between `private_key_jwt` and JARM even though the same remote JWKS truth underlies both

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase boundary
- `.planning/PROJECT.md` — current milestone goal, embedded-library boundary, and support-burden reduction priorities
- `.planning/REQUIREMENTS.md` — `JWKS-01` and `JWKS-02` requirements plus milestone-wide support-truth constraints
- `.planning/ROADMAP.md` — Phase 91 scope, goal, and plan breakdown
- `.planning/STATE.md` — current repo state and next-action framing
- `.planning/METHODOLOGY.md` — assumption-first recommendation mode, research-first decisive defaults, least-surprise host seam, and high-threshold escalation

### Existing shipped runtime and proof
- `lib/lockspire/jwks_fetcher.ex` — guarded fetch path, cache behavior, refresh behavior, and failure mapping for remote JWKS retrieval
- `lib/lockspire/protocol/client_auth/private_key_jwt.ex` — current `jwks_uri` runtime path, stale-key refresh behavior, and telemetry/audit failure emission
- `lib/lockspire/protocol/jarm/client_key_resolver.ex` — current JARM remote-key resolution path and refresh behavior
- `test/lockspire/jwks_fetcher_test.exs` — proof for target safety, timeout, redirect, payload, and cache behavior
- `test/lockspire/protocol/client_auth_test.exs` — proof for remote JWKS fetch, stale-key refresh, and telemetry/audit behavior
- `test/integration/phase62_private_key_jwt_e2e_test.exs` — end-to-end proof that the runtime recovers from `jwks_uri` rotation and stays generic on failure

### Existing support and diagnostics surfaces
- `docs/supported-surface.md` — canonical public support contract; must stay the single public source of truth
- `docs/private-key-jwt-host-guide.md` — existing host guidance for the narrow `jwks_uri` + `private_key_jwt` slice, including current key-rotation wording
- `docs/install-and-onboard.md` — canonical `mix lockspire.verify` install/onboarding diagnostics contract that Phase 91 must not overload
- `lib/lockspire/install/verify.ex` — existing install-wiring diagnostics model and surface boundary
- `lib/mix/tasks/lockspire.verify.ex` — current verification task boundary

### Product and implementation guidance
- `prompts/Embedding an OAuth-OIDC server in Phoenix the case for a new Elixir library.md` — ecosystem comparisons and lessons from Doorkeeper, `node-oidc-provider`, OpenIddict, Spring Authorization Server, Hydra, and Keycloak
- `prompts/lockspire-oauth-oidc-implementation-playbook.md` — intended product form, install model, and architecture split
- `prompts/lockspire-host-app-integration-seam.md` — explicit ownership boundary between Lockspire and the host app
- `prompts/lockspire-operator-admin-ia-and-workflows.md` — operator-product expectations and calm diagnostic UX tone
- `prompts/lockspire-operator-ux-liveview.md` — LiveView/operator UI constraints and truth-boundary reminders
- `prompts/lockspire-security-posture-and-threat-model.md` — security posture around remote fetches and fail-closed behavior
- `prompts/lockspire-telemetry-audit-and-introspection.md` — observability goal that operators can answer what happened, why, and what to do next
- `prompts/lockspire-elixir-oss-library-practices.md` — library observability guidance: telemetry as stable surface, logs as diagnostic-only, and support against log-only diagnosis
- `prompts/lockspire-phoenix-system-design.md` — durable-truth vs derived-state guidance relevant to cache and diagnostics design

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.JwksFetcher`: already provides the guarded fetch/cache/refresh primitive and the concrete low-level fetch failure reasons a higher-level diagnostics API can normalize.
- `Lockspire.Protocol.ClientAuth.PrivateKeyJwt`: already distinguishes remote fetch failure, stale/unknown-key refresh path, signature failure, telemetry emission, and selective audit behavior for client-auth incidents.
- `Lockspire.Protocol.Jarm.ClientKeyResolver`: already exercises the same remote JWKS support story for JARM, which lets Phase 91 unify diagnostics across both remote-key consumers.
- `Lockspire.Observability`: existing shared telemetry/audit emission helper that can carry the stable diagnostic taxonomy without leaking secrets.
- `Lockspire.Install.Verify` and `mix lockspire.verify`: useful precedent for “docs + explicit support command,” but they should remain scoped to install wiring rather than runtime JWKS incidents.

### Established Patterns
- Lockspire already keeps the public wire contract narrow while moving richer truth into internal reason codes, telemetry, tests, and support docs.
- `docs/supported-surface.md` is already treated as the single canonical public support contract; adjacent docs defer to it rather than competing with it.
- The project methodology already prefers research-first decisive defaults and high-threshold escalation; the user’s explicit preference in this discussion reinforces that those defaults should be applied aggressively for this phase.
- The current runtime is intentionally embedded-library shaped: bounded safe fetch, node-local cache semantics, and no background remote-key management daemon.

### Integration Points
- Phase 91 should add a shared remote-JWKS diagnostics layer that both `private_key_jwt` and JARM remote-key paths can feed.
- The resulting diagnostic model should integrate with:
  - docs/support-truth surfaces;
  - a doctor-style support entrypoint;
  - telemetry for runtime evidence;
  - selective audit/status surfaces where durable operator history is warranted;
  - admin/client detail UI as a consumer of the same truth.
- Planner/executor should expect doc updates, runtime diagnostic plumbing, and proof additions to land together so support truth, behavior, and verification stay aligned.

</code_context>

<deferred>
## Deferred Ideas

- Background polling, periodic prefetch, or proactive remote-key readiness checks
- A broader remote metadata ingestion or federation subsystem beyond the narrow `jwks_uri` fetch path already shipped
- UI-only or dashboard-heavy operator experiences that depend on admin being mounted in every host shape
- Overly ambitious per-request durable audit logging for every transient remote JWKS failure
- Broader auth-method or protocol expansion; this milestone remains support-truth and diagnostics work on already shipped surfaces

</deferred>

---

*Phase: 91-jwks-uri-rotation-diagnostics-and-remediation-truth*
*Context gathered: 2026-05-25*
