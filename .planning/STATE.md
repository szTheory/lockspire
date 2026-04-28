---
gsd_state_version: 1.0
milestone: v1.6
milestone_name: milestone
status: planning
stopped_at: Completed 36-end-to-end-proof-and-milestone-closure-02-PLAN.md
last_updated: "2026-04-28T20:49:47.386Z"
last_activity: 2026-04-28
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 12
  completed_plans: 10
  percent: 83
---

# Project State

## Project Reference

See: `.planning/PROJECT.md`

**Core value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Phase 36 — End-to-End Proof and Milestone Closure

## Current Position

Phase: 36
Plan: Not started
Status: Ready to plan
Last activity: 2026-04-28

## Performance Metrics

- Phases completed: 4/4 (v1.7)
- Plans completed: 12/12 (active execution window)

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

### Blockers/Concerns

- No current execution blockers.
- DPoP replay protection and proof-validation boundaries need deliberate scope control so the milestone stays narrow and repo-verifiable.

## Session Continuity

**Next action:** Run `$gsd-plan-phase 36`

**Resume file:** None

**Stopped at:** Completed 36-end-to-end-proof-and-milestone-closure-02-PLAN.md

**Ecosystem:** `.planning/ECOSYSTEM-SIGRA.md`

**Planned Phase:** 36 — End-to-End Proof and Milestone Closure
