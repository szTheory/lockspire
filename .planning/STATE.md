---
gsd_state_version: 1.0
milestone: none
milestone_name: none
status: sustaining_release_train
stopped_at: adoption demo smoke shipped and main CI green
last_updated: "2026-05-27T10:35:00Z"
last_activity: 2026-05-27
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

**Core value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider with high-security defaults while keeping account, login, tenant policy, and operator authentication in the host app.

**Current focus:** Sustaining GA release train. Keep `main` green, keep release truth coherent, and use the adoption demo as secondary DX proof for host-app boot and browser-flow sanity.

## Current Position

Phase: none
Plan: none
Status: `v1.26 Host Integration & Operator Boundary Hardening` shipped in `lockspire 1.2.0`; adoption-demo smoke shipped in PR `#44` and post-merge `main` CI is green.
Last activity: 2026-05-27

## Most Recent Release

- Version: `1.2.0`
- Release PR: `#41 chore(main): release lockspire 1.2.0`
- Milestone PR: `#40 v1.26 Host Integration & Operator Boundary Hardening`
- Protected publish proof: GitHub Actions run `26502800103`
- Install-truth proof: `./scripts/publish/verify_install_truth.sh` passed for `1.2.0`
- GitHub release: `lockspire-v1.2.0`

## Recently Shipped Milestones

| Milestone | Phases | Plans | Requirements | Status |
|-----------|--------|-------|--------------|--------|
| v1.26 | 94-96 | 3 | 5 | shipped |
| v1.25 | 91-93 | 9 | 9 | shipped |
| v1.24 | 88-90 | 9 | 7 | shipped |

## Decisions

- Lockspire defaults to a standing GA release train: `milestone: none`, patch-on-merge for patch-eligible changes, and explicit milestone creation only for adopter-evidenced scope beyond sustainment.
- `.planning/RELEASE-TRAIN.md` is the canonical GSD ledger for latest release proof, patch-train rules, and next-cut conditions.
- `.planning/DEVELOPMENT-TRAIN.md` is the canonical GSD policy for future feature milestones: one `milestone/vNEXT-short-slug` branch, one PR to `main`, and merge only after milestone audit, verification evidence, `mix ci`, and GitHub PR checks pass.
- `Lockspire.Web.AdminRouter` is the bounded admin-only router for generated hosts that want to protect `/lockspire/admin` with host-owned operator authentication while preserving the existing public OAuth/OIDC router.
- Exact-ref release dispatch must ensure the matching GitHub release exists before Hex publish; the `1.2.0` Hex publish succeeded and the missing GitHub release was backfilled.
- Do not reopen broad protocol breadth by default. Gateway/service-mesh productization, hosted auth/CIAM, SAML/LDAP, certification breadth chasing, and auth-method parity work remain diminishing-return unless adopter evidence changes the calculus.
- The repo-local Phoenix adoption demo is a secondary executable DX smoke, not primary support truth and not Hex package content. It proves a host app can boot with Lockspire, seed representative clients/accounts, drive browser login/consent/device flows over HTTP, and run in CI as `Adoption Demo Smoke`.
- Host-owned browser seams in the demo route Lockspire interaction completion and demo consent through the browser/session pipeline before the public OAuth/OIDC forward. That keeps the embedded-library boundary honest: machine endpoints stay public; login, consent, verification, and operator auth stay host-owned.
- The demo uses Lockspire's issued stored access token against Lockspire `/userinfo`. The Phoenix protected-resource plug remains JWT-bearer-oriented; do not conflate token-endpoint stored access tokens with JWT route-protection fixtures without a deliberate future design.

## Blockers/Concerns

- None active. The sustaining default depends on keeping `main` green and the release-truth ledger current whenever a real release lands.

## Session Continuity

**Next action:** Stay on the sustaining GA train. Optional next patch release `1.2.1` only if we want HexDocs to publish the adoption demo guide immediately; otherwise wait for a real runtime/doc fix. Next feature-sized milestone should focus on the Phoenix resource-server/token acceptance story if adopter evidence justifies it.
**Resume file:** None
**Stopped at:** `lockspire 1.2.0` shipped; release dispatch hygiene patch in progress.
**Ecosystem:** .planning/ECOSYSTEM-SIGRA.md
