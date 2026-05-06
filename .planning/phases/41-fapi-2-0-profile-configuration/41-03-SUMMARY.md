---
phase: 41-fapi-2-0-profile-configuration
plan: 03
subsystem: admin-ui
tags: [fapi-2-0, liveview, admin-ui, security-profile, mixed-mode]

# Dependency graph
requires:
  - phase: 41-fapi-2-0-profile-configuration
    plan: 01
    provides: "durable security_profile fields plus SecurityProfile resolver"
  - phase: 41-fapi-2-0-profile-configuration
    plan: 02
    provides: "router FAPI boundary groundwork and mixed-mode semantics"
provides:
  - "Global admin LiveView for ServerPolicy.security_profile"
  - "Per-client security profile edit workflow on the existing client detail LiveView"
  - "Shared policy navigation across PAR, Security Profile, DPoP, and DCR policy surfaces"
  - "Mixed-mode warning for client :none override under global :fapi_2_0_security"
  - "7 targeted LiveView tests covering route exposure, persistence, summary counts, and warning UI"
affects:
  - "41-04 (integration and maintainer docs now align with visible operator workflows)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Admin policy pages share a secondary nav via AdminComponents.policy_nav/1"
    - "Client detail workflows continue using the existing show LiveView plus FormComponent mode switching"
    - "SecurityProfile.resolve_effective_profile/2 drives operator-visible effective posture, not duplicated UI logic"

key-files:
  created:
    - lib/lockspire/web/live/admin/policies_live/security_profile.ex
    - test/lockspire/web/live/admin/policies_live/security_profile_test.exs
    - test/lockspire/web/live/admin/clients_live/show_test.exs
  modified:
    - lib/lockspire/web/components/admin_components.ex
    - lib/lockspire/web/live/admin/clients_live/form_component.ex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - lib/lockspire/web/live/admin/policies_live/par.ex
    - lib/lockspire/web/live/admin/policies_live/dpop.ex
    - lib/lockspire/web/live/admin/policies_live/dcr.html.heex
    - lib/lockspire/web/router.ex

key-decisions:
  - "Security profile editing stays on the existing client detail LiveView as another focused workflow, not a new standalone page family"
  - "Mixed-mode bypass is explicit and operator-visible rather than hidden in effective-profile math"
  - "Policy tab consistency is enforced through one component instead of duplicated link strips per page"

requirements-completed: [FAPI-01]

# Metrics
completed: 2026-05-01
---

# Phase 41 Plan 03: Admin LiveView Surfaces Summary

**Global and per-client security profile controls are now exposed through the admin UI, including effective-profile rendering, mixed-mode warnings, and shared policy navigation.**

## Accomplishments

- Added `Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfile` for global `ServerPolicy.security_profile` edits and override summary counts.
- Added the per-client `/admin/clients/:client_id/security-profile` LiveView route and form mode.
- Extended the client detail page to show global profile, client override, effective profile, and the mixed-mode warning when a client opts out under global FAPI mode.
- Introduced `AdminComponents.policy_nav/1` and wired it into the PAR, Security Profile, DPoP, and DCR policy pages.
- Added targeted LiveView coverage for route exposure, persistence, summary rendering, and mixed-mode visibility.

## Verification

- `mix test test/lockspire/web/live/admin/policies_live/security_profile_test.exs` -> `4 tests, 0 failures`
- `mix test test/lockspire/web/live/admin/clients_live/show_test.exs` -> `3 tests, 0 failures`
- `rg "policy_nav" lib/lockspire/web/live/admin/policies_live` confirms the nav renders on PAR, Security Profile, DPoP, and DCR pages

## Notes

- This plan ratified substantial pre-existing UI scaffolding already present in the worktree and filled the missing route, warning behavior, and verification coverage.
- Manual browser confirmation of the policy pages remains available via `41-VALIDATION.md`, but the planned LiveView automation for this phase is now in place.
