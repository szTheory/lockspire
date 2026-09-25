---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "08"
subsystem: release-maintenance
tags: [git, stable-identity, fail-closed, evidence-ledger, bash]
requires:
  - phase: 138-07
    provides: Fail-closed aggregate GitHub publication and validated evidence-row rendering.
provides:
  - Full Git object-digest validation with typed stable-evidence-ID failures.
  - Branch, tag, and worktree domain receipts that fail closed without hiding valid sibling evidence.
  - Hermetic fixtures for command, empty-output, malformed-output, and every worktree stanza boundary.
affects: [phase-139, phase-140, phase-141, repository-triage]
actuals:
  tokens: 3683
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [typed shell failure contract, partial evidence with retained siblings, centralized stanza finalization]
key-files:
  created: [".planning/phases/138-baseline-inventory-evidence-taxonomy/138-08-SUMMARY.md"]
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Stable Git evidence identity accepts only a complete 40- or 64-character hexadecimal object digest."
  - "An identity failure suppresses only the unidentified row while making the exact domain and aggregate partial."
  - "Partial Git domains retain safely identified sibling rows but never render successful-zero evidence."
requirements-completed: [BASE-02]
coverage:
  - id: D1
    description: Branch and tag hash command, empty-output, and malformed-output failures downgrade the exact domain while retaining valid sibling evidence.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector fails closed when stable IDs cannot be generated
        status: pass
    human_judgment: false
  - id: D2
    description: Worktree identity failures at rollover, blank-line close, and final flush share one fail-closed finalization contract.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector fails closed when stable IDs cannot be generated
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-08-28
status: complete
---

# Phase 138 Plan 08: Stable Git Evidence Identity Fail-Closed Summary

**Validated subject-derived Git evidence IDs with domain-scoped failure receipts, retained sibling observations, and complete boundary fixtures.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-08-28T18:43:54Z
- **Completed:** 2026-08-28T18:50:42Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Hardened `stable_evidence_id` so failed commands, empty output, and anything other than a full SHA-1 or SHA-256 object digest return typed failures rather than producing truncated or empty identifiers.
- Made branch, tag, and worktree ID failures set `stable_id_generation_failed` receipts and aggregate partial status while continuing to render safely identified sibling observations.
- Centralized worktree stanza finalization and covered rollover, blank-line close, and final-stanza flush with command-failure, empty-output, and malformed-output fixtures.
- Preserved canonical kind-plus-subject hashing, deterministic ordering, valid empty-domain semantics, and proposal-only evidence rows.

## Task Commits

1. **Task 1: Make branch and tag identity failures source-visible** — `c16bb6c6` (RED), `a4f2c2c8` (GREEN)
2. **Task 2: Cover every worktree stanza ID failure path** — `74ba3c1c` (RED), `9e6fe7c4` (GREEN), `7f12922b` (REFACTOR)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — validates full object digests, propagates identity failures to exact Git-domain receipts, retains partial-domain sibling rows, and centralizes worktree stanza finalization.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — exposes the focused stable-ID fail-closed contract.
- `test/support/lockspire/release_proof/package_assertions.ex` — supplies branch, tag, and all worktree-boundary identity failure scenarios and assertions.

## Decisions Made

- Stable identity keeps the Phase 138-01 `kind:canonical-subject` hash input unchanged; no positional, random, short-name, or fallback identifier is permitted.
- A domain with one unidentified observation is partial even when other observations remain usable; those usable rows remain visible for evidence continuity.
- Worktree grammar failure and identity failure are combined into one precise partial receipt when both occur.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix format --check-formatted test/lockspire/release/repository_hygiene_contract_test.exs test/support/lockspire/release_proof/package_assertions.ex` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 12 tests and 0 failures.
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed, 2 tests and 0 failures.
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy` — passed; the phase correctly declares no external API integration surface.
- Source scan found no `stable_evidence_id` branch/tag/worktree call that uses `continue` or ignored `true` fallback handling.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The expected TDD RED runs reproduced false-complete branch/tag and worktree receipts before implementation.
- The plan-level format check found one long assertion; the formatter-prescribed layout was applied in the Task 2 REFACTOR commit and the complete verification sequence was rerun.

## Known Stubs

None.

## Next Phase Readiness

Branch, tag, and worktree identity generation now fails closed at every current collector path. Plan 138-09 can address maintained-record selector and hostile-path safety without relying on silently incomplete Git evidence.

## Self-Check: PASSED

- Confirmed all three changed source/test files and this summary exist.
- Confirmed all five Task 1/Task 2 RED, GREEN, and REFACTOR commits exist.
- Re-ran every task and plan verification command after the final source/test edit.
- Confirmed the changed-file stub scan is empty and no new network, authentication, file-access, or schema trust boundary was introduced.
