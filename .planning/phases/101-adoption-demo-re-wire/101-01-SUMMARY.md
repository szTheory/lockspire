---
phase: 101-adoption-demo-re-wire
plan: "01"
subsystem: auth
tags: [jwt, oauth, resource-indicators, phoenix, plug, audience]

# Dependency graph
requires:
  - phase: 97-contract-docs-first
    provides: four-file RECIPE-01 hash-lock mechanism and BEGIN/END marker convention
  - phase: 98-plug-hardening
    provides: VerifyToken RFC 9068 enforcement and audience exact-match logic
provides:
  - Canonical pipeline block declares absolute-URI audience: "https://billing.acme-ledger.test" in all four RECIPE-01 sites (D-01, D-03)
  - Doc prose example aligned to the same absolute URI for internal doc consistency
  - release_readiness_contract_test normalized SHA-256 byte-identical clause and non-empty-audience clause both passing
affects: [101-02, 102-generated-host-scaffolding]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Absolute HTTPS URI as VerifyToken audience: value — required by valid_resource_uri? and exact-match aud enforcement"
    - "Four-file identical edit protocol — audience value change must propagate byte-identically across docs, demo router, install template, and smoke script"

key-files:
  created: []
  modified:
    - docs/protect-phoenix-api-routes.md
    - examples/adoption_demo/lib/adoption_demo_web/router.ex
    - priv/templates/lockspire.install/router.ex
    - scripts/demo/adoption_smoke.py

key-decisions:
  - "D-01 honored: canonical audience/resource value is https://billing.acme-ledger.test (absolute HTTPS, no trailing slash)"
  - "D-03 honored: single-value substitution applied byte-identically to all four hash-locked RECIPE-01 files"
  - "Doc prose example (~line 42) updated to match absolute URI — outside BEGIN/END markers so has no effect on contract hash, but keeps rendered doc internally consistent"

patterns-established:
  - "Audience value must be an absolute HTTPS URI — valid_resource_uri? rejects bare strings like billing-api"
  - "Four-file identical edit: any future audience or pipeline change must be propagated across all four RECIPE-01 sites atomically"

requirements-completed: [DEMO-03]

# Metrics
duration: 10min
completed: 2026-05-28
---

# Phase 101 Plan 01: Audience URI Canonicalization Summary

**Replaced bare `audience: "billing-api"` with absolute URI `audience: "https://billing.acme-ledger.test"` byte-identically across all four RECIPE-01 hash-locked sites, closing the `valid_resource_uri?` rejection and audience-confusion vulnerability classes**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-05-28T20:20:00Z
- **Completed:** 2026-05-28T20:30:00Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Changed `audience: "billing-api"` to `audience: "https://billing.acme-ledger.test"` inside the `# BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE` block in all four RECIPE-01 sites (docs, demo router, install template, Python smoke)
- Updated the doc prose example at ~line 42 of `docs/protect-phoenix-api-routes.md` (outside the markers, no hash impact) to show the same absolute URI, eliminating the broken bare-string example from the rendered doc
- `mix test test/lockspire/release_readiness_contract_test.exs` passes: 31 tests, 0 failures — byte-identical normalized SHA-256 across all four sites and non-empty audience clause both green

## Task Commits

1. **Task 1: Replace audience value with absolute URI across all four hash-locked canonical blocks and align doc prose example** - `0085030` (feat)

**Plan metadata:** (see below in final commit)

## Files Created/Modified

- `docs/protect-phoenix-api-routes.md` - Block line ~18: `audience: "billing-api"` → `audience: "https://billing.acme-ledger.test"`; prose line ~42: same substitution (2 occurrences total, both updated)
- `examples/adoption_demo/lib/adoption_demo_web/router.ex` - Block line 25: `audience: "billing-api"` → `audience: "https://billing.acme-ledger.test"` (1 occurrence)
- `priv/templates/lockspire.install/router.ex` - Commented heredoc line 13: `# audience: "billing-api"` → `# audience: "https://billing.acme-ledger.test"` (1 occurrence, `# `-prefixed form preserved)
- `scripts/demo/adoption_smoke.py` - Commented block line 246: `# audience: "billing-api"` → `# audience: "https://billing.acme-ledger.test"` (1 occurrence, `# `-prefixed form preserved; runtime `exercise_authorization_code()` untouched per plan — Plan 02's job)

## Decisions Made

- D-01 canonical value `https://billing.acme-ledger.test` used verbatim — no trailing slash, absolute HTTPS, byte-for-byte as specified in 101-CONTEXT.md
- D-03 four-file identical edit applied atomically; `release_readiness_contract_test` confirmed hash-lock intact after all four edits
- Doc prose edit is doc-consistency only (outside BEGIN/END markers) — does not affect any contract hash; the plan's verify grep counts 2 occurrences in the doc file as expected

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The four-file substitution was mechanically clean and the contract test passed on the first run.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 101-01 complete: all four RECIPE-01 sites now declare `audience: "https://billing.acme-ledger.test"` and the hash-lock is intact
- Plan 101-02 (Wave 2) can now wire the smoke's runtime `resource=` literal to the same URI and add the `exercise_authorization_code()` 200-with-token assertion — the block value it must match is now correct

---
*Phase: 101-adoption-demo-re-wire*
*Completed: 2026-05-28*
