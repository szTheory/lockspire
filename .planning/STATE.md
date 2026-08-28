---
gsd_state_version: 1.0
milestone: v1.37
milestone_name: Prime-Time Readiness Ratchet
current_phase: 137
current_phase_name: CI, Conformance, and Release Proof
status: blocked
stopped_at: Phase 137 implemented; GitHub-hosted conformance and protected release verification required
last_updated: "2026-08-28T02:08:00Z"
last_activity: 2026-08-27
last_activity_desc: Phase 137 implemented, reviewed, Nyquist-compliant, and threat-secure; external acceptance pending
progress:
  total_phases: 7
  completed_phases: 6
  total_plans: 58
  completed_plans: 58
  percent: 86
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Phase 137 — CI, Conformance, and Release Proof

## Current Position

Phase: 137 — CI, Conformance, and Release Proof
Plan: 10 of 10 implemented
Status: External verification required
Last activity: 2026-08-27 — Phase 137 implementation and internal verification complete; GitHub-hosted acceptance pending

Progress: [█████████░] 86%

## Accumulated Context

### Recent Sustaining Release: 1.4.0

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

**Public release evidence:** `1.4.0`, release PR #79, protected workflow run `30386337705`, tag `lockspire-v1.4.0` at `ee32dbd`; `verify_install_truth.sh` passed for the public version. `1.3.0` shipped earlier the same day through exact-ref run `30323976705` and release PR #71.

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

- The scheduled OIDC/FAPI workflow must run on the default branch against its disposable Billingo provider and retain only classified redacted receipts. These scheduled Phase37 and FAPI jobs require no provider secrets.
- The manual hosted-provider comparison lane remains optional and is the only conformance lane that accepts `LOCKSPIRE_OIDF_HOSTED_PROVIDER_CONFIG_JSON`.
- An approved protected release or staging-equivalent must prove the same tar checksum through outbound Hex bytes, the release-specific Hex API, versioned HexDocs, and the exact-version clean-room journey.
- The release check requires protected credentials and external state; no package was published during autonomous implementation.

## Session Continuity

Last session: 2026-08-28T02:08:00Z
Stopped at: Phase 137 external verification boundary
Resume file: .planning/phases/137-ci-conformance-and-release-proof/137-VERIFICATION.md

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
