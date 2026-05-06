---
phase: 41-fapi-2-0-profile-configuration
plan: 04
subsystem: protocol
tags: [fapi-2-0, integration, conformance, docs, dpop, par]

# Dependency graph
requires:
  - phase: 41-fapi-2-0-profile-configuration
    plan: 01
    provides: "effective security profile resolution for global and per-client modes"
  - phase: 41-fapi-2-0-profile-configuration
    plan: 02
    provides: "FAPI20EnforcerPlug boundary checks on /authorize, /token, and /userinfo"
  - phase: 41-fapi-2-0-profile-configuration
    plan: 03
    provides: "operator workflows for enabling and overriding the security profile"
provides:
  - "Phase-41-scoped end-to-end FAPI integration test proving boundary enforcement plus in-protocol defense-in-depth"
  - "Live conformance smoke-check script for /authorize, /token, and /userinfo"
  - "Maintainer workflow documenting local probe plus OIDF conformance suite handoff"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Integration coverage distinguishes Plug-boundary behavior from downstream defense-in-depth behavior"
    - "Conformance smoke check is env-driven and safe to run against a live mounted Lockspire instance"

key-files:
  created:
    - test/integration/phase41_fapi_2_0_e2e_test.exs
    - scripts/conformance/fapi2-check.sh
  modified:
    - docs/maintainer-conformance.md

key-decisions:
  - "Phase 41 integration coverage stops at PAR + DPoP profile enforcement and leaves algorithm lockdown to Phase 42"
  - "The maintainer script is a smoke check, not a certification claim; the OIDF suite remains the authoritative external lane"
  - "Per-client opt-in and opt-out coverage is part of the load-bearing Phase 41 gate because mixed-mode is an intentional product decision"

requirements-completed: [FAPI-01, FAPI-02, FAPI-03]

# Metrics
completed: 2026-05-01
---

# Phase 41 Plan 04: Integration and Conformance Summary

**Phase 41 now has end-to-end proof for global and per-client FAPI behavior, plus a maintainer-facing smoke-check script and updated conformance guidance.**

## Accomplishments

- Reworked `test/integration/phase41_fapi_2_0_e2e_test.exs` around the actual Phase 41 boundary:
  - direct `/authorize` PAR rejection
  - plain PKCE rejection at PAR
  - successful DPoP-bound authorization-code flow
  - per-client opt-in under global `:none`
  - per-client opt-out under global FAPI
  - `/userinfo` defense-in-depth negative and positive controls
  - `/token` defense-in-depth for Basic-auth requests where the Plug intentionally cannot infer the client
- Replaced the placeholder `scripts/conformance/fapi2-check.sh` text with an executable three-probe `curl` smoke test.
- Rewrote `docs/maintainer-conformance.md` to document enabling the profile, running the local probe, and using the OIDF conformance suite as the release-grade check.

## Verification

- `mix test test/integration/phase41_fapi_2_0_e2e_test.exs` -> `6 tests, 0 failures`
- `bash -n scripts/conformance/fapi2-check.sh` -> pass
- `test -x scripts/conformance/fapi2-check.sh` -> pass

## Notes

- The RS256 and weak-key expectations discussed during recovery were left out of the Phase 41 gate because they belong to the Phase 42 cryptography slice.
- The smoke-check script still requires a live Lockspire instance and a provisioned client; that manual run remains tracked in `41-VALIDATION.md`.
