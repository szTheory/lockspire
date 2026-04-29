---
gsd_state_version: 1.0
milestone: v1.9
milestone_name: milestone
status: planning
stopped_at: Phase 40 context gathered (assumptions mode)
last_updated: "2026-04-29T20:30:00.000Z"
last_activity: 2026-04-29
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md`

**Core value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Phase 40 — JWE Support for Request Objects

## Current Position

Phase: 40
Plan: Planned
Status: Ready for execution
Last activity: 2026-04-29

## Performance Metrics

- Phases completed: 0/1 (v1.9)
- Plans completed: 0/0 (v1.9)

## Accumulated Context

### Decisions

See `PROJECT.md` Key Decisions and archived milestones.

- **v1.7 DPoP Core**: The next milestone should strengthen the real-client trust story rather than add breadth for its own sake.
- The next wedge should optimize first for public and CLI-oriented clients because that is where sender-constrained tokens most improve the current preview surface.
- DPoP is preferred over mTLS for this milestone because it composes with the embedded Phoenix library shape and the device-flow path without introducing enterprise PKI assumptions.
- The first DPoP milestone should be a usable core: proof validation, token binding, replay protection, owned-surface consumption, and truthful discovery/docs.
- The longer-range milestone arc should be persisted in `.planning/EPIC.md` so future milestone selection compounds from repo truth.
- Phase 33-02 keeps DPoP replay storage narrow and durable around a unique replay key plus explicit proof claims instead of a generic cache abstraction.
- Phase 33-02 rejects replayed proofs on the token-endpoint preflight seam now, while leaving cnf binding and token_type work for Phase 34.
- Model DPoP enablement as explicit durable enums instead of metadata so bearer-default behavior and later admin/DCR truth remain deterministic.
- Keep server policy as :bearer | :dpop and client policy as :inherit | :bearer | :dpop so existing clients stay inherited while explicit overrides can narrow or opt in.
- Make the resolver return explicit invalid-policy errors instead of silently coercing malformed state into bearer behavior.
- Authorization-code exchange now resolves one protocol-owned issuance_context and threads it through builders and persistence instead of using grant-local DPoP flags.
- Server-policy and replay-store defaults fall back to the request's repository adapter seam so token-endpoint DPoP resolution stays truthful in embedded and test environments.
- Device-code exchange now resolves TokenEndpointDPoP before approved redemption so DPoP binding stays at the Lockspire-owned /token boundary.
- Generated-host DPoP replay proof uses a fresh proof on second redemption to isolate consumed device_code invalid_grant behavior from proof replay rejection.
- Refresh exchange now derives DPoP mode from the presented refresh token's durable cnf and requires a valid proof only for bound families.
- Refresh proof-object and replay failures remain invalid_dpop_proof, while repository key mismatches collapse publicly to invalid_grant.
- Drive userinfo DPoP enforcement from durable token cnf.jkt state instead of client or server policy lookups.
- Collapse userinfo DPoP proof failures to public invalid_token while using WWW-Authenticate to advertise DPoP capability and accepted algorithms.
- Self-registered clients now resolve omitted or false dpop_bound_access_tokens to explicit bearer policy instead of inheriting future server defaults.
- The DPoP operator surface stays intentionally parallel to PAR: one global policy page plus the existing client edit workflow.
- Discovery now publishes DPoP algorithm metadata only when both `/token` and Lockspire-owned `/userinfo` are mounted.
- Public support docs now claim DPoP only for token requests and Lockspire-owned `userinfo`, with generic host protected-resource middleware explicitly out of scope.
- Extend active introspection response to expose persisted cnf state
- Do not relax caller authentication or inactive/collapsed introspection behavior
- Promote the Phase 32 generated-host DPoP device testing client to :confidential client type so it can introspect its own token in the same harness
- Keep auth_time protocol-owned by validating it in IdToken.sign/1 and filtering it from host claim maps.
- Preserve DPoP runtime strictness and lock it with regression coverage instead of changing proof validation behavior.
- AuthorizationRequest now parses prompt=none, max_age, and auth_time claim demand centrally while preserving exact redirect-uri and nonce enforcement.
- AuthorizeController remained tuple-driven; controller coverage expanded without moving request parsing out of the protocol layer.
- Durable interaction rows now own max_age and auth_time request truth, and only explicit host auth_time input can advance auth_time on login resume.
- prompt=none now returns redirect-safe OIDC errors from AuthorizationFlow before any host login or Lockspire consent UI can execute.
- TokenExchange reads nonce and conditional auth_time from persisted interaction state while keeping OpenID device grants interaction-optional.
- Keep Phase 39 Wave 0 logout propagation coverage compile-safe with skipped placeholders only.
- Extend discovery_test.exs in place so Phase 38 live truth stays green while Phase 39 logout booleans remain explicitly skipped.
- Logout propagation fields remain typed client state with URI presence as the only opt-in.
- Operator logout validation stays offline and enforces same-origin front-channel checks against registered redirect URIs.
- Phase 39 DCR keeps logout metadata explicitly unsupported instead of silently ignoring it.
- Logout propagation persists one event row and separate per-channel delivery rows instead of deriving history from jobs or live client config.
- Repository snapshot selection keys off active access and refresh tokens by sid, then dedupes to distinct client ids before building delivery rows.
- The earlier plan-owned client-field migration was kept as a compatibility no-op because Phase 39-02 had already shipped the real additive migration under version 20260429193000.
- Lockspire starts a named Oban runtime and raises immediately when :lockspire repo or Oban runtime config is missing or invalid.
- Back-channel logout delivery treats the persisted logout_delivery snapshot as the authoritative dispatch contract instead of re-resolving live client state.
- Logout lifecycle telemetry and audit surfaces use explicit requested, enqueued, attempted, succeeded, failed, and discarded stages with raw tokens and raw response payloads redacted at emission time.
- Replay-safe logout completion is keyed by signed event_id values carried through the host return token.
- Backchannel enqueue now persists oban_jobs rows inside the same completion transaction as logout event and delivery state.
- Front-channel completion now renders only local browser dispatch truth and marks front-channel rows as rendered, never succeeded.
- Admin logout propagation uses a dedicated workflow on the existing client edit route so propagation settings stay separate from post-logout redirect editing without widening router scope.

### Blockers/Concerns

- Remaining non-Phase-38 baseline failures are in signing key lifecycle tests:
  - `Lockspire.Web.Live.Admin.KeysLiveTest`
  - `Lockspire.Admin.KeysTest`

## Session Continuity

**Next action:** Investigate and fix the remaining key-lifecycle baseline failures before starting Phase 39.

**Resume file:** --resume-file

**Stopped at:** Phase 40 context gathered (assumptions mode)

**Ecosystem:** `.planning/ECOSYSTEM-SIGRA.md`

**Planned Phase:** Phase 39
