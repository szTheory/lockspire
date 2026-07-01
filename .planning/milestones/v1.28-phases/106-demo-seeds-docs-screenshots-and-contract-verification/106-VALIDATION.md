# Phase 106: Demo Seeds, Docs, Screenshots, and Contract Verification - Validation

**Date:** 2026-06-03
**Status:** Ready for execution

## Validation Architecture

Phase 106 validation combines deterministic source checks, ExUnit coverage, and browser screenshot evidence:

1. **Seed-state proof**
   - Source assertions on `examples/adoption_demo/priv/repo/seeds.exs` for each meaningful admin state.
   - Adoption demo can be reset and re-seeded without manual database setup.

2. **Docs proof**
   - Source assertions on `docs/operator-admin.md` for the final admin journey model.
   - Existing release-readiness/operator-boundary tests remain the guard against host-boundary drift.

3. **Visual proof**
   - Browser-driven screenshots cover every top-level admin journey and mobile coverage for dense screens.
   - Coverage is recorded in `.planning/phases/106-demo-seeds-docs-screenshots-and-contract-verification/106-SCREENSHOTS.md`.

4. **Contract proof**
   - `test/lockspire/web/live/admin/design_system_contract_test.exs` fences class naming, inline styles, shared CSS primitives, and journey links.
   - Focused admin LiveView tests ensure the pages render the expected journeys.

## Commands

- `MIX_ENV=test mix compile --warnings-as-errors`
- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs`
- `mix test test/lockspire/web/live/admin`
- Adoption demo seed + browser screenshot capture for routes listed in `106-SCREENSHOTS.md`

## Required Evidence

- `106-SCREENSHOTS.md` lists desktop/mobile coverage and the screenshot file for each covered route.
- Contract tests cover all Phase 106 requirement IDs indirectly through source/test assertions:
  - `SEED-01`: seed-state assertions or source checks.
  - `DOCS-01`: operator guide assertions.
  - `VISUAL-01`: screenshot inventory.
  - `CONTRACT-01`: design-system contract tests.
