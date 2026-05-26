---
gsd_state_version: 1.0
milestone: none
milestone_name: none
status: release_truth_cleanup
stopped_at: Release-truth cleanup after v1.25
last_updated: "2026-05-26T13:45:00Z"
last_activity: 2026-05-26
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider with high-security FAPI 2.0 standards.

**Current focus:** Release-truth cleanup and next Hex release from the shipped `v1.22`-`v1.25` scope.

## Current Position

Phase: None
Plan: Release-truth cleanup
Status: Final polish before next release
Last activity: 2026-05-26

## Performance Metrics

- Phases completed: 3/3 in the archived `v1.25` milestone
- Plans completed: 9/9 in the archived `v1.25` milestone

Most recently shipped milestone:

| Milestone | Phases | Plans | Requirements | Status |
|-----------|--------|-------|--------------|--------|
| v1.25 | 91-93 | 9 | 9 | shipped |
| v1.24 | 88-90 | 9 | 7 | shipped |

## Deferred Items

None.

## Accumulated Context

### Decisions

- Milestone v1.20 Mutual TLS (RFC 8705) will be implemented via an explicit extraction behaviour (`Lockspire.MTLS.Extractor`).
- Proxy extraction MUST be explicitly configured by the host app.
- Protected Phoenix API routes use `VerifyToken -> EnforceSenderConstraints -> RequireToken` as the canonical shipped pipeline.
- Route-level audience mismatches stay `401 invalid_token`, while scope failures render `403 insufficient_scope`.
- DCR create now accepts logout propagation metadata through shared Lockspire URI/origin validation and persists it on typed client fields.
- DCR create and management-read responses serialize persisted logout metadata directly from stored client state.
- RFC 7592 management update now applies logout propagation metadata through the same normalized typed-field path and clears omitted values under full-replace semantics.
- Repo-native proof for logout metadata management now covers rotated RAT truth, provenance/audit continuity, and negative validation contracts across protocol and controller seams.
- DCR and RFC 7592 now manage the existing logout propagation metadata while preserving the durable back-channel and best-effort front-channel truth model.
- Client records now store typed `token_endpoint_auth_signing_alg` truth so `client_secret_jwt` and `HS256` round-trip coherently across DCR, RFC 7592, discovery, and admin surfaces.
- Discovery now publishes `client_secret_jwt` only on the shared verifier endpoints and emits endpoint-local mixed JWT signing-alg unions with `HS256` kept symmetric-only.
- Admin create, detail, and DCR policy surfaces now expose the narrow `client_secret_jwt` slice with read-only `HS256` truth and unchanged secret-handling posture.
- Milestone v1.24 is complete and archived; the next default candidate should favor support-burden reduction over additional protocol breadth.
- `docs/supported-surface.md` remains the sole public authority for advanced-setup support claims, while helper-backed release-contract assertions act only as drift fences.
- Advanced-setup doc corrections should stay assertion-driven and narrow rather than reopening the support story across derived guides.
- Remote-JWKS runtime proof should anchor on stable incident semantics, bounded-reactive refresh, cache preservation, and generic wire failures instead of implementation trivia.
- The representative second advanced-setup surface remains the generated-host protected-route pipeline, and its under-scoped DPoP-bound path stays pinned to the shipped Bearer insufficient_scope response.
- Phase 93 and milestone v1.25 close on exact repo-native proof commands, requirement-mapped verification artifacts, and a single milestone audit rather than retrospective narrative.
- Deferred follow-on support work must stay explicit, narrow, and trigger-based instead of being implied as shipped scope.
- Milestone v1.25 is archived, and the repo should stop or reassess until real adopter evidence justifies another embedded-library-scoped milestone.
- The remaining high-leverage work after `v1.25` is release-truth polish: green contributor gates, stale-doc cleanup, and refreshed release notes for the shipped `v1.22`-`v1.25` delta.
- `docs/user-flows-jtbd.md` had drifted behind shipped reality by still describing the Phoenix protected-route plug pipeline as future work; release-truth cleanup must favor repo-proven current behavior over older planning narratives.

### Blockers/Concerns

- `mix ci` must be green before the next release candidate is considered ready.

## Session Continuity

**Next action:** Finish release-truth cleanup, restore a green `mix ci`, refresh the public release notes, and cut the next Hex release. After that, stop by default unless new adopter evidence justifies another milestone.
**Resume file:** None
**Stopped at:** Release-truth cleanup after archived v1.25
**Ecosystem:** .planning/ECOSYSTEM-SIGRA.md
