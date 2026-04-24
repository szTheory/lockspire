---
phase: 09-preview-posture-lock
plan: 01
subsystem: docs
tags: [docs, phoenix, oauth, oidc, release, security]
requires:
  - phase: 08-release-trust-fence
    provides: "Repo-owned release workflow, contributor lane, and release-readiness contract patterns"
provides:
  - "Canonical v0.1 preview contract in docs/supported-surface.md"
  - "README, security, onboarding, and release docs aligned to the same embedded-library scope"
  - "Repo-owned proof references for onboarding and release posture"
affects: [README, docs, security, release-posture, preview-contract]
tech-stack:
  added: []
  patterns: ["Canonical support contract with thin referential companion docs", "Repo-owned proof named through tests and workflows"]
key-files:
  created: [.planning/phases/09-preview-posture-lock/09-01-SUMMARY.md]
  modified: [README.md, docs/supported-surface.md, SECURITY.md, docs/install-and-onboard.md, docs/maintainer-release.md]
key-decisions:
  - "Keep docs/supported-surface.md as the single public source of truth for the v0.1 preview surface"
  - "Keep README, SECURITY.md, onboarding, and maintainer docs intentionally thinner and referential"
patterns-established:
  - "Public posture claims live once in docs/supported-surface.md, with other docs linking back instead of duplicating policy"
  - "Repo-owned proof is named through checked-in tests and workflows rather than demo-app or certification claims"
requirements-completed: [POST-01]
duration: 2 min
completed: 2026-04-24
---

# Phase 09 Plan 01: Preview Posture Lock Summary

**Canonical `v0.1` preview contract for the embedded Phoenix library with repo-owned proof references across README, security, onboarding, and release docs**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-24T03:30:45Z
- **Completed:** 2026-04-24T03:33:05Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Made `docs/supported-surface.md` the canonical public `v0.1` preview contract for Lockspire's embedded Phoenix/Elixir surface.
- Reduced `README.md` to a short entrypoint that links back to the canonical contract instead of carrying a second support matrix.
- Aligned `SECURITY.md`, `docs/install-and-onboard.md`, and `docs/maintainer-release.md` to the same repo-proven preview wedge and named proof artifacts.

## Task Commits

Each task was committed atomically:

1. **Task 1: Make `docs/supported-surface.md` the canonical `v0.1` preview contract per D-01 through D-07** - `29d8bba` (docs)
2. **Task 2: Align security, onboarding, and maintainer docs to the canonical preview contract per D-02 through D-10** - `ae3bf46` (docs)

## Files Created/Modified
- `docs/supported-surface.md` - Canonical preview contract with in-scope surface, out-of-scope boundaries, trust posture, and proof map
- `README.md` - Short public entrypoint with the canonical supported-surface link
- `SECURITY.md` - Security disclosure and secure-default posture aligned to the preview wedge
- `docs/install-and-onboard.md` - Generator-first onboarding guide that names the host seam and executable proof
- `docs/maintainer-release.md` - Maintainer release posture constrained to the same preview support boundary

## Verification

- `mix docs.verify` after Task 1: PASS
- `rg -n "v0\\.1|preview|embedded|Phoenix|PKCE|JWKS|userinfo|revocation|introspection|refresh" docs/supported-surface.md README.md`: PASS
- `rg -n "production-ready|PAR|device flow|dynamic client registration|hosted auth service|CIAM" docs/supported-surface.md README.md`: PASS, with matches only in explicit out-of-scope or "should not say" text
- `mix docs.verify` after Task 2: PASS
- `mix test test/lockspire/release_readiness_contract_test.exs`: PASS
- `rg -n 'PKCE S256|required by default|exact-match redirect URI|hashed at rest|single-use|revocation on reuse|no implicit flow|no \`alg=none\`' SECURITY.md docs/supported-surface.md`: PASS
- `rg -n 'install_generator_test|phase6_onboarding_e2e_test|mix ci|release.preflight|hex-publish' docs/install-and-onboard.md docs/maintainer-release.md`: PASS
- `rg -n 'PAR|production-ready|certification|demo app|hosted auth service|CIAM' SECURITY.md docs/install-and-onboard.md docs/maintainer-release.md`: PASS, with matches only in explicit out-of-scope or do-not-claim text

## Decisions Made

- Kept the authoritative support posture in a single doc so future edits have one truth source.
- Named repo-owned proof through checked-in tests and workflows instead of expanding public claims.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Public preview posture is now locked to the embedded-library surface the repo currently proves.
- The repo is ready for the next preview-posture task or broader phase verification without parallel support-policy drift across docs.

## Self-Check: PASSED

- Found `.planning/phases/09-preview-posture-lock/09-01-SUMMARY.md`
- Verified task commits `29d8bba` and `ae3bf46` exist in git history

---
*Phase: 09-preview-posture-lock*
*Completed: 2026-04-24*
