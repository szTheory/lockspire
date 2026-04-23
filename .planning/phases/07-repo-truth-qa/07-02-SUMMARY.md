---
phase: 07-repo-truth-qa
plan: 02
subsystem: qa
tags: [dialyzer, credo, mix, generators, qa]
requires:
  - phase: 07-01
    provides: source-clean runtime and security-sensitive modules for strict Credo
provides:
  - mix-aware Dialyzer configuration for Lockspire's Mix-task and generator surface
  - a narrow checked-in Credo policy for test-only noise
  - a truthful green `mix qa` lane on the maintained development path
affects: [release-hardening, qa, mix, generators, contributor-gates]
tech-stack:
  added: []
  patterns:
    - explicit `:mix` PLT scope for Mix-task analysis
    - test-only analyzer exceptions kept narrow and auditable
key-files:
  created:
    - .credo.exs
    - lib/mix/tasks/lockspire.test.setup.ex
  modified:
    - mix.exs
    - lib/lockspire/generators/install.ex
    - lib/mix/tasks/lockspire.client.create.ex
    - lib/mix/tasks/lockspire.install.ex
    - lib/lockspire/audit/event.ex
    - lib/lockspire/clients.ex
    - lib/lockspire/protocol/token_exchange.ex
    - lib/lockspire/redaction.ex
key-decisions:
  - "Dialyzer now explicitly analyzes the legitimate Mix surface through `plt_add_apps: [:mix]` instead of treating Mix-task warnings as ignorable noise."
  - "Test-only Credo noise is handled with a small checked-in `.credo.exs` rather than broad directory muting or a Dialyzer ignore file."
patterns-established:
  - "Contributor-facing analyzer gates should go green from repo truth with explicit tool configuration, not hidden ignores."
  - "If a test-only analyzer exception is necessary, scope it to the specific check and test path."
requirements-completed: [GATE-01]
duration: 5 min
completed: 2026-04-23
---

# Phase 07 Plan 02: Mix and Analyzer Truthing Summary

**`mix qa` now passes from repo truth with Mix-aware Dialyzer coverage and a narrow test-only Credo exception surface**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-23T20:43:49Z
- **Completed:** 2026-04-23T20:48:30Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- Added explicit Mix-aware Dialyzer scope and cleaned the Mix-task/generator warning sources that were making the QA lane dishonest.
- Fixed the remaining Dialyzer issues surfaced while making the maintained path truthful, including follow-up regressions from the Wave 1 refactor.
- Closed `GATE-01` with a green `mix qa` and a tightly scoped `.credo.exs` limited to test-only noise.

## Task Commits

Each task was committed atomically:

1. **Task 1: Make Dialyzer truthful for the Mix-task and generator surface per D-01 through D-03** - `10af630` (fix)
2. **Task 2: Close GATE-01 with a truthful full `mix qa` pass and only tiny auditable analyzer policy if needed** - `e19b990` (chore)

**Plan metadata:** `pending`

## Files Created/Modified
- `mix.exs` - added explicit Dialyzer Mix app scope and preserved the contributor/release alias contract
- `.credo.exs` - scoped test-only exceptions to alias-usage, alias-order, and one single nesting hotspot
- `lib/lockspire/generators/install.ex` - cleaned Mix shell and project access patterns under Mix-aware analysis
- `lib/mix/tasks/lockspire.client.create.ex` - tightened Mix task option handling for Dialyzer truth
- `lib/mix/tasks/lockspire.install.ex` - cleaned Mix task branching and help handling
- `lib/mix/tasks/lockspire.test.setup.ex` - introduced the maintained test DB setup task used by repo-truth lanes
- `lib/lockspire/audit/event.ex` - removed a dead compact-metadata fallback exposed by Dialyzer
- `lib/lockspire/clients.ex` - regrouped client-type validation clauses to satisfy compiler and analyzer expectations
- `lib/lockspire/protocol/token_exchange.ex` - removed an unreachable error branch in id-token issuance
- `lib/lockspire/redaction.ex` - replaced guard-illegal/drop-impossible branches with simpler helper flow

## Decisions Made
- Used `plt_add_apps: [:mix]` instead of any `.dialyzer_ignore.exs` file so the Mix-task boundary is explicit and reviewable.
- Accepted a narrow `.credo.exs` for test-only checks because the remaining `mix qa` failures were test readability/style debt, not maintained runtime or security-source debt.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Repaired Wave 1 regressions blocking truthful analyzer runs**
- **Found during:** Task 1 (Make Dialyzer truthful for the Mix-task and generator surface per D-01 through D-03)
- **Issue:** `mix dialyzer` exposed follow-up compile and pattern-match issues in `clients.ex`, `redaction.ex`, `token_exchange.ex`, and `audit/event.ex`, which blocked a truthful repo-level analyzer run.
- **Fix:** Cleaned the unreachable branches and compile-invalid guard usage while preserving behavior.
- **Files modified:** `lib/lockspire/audit/event.ex`, `lib/lockspire/clients.ex`, `lib/lockspire/protocol/token_exchange.ex`, `lib/lockspire/redaction.ex`
- **Verification:** `mix dialyzer`, `mix qa`
- **Committed in:** `10af630`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The deviation was required to restore truthful analyzer execution. No scope creep beyond the maintained QA lane.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `07-03`, with `GATE-01` closed and the remaining work focused on keeping the maintained integration and Phase 3 test lanes crisp and deterministic.

## Self-Check: PASSED

---
*Phase: 07-repo-truth-qa*
*Completed: 2026-04-23*
