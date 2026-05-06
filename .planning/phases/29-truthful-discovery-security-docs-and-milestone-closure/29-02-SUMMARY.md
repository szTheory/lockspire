---
phase: 29
plan: 02
subsystem: docs
tags:
  - dcr
  - documentation
  - security
dependency_graph:
  requires:
    - 29-01
  provides:
    - Truthful documentation and scope definition
  affects:
    - SECURITY.md
    - docs/dynamic-registration.md
    - mix.exs
tech_stack:
  added: []
  patterns:
    - Explicit out-of-scope documentation
key_files:
  created:
    - docs/dynamic-registration.md
  modified:
    - SECURITY.md
    - mix.exs
decisions:
  - Documented specific unsupported DCR features (Software Statements, Federation, FAPI, JAR-04, jwks_uri outbound) rather than excluding DCR altogether.
  - Placed rate limiting responsibility fully onto the host app via Plug.
metrics:
  duration: 2m
  completed_date: "2026-04-27"
---

# Phase 29 Plan 02: Update the documentation surface to accurately describe the shipped v1.5 DCR slice Summary

Truthful discovery and DCR guide documentation updated.

## Activities Performed
- Updated `SECURITY.md` to define exact boundaries of DCR scope and state host responsibilities for rate-limiting.
- Created `docs/dynamic-registration.md` as an operator and partner guide.
- Added `dynamic-registration.md` to `mix.exs` `extras` and `groups_for_extras`.

## Deviations from Plan
None - plan executed exactly as written.

## Threat Flags
None.

## Known Stubs
None.

## Self-Check: PASSED
FOUND: docs/dynamic-registration.md
FOUND: ddbb926
