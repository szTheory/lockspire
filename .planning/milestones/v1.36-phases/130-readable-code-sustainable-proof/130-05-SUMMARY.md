---
phase: 130-readable-code-sustainable-proof
plan: "05"
subsystem: testing
tags: [exunit, phoenix-liveview, admin-ui, design-system, test-architecture]
requires:
  - phase: 130-readable-code-sustainable-proof
    provides: "Shared test configuration foundation from Plan 01"
provides:
  - "Capability-oriented CSS, route/workflow, and proof-artifact admin contract suites"
  - "Shared test-only admin contract helpers"
  - "Executable historical test and assertion inventory guard"
affects: [admin-ui, operator-proof, design-system-contracts]
tech-stack:
  added: []
  patterns:
    - "Large source-proof suites are split by stable capability while common helpers remain test-only"
key-files:
  created:
    - test/support/admin_contract_helpers.ex
    - test/lockspire/web/live/admin/design_system/css_contract_test.exs
    - test/lockspire/web/live/admin/design_system/route_contract_test.exs
    - test/lockspire/web/live/admin/design_system/proof_artifact_contract_test.exs
    - test/lockspire/web/live/admin/design_system/inventory_contract_test.exs
  modified:
    - test/lockspire/web/live/admin/design_system_contract_test.exs
key-decisions:
  - "Preserve every historical test description and assertion while organizing modules by proof capability."
  - "Use a test-only `use Lockspire.AdminContractHelpers` macro so paths and pure helpers have one source without runtime API."
  - "Make inventory parity executable: 70 moved tests, 70 unique names, and 462 historical assertion calls."
patterns-established:
  - "Capability splits must physically move tests; wrapper requires and duplicate suites are forbidden."
requirements-completed: [TEST-02]
coverage:
  - id: D1
    description: "Admin CSS/theme, route/workflow, and proof-artifact contracts run as distinct suites without evidence loss."
    requirement: TEST-02
    verification:
      - kind: unit
        ref: "MIX_ENV=test mix test test/lockspire/web/live/admin/design_system"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix test test/lockspire/web/live/admin"
        status: pass
    human_judgment: false
duration: "12m"
completed: 2026-08-26
status: complete
---

# Phase 130 Plan 05: Admin Design Contract Split Summary

**The 3,618-line admin design contract is now three capability suites with shared test-only helpers and an executable no-loss inventory.**

## Accomplishments

- Split CSS/theme/motion/responsive/primitive proof, route/workflow proof, and proof-artifact/redaction proof into independently runnable modules.
- Preserved all 70 historical tests, all 70 unique descriptions, and all 462 historical assertion calls; the inventory suite adds 3 tests and 21 assertion calls.
- Replaced phase-numbered `describe` labels with durable capability names while retaining historically useful individual test descriptions.
- Added a contract that prevents restoration of the legacy monolith, wrapper loading, duplicate test names, phase-numbered grouping, or silent inventory loss.

## Inventory

| Inventory | Before | After |
|---|---:|---:|
| Contract modules | 1 | 3 capability modules + 1 inventory module |
| Historical tests | 70 | 70 |
| Total tests in split directory | 70 | 73 |
| Historical assertion calls | 462 | 462 |
| Total assertion calls including inventory guard | 462 | 483 |
| Lines | 3,618 | 3,865 across helper and split suites |

### Complete old-to-new mapping

Every moved test kept its original description, so the mapping is identity-by-test-name. The complete destination partition is:

- `css_contract_test.exs` (27): admin button namespaces; shared utility CSS; final v1.28 primitives; semantic token categories; brandbook token alignment; dark aliases; light/dark/system themes; explicit motion; reduced motion; Phase 120 brand/source/doc/copy contracts (4); raw-hex allowlist; shared component primitives; Phase 118 status/form/responsive contracts (3); shell theme control; behavior-neutral primitive migrations; Phase 119 source/adoption inventory; 390px client workspace; Phase 103/104 inline-style fences; global inline-style/button fence; Phase 116 visual rubric and component-group inventory.
- `route_contract_test.exs` (23): Phase 121 route truth, required judgment fields, duplicate labels, follow-up routes, support ceiling, secret evidence, and read-only operate scorecards (7); route/docs journey alignment; Phase 107 journey vocabulary; Phase 109 labels/primitives/style and CTA/redaction/action fences (2); Phase 119 DCR and read-only operate semantics (2); operate route boundary, mutation-delegate denial, LiveView primitives, layout CSS, row semantics, sensitive-source denial, and public proof boundary (7); Configure route truth and primitive/action propagation (2); Phase 116 route workflow inventory.
- `proof_artifact_contract_test.exs` (20): semantic disabled-link and token-like-text helper contracts (2); browser evidence accept/reject/redaction and closeout proof coverage/source/adversarial signoff (5); public docs/package proof boundary; Phase 119 redaction/browser boundary; global scorecard, public-surface, copy/redaction, and CSS/responsive guardrails (4); Phase 110 demo seed state and redaction, operator docs, screenshot/browser inventory, screenshot cells, and proof boundary (6); Phase 116 lab support boundary.

`inventory_contract_test.exs` parses these files to enforce the exact per-destination counts `%{css: 27, proof_artifact: 20, route: 23}`, 70 unique historical names, and 462 historical assertion calls.

## Files Created/Modified

- `test/support/admin_contract_helpers.ex` - Shared source paths, parsers, source readers, CSS extraction, route inventory, scorecard, evidence, and HTML assertion helpers.
- `test/lockspire/web/live/admin/design_system/css_contract_test.exs` - Token, theme, motion, responsive, accessibility, and primitive contracts.
- `test/lockspire/web/live/admin/design_system/route_contract_test.exs` - Route truth, journey, read-only queue, confirmation/action, and operator workflow contracts.
- `test/lockspire/web/live/admin/design_system/proof_artifact_contract_test.exs` - Evidence fixtures, browser rows, redaction, supported-surface, and proof-boundary contracts.
- `test/lockspire/web/live/admin/design_system/inventory_contract_test.exs` - No-loss and physical-split architecture guard.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` - Removed after all contracts moved.

## Verification

- `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system` - PASS, `73 tests, 0 failures`.
- `MIX_ENV=test mix test test/lockspire/web/live/admin` - PASS, `173 tests, 0 failures`.
- Historical inventory comparison - PASS, `70 -> 70 tests`, `462 -> 462 assertion calls` before the new inventory guard.

## Deviations from Plan

- Added `inventory_contract_test.exs` beyond the three planned capability suites so the required old-to-new inventory remains executable instead of documentation-only.

## Issues Encountered

- Moving tests one directory deeper initially invalidated `__DIR__`-relative source paths. The shared helper establishes the original contract directory explicitly, and all moved direct path reads use that stable base.
- Test startup emits the existing non-blocking KeyCache refresh log before ExUnit; both required commands exit successfully.

## User Setup Required

None.

## Next Phase Readiness

The admin proof suite is capability-shaped and the complete admin LiveView test tree is green. Later readability work can rename historical individual test descriptions independently without risking coverage movement.

---
*Phase: 130-readable-code-sustainable-proof*
*Completed: 2026-08-26*
