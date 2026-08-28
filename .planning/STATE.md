---
gsd_state_version: 1.0
milestone: v1.37
milestone_name: Prime-Time Readiness Ratchet
status: Awaiting next milestone
stopped_at: v1.37 archived; sustaining GA release train active
last_updated: "2026-08-28T04:43:03.593Z"
last_activity: 2026-08-28
last_activity_desc: Milestone v1.37 completed and archived
progress:
  total_phases: 7
  completed_phases: 7
  total_plans: 58
  completed_plans: 58
  percent: 100
current_phase: 137
current_phase_name: CI, Conformance, and Release Proof
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Sustaining GA release train; no active feature milestone

## Current Position

Phase: Milestone v1.37 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-08-28 — Milestone v1.37 completed and archived

## Accumulated Context

### Recent Sustaining Release: 1.5.0

- Release PR #93 merged the 1.5.0 bookkeeping at `02e74366`; release automation hardening #94 produced current source SHA `5d10ce2219c2e687cf9573c8b280abfb118a47d8`.
- Canonical `main` CI run `33141161205` passed at that exact source SHA.
- Protected recovery release run `33141484467` built, published, and publicly re-verified one `lockspire-1.5.0.tar` (415744 bytes, SHA-256 `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de`).
- Default-branch supplemental OIDF run `33139876101` retained allowlisted Phase37 and FAPI2 receipts with immutable suite identity. Both honestly classified suite failures; the lane remains supplemental and makes no certification claim.

### 2026-07-28 sustaining pass (1.3.0 -> 1.4.0)

- The adoption demo host app was rebranded Acme Ledger -> Billingo, gained a host-owned 404/500 error view, and its authorized-apps screen now reads real consent grants with a working Disconnect scoped to the signed-in customer (#75).
- Building that screen surfaced a protocol-layer defect: re-approving a client the account already remembered created a duplicate active grant, so a host revoke UI would list an app twice and Disconnect only one of the pair. Fixed with `ConsentPolicy.duplicate_grant/2` (#77).
- `phoenix_live_view` moved from a `~> 1.1.28` pin to a `>= 1.1.28 and < 2.0.0` range so adopters are not forced onto 1.2.x to upgrade Lockspire (#76).
- Published architecture and code-walkthrough guides, with a documentation contract test pinning their ExDoc/README/package wiring (#73, #74).
- **Release Please had been aborting on every run since 1.3.0** with "There are untagged, merged release PRs outstanding", while reporting success. No release PR had been proposed since. Cause: the repo runs Release Please with `skip-github-release: true`, so nothing advanced the merged release PR's `autorelease:` label. The publish job now advances it after a successful publish (#78).
- Release ledger drift blocked `main` after both 1.3.0 and 1.4.0. `.planning/RELEASE-TRAIN.md` is now a Release Please `extra-files` target, so the release PR bumps the ledger alongside `mix.exs` (#80, #81).

### Earlier

- Docker/adoption demo DX hardening made hostname-first Traefik access the normal browser path and kept direct host ports as explicit fallback.
- Operator/admin anonymous access now redirects to `/login?return_to=%2Flockspire%2Fadmin`; signed-in non-operators still receive operator-only 403 guidance.
- Manual browser UAT passed at `http://lockspire-demo.localhost/lockspire/admin` after logging in as `ops`.
- Cairnloop still owns `127.0.0.1:4100`; do not treat that direct port as Lockspire unless a launcher explicitly prints it.

**Public release evidence:** `1.5.0`, release PR #93, canonical CI run `33141161205`, protected release run `33141484467`, tag `lockspire-v1.5.0`, source `5d10ce2219c2e687cf9573c8b280abfb118a47d8`; the exact public-version clean-room journey passed.

### Decisions

- v1.37 is an evidence-led readiness milestone: installation and the clean-room SaaS journey are the acceptance spine.
- Public API changes are additive or deprecation-only; supported v1.x behavior and security defaults remain compatible.
- The host owns accounts, login, branding, tenant/product policy, and operator authentication; Lockspire remains an embedded library.
- Admin visual redesign and formal certification are excluded while maintainer review capacity is limited.
- [Phase 131]: Generated Lockspire routes are an imported Phoenix macro; host-owned verification and consent routes precede an explicitly operator-guarded admin forward and public router.
- [Phase 131]: Install config declares the host logout path, and the account-resolver example uses only subject, id_token, and userinfo Claims fields.
- [Phase 131]: Migration installation preflights the complete package and host inventories before creating files, and exclusive writes preserve the host no-overwrite boundary.
- [Phase 131]: ConsentContext exposes only safe host display fields and terminal redirects.
- [Phase 131]: Installer consent template must exactly match a compiling executable fixture.
- [Phase 131]: Default generated smoke proves the :none profile, discovery/JWKS, S256 PKCE, and exact redirects; FAPI proof is explicit and separately discovered.
- [Phase 131]: Install verification now aggregates independently actionable runtime, seam, compiled-route, and host-migration diagnostics.
- [Phase 131]: Generated consent renders a non-interactive loading status and snapshots mount-time host resolver context for deferred authoritative lookup.
- [Phase 132]: `Lockspire.AccessToken` is the canonical semantic parser for subject, scopes, audiences, expiration, and allowlisted sender confirmation; raw claims remain compatible.
- [Phase 132]: Direct and dynamic client registration share a neutral capability validator, with optional RFC 7591 scope metadata kept distinct from the direct facade's required scope list.
- [Phase 132]: Protected-resource DPoP replay recording defaults to the configured durable Ecto repository; incompatible or failing custom stores fail closed.
- [Phase 132]: Lockspire establishes protocol validity and sender constraints, while the host separately owns tenant, object, billing, product, response, and rate-limit authorization.
- [Phase ?]: Phase 133 Plan 01: acceptance supervision remains provider/client-role-bounded, copied package provenance is mandatory, and diagnostics are redacted before rendering.

### Pending Todos

None yet.

### Blockers/Concerns

- No milestone blockers remain.
- Supplemental OIDF receipts identify authorization-endpoint semantics and broader FAPI/PAR/TLS interoperability as follow-up conformance work. These are retained findings, not a certification claim or release gate.
- The optional hosted-provider comparison remains the only conformance lane that accepts `LOCKSPIRE_OIDF_HOSTED_PROVIDER_CONFIG_JSON`.

## Session Continuity

Last session: 2026-08-28T04:41:30Z
Stopped at: v1.37 archived; sustaining GA release train active
Resume file: .planning/RELEASE-TRAIN.md

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 131 P01 | 8m | 2 tasks | 7 files |
| Phase 131 P02 | 4m | 2 tasks | 2 files |
| Phase 131 P03 | 17min | 2 tasks | 11 files |
| Phase 131 P04 | 18 min | 2 tasks | 7 files |
| Phase 131 P05 | 7 min | 2 tasks | 7 files |
| Phase 131 P06 | 30 min | 2 tasks | 5 files |
| Phase 131 P07 | 19m | 2 tasks | 4 files |
| Phase 132 P01 | 7m | 2 tasks | 4 files |
| Phase 132 P02 | 16m | 2 tasks | 8 files |
| Phase 132 P03 | 12m | 2 tasks | 5 files |
| Phase 132 P04 | - | 2 tasks | 12 files |
| Phase 133 P01 | 8m | 3 tasks | 8 files |

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
